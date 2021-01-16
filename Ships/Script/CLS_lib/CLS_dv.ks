// CLS_dv.ks - A library of functions specific to calculating  burn times / deltaV for the CLS (Common Launch Script)
// Copyright © 2021 Qwarkk6
// Lic. CC-BY-SA-4.0 

@lazyglobal off.

// calculates remaining dV of current stage
Function StageDV {
	Parameter StageNumber.
	Local fuelmass is (PartlistFuelCapacity(stagetanks,OxidizerFuelName)*OxidizerFuelMass) + (PartlistFuelCapacity(stagetanks,CryoFuelName)*CryoFuelMass) + (PartlistFuelCapacity(stagetanks,LiquidFuelName)*LiquidFuelMass).
	
	// effective ISP
	local p is 0.
	local avgIsp is 0.
	Activeenginelist().
	for e in aelist {
		set avgIsp to avgIsp + e:availablethrust / ship:availablethrust * e:vacuumisp.
	}		
	
	if StageNumber > 1 {
		return avgIsp*9.81*ln((ship:mass-Partlistmass(Ship:partsingroup("AG10"))) / ((ship:mass-Partlistmass(Ship:partsingroup("AG10")))-fuelmass)).
	} else {
		return avgIsp*9.81*ln(ship:mass / (ship:mass-fuelmass)).
	}
}

// calulates remaining burn time for current fuel load
Function RemainingBurn {
	Parameter fuel.
	Activeenginelist().
	local ff is 0.
	For e in aelist {
		set ff to (ff+e:fuelflow).
	}
	return fuel/(ff+0.01).
}

// calculates dV required to circularise at current apoapsis
Function CircDV {
	local v1 is (ship:body:mu * (2/(ship:apoapsis + ship:body:radius) - 2/(ship:apoapsis + ship:periapsis + 2*ship:body:radius)))^0.5.
	local v2 is (ship:body:mu * (2/(ship:apoapsis + ship:body:radius) - 2/(2*ship:apoapsis + 2*ship:body:radius)))^0.5.
	return v2-v1.
}

// calculates burn time for the next manuever node. ActiveEngines() needs to be run prior
Function nodeBurnTime {
	local dV is nextnode:deltav:mag.
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