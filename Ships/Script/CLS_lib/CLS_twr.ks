// CLS_twr.ks - A library of functions specific to calculating twr / throttle in the CLS (Common Launch Script)
// Copyright © 2021 Qwarkk6
// Lic. CC-BY-SA-4.0 

@lazyglobal off.

// determines acceleration due to gravity
Function adtg {
	return(constant:g*body:mass)/(body:radius+ship:altitude)^2.
}
	
// calculates twr based on vehicleConfig
Function twr {
	local throt is min(throttle,1).
	local g is adtg().
	local thrust is PartlistAvailableThrust(aelist)+0.01.
	local srbThrust is 0.
	
	if vehicleConfig = 1 {
		set srbThrust to PartlistCurrentThrust(SRBs)+0.01.
	}
	return (throt*thrust+srbThrust)/(ship:mass*g).
}
	
// calculates maximum twr if all engines were at max thrust
Function maxtwr {
	local thrust is ship:availablethrust+0.01.
	local g is adtg().
	return thrust/(ship:mass*g).
}
	
// calculates throttle required to achieve a given TWR based on vehicleConfig
Function twrthrottle {
	parameter targetTWR.
	local g is adtg().
	if vehicleConfig = 0 {
		local engThrust is ship:availablethrust+0.1.
		global twrThrot is (ship:mass*g)/thrust*targetTWR.
	} else {
		local engThrust is PartlistAvailableThrust(aelist).
		local srbThrust is PartlistCurrentThrust(SRBs).
		if runmode = 0 {
			set srbThrust to PartlistPotentialThrust(asrblist).
		}
		global twrThrot is (ship:mass*g*targetTWR-srbThrust)/engThrust.
	}
	return Max(0.01,Min(1,twrThrot)).
}
	
// calculates post SRB separation throttle required to achieve a given TWR
Function srbsepthrottle {
	parameter targetTWR.
	local g is adtg().
	local engThrust is PartlistAvailableThrust(aelist).
	local srbMass is PartlistMass(SRBs).
	local sepThrot is ((ship:mass-srbMass)*g)/engThrust*targetTWR.
	return Max(0.01,Min(1,sepThrot)).
}