//Monitors engines for flameout
Function EngineFlameout {
	list engines in engList.
	if engList:length = 1 {
		For p in engList {
			if p:getmodule("ModuleEnginesFX"):getfield("status") = "Flame-Out!" {
				return true.
			} else {
				return false.
			}
		}
	} else {
		For e in engList {
			If e:ignition and not e:flameout {
				return false.
			}
			If e:ignition and e:flameout {
				return true.
			}
		}
	}
}

//Resource monitoring
function AbortResMonitor {	
	For res in ship:resources {
		If res:Name = "ElectricCharge" {
			set EC to (Res:Amount/Res:Capacity)*100.
		}
		if res:Name = "Aerozine50" {
			set rcsFuel to (Res:Amount/Res:Capacity)*100.
		} 
	}		
} 

//kOS terminal readouts
function AbortHUD {
	Print "Abort Procedure          " at (0,0).
	Print "Status: " + shipStat + "                    " at (0,1).
	Print "RCS: " + padding(rcsFuel,2,1,false) + "% | EC: " +  padding(EC,2,1,false) + "%   " at (0,2).
	Print "------------------" at (0,3).
}

clearscreen.
runpath("0:/cls_lib/lib_num_to_formatted_str.ks").
runpath("0:/cls_lib/lib_navball.ks").
runpath("0:/cls_lib/CLS_nav.ks").
toggle abort.
set rcsFuel to 0.
set EC to 0.
RCS on. SAS off.
set entrytime to time:seconds.

//Steering setup
set Yaw to ship:facing:yaw.
set Roll to ship:facing:roll.
set Pitch to ship:facing:pitch.
set steerto to heading(Pitch,Yaw,Roll).
lock steering to steerto.

until EngineFlameout() = true {
	set tRate to (time:seconds - entrytime)*2.5.
	set steerto to R(Pitch+tRate,Yaw+tRate,Roll).
	set shipStat to "Abort Burn".
	AbortResMonitor(). AbortHUD().
	wait 0.001.
}

until ship:verticalspeed < 0 or pitch_for_vect(ship,ship:srfprograde:forevector) < 10 {
	set steerto to R(Pitch+tRate,Yaw+tRate,Roll).
	set shipStat to "Coasting".
	AbortResMonitor(). AbortHUD().
	wait 0.001.
}

runpath("0:/ReEntry.ks").