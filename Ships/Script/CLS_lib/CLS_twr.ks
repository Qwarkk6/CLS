// CLS_twr.ks - A library of functions specific to calculating twr / throttle in the CLS (Common Launch Script)
// Copyright © 2021 Qwarkk6
// Lic. CC-BY-SA-4.0 

@lazyglobal off.

// determines acceleration due to gravity
Function adtg {
	return(constant:g*body:mass)/(body:radius+ship:altitude)^2.
}
	
// calculates twr based on mode
Function twr {
	local throt is min(throttle,1).
	local g is adtg().
	local t is partlistavthrust(aelist)+0.01.
	local st is 0.
	
	if mode = 1 {
		set st to partlistCurThrust(SRBs)+0.01.
	}
	return (throt*t+st)/(ship:mass*g).
}
	
// calculates maximum twr if all engines were at max thrust
Function maxtwr {
	local t is ship:availablethrust+0.1.
	local g is adtg().
	return t/(ship:mass*g).
}
	
// calculates throttle required to achieve a given TWR based on mode
Function twrthrottle {
	parameter targetTWR.
	local g is adtg().
	if mode = 0 {
		local t is ship:availablethrust+0.1.
		global twrThrot is (ship:mass*g)/t*targetTWR.
	} else {
		local t is partlistavthrust(aelist).
		local tC is PartlistCurThrust(SRBs).
		global twrThrot is (ship:mass*g*targetTWR-tC)/t.
	}
	return Max(0.01,Min(1,twrThrot)).
}
	
// calculates post SRB seperation throttle required to achieve a given TWR
Function srbsepthrottle {
	parameter targetTWR.
	local g is adtg().
	local t is partlistavthrust(aelist).
	local m is Partlistmass(SRBs).
	local sepThrot is ((ship:mass-m)*g)/t*targetTWR.
	return Max(0.01,Min(1,sepThrot)).
}