// CLS_dv.ks - A library of functions specific to calculating  burn times / deltaV for the CLS (Common Launch Script)
// Copyright © 2021 Qwarkk6
// Lic. CC-BY-SA-4.0 

@lazyglobal off.

// calculates remaining dV of current stage
Function stageDV {
	local plist is stagetanks.
	local englist is aelist.
	if vehicleConfig = 1 {
		set plist to ssrb.
		set englist to ssrb.
	}
	local fuelRemaining is FuelRemaining(plist).
	local shipMass is ship:mass.
	local altP is ship:body:atm:altitudepressure(ship:altitude).
	
	// effective ISP
	local mDotTotal is 0.
	local thrustTotal is 0.
	Global averageIsp is 0.
	for e in englist {
		local thrust is e:thrust.
		if thrust = 0 {
			set thrust to e:possiblethrust.
		} 
		set thrustTotal to thrustTotal + thrust.
		if e:isp = 0 { 
			set mDotTotal to mDotTotal + thrust / max(1,e:ispat(altP)).
		} else {
			set mDotTotal to mDotTotal + thrust / e:isp.
		}
	}
	if not mDotTotal = 0 {
		set averageIsp to thrustTotal/mDotTotal.
	}
	local massflow is thrustTotal/(averageIsp*constant:g0).
	Global BurnRemaining is fuelRemaining/massFlow.
	Global dVRemaining is (averageIsp*constant:g0*ln(shipMass / (shipMass-fuelRemaining)))-1.
}

// calculates dV required to circularise at current apoapsis
Function circulariseDV_Apoapsis {
	local mu is ship:body:mu.
	local apo is ship:apoapsis.
	local rad is ship:body:radius.
	
	local v1 is (mu * (2/(apo + rad) - 2/(apo + ship:periapsis + 2*rad)))^0.5.
	local v2 is (mu * (2/(apo + rad) - 2/(2*apo + 2*rad)))^0.5.
	return ABS(v2-v1).
}

// calculates dV required to circularise at current Periapsis
Function circulariseDV_Periapsis {
	local mu is ship:body:mu.
	local peri is ship:periapsis.
	local rad is ship:body:radius.
	
	local v1 is (mu * (2/(peri + rad) - 2/(ship:apoapsis + peri + 2*rad)))^0.5.
	local v2 is (mu * (2/(peri + rad) - 2/(2*peri + 2*rad)))^0.5.
	return v2-v1.
}

// calculates dV required to circularise at a periapsis of the target orbit
Function circulariseDV_TargetPeriapsis {
	Parameter targetApo is 250000.
	Parameter targetPeri is 250000.
	local mu is ship:body:mu.
	local rad is ship:body:radius.
	
	local v1 is (mu * (2/(targetPeri + rad) - 2/(ship:apoapsis + targetPeri + 2*rad)))^0.5.
	local v2 is (mu * (2/(targetPeri + rad) - 2/(targetApo + targetPeri + 2*rad)))^0.5.
	return ABS(v2-v1).
}

// calculates dV required at Apo to bring Peri to a target orbit
Function BurnApoapsis_TargetPeriapsis {
	Parameter targetOrbit is 250000.
	local mu is ship:body:mu.
	local rad is ship:body:radius.
	local apo is ship:apoapsis.
	
	local v1 is (mu * (2/(apo + rad) - 2/(apo + ship:periapsis + 2*rad)))^0.5.
	local v2 is (mu * (2/(apo + rad) - 2/(targetOrbit+apo + 2*rad)))^0.5.
	return ABS(v2-v1).
}

// calculates dV required at peri to bring apo to a target orbit
Function BurnPeriapsis_TargetApoapsis {
	Parameter targetOrbit is 250000.
	local mu is ship:body:mu.
	local rad is ship:body:radius.
	local peri is ship:periapsis.
	
	local v1 is (mu * (2/(peri + rad) - 2/(ship:apoapsis + peri + 2*rad)))^0.5.
	local v2 is (mu * (2/(peri + rad) - 2/(targetOrbit+peri + 2*rad)))^0.5.
	return v2-v1.
}

// output[1] calculates burn time for the next manuever node. 
// output[2] calculates half burn time for the next manuever node in order to calculate when to start the burn.
// output[3] calculates throttle required to limit burn to tLimit parameter
// ActiveEngines() needs to be run prior
Function nodeBurnData {
	Parameter n_node is nextnode.
	Parameter tLimit is 0.
	local dV is n_node:deltav:mag.
	local dVhalf is n_node:deltav:mag/2.
	local f is ship:availablethrust.
	local m is ship:mass.
	local e is constant:e.
	local g is constant:g0.
	local fLimit is 0.
	local manueverThrottle is 1.
	local output is list().
	
	// effective ISP
	local p is 0.
	for e in aelist {
		set p to p + e:availablethrust / f * e:vacuumisp.
	}
	
	if tLimit > 0 {
		set fLimit to (g*m*p*(1-e^((-1*dV)/(g*p))))/tLimit.	//kN thrust required to meet tLimit second burn time
		set manueverThrottle to flimit / f.
		set f to min(f,fLimit).
	}
	
	local burnDuration is g*m*p*(1-e^((-1*dV)/(g*p)))/f.
	local burnStart is g*m*p*(1-e^((-1*dVhalf)/(g*p)))/f.

	output:add(burnDuration).
	output:add(burnStart).
	output:add(manueverThrottle).
	return output.
}
