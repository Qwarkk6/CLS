// CLS_Gen.ks - A library of general functions for the CLS (Common Launch Script)
// Copyright © 2021 Qwarkk6
// Lic. CC-BY-SA-4.0 

@lazyglobal off.

// Controls Warp rate. Cancels time warp for launch, abort & staging. Prevents warp going over 2x to maintain code stability
Function Warpcontrol {
	If runmode = -666 or launchcomplete = true {
		If warp > 0 Set warp to 0.
	}
	If runMode = -1 {
		if cdown > -60 {
			If warp > 0 Set warp to 0.
		} else {
			If warp > 3 Set warp to 3.
		}
	}
	If runMode >= 0 {
		If staginginprogress or ImpendingStaging {
			If warp > 0 Set warp to 0.
		} else if runmode = 4 {
			if time:seconds < burnStartTime-60 {
				If warp > 2 Set warp to 2.
			} else {
				Set warp to 0.
			}
		} else if runmode = 5 {
			Set warp to 0.
		} else {
			If warp > 1 Set warp to 1.
		}
	}
}

// Takes a "hh:mm:ss" input for a specific launch time and calculates seconds until this time.
Function SecToLaunch {
	Parameter STLInput.
	Local STL is STLInput:tostring.
	Local TotTime is time:seconds:tostring.
	
	if STL:contains(":") {
		local H is STL:split(":")[0].
		local M is STL:split(":")[1].
		local S is STL:split(":")[2].
		local Ss is "0." + TotTime:split(".")[1].
		
		Local TodaySeconds is time:second + Ss:tonumber() + (time:minute*60) + (time:hour*60*60).
		Local TargetSeconds to S:tonumber() + (M:tonumber()*60) + (H:tonumber()*60*60).
		
		if TargetSeconds <= (TodaySeconds+23) {
			Return (TargetSeconds + 21600) - TodaySeconds.
		} else {
			Return TargetSeconds - TodaySeconds.
		}
		
	} else {
		return STLInput.
	}
}
