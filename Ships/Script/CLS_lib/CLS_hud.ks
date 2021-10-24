// CLS_hud.ks - A library of functions specific to how the CLS (Common Launch Script) prints to the in-game terminal
// Copyright © 2021 Qwarkk6
// Lic. CC-BY-SA-4.0 

@lazyglobal off.

// Scroll print function
// Credit to /u/only_to_downvote / mileshatem for the original (and much more straightforward) scrollprint function that this is an adaptation of
Function scrollprint {
	Parameter nextprint.
	Parameter timeStamp is true.
	local maxlinestoprint is 33.	// Max number of lines in scrolling print list
	local t_minus is "T" + hud_missionTime(cdown).
	local t_plus is "T" + hud_missionTime(missiontime).

	if timeStamp = true {
		if runmode = 0 {
			printlist:add(t_minus + " - " + nextprint).
		} else {
			printlist:add(t_plus + " - " + nextprint).
		}
	} else {
		printlist:add(nextprint).
	}

	if printlist:length < maxlinestoprint {
		For printline in printlist {
			print printlist[printlist:length-1] at (0,(printlist:length-1)+listlinestart).
		}
	} else {
		printlist:remove(0).
		local currentline is listlinestart.
		until currentLine = 38 {
			For printline in printlist {
				Print "                                                 " at (0,currentLine).
				Print printline at (0,currentline).
				Set currentline to currentline+1.
			}
		}
	}
}

// presents time of day in hh:mm:ss format
Function t_o_d {
	parameter time.
	
	local hoursPerDay is round(body:rotationperiod).
	local dd is floor(time/(hoursPerDay*3600)).  
	local hh is floor((time-hoursPerDay*3600*dd)/3600).  
	local mm is floor((time-3600*hh-hoursPerDay*3600*dd)/60).  
	local ss is round(time) - mm*60 -   hh*3600 - hoursPerDay*3600*dd. 

	if ss = 60 {
		set ss to 0.
		set mm to mm+1.
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
function hud_missionTime {
	parameter mission_time.
	local mm is floor(Abs(mission_time)/60).
	local ss is round(Abs(mission_time))-(mm*60).
	local t is "-".
	
	If mission_time < 0 {
		set t to "-".
	} else {
		set t to "+".
	}
	
	if ss < 10 {
		set ss to "0" + ss.
	}
	if ss = 60 {
		set mm to mm+1.
		set ss to "00".
	}
	if mm < 10 {
		set mm to "0" + mm.
	}
	
	return t + mm + ":" + ss.
}

// Converts stage number to engine readout text.
Function engineReadout {
	parameter stage.
	local stageNumber is list(0,1,2,3).
	local string is list("-","Main Engine","Second Engine","Third Engine").
	
	if stage > 3 {
		Return "Engine".
	} else {
		return string[stageNumber:find(stage)].
	}
}

//Function for detecting when maxQ occurs
Function maxQ {
	parameter dynamicPressure.
	
	if dynamicPressure = 0 {
		global dynamicPressure is ship:Q.
	}
	if time:Seconds > dynamicPressureTime {
		if ship:Q < dynamicPressure {
			scrollPrint("Max Q").
			set passedMaxQ to true.
		} else {
			global dynamicPressure is ship:Q.
			global dynamicPressureTime is time:seconds+0.5.
		}
	}
}
	
// Periodic readouts for vehicle speed, altitude and downrange distance
Function eventLog {
	If missiontime >= logTime {
		//Downrange calculations
		local v1 is ship:geoposition:position - ship:body:position.
		local v2 is launchLoc:position - ship:body:position.
		local downRangeDistance is vang(v1,v2) * constant:degtorad * ship:body:radius.
		
		scrollPrint("Speed: "+FLOOR(Ship:AIRSPEED*3.6) + "km/h").
		scrollPrint("          Altitude: "+ROUND(ship:altitude/1000,2)+"km",false).
		scrollPrint("          Downrange: "+ROUND(downRangeDistance/1000,2)+"km",false).
		Set logTime to logTime + 60.
	}
}

// Initiates the HUD on the terminal
Function HUDinit {
	Parameter launchtime.
	Parameter targetapoapsis.
	Parameter targetperiapsis.
	Parameter targetinclination.
	Parameter logging.
	
	Print Ship:name + " Launch Sequence Initialised" at (0,0).
	Print "Target Launch Time: NET " + T_O_D(launchtime) at (0,1).
	if targetapoapsis = maxApo {
		Print "Target Parking Orbit: Highest Possible" at (0,2).
	} else {
		Print "Target Parking Orbit: " + Ceiling(targetapoapsis/1000,2) + "km x " + Ceiling(targetperiapsis/1000,2) + "km" at (0,2).
	}
	Print "Target Orbit Inclination: " + Ceiling(ABS(targetinclination),2) + "°" at (0,3).
	if logging {
		Print "-Logging-Data---------------------------------------" at (0,40).
	} else {
		Print "----------------------------------------------------" at (0,40).
	}
}

// Handles countdown 
Function countdown {
	Parameter tminus.
	Parameter cdown.
	local cdlist is list(19,17,15,13,11,9,8,7,5,4).
	
	if cdlist[cdownreadout] = tminus and tminus > 3 {
		if ABS(cdown) <= tminus {
			scrollPrint("T" + hud_missionTime(cdown),false).
			set cdownreadout to min(cdownreadout+1,9).
			global tminus is tminus-1.
		}
	} 
}

// Identifies / Calculates data to be displayed on the terminal HUD.
Function AscentHUD {
	
	local hud_met is "Mission Elapsed Time: " + "T" + hud_missionTime(missiontime) + " (" + runmode + ") ".
	local hud_staging is "-------".
	local hud_apo is "Apo: " + padding(floor(ship:apoapsis/1000,2),1,2,false) + "km ".
	local hud_apo_eta is "eta: " + padding(round(eta:apoapsis,1),3,1,false) + "s ".
	local hud_peri is "Per: " + padding(floor(ship:periapsis/1000,2),1,2,false) + "km ".
	local hud_peri_eta is "eta: " + padding(round(eta:periapsis,1),3,1,false) + "s ".
	local hud_ecc is "Ecc: " + padding(max(Round(ship:orbit:eccentricity,4),0.0001),1,4,false).
	local hud_inc is "Inc: " + padding(Round(ship:orbit:inclination,5),1,5,false) + "°".
	local hud_dV is " dV: ------- ".
	local hud_dV_req is "Req: " + padding(Round(circulariseDV_Apoapsis()),2,0,false) + "m/s ".
	local hud_pitch is "Pitch: " + padding(Round(trajectorypitch,1),2,1,false) + "° ".
	local hud_head is "Head:  " + padding(Round(launchazimuth,1),2,1,false) + "°".
	local hud_fuel is "Fuel:  ----- ".
	local hud_twr is "TWR:   " + padding(Round(max(twr(),0),2),1,2,false).
	

	if tminus < 10 or runmode > 0 {
		set hud_dV to " dV: " + padding(Round(StageDV()),2,0,false) + "m/s ".
		if vehicleConfig = 1 {
			set hud_fuel to "Fuel:  " + padding(min(999,Round(remainingburnSRB())),3,0,false) + "s ".
		} else {
			set hud_fuel to "Fuel:  " + padding(min(999,Round(remainingburn())),3,0,false) + "s ".
		}
	}
	if eta:apoapsis > 998 {
		set hud_apo_eta to "eta: " + padding(floor(eta:apoapsis/60),3,0,false) + "m  ".
	}
	if eta:periapsis > 998 {
		set hud_peri_eta to "eta: " + padding(floor(eta:periapsis/60),3,0,false) + "m  ".
	}
	If staginginprogress or ImpendingStaging {
		set hud_staging to "Staging".
	} 
	if LEO = true {
		if threeBurn = true {
			set hud_dV_req to "Req: " + padding(Round(BurnApoapsis_TargetPeriapsis(targetapoapsis)+ABS(circulariseDV_TargetPeriapsis(targetapoapsis,targetperiapsis))),2,0,false) + "m/s ".
		} else {
			set hud_dV_req to "Req: " + padding(Round(ABS(circulariseDV_Periapsis)),2,0,false) + "m/s ".
		}
	}
	if ship:apoapsis < ship:body:atm:height {
		set hud_dV_req to "Req: ------- ".
	}
	if runmode > 2 {
		set hud_pitch to "Pitch: " + padding(Round(pitch_for_vector(ship:facing:forevector),1),2,1,false) + "° ".
		set hud_head to "Head:  " + padding(Round(heading_for_vector(ship:facing:forevector),1),2,1,false) + "°".
	}

	local hud_printlist is list(hud_met,hud_staging,hud_apo,hud_apo_eta,hud_peri,hud_peri_eta,hud_ecc,hud_inc,hud_dV,hud_dV_req,hud_pitch,hud_head,hud_fuel,hud_twr).
	local hud_printlocX is list(00,23,01,01,01,01,19,19,19,19,35,35,35,35).
	local hud_printlocY is list(04,40,41,42,43,44,41,42,43,44,41,42,43,44).
	local printLine is 0.
	until printLine = hud_printlist:length {
        print hud_printlist[printLine] at (hud_printlocx[printLine],hud_printlocy[printLine]).
		set printLine to printLine+1.
	}
}

// GUI for unexpected issues during countdown
Function scrubGUI {
	Parameter cdownHoldReason.
	
	local userInput is false.
	local proceedMode is 0.
	local gui is gui(290).
	local scrubInfo is "Unknown Scrub Reason".
	local scrubInfoCont is "".
	
	if cdownHoldReason = "MFT Detect Issue" {
		set scrubInfo to "CLS has failed to gather necessary info about the vehicles fuel type, mass & capacity. CLS will not function as intended without this information. Continue at your own risk!".
	} else if cdownHoldReason = "Subnominal Staging Detected" {
		set scrubInfo to "Something is wrong with vehicle staging order. Staging requirements are as follows:".
		set scrubInfoCont to "• Initial launch engines must be placed into stage 1.  • SRBs (if present) must be placed into stage 2.       • Launch clamps must be placed into stage 3 (if the rocket has SRBs) or stage 2 (if the rocket has no SRBs).".
	} else if  cdownHoldReason = "AG10 Advisory" {
		set scrubInfo to "There is nothing in action group 10. AG10 is reserved for fairing jettison".
	} else if cdownHoldReason = "Crew Abort Procedure Error" {
		set scrubInfo to "CLS has detected crew onboard, but nothing in the abort action group".
	} else if cdownHoldReason = "Insufficient Power" {
		set scrubInfo to "Vehicle electric charge is below 40%".
	} else if cdownHoldReason = "No launch clamps detected" {
		set scrubInfo to "CLS cannot detect any launch clamps. Scrub advised".
	}.
	
	//Label 0
	local label0 is gui:addLabel("<size=18>Unplanned Hold</size>").
	set label0:style:align to "center".
	set label0:style:hstretch to true. // fill horizontally
	
	//Label 1
	local label1 is gui:addLabel(cdownHoldReason).
	set label1:style:fontsize to 16.
	set label1:style:align to "center".
	set label1:style:hstretch to true. // fill horizontally
	
	//Buttons
	local buttonline1 is gui:addhlayout().
	local buttonline2 is gui:addhlayout().
	local continue is buttonline1:addbutton("Continue Countdown").
	set continue:style:width to 145.
	local recycle is buttonline1:addbutton("Recycle Countdown").
	set recycle:style:width to 145.
	local scrub is buttonline2:addbutton("Scrub Launch").
	set scrub:style:width to 145.
	local explain is buttonline2:addbutton("More info").
	set explain:style:width to 145.
	
	//Label2
	local label2 is gui:addLabel(scrubInfo).
	set label2:style:align to "center".
	set label2:style:hstretch to true.	
	label2:hide().
	
	//Label3
	local label3 is gui:addLabel(scrubInfoCont).
	//set label3:style:align to "center".
	set label3:style:hstretch to true.	
	label3:hide().
	
	set continue:onclick to {
		set userInput to true.
		set proceedMode to 1.
	}.
	set recycle:onclick to {
		set userInput to true.
		set proceedMode to 2.
	}.
	set scrub:onclick to {
		set userInput to true.
		set proceedMode to 3.
	}.
	set explain:onclick to {
		label2:show().
		if label3:text:length > 0 { label3:show(). }
	}.
	gui:show().
	wait until userInput.
	gui:hide().
	return proceedMode.
}.