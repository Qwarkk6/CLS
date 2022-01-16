//Monitors engines for flameout
Function EngineFlameout {
	For e in engList {
		If e:ignition and not e:flameout {
			return false.
		}
		If e:ignition and e:flameout {
			return true.
		}
	}
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

//kOS terminal readouts
function abortHUD {
	Print "Abort Procedure          " at (0,0).
	Print "Status: " + shipStatus + "                    " at (0,1).
	Print "RCS: " + padding(rcsFuel,2,1,false) + "% | EC: " +  padding(EC,2,1,false) + "%   " at (0,2).
	Print "------------------" at (0,3).
}

//Initialise
clearscreen.
RCS on. SAS off.
list engines in engList.
abort on. lock throttle to 1.
runpath("0:/CLS_lib/lib_num_to_formatted_str.ks").
runpath("0:/CLS_lib/lib_navball.ks").
runpath("0:/CLS_lib/CLS_nav.ks").

//HUD setup
set shipStatus to "Abort Burn".

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
	
	if EngineFlameout() and shipStatus = "Abort Burn" {
		set shipStatus to "Coasting".
		lock steering to ship:srfprograde.
	}
}
runpath("0:/ChuteDescent.ks").