// CLS_Gen.ks - A library of general functions for the CLS (Common Launch Script)
// Copyright © 2021 Qwarkk6
// Lic. CC-BY-SA-4.0 

@lazyglobal off.

// Controls Warp rate. Prevents warp going over 2x to maintain code stability
Function warpControl {
	parameter runmode.
	local rMode is list(-666,-2,-1,0,1,2,3,4,5,6).
	local warpLimit is list(0,0,0,1,1,1,1,1,0,1).
	
	// At pre-launch if liftoff time is over a minute away
	If runmode = -1 and time:seconds - launchtime < -60 {
		if warp > 3 {
			set warp to 3.
		}
	//During staging
	} else if staginginprogress or ImpendingStaging {
		if warp > 0 {
			set warp to 0.
		}
	//When the script finishes
	} else if launchcomplete {
		if warp > 0 {
			set warp to 0.
		}
	//If circularisation burn is over 90 seconds away
	} else if runmode = 4 and ship:altitude > body:atm:height and time:seconds < burnStartTime-90 {
		if warp > 2 {
			set warp to 2.
		}
	//runmode specific warp limit
	} else {
		if warp > warpLimit[rMode:find(runmode)] {
			set warp to warpLimit[rMode:find(runmode)].
		}
	}
}

// Takes a "hh:mm:ss" input for a specific launch time and calculates seconds until this time.
Function secToLaunch {
	Parameter input.
	Local stl is input:tostring.
	Local totTime is time:seconds:tostring.
	
	if stl:contains(":") {
		local H is stl:split(":")[0].
		local M is stl:split(":")[1].
		local S is stl:split(":")[2].
		local Ss is "0." + totTime:split(".")[1].
		
		Local TodaySeconds is time:second + Ss:tonumber() + time:minute*60 + time:hour*60*60.
		Local TargetSeconds to S:tonumber() + M:tonumber()*60 + H:tonumber()*60*60.
		
		if TargetSeconds <= TodaySeconds+23 {
			Return TargetSeconds + 21600 - TodaySeconds.
		} else {
			Return TargetSeconds - TodaySeconds.
		}
	} else {
		return input.
	}
}
