//Monitors engines for flameout
Function EngineFlameout {
	list engines in engList.
	For e in engList {
		If e:ignition and not e:flameout {
			return false.
		}
		If e:ignition and e:flameout {
			return true.
		}
	}
}

//Resource monitoring
function ReourceTracker {	
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
function HUD {
	Print "Abort Procedure          " at (0,0).
	Print "Status: " + status + "                    " at (0,1).
	Print "RCS: " + padding(rcsFuel,2,1,false) + "% | EC: " +  padding(EC,2,1,false) + "%   " at (0,2).
	Print "------------------" at (0,3).
}

//Initialise
clearscreen.
RCS on. SAS off.
abort on.
runpath("0:/cls_lib/lib_num_to_formatted_str.ks").
runpath("0:/cls_lib/lib_navball.ks").
runpath("0:/cls_lib/CLS_nav.ks").

//HUD setup
set status to "Abort Burn".

//Steering setup
//System of slowing pitching and yawing away from original steering atitude to ensure aborted capsule is clear of previous stages
set yaw to ship:facing:yaw.
set roll to ship:facing:roll.
set pitch to ship:facing:pitch.
set entrytime to time:seconds.
lock turnRate to (time:seconds - entrytime)*3.
lock steering to R(pitch+turnRate,yaw+turnRate,roll).

wait until ship:verticalspeed > 1.

until ship:verticalspeed < 0 or pitch_for_vector(ship:srfprograde:forevector) < 10 {
	ReourceTracker(). HUD().
	
	if EngineFlameout() and status = "Abort Burn" {
		set status to "Coasting".
	}
}
runpath("0:/ChuteDescent.ks").