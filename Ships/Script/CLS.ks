// CLS.ks - An auto-launch script that handles everything from pre-launch through ascent to a final circular orbit for any desired apoapsis and inclination.
// Copyright © 2021 Qwarkk6
// Lic. CC-BY-SA-4.0 

// Massive credit to /u/only_to_downvote / mileshatem for his launchtoCirc script on which CLS.ks is based. Some of his code remains in CLS.
// launchtoCirc can be found here:	https://github.com/mileshatem/launchToCirc

//			Usage:			run CLS.						Only required input. Opens GUI for user to input their launch parameters.
//
//			GUI settings:	Desired Apoapsis	Custom: 	Allows user to input their chosen target apoapsis in km.
//												Highest: 	Launches the vehicle into the highest possible circular orbit based on its dV.
//							
//							Desired Inclination:			The inclination of the final orbit. Positive number = ascending launch azimuth. Negative number = descending launch azimuth
//							
//							Launch Window		Time:		Allows user to input a specific launch time in hh:mm:ss format. If inputted time is earlier than current time, it will presume a the launch will happen at that time the following day.
//												tMinus:		Allows user to input the number of seconds until launch. Must be higher than 23.
//												
//							Vehicle Stages:					The number of stages the vehicle has. CLS will assume these stages are for launch - if the rocket has stages not intended for use during ascent, dont include them here. 
//							

// Required staging / vehicle set-up:
//   - Initial launch engines must be placed into stage 1.
//   - SRBs (if present) must be placed into stage 2.
//	 - Launch clamps must be placed into stage 3 (if the rocket has SRBs) or stage 2 (if the rocket has no SRBs).
//   - Without ullage motors: stage separation and next stage ignition must be grouped into one stage.
//	 - With ullage motors that pull jettisoned stage away from the next stage: stage separation, ullage ignition and next stage ignition must be grouped into one stage.
//	 - With ullage motors that push the next stage away from jettisoned stage: stage separation and ullage ignition must be grouped into one stage, with next stage ignition in the following stage.
//	 - In a 3 booster config (i.e Falcon Heavy or Delta Heavy), all engines on the central booster should be tagged "CentralEngine". This allows them to be individually throttled down during ascent.
//	 - Uses RCS during stage separation so upper stage(s) should have RCS fuel/thrusters. Not a hard requirement though.
//	 - Lifoff thrust to weight ratio (TWR) must be above 1.3 (this number can be configured in TWR configuration).
//   - If launching a vehicle with crew, the script will follow an abort procedure and chute controlled decent if necessary during flight. Ensure your abort action group is correct and the crewed part has parachutes!

// Action groups:
//   - Place any fairing or LES jettison into action group 10. Will jettison based on atmopshere pressure.
//   - Abort action group will be automatically triggered if conditions are met.
//   - Due to a kOS bug(?) it is essential that parts placed in the action group 10 / abort are not in other action groups. If it is essential for them to appear in other action groups, ensure that they are placed into ag10 / abort FIRST.

// Notes:
//	 - This script has no dependant mods, however the script has functions compatible with Hullcam VDS Continues and TAC Self destruct continued
//	 - Can detect SRBs with thrust curves and will throttle up main engine(s) to cover thrust losses due to throttle curve
//	 - If the script progresses far enough to activate any stages, but then the script is terminated (either manually or due to anomaly detection) you will need to revert to launchpad before using the script again in order to reset the stages.
//	 - The script will throttle engines to achieve a liftoff TWR of 1.4 (1.8 with SRBs).
//   - The script will auto switch to Hullcam VDS cameras at various points. Cameras for launch need to be tagged "CameraLaunch". Cameras for Stage sep need to be tagged "CameraSep". Cameras for onboard views need tagged "Camera1" or "camera2" with the number associated with their stage.
//   - The script will activate parts from TAC Self destruct continued as a FTS if an abort is detected - do not put these parts inside the abort AG

//////////////////////////////////////////////////////////////////////
//////////////////////////USER CONFIGURATION//////////////////////////
//////////////////////////////////////////////////////////////////////

//Quicksave
if KUniverse:canquicksave {
	KUniverse:quicksaveto(Ship:name + " (Pre-Launch)").
}

//Runs GUI for user to input launch parameters
runpath("0:/CLS_lib/CLS_window.ks").
runpath("0:/CLS_lib/CLS_parameters.ks").
clearscreen. print "Define Launch Parameters" at (0,0).
set launchParameters to launchParameters().

// Default launch parameters (changed with GUI input above)
set targetapoapsis to launchParameters[0].			//250,000m
set targetperiapsis to launchParameters[1].			//250,000m
set targetinclination to launchParameters[2].		//0°
set launchWindow to launchParameters[3].			//23 Seconds
set maxStages to launchParameters[4].				//2
set launchFailure to launchParameters[5].			
set launchFailureApo to launchParameters[6].

// TWR configuration
set minLiftoffTWR to 1.3.				// Minimum liftoff TWR. Launch will abort just before liftoff if the vehicle attempts to launch with anything lower.
set LiftoffTWR to 1.4.					// Liftoff TWR. Engines will be throttled to achieve this TWR at liftoff (if there is sufficient thrust). There are deltaV savings to be had with a higher TWR, 1.4 was best for a 'one size fits all' approach. Rockets with SRBs will aim for 1.8.
set maxAscentTWR to 4.					// Maximum TWR during ascent. The rocket will throttle down to maintain this when it is reached. There are deltaV savings to be had with a higher TWR, but be careful of vehicle heating.
set UpperAscentTWR to 0.8.				// Throttles upper stage engines to this TWR when the stage has increased time to apoapsis sufficiently.

// Staging delays
set stagedelay to 1.					// Delay after engine shutdown before staging will occur.
set jettisondelay to 0.1.				// Delay after booster shutdown before staging will occur.
set throttledelay to 1. 				// Delay after stage separation before engine throttles up

// Crew abort check
set crewAbortCheck to true.				// Whether or not to check if there is anything in the abort action group prior to crewed launches. If true, CLS will abort any crewed launch with no abort action groups.
set crewCount to ship:crew():length.

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

// Initiate settings
clearscreen. set config:audioerr to true. unlock all. sas off. rcs off. on sas { sas off. return true. }
set Ship:control:pilotmainthrottle to 0.
set terminal:width to 52. set terminal:height to 45.
set config:ipu to 800. 
set warpLimit to 0. on warp { if warp > warpLimit { set warp to warpLimit. } return true. }

// Steering manager setup
set SteeringManager:RollTS to 5.						// Reduces oversensitive roll correction during ascent
set SteeringManager:maxStoppingTime to 1.

// Script Library
runpath("0:/CLS_lib/CLS_dv.ks"). 
runpath("0:/CLS_lib/CLS_gen.ks").
runpath("0:/CLS_lib/CLS_hud.ks").
runpath("0:/CLS_lib/CLS_nav.ks").
runpath("0:/CLS_lib/CLS_res.ks").
runpath("0:/CLS_lib/CLS_twr.ks").
runpath("0:/CLS_lib/CLS_ves.ks").
runpath("0:/CLS_lib/lib_lazcalc.ks").
runpath("0:/CLS_lib/lib_navball.ks").

// Orbit Variables
set atmAlt to ship:body:atm:height+1000.													// +1000 as a safety net
If targetapoapsis < atmAlt*1.42857143 {														// 100km stock / 200km RSS
	set LEO to true.																		// Lower orbits are handled differently by CLS - it will overshoot the target and then correct for it later
	lock orbitData to ship:periapsis.
} else {
	set LEO to false.
	lock orbitData to ship:apoapsis.
}

// Calculates initial launch data
set launchazimuth to LAZcalc(LAZcalc_init(targetapoapsis,targetinclination)).				// Calculates Azimuth required to hit desired inclination
set trajectorypitch to 90.																	// set inital pitch to vertical
set launchroll to rollLock(roll_for()) - heading(launchazimuth,trajectorypitch):roll.		// Rocket will launch so that its 'roll orientation' remains the same from launch to orbit.
set launchtime to Time:seconds + secondsToLaunch(launchWindow).								// Predicts launch time assuming no countdown holds - Script takes 23 seconds between initialisation and launch. Function converts hh:mm:ss input to seconds
lock steering to heading(launchazimuth,trajectorypitch,launchroll).					// Master steering command

//Countdown Variables
lock cdown to Time:seconds - launchtime.													// Calculates time to launch. Used to ensure pre-launch events happen at specific times.
set tminus to 20.																			// Countdown timer
set cdownreadout to 0.																		// Countdown function
set cdownHoldReason to "-".																	// Tracks reason for countdown holds. Set during countdown

//General Variables
set runmode to 0.																			// Tracks phase of the script
set missionElapsedTime to 0.
set launchAlt to alt:radar.
set ApoETAcheck to false.																	// Tracks the vehicle's time to apoapsis 
set throttleCheck to false.																	// Tracks whether it is suitable for upper stage to throttle down.	
set throttletime to 0.																		// Tracks time of engine throttling. Used for gradual throttling.
set currentthrottle to 0.																	// Tracks initial throttle during engine throttle up or down
set insufficientDV to false.																// Used to detect insufficient DV to complete ascent 
set ascentComplete to false.																// Used to monitor multiple data streams to determine best time to end ascent
set stagingCleared to false.
set approachingApo to false.																// Tracks whether ships apopsis is getting close to the target to begin throttling down for fine apoapsis control	
set CentralEnginesThrottleComplete to false.
set CentralEnginesCalculation to false.														// Tracks central booster throttling for 3 booster lifter configurations
set CentralEnginesThrottle to 0.															// Tracks throttle required during central engine throttling of 3 booster vehicle configurations
set abortReason to "".
set BurnRemaining to 0.
set dVRemaining to 0.
set averageisp to 0.
set printqueue to List(). set listlinestart to 6.											// Scrolling print configuration
set dynamicPressure to 0. set dynamicPressureTime to 0. set passedMaxQ to false.				// Variables used to track MaxQ and provide regular speed, distance & alitude updates
HUDinit(launchtime,targetapoapsis,targetperiapsis,targetinclination).				// Prints info at top of HUD

//Ship Info Variables
if Ship:name:length > 15 { set Ship:name to "Vehicle". }									// Ensures vehicle name fits on terminal width
set VehicleConfig to 0.																		// 0 = no SRBs present. 1 = SRBs present. 0 as default.
set currentstagenum to 1.																	// Tracks current stage number
set numparts to Ship:parts:length.															// Tracks the number of parts. If this decreases unexpectedly, the script assumes a RUD and triggers an abort.
set PayloadProtection to false.																// Tracks if the vehicle is using a method of payload protection such as fairings or LES. Detected during countdown
set PayloadProtectionStage to 0.															// Tracks stage of PayloadProtection (eg fairings). Used to determine if fairings must be jettisoned prior to staging (eg Atlas 5m Configurations)
set PayloadProtectionConfig to "-".															// Tracks type of payload protection (eg fairings or LES)
set manualAbort to false.																	// Tracks whether manual abort has been triggered
set CentralEngines to false.																// Tracks if the vehicle has 'Central Engines' and is therefore a 3 booster design. See Required staging set-up above. Detected during countdown
set launchClamps to launchClampCheck().														// Detects launch clamps.
set BatteryCapacity to ship:electriccharge.
set vesTWR to 0.
FuelCellDetect(). PrelaunchEngList().														// Gathers info on initial engines and detects fuel cells. Removes thrustlimits on all engines to hand control over to CLS. 

//Circularisation Variables
set threeBurn to false.																		// Tracks Whether CLS has determined 3 burns is most efficicent to achieve target orbit
set burnDuration to 0.
set burnStartTime to Time:seconds+100000.													// Determines time at which manuever burn should start. 
set burnDeltaV to 0.																		// Tracks initially calculated burn dV - used to determine when burn should end

//Staging Variables
set ImpendingStaging to false.																// Boolean. True when rocket is about to stage
set staginginprogress to false.																// Boolean. True when rocket is staging
set Ullagedetected to false.																// Boolean. Tracks whether vehicle uses ullage motors during staging. set during staging.
set stagingApoapsisETA to 100000.															// Tracks eta:apoapsis at time of staging - used to determine when upper stages can throttle down
set ImpendingStagingTime to 0.																// Logs time at which CLS detects imminent staging
set ImpendingStagingPitch to 0.																// Logs current pitch when imminent staging is detected for a gradual pitch to prograde
set SRBstagingOverride to false.															// Overrides staging detection and forces staging when SRB thrust curve is < 0.25.
set stagingEndTime to 0.																	// Tracks staging end time. 
set PreStagingTWR to 0.																		// Tracks TWR at SRB / Central engine booster sep

//////////////////////////////////////////////////////////////////////
/////////////////////////////COUNTDOWN////////////////////////////////
//////////////////////////////////////////////////////////////////////
if cdown < -90 { set warpLimit to 3. when cdown > -90 then { set warpLimit to 0. set warp to warpLimit. }}
	
until cdown >= -21 {
	print "T" + hud_missionTime(cdown) + launchNode + "   " at (0,(printqueue:length)+listlinestart).
	if not abort and not manualAbort { AscentHUD().	} wait 0.01.
	wait 0.01.
}

until runmode > 0 {
	Countdown(tminus,cdown).	// Displays the countdown on the terminal
	
	//Startup
	if cdown >= -20 and tminus = 20 {
		CdownPrint("Startup").
		set tminus to tminus-1.
	}
	
	If cdown >= -18 and tminus = 18 {
		If batteryCheck(0.4) = false {					// Function for checking resource is above a threshold
			set cdownHoldReason to "Insufficient Power". 
			set runmode to 0.
		} else {
			print "T-00:" + abs(floor(cdown)) + " - " + Ship:name + " is on Internal Power" at (0,listlinestart).
			CdownPrint(Ship:name + " is on Internal Power").
		}
		set tminus to tminus-1.
	}
	
	// Detects presence of SRBs or 3 booster design and changes mode configuration
	If cdown >= -16 and tminus = 16 {
		SRBDetect(). PrelaunchEngList(). stageSRBlist().										// Function for detecting SRBs
		If Ship:partstaggedpattern("^CentralEngine"):length > 0 {
			set CentralEngines to true.
			CdownPrint(CentralEngines).
		}				
		CdownPrint("Launch Mode " + vehicleConfig + " Configured").
		set tminus to tminus-1.
	}
	
	// Staging checks. Holds launch if clamps or decouplers are incorrectly staged, or clamps are not present. See required staging set-up above
	If cdown >= -14 and tminus = 14 {
		if launchClamps = false {
			set cdownHoldReason to "No launch clamps detected". 
			set runmode to -1.
		} else if stagingCheck() {
			set cdownHoldReason to "Subnominal Staging Detected". 
			set runmode to -1.
		} else {
			CdownPrint("Staging Checks Complete").
		}
		set tminus to tminus-1.
	}
	
	// Determines main fuel tank and calculates its fuel capacity. Holds launch if this cant be determined. 
	If cdown >= -12 and tminus = 12 {
		PrimaryFuel(). fueltank(ResourceOne).
		If FuelRemaining(stagetanks) = 0 {
			set runmode to -1.
			set cdownHoldReason to "MFT Detect Issue".
		}
		CdownPrint("Pressurization Checks Complete").
		set tminus to tminus-1.
	}
	
	// Detects LES or fairing configuration based on parts assigned to action group 10. Holds launch if there are no parts in action group 10 or if there are parts in action group 10 that shouldnt be.
	If cdown >= -10 and tminus = 10 {
		If Ship:partsingroup("AG10"):length > 0 {
			set PayloadProtection to true.
			For P in Ship:partsingroup("AG10") {
				set PayloadProtectionStage to P:Stage.
				If P:modules:join(","):contains("ModuleEngine") {
					set PayloadProtectionConfig to "LES".
				} else {
					set PayloadProtectionConfig to "Fairings".
				}
			}
			CdownPrint(PayloadProtectionConfig + " Configured For Launch").
		} else {
			CdownPrint("Fairing Checks Complete").
			set runmode to -1.
			set cdownHoldReason to "AG10 Advisory".				
		}
		set tminus to tminus-1.
	}	
	
	// Checks abort procedures are ready
	If cdown >= -7 and tminus = 7 {
		if crewCount = 0 {
			CdownPrint(false,false).
		} else {
			if Ship:partsingroup("abort"):length < 1 or chuteDetect() = false and crewAbortCheck {
				set runmode to -1.
				set cdownHoldReason to "Crew Abort Procedure Error".
			} else {
				CdownPrint("Abort Systems Configured For Launch").
			}
		}
		set tminus to tminus-1.
	}
	
	//Configures Flight Termination System - Requires TAC Self Destruct Continued Mod
	If cdown >= -5 and tminus = 5 {
		CameraControl(1,true).
		set FTSlist to list().
		for p in ship:parts {
			if p:hasmodule("TacSelfDestruct") {
				CdownPrint("FTS ready for Launch").
				p:getmodule("TacSelfDestruct"):setfield("countdown",false).
				p:getmodule("TacSelfDestruct"):setfield("time delay",1).
				FTSlist:add(p). break.
			}
		} 
		if FTSlist:length = 0 {
			CdownPrint(false,false).
		}
		set tminus to tminus-1.
	}
	
	// Ignition and calculation for main engine throttle up during countdown
	If cdown >= -3 and tminus = 3 {
		stage.
		Activeenginelist().
		CdownPrint("Ignition").
		set throttletime to Time:seconds.
		lock vesTWR to twr().
		lock liftoffThrottle to TWRthrottle(LiftoffTWR).
		lock throttle to min(liftoffThrottle,liftoffThrottle*(Time:seconds-throttletime)/2).
		set tminus to tminus-1.
	}
	
	// Checks engines are producing thrust. Terminates script if they arent.
	If cdown >= -2 and tminus = 2 {
		if ship:availablethrust > 0.1 {
			CdownPrint("T-00:02 - Thrust Verified",false).
		} else {
			lock throttle to 0.
			clearscreen. set config:audioerr to false.
			Hudtext("Launch Aborted - Insufficient Thrust",5,2,50,red,true).
			print 1/0. //Intentional error to scrub launch
		}
		set tminus to tminus-1.
	}

	// SRB ignition (if SRBs are present). Main engines reach lift-off thrust.
	If cdown >= -1 and tminus = 1 {
		if vehicleConfig = 0 {
			CdownPrint("T" + hud_missionTime(cdown),false).
		} else {
			stage.
			CdownPrint("SRB Ignition").
			activeSRBlist(). 
		}
		StageDV().
		set tminus to tminus-1.
	}	
	
	// Checks vehicle TWR. Will terminate script if its below the threshold configured in TWR configuration. If TWR is ok, the vehicle will liftoff at the TWR configured in TWR configuration (if it has enough thrust).
	If cdown >= 0 and tminus = 0 and throttle >= liftoffThrottle*0.985 {
		If vesTWR < minLiftoffTWR {
			lock throttle to 0.
			clearscreen. set config:audioerr to false.
			Hudtext("Launch Aborted - Insufficient Thrust",5,2,50,red,true).
			print 1/0. //Intentional error to scrub launch
		} else {
			if launchClamps { stage. }
			scrollprint("Liftoff (" + T_O_D(time:seconds) + ")").
			set liftoffThrottle to liftoffThrottle. lock throttle to liftoffThrottle.
			lock missionElapsedTime to time:seconds - launchTime.
			if vehicleConfig = 1 {	
				lock throttle to liftoffThrottle+((PartlistAvailableThrust(asrblist)-PartlistCurrentThrust(asrblist))/PartlistAvailableThrust(aelist)).
			} 
			unlock cdown.
			set runmode to 1.
		}
	}
	
	// Countdown hold for unplanned issues
	// Holds the countdown and gives you the choice to continue, recycle or abort the launch
	if runmode = -1 {
		print ("Hold Hold Hold                    ") at (0,listlinestart).
		print cdownHoldReason at (0,listlinestart+1).
		set proceedMode to scrubGUI(cdownHoldReason).
		
		if proceedMode = 1 {													// continue countdown
			set runmode to 0.
			set launchtime to time:seconds + tminus.
			if cdownHoldReason = "Crew Abort Procedure Error" and Ship:partsingroup("abort"):length < 1 or chuteDetect() = false { set launchFailure to false. }		// deactives random launch failure if countdown is continued with abort procedure issues not corrected
			Print "Target Launch Time: NET " + T_O_D(launchtime) at (0,1).
			Print "                                     " at (0,listlinestart).
			Print "                                     " at (0,listlinestart+1).
		} else if proceedMode = 2 {												// Recycle countdown
			set runmode to 0.
			set tminus to 20.
			set cdownreadout to 0. clearscreen. 
			HUDinit(launchtime,targetapoapsis,targetperiapsis,targetinclination).
			set launchtime to time:seconds + 23.
			Print "Target Launch Time: NET " + T_O_D(launchtime) at (0,1).
		} else if proceedMode = 3 {												// Scrub launch
			clearscreen. set config:audioerr to false.
			Hudtext("Launch Scrubbed",5,2,50,red,true).
			print 1/0. //Intentional error to scrub launch	
		}
	}
	
	if not abort and not manualAbort { AscentHUD().	} wait 0.01.
}

//////////////////////////////////////////////////////////////////////
//////////////////////Ascent Trigger Conditions///////////////////////
//////////////////////////////////////////////////////////////////////

//Fairing Jettison
if PayloadProtection {
	when Body:atm:altitudepressure(ship:altitude) < 0.00002 and currentstagenum > 1 and Time:seconds - stagingEndTime >= 8 or PayloadProtection = false then {
		if PayloadProtection = false { return false. }
		FairingJettison().
	}
	when (Stage:number - PayloadProtectionStage)=1 and ImpendingStaging or PayloadProtection = false then {
		if PayloadProtection = false { return false. }
		FairingJettison().
	}
}

// Angle to desired steering > 25 deg (i.e. steering control loss) during atmospheric ascent
when Vang(Ship:facing:vector, steering:vector) > 15 or runmode = 3 then {
	if runmode = 3 { return false. }
	local ts is time:seconds.
	when time:seconds > ts+5 then {
		if Vang(Ship:facing:vector, steering:vector) > 15 {
			set abortReason to "Loss of Ship Control".
			abortProcedure().
		}
	}
}

//Ship on incorrect heading
when abs(launchazimuth - heading_for()) > 7 and runmode = 2 or runmode = 3 then {
	if runmode = 3 { return false. }
	local ts is time:seconds.
	when time:seconds > ts+5 then {
		if abs(launchazimuth - heading_for()) > 7 {
			set abortReason to "Off nominal heading".
			abortProcedure().
		}
	}
}

// Abort if number of parts less than expected (i.e. ship breaking up)
when Ship:parts:length <= (numparts-1) and Stage:ready or runmode = 3 then {
	if abort { return false. }		//Avoids triggering this due to manual abort
	if runmode = 3 { return false. }
	set abortReason to "Ship breaking apart".
	abortProcedure().
}

// Abort if falling back toward surface (i.e. insufficient thrust)
when verticalspeed < -1.0 and ship:altitude < atmAlt then {
	if runmode = 3 { return false. }
	set abortReason to "Terminal Thrust".
	abortProcedure().
}

// Abort due to insufficient electric charge
when batteryCheck(0.01) = false then {
	set abortReason to "Insufficient Internal Power".
	abortProcedure().
}

//Manual abort triggered
on abort {
	set manualAbort to true.
	set abortReason to "Manual Abort".
	abortProcedure().
}

//Random chance of launch failure
if launchFailure {
	when ship:apoapsis >= launchFailureApo or ship:apoapsis > atmAlt then {
		if ship:apoapsis > atmAlt { return false. }
		set abortReason to "Random Launch Failure".
		abortProcedure().
	}
}

//Main staging detection - Detects imminent fuel depletion of current main fuel tank
when BurnRemaining < 5 and time:seconds > stagingEndTime+5 and not staginginprogress and not ImpendingStaging or currentstagenum = maxStages then {
	if currentstagenum = maxStages { return false. }
	set ImpendingStaging to true.
	set ImpendingStagingTime to time:seconds.
	if vehicleConfig = 1 or centralEngines { when dVRemaining < 3 or time:seconds > ImpendingStagingTime+4 then { set PreStagingTWR to vesTWR. }}
	set ImpendingStagingPitch to pitch_for_vector(ship:facing:forevector).
	set warpLimit to 0. set warp to warpLimit.
	if currentstagenum < maxStages-1 or vehicleConfig = 1 or centralEngines {
		return true.
	}
}

when impendingstaging and warpLimit > 0 or currentstagenum = maxStages then {
	if currentstagenum = maxStages { return false. }
	set warpLimit to 0. set warp to warpLimit.
	if currentstagenum < maxStages-1 {
		return true.
	}
}

//Handles Activation and Deactivation of Fuel cells
if FCList:length > 0 {
	when batteryCheck(0.25) = false then { 
		For p in FCList {
			p:getmodule("ModuleResourceConverter"):doaction("toggle converter",true).
		}
	}
}

//////////////////////////////////////////////////////////////////////
//////////////////////////Initial Ascent//////////////////////////////
//////////////////////////////////////////////////////////////////////

set warpLimit to 1.
set numparts to Ship:parts:length.
lock trajectorypitch to 90-(5/(100/ship:verticalspeed)).
when alt:radar >= launchAlt*2.5 then { CameraControl(currentstagenum). }
until ship:verticalspeed > 100 {
	if not abort and not manualAbort { AscentHUD().	}
	StageDV(). wait 0.01.
}
set runmode to 2.
set launchroll to launchroll + (launchazimuth - heading_for_vector(east_for())).
scrollprint("Starting Ascent Trajectory").
set gravityTurnApogee to ship:apoapsis.

//////////////////////////////////////////////////////////////////////
///////////////////////////Main Ascent////////////////////////////////
//////////////////////////////////////////////////////////////////////

until ascentComplete or insufficientDV {
	
	if not abort and not manualAbort { AscentHUD().	}		// Initiates the HUD information at the bottom of the terminal.
	if passedMaxQ = false { maxQ(dynamicPressure). }			// Function for detecting MaxQ
	if not impendingstaging and not staginginprogress { set warpLimit to 1. }

	//Azimuth calculation
	if abs(targetinclination) > 0.1 and abs(targetinclination) < 180 and ship:orbit:inclination > (abs(targetinclination) - 0.1) {
		set launchazimuth to incTune(targetinclination).
	}
	
	// Pitch control
	if ImpendingStaging or staginginprogress or time:seconds > stagingEndTime and time:seconds < stagingEndTime+6 { 
		set trajectorypitch to stagingPitch().
	} else {
		set trajectorypitch to PitchProgram_Sqrt(gravityTurnApogee).
	}
	
	// Ascent TWR control for first stage
	If currentstagenum = 1 {
	
		if vesTWR > maxAscentTWR+0.01 {
			scrollprint("Maintaining TWR").
			lock throttle to TWRthrottle(maxAscentTWR).
		}
		
		// Gradual throttle down of central engines in 3 booster config. Occurs when the vehicles maximum possible TWR reaches 2.
		If CentralEngines = true and CentralEnginesThrottleComplete = false and not impendingstaging and not staginginprogress {
			local t is (ship:availablethrust/aelist:length*0.55)*Ship:partstaggedpattern("^CentralEngine"):length+ship:availablethrust/aelist:length*(aelist:length-Ship:partstaggedpattern("^CentralEngine"):length).			//Finds thrust of one engine * 0.55 (what the center engines throttle to) then adds thrust of other engines																				
			If (ship:mass*adtg())/t*vesTWR <= 1 or (ship:mass*adtg())/t*2.1 <= 1 {											//If vessel can throttle central engine to maintain twr or keep twr above 2.1
				If CentralEnginesCalculation = false {
					set throttletime to Time:seconds.
					set CentralEnginesCalculation to true.
					scrollprint("Throttling Central Engines").
					set currentthrottle to throttle.		
					set CentralEnginesThrottle to (ship:mass*adtg())/t*vesTWR.
					lock throttle to (CentralEnginesThrottle - currentthrottle)*((Time:seconds-throttletime)/1.5)+currentthrottle.							//Calculates throttle needed (after throttle) to maintain currenttwr.
				}
			}
			If CentralEnginesCalculation = true {
				For e in Ship:partstaggedpattern("^CentralEngine") {
					If Time:seconds - throttletime < 1.5 {
						set e:thrustlimit to ((55 - 100)*((Time:seconds-throttletime)/1.5)+100).
					} else {
						set e:thrustlimit to 55.
						lock throttle to CentralEnginesThrottle.
						set CentralEnginesThrottleComplete to true.
					}
				}								
			}
		} 
	}
	
	// Ascent TWR control For second stage
	If currentstagenum > 1 and staginginprogress = false {
		
		// Checks whether it has been 5 seconds since staging and time to apoapsis is above 120 seconds and second stage has boosted eta:apoapsis by 30 seconds since sep before gradually throttling to TWR set by UpperAscentTWR			
		If eta:apoapsis < eta:periapsis and Eta:apoapsis > max(150,stagingApoapsisETA) and throttleCheck = false and stagingCleared {
			set ApoEtacheck to true.
			if vesTWR > UpperAscentTWR {
				set throttleCheck to true.
				set throttletime to Time:seconds.
				set currentthrottle to throttle.
				scrollprint("Throttling Down").
			}
		}
		If ApoEtacheck = true {
			If vesTWR > UpperAscentTWR and throttleCheck = true {
				lock throttle to max(TWRthrottle(UpperAscentTWR),((TWRthrottle(UpperAscentTWR) - currentthrottle)*((Time:seconds-throttletime)/5)+currentthrottle)).
			}
			//Throttle down approaching target apoapsis
			if orbitData >= targetapoapsis*0.925 and Eta:apoapsis > 30 {
				if approachingApo = false {
					set currentThrottle2 to throttle.
					set approachingApo to true.
					scrollprint("Terminal Guidance").
				} else {
					lock throttle to max(TWRthrottle(0.02),currentThrottle2*((targetapoapsis-orbitData)/(targetapoapsis*0.075))).
				}
			} else if Eta:apoapsis < 75 {						// If time to apoapsis drops below 75 seconds after engines have throttled down, this will throttle them back up
				set ApoEtacheck to false.
				set throttleCheck to false.
				lock throttle to TWRthrottle(maxAscentTWR).
			}
		}
	}
	
	//End of ascent detection
	if not staginginprogress {
		if eta:apoapsis < eta:periapsis {
			if orbitData >= (targetapoapsis-50) {
				set ascentComplete to true.
			}
		} else {
			if ship:periapsis >= atmAlt {
				if ship:apoapsis >= (targetapoapsis-50) {
					set ascentComplete to true.
				}
				if ship:apoapsis >= targetapoapsis+(targetapoapsis*0.05) {
					set threeBurn to true.
					set LEO to true.
				}
			}
		}
		if LEO = true {
			//Apoapsis is getting too large. Vehicle has enough dV to stop burn, burn at apoapsis to raise periapsis and then circularise at periapsis with a retrograde burn.
			if ship:apoapsis >= 1.75*targetapoapsis and eta:apoapsis > 480 and eta:apoapsis < eta:periapsis {
				if ship:altitude > body:atm:height and BurnApoapsis_TargetPeriapsis(targetperiapsis)+circulariseDV_TargetPeriapsis(targetapoapsis,targetperiapsis) < dVRemaining {
					set ascentComplete to true.
					set threeBurn to true.
				}
			}
		}
	}
	
	//Insufficient Dv detection 
	if ship:apoapsis > body:atm:height*1.05 and currentstagenum = MaxStages and stagingCleared and PayloadProtection = false {
		if LEO = false {
			//Vehicle wont have enough deltaV to circularise if it raises its apoapsis any further. Cuts the burn short and will circularise at current apoapsis.
			if circulariseDV_Apoapsis() >= (dVRemaining*0.95) {
				set insufficientDV to true.
			}
		} else {
			//Current periapsis is above atmosphere (we are in orbit). Vehicle wont have enough deltaV to circularise if it raises its apoapsis any further. Cuts the burn short and will circularise at current periapsis.
			if ship:periapsis > atmAlt and circulariseDV_Periapsis()>=(dVRemaining*0.95) {
				set insufficientDV to true.
			}
			//Periapsis is in atmosphere and if we continue to burn we may not have enough dv left to burn at apo to bring peri outside atmosphere and achieve minimum orbit
			if ship:periapsis < atmAlt and BurnApoapsis_TargetPeriapsis(atmAlt) >= (dVRemaining*0.95) {
				set insufficientDV to true.
				set threeBurn to true.
			}
		}
	}
	
	//Boolean for stagingevent more than 15 seconds ago
	if currentstagenum > 1 and Time:seconds - stagingEndTime >= 15 {
		set stagingCleared to true.
	}
	
	//Stage shutdown detection
	If staginginprogress = false and currentstagenum < MaxStages {
		// Engine flameout detection
		if vehicleConfig = 1 {
			For e in asrblist {
				If e:ignition and e:flameout {	
					set SRBstagingOverride to true.
					stagingDetection(). break.
				}
			}
		}
		For e in aelist {
			If e:ignition and e:flameout {	
				stagingDetection(). break.
			}
		}
	}
	StageDV(). wait 0.01.
}

//End of ascent actions
scrollprint(enginereadout(currentstagenum) + " Cut-Off ").
if ascentComplete {
	scrollprint("          Parking Orbit Confirmed",false).
} else if insufficientDV {
	scrollprint("          Insufficient dV detected",false).
}
scrollprint("          Entering Coast Phase",false).
lock throttle to 0. RCS on.
set runmode to 3.

//////////////////////////////////////////////////////////////////////
//////////////////////////Staging Function////////////////////////////
//////////////////////////////////////////////////////////////////////

// Continuous staging check logic
Function stagingDetection {
	set warpLimit to 0. if warp > warpLimit { set warp to warpLimit. }. 
	local stageflameout is false.
	local boosterflameout is false.
	
	// Engine flameout detection
	If staginginprogress = false and currentstagenum < MaxStages {
		For e in aelist {
			If SRBstagingOverride or e:ignition and e:flameout {	
				set staginginprogress to true.
				set ImpendingStaging to false.
				rcs on. wait 0.01.

				If ship:availablethrust >= 0.1 {								// Flameout is booster shutdown only
					set boosterflameout to true. break.
				} else if ship:availablethrust < 0.1 {	// Flameout is entire stage shutdown
					lock throttle to 0.
					set stageflameout to true. break.
				}	
			}
		}
	}
	if stageflameout {
		scrollprint(enginereadout(currentstagenum) + " Cut-Off").
		CameraControl(currentstagenum+1).
		wait stagedelay. StageJettison().
	} else if boosterflameout {
		If vehicleConfig = 1 {
			scrollprint("SRB Flameout").
		} else {
			scrollprint("External Tank Depletion").
		}
		wait jettisondelay. BoosterJettison().
	}
}

// Booster or external tank staging (after specified delay)		
Function BoosterJettison {
	set warpLimit to 0. if warp > warpLimit { set warp to warpLimit. }. 
	Stage.
	set numparts to Ship:parts:length.
	FuelTank(ResourceOne).
	Activeenginelist(). ActiveSRBlist().
	If vehicleConfig = 0 {
		scrollprint("External Tank Jettison").
		For e in Ship:partstaggedpattern("^CentralEngine") {
			set e:thrustlimit to 100.
		}
	} else {
		scrollprint("SRB Jettison").
		SRBDetect(). if vehicleConfig = 1 { stageSRBlist(). }
	}
	local postStagingTWR is TWRthrottle(PreStagingTWR).
	If PreStagingTWR = 0 {
		lock throttle to TWRthrottle(maxAscentTWR).
	} else if PreStagingTWR < maxAscentTWR {
		lock throttle to postStagingTWR.
	} else {
		lock throttle to TWRthrottle(maxAscentTWR).
	}
	set stagingEndTime to Time:seconds.
	set ImpendingStaging to false.
	set staginginprogress to false.
	set SRBstagingOverride to false.
	rcs off.
}
		
// Full staging
Function StageJettison {
	// Checks for ullage & gradually throttles up engines
	set warpLimit to 0. if warp > warpLimit { set warp to warpLimit. }. 
	Stage.
	if detectUllage() { Set UllageDetected to true. }
	set numparts to Ship:parts:length.
	set currentstagenum to currentstagenum+1.
	scrollprint("Stage "+currentstagenum+" separation").
	set stagingCleared to false.
	set stagingEndTime to Time:seconds.
	if centralEngines {
		if Ship:partstaggedpattern("^CentralEngine"):length = 0 {
			set CentralEngines to false.
		}
	}
	If UllageDetected = true {
		wait until ship:availablethrust < 0.01.
		stage.
		set numparts to Ship:parts:length.
		Scrollprint("Ullage Motor Shutdown").		
		set UllageDetected to false. wait 0.01.
	}
	until Ship:availablethrust > 0.01 {
		set throttledelay to throttledelay-0.01.
		wait 0.01.
	}
	Activeenginelist(). ActiveSRBlist().
	set ImpendingStaging to false.
	set staginginprogress to false.
	set stagingEndTime to Time:seconds.
	set stagingApoapsisETA to eta:apoapsis.
	rcs off.
	PrimaryFuel(). FuelTankUpper(ResourceOne). FuelCellDetect().
	scrollprint("Stage "+currentstagenum+" Ignition").
	if runmode = 2 {
		lock throttle to min(TWRthrottle(maxAscentTWR),(TWRthrottle(maxAscentTWR)*((Time:seconds-stagingEndTime)-throttledelay)/3)).
	} else {
		lock throttle to 0.
	}
}

//////////////////////////////////////////////////////////////////////
//////////////////////////Ascent Functions////////////////////////////
//////////////////////////////////////////////////////////////////////

//Fairing Jettison
Function FairingJettison {
	If (Stage:number - PayloadProtectionStage)=1 {
		set numparts to Ship:parts:length - Ship:partsingroup("AG10"):length.
		Stage.
	} else {
		Toggle Ag10. 
		set numparts to Ship:parts:length.
	}
	scrollprint(PayloadProtectionConfig + " Jettisoned").
	set PayloadProtection to false.
}

//Abort
Function abortProcedure {
	set warpLimit to 0. if warp > warpLimit { set warp to warpLimit. }.
	Activeenginelist().
	if not manualAbort {
		for e in aelist {
			e:shutdown.
		}
	}
	CameraControl(currentstagenum, false, true).
	set Ship:control:neutralize to true.
	Hudtext("Launch Aborted",5,2,50,red,true).
	Hudtext(abortReason,5,2,50,red,true).
	clearscreen. set config:audioerr to false. AscentHUD().	
	if Ship:partsingroup("abort"):length > 0 {
		runpath("0:/Abort.ks").
		shutdown.
	}
	if FTSlist:length > 0 and runmode < 3 {
		FTSlist[0]:getmodule("TacSelfDestruct"):doaction("Self Destruct!",true).
	}
	clearscreen.
	Print "CLS has aborted launch at T" + hud_missionTime(missionElapsedTime) at (0,4).
	Print "Cause: " + abortReason + " at " + round(ship:altitude,0) + "m" at (0,5).
	Print "kOS terminal powering down" at (0,6).
	shutdown.
}
	
//////////////////////////////////////////////////////////////////////
///////////////////////Post Ascent Functions//////////////////////////
//////////////////////////////////////////////////////////////////////

//Manuever node creation
Function runmodeMV {
	set warpLimit to 0. if warp > warpLimit { set warp to warpLimit. }.
	if hasnode { remove nextnode. }
	if LEO = true {
		if threeBurn = true {
			if eta:apoapsis < eta:periapsis {
				set cnode to node(time:seconds + eta:apoapsis, 0, 0, BurnApoapsis_TargetPeriapsis(targetperiapsis)).
			} else {
				set cnode to node(time:seconds + eta:periapsis, 0, 0, BurnPeriapsis_TargetApoapsis(targetapoapsis)).
			}
		} else {
			//If apoapsis is closer to target
			if abs(ship:apoapsis-targetapoapsis) < (targetperiapsis-ship:periapsis) {
				set cnode to node(time:seconds + eta:apoapsis, 0, 0, circulariseDV_Apoapsis()).
			//If periapsis is closer to target
			} else if abs(ship:apoapsis-targetapoapsis) > (targetperiapsis-ship:periapsis) {
				set cnode to node(time:seconds + eta:periapsis, 0, 0, circulariseDV_Periapsis()).
			}
		}
	} else {
		set cnode to node(time:seconds + eta:apoapsis, 0, 0, circulariseDV_Apoapsis()).		
	}
	add cnode.
}

//Post-ascent staging 
Function runmodePAStaging {
	set warpLimit to 0. if warp > warpLimit { set warp to warpLimit. }.
	if currentstagenum < maxStages {
		if dVRemaining < cnode:deltav:mag or currentstagenum = 1 {
			RCS on.
			Lock steering to heading(heading_for_vector(Ship:srfprograde:forevector),pitch_for_vector(Ship:srfprograde:forevector),launchroll).
			If PayloadProtection = true { 
				wait 2.5.
				set numparts to Ship:parts:length - Ship:partsingroup("AG10"):length.
				scrollprint(PayloadProtectionConfig + " Jettisoned").
				set PayloadProtection to false.
				if (Stage:number - PayloadProtectionStage)=1 {
					Stage.
				} else {
					Toggle Ag10. 
				}
			}
			wait until vang(steering:vector,ship:facing:vector) < 1.
			wait 2.5.
			set staginginprogress to true.
			StageJettison().
		}
	}
}

//Coast phase
Function runmodeCoast {
	set warpLimit to 3. if warp > warpLimit { set warp to warpLimit. }.
	scrollprint("FTS has safed").
	lock steering to Ship:prograde:vector.
	when vang(steering,ship:facing:vector) < 1 then { RCS off. }
	lowPowerMode(true).
	set burnParameters to nodeBurnData(nextnode,30).
	set burnDuration to burnParameters[0].
	set burnStartTime to time:seconds + cnode:eta - burnParameters[1].
	set burnDeltaV to cnode:deltav.
	wait 1. stageDV().
	until time:seconds >= burnStartTime-90 {
		AscentHUD(). wait 0.01.
	}
}

//Circularisation Burn
Function runmodeCircBurn {
	lowPowerMode(false).
	RCS on.
	Activeenginelist().
	StageDV().
	set warpLimit to 0. if warp > warpLimit { set warp to warpLimit. }.
	
	//dV check in case boil-off losses could result in incomplete burn
	if dVRemaining < cnode:deltav:mag {
		set cnode:prograde to dVRemaining*0.99.
		set burnParameters to nodeBurnData(nextnode,30).
		set burnDuration to burnParameters[0].
		set burnStartTime to time:seconds + cnode:eta - burnParameters[1].
		set burnDeltaV to cnode:deltav.
	}
	
	scrollprint("Preparing for Burn").
	scrollprint("          Delta-v requirement: " + ceiling(cnode:deltav:mag,2) + "m/s",false).
	scrollprint("          Burn time: " + hud_missionTime(burnDuration),false).	
	
	lock steering to cnode:burnvector.
	if GimbalDetect() {
		when vang(steering,ship:facing:vector) > 5 and time:seconds >= burnStartTime-5 or time:seconds > burnStartTime then {
			if time:seconds > burnStartTime { return false. }
			lock throttle to twrthrottle(0.05).
			scrollprint("Correcting attitude with Thrust gimbal").	
		}
	}
	until time:seconds >= burnStartTime {
		AscentHUD(). wait 0.01.
	}
	lock throttle to burnParameters[2].
	scrollprint(enginereadout(currentstagenum) + " Ignition").
	until cnode:deltav:mag / burnDeltaV:mag < 0.075 {
		StageDV(). AscentHUD(). wait 0.01.
	}
	set manueverVector to cnode:burnvector.
	lock steering to manueverVector.
	lock throttle to burnParameters[2] * min(cnode:deltav:mag/((ship:availablethrust*burnParameters[2])/ship:mass),1).		// This will throttle the engine down when there is less than 1 second remaining in the burn
	until cnode:deltav:mag < 0.1 or vdot(burnDeltaV,cnode:deltav) < 0.1 {
		StageDV(). AscentHUD(). wait 0.01.
	}
	lock throttle to 0.
	scrollprint(enginereadout(currentstagenum) + " Cut-Off").
	}

//////////////////////////////////////////////////////////////////////
//////////////////////////Post Ascent Flow////////////////////////////
//////////////////////////////////////////////////////////////////////

//Post ascent workflow
runmodeMV().
runmodePAStaging().
runmodeCoast().
runmodeCircBurn().
set warpLimit to 0. if warp > warpLimit { set warp to warpLimit. }.
lock steering to Ship:prograde:vector. RCS on.
if threeBurn = true {
	set threeBurn to false.
	remove cnode.
	runmodeMV().
	runmodePAStaging().
	runmodeCoast().
	runmodeCircBurn().
} else {
	scrollprint("          Orbit Cicularised",false).
	scrollprint("Program Completed").
	wait until vang(steering,ship:facing:vector) < 1.
	unlock all. sas on. rcs off. 
	if hasnode { remove cnode. }
	wait 1. StageDV().
	Print "                                              " at (0,0).
}