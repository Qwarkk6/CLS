// CLS_nav.ks - A library of functions specific to navigation in the CLS (Common Launch Script)
// Copyright © 2021 Qwarkk6
// Lic. CC-BY-SA-4.0 

@lazyglobal off.

// Locks roll to the 4 directions
Function rollLock {
	parameter cRoll.
	if cRoll >= 45 and cRoll < 135 {
		return 90.
	}
	if cRoll >= 135 and cRoll < 225 {
		return 180.
	}
	if cRoll >= 225 and cRoll < 315 {
		return 270.
	}
	if cRoll >= 315 and cRoll < 45 {
		return 0.
	}
}

// Finds pitch for a specified vector
function pitch_for_vect {
	parameter vect.
	return 90 - vectorangle(ship:up:forevector,vect).
}

// Finds compass heading for a specified vector.
// Credit to /u/Dunbaratu (one of the creators of kOS) for this function
function compass_for_vect {
	parameter vect.

	local east is east_for().
	local x is vdot(ship:north:vector,vect).
	local y is vdot(east,vect).
	local compass is arctan2(y,x).

	if compass < 0 { 
		return 360 + compass.
	} else {
		return compass.
	}	
}

// Calculates pitch for ascent
// Credit to TheGreatFez for this function. I have modified it slightly to limit angle of attack during high dynamic pressure
function PitchProgram_Sqrt {
	parameter switch_alt is 0.
	parameter scale_factor is 0.7.
	local alt is ship:altitude-switch_alt.
	local maxQsteer is max(0,10-ship:q*15).
	local pitch_max is pitch_for_vect(Ship:srfprograde:forevector)+maxQsteer.
	local pitch_min is pitch_for_vect(Ship:srfprograde:forevector)-maxQsteer.
	local alt_diff is scale_factor*(body:atm:height-switch_alt).
	
	if ship:altitude >= switch_alt {
		global pitch_ang is 90 - max(5,min(85,90*sqrt(alt/alt_diff))).
	}
	return max(min(pitch_ang,pitch_max),pitch_min).
}

//Engages RCS during staging while engines are not burning to maintain attitude control
function stagingRCS {
	parameter t.
	
	if time:seconds - t < 10 and time:seconds - t > 0 {
		if throttle < 0.1 {
			rcs on.
		}
	} else {
		rcs off.
	}
}