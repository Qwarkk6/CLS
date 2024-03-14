// CLS_Gen.ks - A library of general functions for the CLS (Common Launch Script)
// Copyright © 2021 Qwarkk6
// Lic. CC-BY-SA-4.0 

@lazyglobal off.

// Takes a "hh:mm:ss" input for a specific launch time and calculates seconds until this time.
Function secondsToLaunch {
	Parameter input.
	Local inputString is input:tostring.
	Local timeString is time:seconds:tostring.
	
	if inputString:contains(":") {
		local Hours is inputString:split(":")[0].
		local Minutes is inputString:split(":")[1].
		local Seconds is inputString:split(":")[2].
		local Ss is "0." + timeString:split(".")[1].
		
		Local TodaySeconds is time:second + Ss:tonumber() + time:minute*60 + time:hour*60*60.
		Local TargetSeconds to Seconds:tonumber() + Minutes:tonumber()*60 + Hours:tonumber()*60*60.
		
		if TargetSeconds <= TodaySeconds+23 {
			Return TargetSeconds + round(body:rotationperiod)*60*60 - TodaySeconds.
		} else {
			Return TargetSeconds - TodaySeconds.
		}
	} else {
		return input.
	}
}

//Figures out real world time (GMT).
Function realWorldTime {
	local rwtime is kuniverse:realtime.
	local years is floor(rwtime/31536000).
	set rwtime to rwtime-(years*31536000).
	local days is floor(rwtime/86400).
	set rwtime to rwtime-(days*86400).
	local hours is floor(rwtime/3600).
	set rwtime to rwtime-(hours*3600).
	local minutes is floor(rwtime/60).
	return hours+1 + "." + minutes.
}

//Camera control function
//Cameras for launch need to be tagged "CameraLaunch"
//Cameras for Stage sep need to be tagged "CameraSep"
//Cameras for onboard views need tagged "Camera1" or "camera2" with the number associated with their stage
Function CameraControl {
	Parameter StageNumber is currentstagenum.
	Parameter Launch is false.
	local stageString is "Camera" + StageNumber.
	
	if ship:partstaggedpattern("Camera"):length > 0 {
		for p in ship:partstaggedpattern("Camera") {
			p:getmodule("MuMechModuleHullCameraZoom"):doaction("deactivate camera",true).
			p:getmodule("MuMechModuleHullCameraZoom"):doaction("deactivate camera",true).
		}
	}
	
	if Launch {
		if ship:partstagged("CameraLaunch"):length = 1 {
			ship:partstagged("CameraLaunch")[0]:getmodule("MuMechModuleHullCameraZoom"):doaction("activate camera",true).
		}
	} else {
		if ship:partstagged(stageString):length = 1 {
			ship:partstagged(stageString)[0]:getmodule("MuMechModuleHullCameraZoom"):doaction("activate camera",true).
		}
	}
}