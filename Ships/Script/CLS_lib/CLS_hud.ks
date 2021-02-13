// CLS_hud.ks - A library of functions specific to how the CLS (Common Launch Script) prints to the in-game terminal
// Copyright © 2021 Qwarkk6
// Lic. CC-BY-SA-4.0 

@lazyglobal off.

// Scroll print function
// Credit to /u/only_to_downvote / mileshatem for the original (and much more straightforward) scrollprint function that this is an adaptation of
Function scrollprint {
	Declare parameter nextprint.
	local maxlinestoprint is 34.	// Max number of lines in scrolling print list
	local listlinestart is 6.		// First line For scrolling print list
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
Function engineReadout {
	parameter stage.
	local stageNum is list(0,1,2,3).
	local string is list("-","Main Engine","Second Engine","Third Engine").
	
	if stage > 3 {
		Return "Engine".
	} else {
		return string[stageNum:find(stage)].
	}
}

// Periodic readouts for vehicle speed, altitude and downrange distance
Function eventLog {
	local logTimeIncrement is 60.
	local launchLoc is kerbin:geopositionlatlng(-0.0972601544390867,-74.5576823578623).
	local shipGEO is ship:geoposition.
	
	If runMode > 1 {
		If ship:altitude >= body:atm:height {
			scrollPrint("Karman Line Reached").
		}
		If missiontime >= logTime {
			
			//Downrange calculations
			local v1 is shipGEO:position - ship:body:position.
			local v2 is launchLoc:position - ship:body:position.
			local distAng is vang(v1,v2).
			local downRangeDist is distAng * constant:degtorad * ship:body:radius.
			
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
	Parameter logging.
	
	Print Ship:name + " Launch Sequence Initialised" at (0,0).
	Print "Target Launch Time: NET " + T_O_D(launchtime) at (0,1).
	if targetapoapsis = 500000 {
		Print "Target Parking Orbit: Highest Possible" at (0,2).
	} else {
		Print "Target Parking Orbit: " + Ceiling(targetapoapsis,2) + "m" at (0,2).
	}
	Print "Target Orbit Inclination: " + Ceiling(ABS(targetinclination),2) + "°" at (0,3).
	if logging {
		Print "-Logging-Data---------------------------------------" at (0,40).
	} else {
		Print "----------------------------------------------------" at (0,40).
	}
	Print "Fuel: 000s" at (41,42).
	Print "Offset: --°" at (1,42).
	Print "Apo:  000s" at (41,41).
}

// Handles countdown 
Function countdown {
	Parameter tminus.
	Parameter cdown.
	local cdlist is list(list(20,19,17,15,13,11,9,8,7,5,4),list("Startup","$","$","$","$","$","$","Range is Green","$","$","$")).
	
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
	
	local hud_met is "Mission Elapsed Time: " + "T" + D_MT(missiontime).
	local hud_pitch is "Pitch: " + padding(Round(trajectorypitch,1),2,1,false) + "°".
	local hud_stage is "Stage: " + currentstagenum + "/" + MaxStages.
	local hud_staging is "-------".								
	local hud_var1 is "Aero: " + padding(Round(ship:q,2),1,2,false).
	local hud_var2 is "Mode:  " + mode.
	local hud_twr is "TWR:  " + padding(Round(max(twr(),0),2),1,2,false).
	local hud_apo is "Apo:  000s ".
	local hud_fuel is "Fuel: " + padding(min(999,Round(RemainingBurn())),3,0,false) + "s".
	local hud_azimuth is "Head:  " + padding(Round(launchazimuth,1),2,1,false) + "°".
	
	if runmode > -1 {
		set hud_apo to "Apo:  " + padding(round(min(999,eta:apoapsis)),3,0,false) + "s ".
	}
	If staginginprogress or ImpendingStaging {
		set hud_staging to "Staging".
	} 
	if ship:apoapsis > body:atm:height and currentstagenum > 1 and (Time:seconds - stagefinishtime) >= 5 {
		set hud_var1 to "Circ: " + padding(Round(CircDV()),2,0,false) + "m/s ".
		set hud_var2 to "dV: " + padding(Round(StageDV(currentstagenum)),2,0,false) + "m/s ".
	}
	if RemainingBurn() > 999 {
		set hud_fuel to "Fuel: 000s".
	}
	
	local hud_printlist is list(hud_met,hud_pitch,hud_stage,hud_staging,hud_var1,hud_var2,hud_twr,hud_apo,hud_fuel,hud_azimuth).
	local hud_printlocx is list(00,01,29,23,16,29,16,41,41,01).
	local hud_printlocy is list(04,41,42,40,41,41,42,41,42,42).
	
	local printLine is 0.
	until printLine = hud_printlist:length {
        print hud_printlist[printLine] at (hud_printlocx[printLine],hud_printlocy[printLine]).
		set printLine to printLine+1.
	}
}

// GUI for unexpected issues during countdown
Function scrubGUI {
	Parameter scrubreason.
	Parameter runmode.

	local isDone is false.
	local proceedMode is 0.
	local gui is gui(200).
	
	//Label 0
	local label0 is gui:addLabel("Unplanned Hold").
	set label0:style:align to "center".
	set label0:style:hstretch to true. // fill horizontally
	
	//Label 1
	local label1 is gui:addLabel(scrubreason).
	set label1:style:align to "center".
	set label1:style:hstretch to true. // fill horizontally
	
	if runmode = -2 {
		global continue is gui:addbutton("Continue Countdown").
		set continue:onclick to {
			set isDone to true.
			set proceedMode to 1.
		}.
	} else if runmode = -3 {
		global recycle is gui:addbutton("Recycle Countdown").
		set recycle:onclick to {
			set isDone to true.
			set proceedMode to 2.
		}.
	}
	local scrub is gui:addbutton("Scrub Launch").
	set scrub:onclick to {
		set isDone to true.
		set proceedMode to 3.
	}.
	gui:show().
	
	wait until isDone.
	gui:hide().
	return proceedMode.
}