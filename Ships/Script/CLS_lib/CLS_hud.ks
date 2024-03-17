// CLS_hud.ks - A library of functions specific to how the CLS (Common Launch Script) prints to the in-game terminal
// Copyright © 2021 Qwarkk6
// Lic. CC-BY-SA-4.0 

@lazyglobal off.

//Handles countdown status update printing
Function CdownPrint {
	Parameter nextprint.
	Parameter statusUpdate is true.
	
	if statusUpdate {
		print "                                                    " at (0,listlinestart).
		print "T" + hud_missionTime(cdown) + " - " + nextprint at (0,listlinestart).
	} else {
		print "T" + hud_missionTime(cdown) at (0,listlinestart).
	}
}

// Handles countdown non-status update printing
Function countdown {
	Parameter tminus.
	Parameter cdown.
	local cdlist is list(19,17,15,13,11,9,8,6,4).
	
	if cdlist[cdownreadout] = tminus {
		if abs(floor(cdown)) = tminus {
			print "T" + hud_missionTime(cdown) at (0,listlinestart).
			set cdownreadout to min(cdownreadout+1,8).
			global tminus is tminus-1.
		}
	} 
}

// Scroll print function
// Credit to /u/only_to_downvote / mileshatem for the original (and much more straightforward) scrollprint function that this is an adaptation of
Function scrollprint {
	Parameter nextprint.
	Parameter tStamp is true.
	local maxlinestoprint is 32.	// Max number of lines in scrolling print list
	
	if tStamp = true {
		local t_plus is "T" + hud_missionTime(missionElapsedTime) + " - ".
		printqueue:add(t_plus + nextprint).
	} else {
		printqueue:add(nextprint).
	}
	
	local duplicate is false.
	if printqueue:length > 1 {
		local lastprint is printqueue[printqueue:length-2].
		local thisprint is printqueue[printqueue:length-1].
		if lastprint:contains(thisprint) { set duplicate to true. }
	}
	
	if not duplicate {
		if printqueue:length < maxlinestoprint {
			print printqueue[printqueue:length-1] at (0,(printqueue:length-1)+listlinestart).
		} else {
			printqueue:remove(0).
			local currentline is listlinestart.
			until currentLine = 38 {
				For printline in printqueue {
					Print "                                                 " at (0,currentLine).
					Print printline at (0,currentline).
					Set currentline to currentline+1.
				}
			}
		}
	} else {
		printqueue:remove(printqueue:length-1).
	}
}

// presents time of day in hh:mm:ss format
Function t_o_d {
	parameter currtime.
	
	local hoursPerDay is round(body:rotationperiod/3600).
	local dd is floor(currtime/(hoursPerDay*3600)).  
	local hh is floor((currtime-hoursPerDay*3600*dd)/3600).  
	local mm is floor((currtime-3600*hh-hoursPerDay*3600*dd)/60).  
	local ss is round(currtime) - mm*60 -   hh*3600 - hoursPerDay*3600*dd. 

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
	parameter stageNum.
	local stageNumber is list(0,1,2,3).
	local string is list("-","Main Engine","Second Engine","Third Engine").
	
	if stageNum > 3 {
		Return "Engine".
	} else {
		return string[stageNumber:find(stageNum)].
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

// Initiates the HUD on the terminal
Function HUDinit {
	Parameter launchtime.
	Parameter targetapoapsis.
	Parameter targetperiapsis.
	Parameter targetinclination.
	
	Print Ship:name + " Launch Sequence Initialised" at (0,0).
	Print "Target Launch Time: NET " + T_O_D(launchtime) at (0,1).
	if targetapoapsis = maxApoapsis {
		Print "Target Parking Orbit: Highest Possible" at (0,2).
	} else {
		Print "Target Parking Orbit: " + Ceiling(targetapoapsis/1000,2) + "km x " + Ceiling(targetperiapsis/1000,2) + "km" at (0,2).
	}
	Print "Target Orbit Inclination: " + Ceiling(targetinclination,2) + "°" at (0,3).
	Print "----------------------------------------------------" at (0,39).
}

// Identifies / Calculates data to be displayed on the terminal HUD.
Function AscentHUD {
	
	local hud_met is "Mission Elapsed Time: " + "T" + hud_missionTime(missionElapsedTime) + " (" + runmode + ") ".
	local hud_staging is "-------------------".
	local hud_alt is "Alt: " + floor(ship:altitude/1000,2) + "km   ".
	local hud_apo is "Apo: " + floor(ship:apoapsis/1000,2) + "km   ".
	local hud_apo_eta is "eta: " + round(eta:apoapsis,0) + "s    ".
	local hud_peri is "Per: " + floor(ship:periapsis/1000,2) + "km   ".
	local hud_peri_eta is "eta: " + round(eta:periapsis,0) + "s    ".
	local hud_ecc is "Ecc: " + max(Round(ship:orbit:eccentricity,4),0.0001).
	local hud_inc is "Inc: " + Round(ship:orbit:inclination,4) + "°  ".
	local hud_isp is "ISP: " + Round(averageIsp,1) + "s   ".
	local hud_dV is " dV: " + Round(dVRemaining) + "m/s  ".
	local hud_dV_req is "Req: ------- ".
	local hud_pitch is "Pitch: " + Round(trajectorypitch,1) + "°   ".
	local hud_head is "Head:  " + Round(launchazimuth,1) + "°   ".
	local hud_fuel is "Fuel:  " + min(999,Round(BurnRemaining)) + "s  ".
	local hud_twr is "TWR:   " + Round(max(vesTWR,0),2) + "   ".
	local hud_throttle is "Throt: " + Round(max(min(throttle,1),0)*100,1) + "%  ".
	
	if eta:apoapsis > 300 {
		set hud_apo_eta to "eta: " + floor(eta:apoapsis/60) + "m    ".
	}
	if eta:periapsis > 300 {
		set hud_peri_eta to "eta: " + floor(eta:periapsis/60) + "m    ".
	}
	If staginginprogress {
		set hud_staging to "----- Staging -----".
	} 
	if ImpendingStaging {
		set hud_staging to " Impending Staging ".
	}
	if LEO = true {
		if threeBurn = true {
			set hud_dV_req to "Req: " + Round(BurnApoapsis_TargetPeriapsis(targetapoapsis)+ABS(circulariseDV_TargetPeriapsis(targetapoapsis,targetperiapsis))) + "m/s ".
		} else {
			set hud_dV_req to "Req: " + Round(ABS(circulariseDV_Periapsis)) + "m/s  ".
		}
	}
	if ship:apoapsis > ship:body:atm:height {
		set hud_dV_req to "Req: " + Round(circulariseDV_Apoapsis()) + "m/s  ".
	}
	if runmode > 2 {
		if hasnode {
			set hud_pitch to "Circ:  " + Round(max(0,burnDuration-max(0,time:seconds-burnStartTime)),1) + "s  ".
			set hud_head to "Eta:   " + Round(max(burnStartTime-time:seconds,0),0) + "s  ".
		} else {
			set hud_pitch to "Circ:  " + "N/A  ".
			set hud_head to "Eta:   " + "N/A  ".
		}
	}
	
	print hud_met at (0,4).
	print hud_staging at (17,39).
	print hud_alt at (1,40). print hud_ecc at (19,40). print hud_pitch at (35,40).
	print hud_apo at (1,41). print hud_inc at (19,41). print hud_head at (35,41).
	print hud_apo_eta at (1,42). print hud_isp at (19,42). print hud_fuel at (35,42).
	print hud_peri at (1,43). print hud_dV at (19,43). print hud_twr at (35,43).
	print hud_peri_eta at (1,44). print hud_dV_req at (19,44). print hud_throttle at (35,44).
}

// GUI for unexpected issues during countdown
Function scrubGUI {
	Parameter cdownHoldReason.
	
	local userInput is false.
	local proceedMode is 0.
	local HUD_gui is gui(290).
	local scrubInfo is "Unknown Scrub Reason".
	local scrubInfoCont is "".
	//local scrubInfoCont2 is "".
	
	if cdownHoldReason = "MFT Detect Issue" {
		set scrubInfo to "CLS has failed to gather necessary info about the vehicles fuel type, mass & capacity. CLS will not function as intended without this information. Continue at your own risk!".
	} else if cdownHoldReason = "Subnominal Staging Detected" {
		set scrubInfo to "Something is wrong with vehicle staging order. Staging requirements are as follows:".
		set scrubInfoCont to "• Initial launch engines must be placed into stage 1.  • SRBs (if present) must be placed into stage 2.       • Launch clamps must be placed into stage 3 (if the rocket has SRBs) or stage 2 (if the rocket has no SRBs).".
		//set scrubInfoCont2 to "Issue relates to: " + stagingErrorPart:join(", ").
	} else if  cdownHoldReason = "AG10 Advisory" {
		set scrubInfo to "There is nothing in action group 10. AG10 is reserved for fairing jettison".
	} else if cdownHoldReason = "Crew Abort Procedure Error" {
		set scrubInfo to "CLS has detected crew onboard, but nothing in the abort action group or no chutes attached to the crew pod".
	} else if cdownHoldReason = "Insufficient Power" {
		set scrubInfo to "Vehicle electric charge is below 40%".
	} else if cdownHoldReason = "No launch clamps detected" {
		set scrubInfo to "CLS cannot detect any launch clamps. Scrub advised".
	}.
	
	//Label 0
	local label0 is HUD_gui:addLabel("<size=18>Unplanned Hold</size>").
	set label0:style:align to "center".
	set label0:style:hstretch to true. // fill horizontally
	
	//Label 1
	local label1 is HUD_gui:addLabel(cdownHoldReason).
	set label1:style:fontsize to 16.
	set label1:style:align to "center".
	set label1:style:hstretch to true. // fill horizontally
	
	//Buttons
	local buttonline1 is HUD_gui:addhlayout().
	local buttonline2 is HUD_gui:addhlayout().
	local continue is buttonline1:addbutton("Continue Countdown").
	set continue:style:width to 145.
	local recycle is buttonline1:addbutton("Recycle Countdown").
	set recycle:style:width to 145.
	local scrub is buttonline2:addbutton("Scrub Launch").
	set scrub:style:width to 145.
	local explain is buttonline2:addbutton("More info").
	set explain:style:width to 145.
	
	//Label2
	local label2 is HUD_gui:addLabel(scrubInfo).
	set label2:style:align to "center".
	set label2:style:hstretch to true.	
	label2:hide().
	
	//Label3
	local label3 is HUD_gui:addLabel(scrubInfoCont).
	set label3:style:hstretch to true.	
	label3:hide().
	
	//Label3
	//local label4 is HUD_gui:addLabel(scrubInfoCont2).
	//set label4:style:hstretch to true.	
	//label4:hide().
	
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
		//if label4:text:length > 0 { label4:show(). }
	}.
	HUD_gui:show().
	wait until userInput.
	HUD_gui:hide().
	return proceedMode.
}.