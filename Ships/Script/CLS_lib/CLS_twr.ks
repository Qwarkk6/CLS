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
	local g is adtg().
	local engThrust is ship:thrust.
	if vehicleConfig = 1 {
		set engThrust to PartlistCurrentThrust(aelist).
	}
	local srbThrust is ship:thrust - engThrust.
	
	return (engThrust+srbThrust)/(ship:mass*g).
}

// calculates throttle required to achieve a given TWR based on vehicleConfig
Function twrthrottle {
	parameter targetTWR.
	local g is adtg().
	local twrThrot is 0.
	
	if vehicleConfig = 0 {
		local engThrust is ship:availablethrust+0.01.
		set twrThrot to (ship:mass*g)/engThrust*targetTWR.
	} else {
		local engThrust is PartlistAvailableThrust(aelist).
		local srbThrust is PartlistCurrentThrust(asrblist).
		if runmode = 0 and tminus > 0 {
			set srbThrust to PartlistPotentialThrust(asrblist).
		}
		set twrThrot to (ship:mass*g*targetTWR-srbThrust)/engThrust.
	}
	return Min(1,twrThrot).
}
