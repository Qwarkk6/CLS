// CLS_nav.ks - A library of functions specific to navigation in the CLS (Common Launch Script)
// Copyright © 2021 Qwarkk6
// Lic. CC-BY-SA-4.0 

@lazyglobal off.

// Checks rocket is stable during staging
Function SteeringHold {
	Parameter t.
	if EngstagingOverride = true {
		Global SteeringAngle is VANG(ship:facing:vector, ship:facing:vector).
	} else {	
		Global SteeringAngle is VANG(steerto:vector, ship:facing:vector).
	}
	If SteeringAngle < 1 and StagingSteerHold = false {
		global steertime1 is time:seconds.
		global StagingSteerHold is true.
	} 
	if SteeringAngle < 1 and StagingSteerHold = true {
		global steertime2 is time:seconds.
	}
	if SteeringAngle >= 1 {				//resets count if ships moves outside of 1°
		global StagingSteerHold is false.
		global steertime1 is 0.
		global steertime2 is 0.
	}
	if StagingSteerHold = true {
		if steertime2 - steertime1 > t {
			return true.
		} else {
			return false. 
		}
	}
}

// Handles PitchPD use for multiple modes
Function pitchlimit {
	parameter m,ta,et.
	
	if m = 1 {
		if ship:apoapsis > ta*0.75 or et > 100 {
			return 0.
		} else { 
			return 5.
		}
	}
	if m = 2 {
		if twr() < 0.5 {
			return 12-(twr()*10).
		} else {
			return 5.
		}
	}
}

// Locks roll to the 4 directions
Function rollLock {
	parameter currRoll.
	
	if currRoll >= 45 and currRoll < 135 {
		return 90.
	}
	if currRoll >= 135 and currRoll < 225 {
		return 180.
	}
	if currRoll >= 225 and currRoll < 315 {
		return 270.
	}
	if currRoll >= 315 and currRoll < 45 {
		return 0.
	}
}

// Finds pitch for a specified vector
function pitch_for_vect {
	parameter ves.
	parameter vect.

	return 90 - vectorangle(ves:up:forevector,vect).
}

// Finds compass heading for a specified vector.
// Credit to /u/Dunbaratu (one of the creators of kOS) for this function
function compass_for_vect {
	parameter ves.
	parameter vect.

	local east is east_for(ves).

	local x is vdot(ves:north:vector,vect).
	local y is vdot(east,vect).

	local compass is arctan2(y,x).

	if compass < 0 { 
		return 360 + compass.
	} else {
		return compass.
	}	
}