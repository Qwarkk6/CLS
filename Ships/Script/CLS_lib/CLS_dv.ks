// CLS_dv.ks - A library of functions specific to calculating  burn times / deltaV for the CLS (Common Launch Script)
// Copyright © 2021 Qwarkk6
// Lic. CC-BY-SA-4.0 

@lazyglobal off.

// calculates remaining dV of current stage
Function stageDV {
	local plist is aelist.
	local fuelmass is FuelRemaining(stagetanks,ResourceOne)*ResourceOneMass + FuelRemaining(stagetanks,ResourceTwo)*ResourceTwoMass.
	local shipMass is ship:mass.
	
	if vehicleConfig = 1 {
		set fuelmass to FuelRemaining(asrblist,SolidFuelName)*SolidFuelMass.
		set plist to asrblist.
	}

	// effective ISP
	local mDotTotal is 0.
	local thrustTotal is 0.
	local averageIsp is 0.
	for e in plist {
		local thrust is e:thrust.
		if thrust = 0 {
			set thrust to e:possiblethrust.
		} 
		set thrustTotal to thrustTotal + thrust.
		if e:isp = 0 { 
			set mDotTotal to mDotTotal + thrust / max(1,e:ispat(ship:body:atm:altitudepressure(ship:altitude))).
		} else {
			set mDotTotal to mDotTotal + thrust / e:isp.
		}
	}
	if not mDotTotal = 0 {
		set averageIsp to thrustTotal/mDotTotal.
	}
	return (averageIsp*constant:g0*ln(shipMass / (shipMass-fuelmass)))-1.
}

// calulates remaining burn time for current fuel load
Function remainingBurn {
	local fuelRemaining is FuelRemaining(stagetanks,ResourceOne) + FuelRemaining(stagetanks,ResourceTwo).
	local fuelFlow is 0.01.
	local engList is aelist:copy().
	
	If Ship:partstaggedpattern("^CentralEngine"):length > 0 {
		for p in engList {
			if p:tag = "CentralEngine" {
				global idx is aelist:find(p).
			}
		}
		engList:remove(idx).
		For e in engList {
			if e:fuelflow = 0 {
				set fuelFlow to fuelFlow+e:maxfuelflow.
			} else {
				set fuelFlow to fuelFlow+e:fuelflow.
			}
		}
	} else {
		For e in aelist {
			if e:fuelflow = 0 {
				set fuelFlow to fuelFlow+e:maxfuelflow.
			} else {
				set fuelFlow to fuelFlow+e:fuelflow.
			}
		}
	}
	return fuelRemaining/fuelFlow.
}

// calulates remaining burn time for current fuel load
Function remainingBurnSRB {
	local fuelRemaining is 0.01.
	local fuelFlow is 0.01.
	For tank in asrblist {
		For res in tank:resources {
			if res:name = SolidFuelName and res:enabled = true {
				set fuelRemaining to (fuelRemaining + res:amount).
			}
		}
	}
	For e in asrblist {
		if e:fuelflow = 0 {
			set fuelFlow to fuelFlow+e:maxfuelflow.
		} else {
			set fuelFlow to fuelFlow+e:fuelflow.
		}
	}
	return fuelRemaining/fuelFlow.
}

// calculates dV required to circularise at current apoapsis
Function circulariseDV_Apoapsis {
	local v1 is (ship:body:mu * (2/(ship:apoapsis + ship:body:radius) - 2/(ship:apoapsis + ship:periapsis + 2*ship:body:radius)))^0.5.
	local v2 is (ship:body:mu * (2/(ship:apoapsis + ship:body:radius) - 2/(2*ship:apoapsis + 2*ship:body:radius)))^0.5.
	return ABS(v2-v1).
}

// calculates dV required to circularise at current Periapsis
Function circulariseDV_Periapsis {
	local v1 is (ship:body:mu * (2/(ship:periapsis + ship:body:radius) - 2/(ship:apoapsis + ship:periapsis + 2*ship:body:radius)))^0.5.
	local v2 is (ship:body:mu * (2/(ship:periapsis + ship:body:radius) - 2/(2*ship:periapsis + 2*ship:body:radius)))^0.5.
	return v2-v1.
}

// calculates dV required to circularise at a periapsis of the target orbit
Function circulariseDV_TargetPeriapsis {
	Parameter targetApo is 250000.
	Parameter targetPeri is 250000.
	local v1 is (ship:body:mu * (2/(targetPeri + ship:body:radius) - 2/(ship:apoapsis + targetPeri + 2*ship:body:radius)))^0.5.
	local v2 is (ship:body:mu * (2/(targetPeri + ship:body:radius) - 2/(targetApo + targetPeri + 2*ship:body:radius)))^0.5.
	return ABS(v2-v1).
}

// calculates dV required at Apo to bring Peri to a target orbit
Function BurnApoapsis_TargetPeriapsis {
	Parameter targetOrbit is 250000.
	local v1 is (ship:body:mu * (2/(ship:apoapsis + ship:body:radius) - 2/(ship:apoapsis + ship:periapsis + 2*ship:body:radius)))^0.5.
	local v2 is (ship:body:mu * (2/(ship:apoapsis + ship:body:radius) - 2/(targetOrbit+ship:apoapsis + 2*ship:body:radius)))^0.5.
	return ABS(v2-v1).
}

// calculates dV required at peri to bring apo to a target orbit
Function BurnPeriapsis_TargetApoapsis {
	Parameter targetOrbit is 250000.
	local v1 is (ship:body:mu * (2/(ship:periapsis + ship:body:radius) - 2/(ship:apoapsis + ship:periapsis + 2*ship:body:radius)))^0.5.
	local v2 is (ship:body:mu * (2/(ship:periapsis + ship:body:radius) - 2/(targetOrbit+ship:periapsis + 2*ship:body:radius)))^0.5.
	return v2-v1.
}

// calculates burn time for the next manuever node. ActiveEngines() needs to be run prior
Function nodeBurnTime {
	Parameter n_node is nextnode.
	local dV is n_node:deltav:mag.
	local f is ship:availablethrust.
	local m is ship:mass.
	local e is constant:e.
	local g is constant:g0.
	
	// effective ISP
	local p is 0.
	for e in aelist {
		set p to p + e:availablethrust / ship:availablethrust * e:vacuumisp.
	}	

	return g*m*p*(1-e^((-1*dV)/(g*p)))/f.
}

// calculates half burn time for the next manuever node in order to calculate when to start the burn. ActiveEngines() needs to be run prior
Function nodeBurnStart {
	Parameter MnVnode.
	local dV is MnVnode:deltav:mag/2.
	local f is ship:availablethrust.
	local m is ship:mass.
	local e is constant:e.
	local g is constant:g0.
	
	// effective ISP
	local p is 0.
	for e in aelist {
		set p to p + e:availablethrust / ship:availablethrust * e:vacuumisp.
	}	

	return g*m*p*(1-e^((-1*dV)/(g*p)))/f.
}