// CLS_nav.ks - A library of functions specific to navigation in the CLS (Common Launch Script)
// Copyright © 2021 Qwarkk6
// Lic. CC-BY-SA-4.0 

@lazyglobal off.

// Locks roll to the 4 directions
Function rollLock {
	parameter currentRoll.
	if currentRoll >= 45 and currentRoll < 135 {
		return 90.
	}
	if currentRoll >= 135 and currentRoll < 225 {
		return 180.
	}
	if currentRoll >= 225 and currentRoll < 315 {
		return 270.
	}
	if currentRoll >= 315 and currentRoll < 45 {
		return 0.
	}
}

// Finds pitch for a specified vector
function pitch_for_vector {
	parameter vect.
	return 90 - vectorangle(ship:up:forevector,vect).
}

// Finds compass heading for a specified vector.
// Credit to /u/Dunbaratu (one of the creators of kOS) for this function
function heading_for_vector {
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
	parameter baseApogee is 0.
	
	local turnend is body:atm:height*1.15.
	local currentApogee is (ship:apoapsis-BaseApogee).
	local pitch_ang is 90 - max(5,min(90,85*sqrt(currentApogee/turnend))).
	local maxQsteer is max(0.5,15-ship:q*15).
	local pitch_max is pitch_for_vector(Ship:srfprograde:forevector)+maxQsteer.
	local pitch_min is pitch_for_vector(Ship:srfprograde:forevector)-maxQsteer.
	
	return max(min(pitch_ang,pitch_max),pitch_min).
}

//Fine tunes inclination
Function incTune {
	Parameter desiredInc.
	local output is 0.
	
	local inc is ship:orbit:inclination.

	if desiredInc < 0 {
		if inc < abs(desiredInc) {
			set output to heading_for_vector(ship:prograde:vector)+(sqrt(max(abs(desiredInc)-inc,0))*5).
		} else if inc >= abs(desiredInc) {
			set output to heading_for_vector(ship:prograde:vector)-(sqrt(max(abs(desiredInc)-inc,0))*5).
		}
	} else {	
		if inc < desiredInc {
			set output to heading_for_vector(ship:prograde:vector)-(sqrt(max(abs(desiredInc)-inc,0))*5).
		} else {
			set output to heading_for_vector(ship:prograde:vector)+(sqrt(max(abs(desiredInc)-inc,0))*5).
		}
	}
	
	if output < 0 { 
		return 360 + output.
	} else {
		return output.
	}	
}

// Staging Pitch control
Function StagingPitch {		
	local srfProPitch is pitch_for_vector(Ship:srfprograde:forevector).
	
	If ImpendingStaging {
		local pDiff is abs(srfProPitch - ImpendingStagingPitch). 
		local tDiff is time:seconds - ImpendingStagingTime.
		if tDiff < 3 {
			if srfProPitch > ImpendingStagingPitch {
				return ImpendingStagingPitch + ((pDiff*tDiff)/3).
			} else {
				return ImpendingStagingPitch - ((pDiff*tDiff)/3).
			}
		} else {
			return srfProPitch.
		}
	} 
	If staginginprogress or time:seconds < stagingEndTime+3 and time:seconds > stagingEndTime { 
		set ImpendingStagingTime to 0.		
		return srfProPitch.
	}
	If time:seconds >= stagingEndTime+3 and time:seconds < stagingEndTime+6 {
		local tPitch is PitchProgram_Sqrt(gravityTurnApogee).
		local pDiff is abs(srfProPitch - tPitch). 
		local tDiff is (time:seconds-3)-stagingEndTime. 
		if tDiff < 3 {
			if tPitch > srfProPitch {
				return srfProPitch + ((pDiff*tDiff)/3).
			} else {
				return srfProPitch - ((pDiff*tDiff)/3).
			}
		}
	}
}