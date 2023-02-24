//Monitors engines for flameout
Function EngineFlameout {
	list engines in engList.
	local abortFlamoutCounter is 0.
	
	if engList:length > 0 {
		For e in engList {
			If e:flameout {
				set abortFlamoutCounter to abortFlamoutCounter + 1.
			}
		}
		if abortFlamoutCounter > 0 {
			return true.
		} else {
			return false.
		}
	} else {
		return true.
	}
}

//Detect whether seperation engine in LES.
Function lesDetect {
	local check is false.
	list engines in engList.
	For e in engList {
		if e:ignition and not e:flameout {
			if e:throttlelock = true {
				lesListTemp:add(e).
			}
		}
	}
	For p in lesListTemp {
		if p:resources:join(","):contains("SolidFuel") {
			lesList:add(p).
			set check to true.
		}
	}
	return check.
}

//Checks for thrust indicating succesful abort motor ignition
Function thrustCheck {
	list engines in engList.
	local check is false.
	For e in engList {
		If e:ignition and not e:flameout {
			if e:thrust > 0 and e:fuelflow > 0 {
				set check to true.
			}
		}
	}
	return check.
}

//Resource monitoring
function abortReourceTracker {	
	list resources in resList.
	For res in reslist {
		If res:Name = "ElectricCharge" {
			set EC to (Res:Amount/Res:Capacity)*100.
		}
		if res:Name = "Aerozine50" {
			set rcsFuel to (Res:Amount/Res:Capacity)*100.
		} 
	}		
} 

//Enables all vessel resources
function enableResources {
	for p in ship:parts {
		for r in p:resources {
			if r:enabled = false {
				set r:enabled to true.
			}
		}
	}
}

//kOS terminal readouts
function abortHUD {
	Print "Abort Procedure          " at (0,0).
	Print "Status: " + shipStatus + "                    " at (0,1).
	Print "RCS: " + padding(rcsFuel,2,1,false) + "% | EC: " +  padding(EC,2,1,false) + "%   " at (0,2).
	Print "------------------" at (0,3).
}

//Initialise
clearscreen.
RCS on. SAS off. enableResources().
set engList to list(). set lesListTemp to list(). set lesList to list().
abort on. lock throttle to 1.
runpath("0:/CLS_lib/lib_num_to_formatted_str.ks").
runpath("0:/CLS_lib/lib_navball.ks").
runpath("0:/CLS_lib/CLS_nav.ks").

//HUD setup
if lesDetect() {
	set shipStatus to "LES Active".
} else {
	set shipStatus to "Abort Burn".
}

//Steering setup
//System of slowing pitching and yawing away from original steering atitude to ensure aborted capsule is clear of previous stages
set yaw to ship:facing:yaw.
set roll to ship:facing:roll.
set pitch to ship:facing:pitch.
set entrytime to time:seconds.
lock turnRate to (time:seconds - entrytime)*3.
lock steering to R(pitch+turnRate,yaw+turnRate,roll).

wait until thrustCheck().

until EngineFlameout() and ship:verticalspeed < 0 or EngineFlameout() and pitch_for_vector(ship:srfprograde:forevector) < 10 {
	abortReourceTracker(). abortHUD().
	
	if EngineFlameout() {
		if shipStatus = "Abort Burn" or shipStatus = "LES Active" {
			set shipStatus to "Coasting".
			lock steering to ship:srfprograde.
		}
		if lesList:length > 0 and Ship:partsingroup("AG10"):length > 0 {
			toggle Ag10. 
		}
	}
}

runpath("0:/ChuteDescent.ks").