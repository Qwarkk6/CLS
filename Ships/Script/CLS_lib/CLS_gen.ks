// CLS_Gen.ks - A library of general functions for the CLS (Common Launch Script)
// Copyright © 2021 Qwarkk6
// Lic. CC-BY-SA-4.0 

@lazyglobal off.

// Controls Warp rate. Cancels time warp for launch, abort & staging. Prevents warp going over 2x to maintain code stability
Function warpControl {
	parameter runMode.
	local rMode is list(-666,-3,-2,-1,0,1,2,3,4,5,6).
	local warpLimit is list(0,0,0,0,1,1,1,1,1,0,1).
	
	If runMode = -1 and cdown < -60 {
		return 3.
	} else if staginginprogress or ImpendingStaging {
		return 0.
	} else if launchcomplete {
		return 0.
	} else if runMode = 4 and ship:altitude > body:atm:height and time:seconds < burnStartTime-90 {
		return 2.
	} else {
		return warpLimit[rMode:find(runMode)].
	}
}

// Takes a "hh:mm:ss" input for a specific launch time and calculates seconds until this time.
Function secToLaunch {
	Parameter stlInput.
	Local stl is stlInput:tostring.
	Local totTime is time:seconds:tostring.
	
	if stl:contains(":") {
		local H is stl:split(":")[0].
		local M is stl:split(":")[1].
		local S is stl:split(":")[2].
		local Ss is "0." + totTime:split(".")[1].
		
		Local TodaySeconds is time:second + Ss:tonumber() + (time:minute*60) + (time:hour*60*60).
		Local TargetSeconds to S:tonumber() + (M:tonumber()*60) + (H:tonumber()*60*60).
		
		if TargetSeconds <= (TodaySeconds+23) {
			Return (TargetSeconds + 21600) - TodaySeconds.
		} else {
			Return TargetSeconds - TodaySeconds.
		}
		
	} else {
		return stlInput.
	}
}
