// CLS_hud.ks - A library of functions specific to how the CLS (Common Launch Script) prints to the in-game terminal
// Copyright © 2021 Qwarkk6
// Lic. CC-BY-SA-4.0 

@lazyglobal off.

// Scroll print function
// Credit to /u/only_to_downvote / mileshatem for the original (and much more straightforward) scrollprint function that this is an adaptation of
Function scrollprint {
	Declare parameter nextprint.
	if nextprint = "$" {
		if runmode = -1 {
			printlist:add("T" + d_mt(cdown)).
		} else {
			printlist:add("T" + d_mt(missiontime)).
		}
	} else if runmode = -2 or runmode = -3 {			
		printlist:add(nextprint).
	} else if not printlisthistory:contains(nextprint) {	
		if nextprint:startswith("   ") {
			printlist:add(nextprint).
		} else if runmode = -1 {
			printlist:add("T" + d_mt(cdown) + " - " + nextprint).
		} else {
			printlist:add("T" + d_mt(missiontime) + " - " + nextprint).
		}
	}
	//printlisthistory:add(nextprint).
	if not printlisthistory:contains(nextprint) or nextprint = "$" or runmode = -2 or runmode = -3 {
		if printlist:length = maxlinestoprint {printlist:remove(0).}
		Local currentline is listlinestart.
		For printline in printlist {
			Print "                                                 " at (0,currentLine).
			Print printline at (0,currentline).
			Set currentline to currentline+1.
		}	
		printlisthistory:add(nextprint).
	}
}

// presents time of day in hh:mm:ss format
Function t_o_d {
	parameter ts.
	
	global hpd is 6.
	global dd is floor(ts/(hpd*3600)).  
	global hh is floor((ts-hpd*3600*dd)/3600).  
	global mm is floor((ts-3600*hh-hpd*3600*dd)/60).  
	global ss is round(ts) - mm*60 -   hh*3600 - hpd*3600*dd. 

	if ss = 60 {
	global ss is 0.
		global mm is mm+1.
	}
	
	if ss < 10 and mm > 10 {
		return hh + ":" + mm + ":0" + ss.
	}
	else if ss > 10 and mm < 10 {
		return hh + ":0" + mm + ":" + ss.
	}
	else if ss < 10 and mm < 10 {
		return hh + ":0" + mm + ":0" + ss.
	}
	else {
	return hh + ":" + mm + ":" + ss.
	}	
}

// presents mission time to mm:ss format
function d_mt {
	parameter mt.
	local m is floor(Abs(mt)/60).
	local s is round(Abs(mt))-(m*60).
	local t is "-".
	
	If mt < 0 {
		set t to "-".
	} else {
		set t to "+".
	}
	
	if s < 10 {
		set s to "0" + s.
	}
	if s = 60 {
		set m to m+1.
		set s to "00".
	}
	if m < 10 {
		set m to "0" + m.
	}
	
	return t + m + ":" + s.
}

// Converts stage number to engine readout text.
Function Enginereadout {
	If currentstagenum = 1 {
		Return "Main Engine".
	}
	If currentstagenum = 2 {
		Return "Second Engine".
	}
	If currentstagenum = 3 {
		Return "Third Engine".
	}
	If currentstagenum > 3 {
		Return "Engine".
	}
}

// Periodic readouts for vehicle speed, altitude and downrange distance
Function Eventlog {
	If runMode > 1 {
		If ship:altitude >= body:atm:height {
			scrollPrint("Karman Line Reached").
		}
		If missiontime >= logTime {
			Local downRangeDist is SQRT(launchLoc:Distance^2 - (Ship:Altitude-launchAlt)^2).
			scrollPrint("Speed: "+FLOOR(Ship:AIRSPEED*3.6) + "km/h").
			scrollPrint("          Altitude: "+ROUND(Altitude/1000,2)+"km").
			scrollPrint("          Downrange: "+ROUND(downRangeDist/1000,2)+"km").
			If runMode < 3 {
				Set logTime to logTime + (logTimeIncrement).
			} else {
				Set logTime to logTime + 100000.
			}
		}
	}
}

// Initiates the HUD on the terminal
Function HUDinit {
	Parameter launchtime.
	Parameter targetapoapsis.
	Parameter targetinclination.
	Print "----------------------------------------------------" at (0,40).
	Print Ship:name + " Launch Sequence Initialised" at (0,0).
	Print "Target Launch Time: NET " + T_O_D(launchtime) at (0,1).
	if targetapoapsis = 84000000 {
		Print "Target Parking Orbit: Highest Possible" at (0,2).
	} else {
		Print "Target Parking Orbit: " + Ceiling(targetapoapsis,2) + "m" at (0,2).
	}
	Print "Target Orbit Inclination: " + Ceiling(ABS(targetinclination),2) + "°" at (0,3).
	Print "Fuel: ---%" at (41,42).
	Print "Offset: --°" at (1,42).
	Print "Apo:  000s" at (41,41).
}

// Handles countdown 
Function Countdown {
	Parameter tminus.
	Parameter cdown.
	
	if cdlist[0][cdownreadout] = tminus and tminus >= 3 {
		if ABS(cdown) <= tminus {
			scrollPrint(cdlist[1][cdownreadout]).
			set cdownreadout to min(cdownreadout+1,10).
			global tminus is tminus-1.
		}
	} 
}

// Identifies / Calculates data to be displayed on the terminal HUD.
Function AscentHUD {
	Print "Mission Elapsed Time: " + "T" + D_MT(missiontime) at (0,4).
	Print "Pitch:  " + padding(Round(trajectorypitch,1),2,1,false) + "°" at (1,41). 
	Print "      " at (23,41).
	if ship:apoapsis > body:atm:height and currentstagenum > 1 and (Time:seconds - stagefinishtime) >= 5 {
		Print "Circ: " + padding(Round(CircDV()),2,0,false) + "m/s " at (17,41).
		Print "dV: " + padding(Round(StageDV(currentstagenum)),2,0,false) + "m/s " at (30,41).
	} else {
		Print "Aero: " + padding(Round(ship:q,2),1,2,false) at (17,41).
		Print "Mode:  " + mode at (30,41).
	} 
	Print "TWR:  " + padding(Round(max(twrsrb(),0),2),1,2,false) at (17,42).
	if runmode >= 3 {
		Print "Apo:  " + padding(round(eta:apoapsis),3,0,false) + "s" at (41,41).
		Print "Fuel: " + padding(Round(Partlistfuelpercent(stagetanks,OxidizerFuelName,MFTCap)),3,0,false) + "%" at (41,42).
		if hasnode { 
			Print "Offset: " + padding(Round(VANG(steerto, cnode:burnvector),1),2,1,false) + "° " at (1,42).
		} else {
			Print "Offset: --     " at (1,42).
		}
	} else if runmode >= 0 and runmode < 3 {
		Print "Offset: " + padding(Round(VANG(steerto:vector, Ship:srfprograde:forevector),1),2,1,false) + "°" at (1,42).
		Print "Apo:  " + padding(round(eta:apoapsis),3,0,false) + "s" at (41,41).
		Print "Fuel: " + padding(Round(Partlistfuelpercent(stagetanks,OxidizerFuelName,MFTCap)),3,0,false) + "%" at (41,42).
	} else {
		Print "Offset: " + padding(Round(VANG(steerto:vector, Ship:facing:forevector),1),2,1,false) + "°" at (1,42).
	}
	
	If staginginprogress or ImpendingStaging {
		Print "Staging" at (23,40).
	} else {
		Print "-------" at (23,40).
	}
	
	Print "Stage: " + currentstagenum at (30,42).
}