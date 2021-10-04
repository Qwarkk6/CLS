// CLS_dv.ks - A library of functions specific to calculating  burn times / deltaV for the CLS (Common Launch Script)
// Copyright © 2021 Qwarkk6
// Lic. CC-BY-SA-4.0 

@lazyglobal off.

// calculates remaining dV of current stage
Function stageDV {
	Parameter P.		//whether parts in ag10 are stil present
	Local fuelmass is plistFuelRem(stagetanks,ResourceOne)*ResourceOneMass + plistFuelRem(stagetanks,ResourceTwo)*ResourceTwoMass.
	
	if P = true {
		global m is ship:mass - Partlistmass(Ship:partsingroup("AG10")).
	} else {
		global m is ship:mass.
	}

	// effective ISP
	local avgIsp is 0.
	local avT is ship:availablethrust+0.001.
	activeEngineList().
	for e in aelist {
		local t is e:availablethrust+0.001.
		set avgIsp to avgIsp + t / avT * e:vacuumisp.
	}
	return avgIsp*constant:g0*ln(m / (m-fuelmass)).
}

// calulates remaining burn time for current fuel load
Function remainingBurn {
	local fuel is plistFuelRem(stagetanks,ResourceOne)+plistFuelRem(stagetanks,ResourceTwo).
	activeEngineList().
	local ff is 0.01.
	//local idx is -1.
	local fflist is aelist:copy().
	
	If Ship:partstaggedpattern("^CentralEngine"):length > 0 {
		for p in fflist {
			if p:tag = "CentralEngine" {
				global idx is aelist:find(p).
			}
		}
		fflist:remove(idx).
		//if idx > -1 {
		//	fflist:remove(idx).
		//}
		For e in fflist {
			set ff to ff+e:fuelflow.
		}
	} else {
		For e in aelist {
			set ff to ff+e:fuelflow.
		}
	}
	return fuel/ff.
}

// calulates remaining burn time for current fuel load
Function remainingBurnSRB {
	activeSRBlist().
	local fuelrem is 0.01.
	local ff is 0.01.
	For tank in asrblist {
		For res in tank:resources {
			if res:name = SolidFuelName and res:enabled = true {
				set fuelrem to (fuelrem + res:amount).
			}
		}
	}
	For e in asrblist {
		set ff to (ff+e:fuelflow).
	}
	return fuelrem/ff.
}

// calculates dV required to circularise at current apoapsis
Function circDVApo {
	local v1 is (ship:body:mu * (2/(ship:apoapsis + ship:body:radius) - 2/(ship:apoapsis + ship:periapsis + 2*ship:body:radius)))^0.5.
	local v2 is (ship:body:mu * (2/(ship:apoapsis + ship:body:radius) - 2/(2*ship:apoapsis + 2*ship:body:radius)))^0.5.
	return ABS(v2-v1).
}

// calculates dV required to circularise at current Periapsis
Function circDVPeri {
	local v1 is (ship:body:mu * (2/(ship:periapsis + ship:body:radius) - 2/(ship:apoapsis + ship:periapsis + 2*ship:body:radius)))^0.5.
	local v2 is (ship:body:mu * (2/(ship:periapsis + ship:body:radius) - 2/(2*ship:periapsis + 2*ship:body:radius)))^0.5.
	return v2-v1.
}

// calculates dV required to circularise at a periapsis of the target orbit
Function circDVTargetPeri {
	Parameter targetOrbit is 250000.
	local v1 is (ship:body:mu * (2/(targetOrbit + ship:body:radius) - 2/(ship:apoapsis + targetOrbit + 2*ship:body:radius)))^0.5.
	local v2 is (ship:body:mu * (2/(targetOrbit + ship:body:radius) - 2/(2*targetOrbit + 2*ship:body:radius)))^0.5.
	return ABS(v2-v1).
}

// calculates dV required at Apo to bring Peri to a target orbit
Function BurnDv {
	Parameter targetOrbit is 250000.
	local v1 is (ship:body:mu * (2/(ship:apoapsis + ship:body:radius) - 2/(ship:apoapsis + ship:periapsis + 2*ship:body:radius)))^0.5.
	local v2 is (ship:body:mu * (2/(ship:apoapsis + ship:body:radius) - 2/(targetOrbit+ship:apoapsis + 2*ship:body:radius)))^0.5.
	return ABS(v2-v1).
}

// calculates burn time for the next manuever node. ActiveEngines() needs to be run prior
Function nodeBurnTime {
	Parameter node is nextnode.
	Activeenginelist().
	local dV is node:deltav:mag.
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
	Activeenginelist().
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