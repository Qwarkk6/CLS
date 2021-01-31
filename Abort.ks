// Abort.ks - An abort procedure script which maintains steering control and terminal readouts during an abort. Script terminates once the vehicle begins to fall.
// Copyright © 2021 Qwarkk6
// Lic. CC-BY-SA-4.0 

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
function AbortResMonitor {	
	For res in ship:resources {
		If res:Name = "ElectricCharge" {
			set EC to (Res:Amount/Res:Capacity)*100.
		}
		if res:Name = "MonoPropellant" {
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
set steerto to heading(compass_for_vect(ship,ship:facing:forevector),pitch_for_vect(ship,ship:facing:forevector)).
lock steering to steerto.
set entrytime to time:seconds.

until EngineFlameout() = true {
	set steerto to heading(compass_for_vect(ship,ship:facing:forevector),pitch_for_vect(ship,ship:facing:forevector)).
	set shipStat to "Abort Burn".
	AbortResMonitor(). AbortHUD().
	wait 0.001.
}

until ship:verticalspeed < 0 or pitch_for_vect(ship,ship:srfprograde:forevector) < 10 {
	set steerto to ship:srfprograde.
	set shipStat to "Coasting".
	AbortResMonitor(). AbortHUD().
	wait 0.001.
}