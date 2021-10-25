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
//							Data Logging:					CLS can log data to an external csv file for later reference. Requires a logs folder in the archive. Note: Do not open the file during launch, it will cause an error.

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

// Action groups:
//   - Place any fairing or LES jettison into action group 10. Will jettison based on atmopshere pressure.
//   - Abort action group will be automatically triggered if conditions defined under runmode -666 are met.
//   - Due to a kOS bug(?) it is essential that parts placed in the action group 10 / abort are not in other action groups. If it is essential for them to appear in other action groups, ensure that they are placed into ag10 / abort FIRST.

// Notes:
//	 - This script has no dependant mods, however the script checks for parts from the Procedural Fairing & Hullcam mods.
//	 - Can detect SRBs with thrust curves and will:		a) decouple them when they reach a low trust percentage		b) throttle main engine up to cover thrust losses due to throttle curve
//	 - If the script progresses far enough to activate any stages, but then the script is terminated (either manually or due to anomaly detection) you will need to 'revert to launchpad' before using the script again in order to reset the stages.
//	 - The script will throttle engines to achieve a liftoff TWR of 1.6 (this number can be configured in TWR configuration).

//////////////////////////////////////////////////////////////////////
//////////////////////////USER CONFIGURATION//////////////////////////
//////////////////////////////////////////////////////////////////////

//Runs GUI for user to input launch parameters
runpath("0:/cls_lib/CLS_parameters.ks").
clearscreen. print "Define Launch Parameters" at (0,0).
set launchParameters to launchParameters().

// Default launch parameters (changed with GUI input above)
set targetapoapsis to launchParameters[0].			//250,000m
set targetperiapsis to launchParameters[1].			//200,000m
set targetinclination to launchParameters[2].		//0°
set launchWindow to launchParameters[3].			//23 Seconds
set maxStages to launchParameters[4].				//2
set csvLog to launchParameters[5].					//false

// TWR configuration
set minLiftoffTWR to 1.3.				// Minimum liftoff TWR. Launch will abort just before liftoff if the vehicle attempts to launch with anything lower.
set LiftoffTWR to 1.6.					// Liftoff TWR. Engines will be throttled to achieve this TWR at liftoff (if there is sufficient thrust). There are deltaV savings to be had with a higher TWR, 1.6 was best for a 'one size fits all' approach
set maxAscentTWR to 4.					// Maximum TWR during ascent. The rocket will throttle down to maintain this when it is reached. There are deltaV savings to be had with a higher TWR, but be careful of vehicle heating.
set UpperAscentTWR to 0.8.				// Throttles upper stage engines to this TWR when the stage has increased time to apoapsis sufficiently.

// Staging delays
set stagedelay to 0.5.					// Delay after engine shutdown before staging will occur.
set throttledelay to 0.5. 				// Delay after stage separation before engine throttles up

// Crew abort check
set crewAbortCheck to true.				// Whether or not to check if there is anything in the abort action group prior to crewed launches. If true, CLS will abort any crewed launch with no abort action groups.
set crewCount to ship:crew():length.

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

// Initiate settings
clearscreen. unlock all. sas off. rcs off.
set Ship:control:pilotmainthrottle to 0.
set terminal:width to 52. set terminal:height to 45.
set config:ipu to 800. set config:stat to false.

// Steering manager setup
set SteeringManager:RollTS to 5.						// Reduces oversensitive roll correction during ascent

// Script Library
runpath("0:/cls_lib/CLS_dv.ks"). 
runpath("0:/cls_lib/CLS_gen.ks").
runpath("0:/cls_lib/CLS_hud.ks").
runpath("0:/cls_lib/CLS_nav.ks").
runpath("0:/cls_lib/CLS_res.ks").
runpath("0:/cls_lib/CLS_twr.ks").
runpath("0:/cls_lib/CLS_ves.ks").
runpath("0:/cls_lib/lib_instaz.ks").
runpath("0:/cls_lib/lib_lazcalc.ks").
runpath("0:/cls_lib/lib_navball.ks").
runpath("0:/cls_lib/lib_num_to_formatted_str.ks").
runpath("0:/cls_lib/CLS_log.ks").

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
set launchtime to Time:seconds + secondsToLaunch(launchWindow).									// Predicts launch time assuming no countdown holds - Script takes 23 seconds between initialisation and launch. Function converts hh:mm:ss input to seconds
Lock steering to heading(launchazimuth,trajectorypitch,launchroll).							// Master steering command

// Staging variables
set ImpendingStaging to false.																// Boolean. True when rocket is about to stage
set ImpendingStagingTime to 0.																// Logs time at which CLS detects imminent staging
set ImpendingStagingPitch to 0.																// Logs current pitch when imminent staging is detected for a gradual pitch to prograde
set staginginprogress to false.																// Boolean. True when rocket is staging
set stagingComplete to false.																// Boolean. True when staging has succesfully occured
set srbStagingStartTime to Time:seconds+100000.												// Tracks staging start time of SRBs / boosters. set to high number while unused
set srbFlameoutTime to 0.																	// Tracks impending SRB burn out
set stagingStartTime to Time:seconds+100000.												// Tracks staging start time. set to high number while unused
set stagingEndTime to Time:seconds+100000.													// Tracks staging end time. set to high number while unused
set SRBstagingOverride to false.															// Overrides staging detection and forces staging when SRB thrust curve is < 0.25.
set EngstagingOverride to false.															// Overrides staging detection for engine flame-out. 
set Ullagedetected to false.																// Boolean. Tracks whether vehicle uses ullage motors during staging. set during staging.
set stagingApoapsisETA to 1000.																// Tracks eta:apoapsis at time of staging - used to determine when upper stages can throttle down

// Loop variables 
set launchcomplete to false.																// Terminates script on completion
set runmode to 0.																			// Tracks phase of the script
set cdownreadout to 0.																		// Countdown function
set tminus to 20.																			// Countdown timer
set cdownHoldReason to "-".																	// Tracks reason for countdown holds. Set during countdown
set launchThrottle to 1.																	// Launch throttle to achieve liftoff TWR as configured above
set gravityTurnVelocity to 100.																// Tracks vertical velocity at which gravity turn will start - higher for vehicles that dont hit takeoff TWR
set throttletime to 0.																		// Tracks time of engine throttling. Used for gradual throttling.
set currentthrottle to 0.																	// Tracks initial throttle during engine throttle up or down
set CentralEnginesCalculation to false.														// Tracks central booster throttling for 3 booster lifter configurations
set CentralEnginesThrottle to 0.															// Tracks throttle required during central engine throttling of 3 booster vehicle configurations
set ApoETAcheck to false.																	// Tracks whether the vehicle's time to apoapsis is suitable for throttle down 			
set threeBurn to false.																		// Tracks Whether CLS has determined 3 burns is most efficicent to achieve target orbit
set ascentComplete to false.																// Used to monitor multiple data streams to determine best time to end ascent
set insufficientDV to false.																// Used to detect insufficient DV to complete ascent 

// Ship information / Variables
if Ship:name:length > 15 { set Ship:name to "Vehicle". }									// Ensures vehicle name fits on terminal width
set VehicleConfig to 0.																		// 0 = no SRBs present. 1 = SRBs present. 0 as default.
set currentstagenum to 1.																	// Tracks current stage number
set numparts to Ship:parts:length.															// Tracks the number of parts. If this decreases unexpectedly, the script assumes a RUD and triggers an abort.
set CentralEngines to false.																// Tracks if the vehicle has 'Central Engines' and is therefore a 3 booster design. See Required staging set-up above. Detected during countdown
set PayloadProtection to false.																// Tracks if the vehicle is using a method of payload protection such as fairings or LES. Detected during countdown
set PayloadProtectionStage to 0.															// Tracks stage of PayloadProtection (eg fairings). Used to determine if fairings must be jettisoned prior to staging (eg Atlas 5m Configurations)
set PayloadProtectionConfig to "-".															// Tracks type of payload protection (eg fairings or LES)
set FuelCellActive to False.																// Tracks status of on board fuel cells
FuelCellDetect(). PrelaunchEngList().														// Gathers info on initial engines and detects fuel cells. Removes thrustlimits on all engines to hand control over to CLS. 	

// Manuever node / burn variables
set burnStartTime to Time:seconds+100000.													// Determines time at which manuever burn should start. 
set burnStarted to false.																	// Tracks whether the burn has started
set burnDeltaV to 0.																		// Tracks initially calculated burn dV - used to determine when burn should end

//HUD Initialise
set printlist to List(). set listlinestart to 6.											// Scrolling print configuration
set logtime to 60. set dynamicPressure to 0. set dynamicPressureTime to 0. set passedMaxQ to false.				// Variables used to track MaxQ and provide regular speed, distance & alitude updates
HUDinit(launchtime,targetapoapsis,targetperiapsis,targetinclination,csvLog).				// Prints info at top of HUD

// Data logging
if csvLog {
	LogInitialise(targetapoapsis,targetperiapsis,targetinclination).						//Creates an external csv file with launch data
}

// Main loop begin
Until launchcomplete {

	// Initiate looping functions
	AscentHUD().						// Initiates the HUD information at the bottom of the terminal.
	warpControl(runmode).				// Activates warp control function anytime warp speed is manually adjusted

	//Log feature - logs data to the csv file created by LogInitialise()
	if csvLog and missiontime > 0 {
		log_data(missiontime,LIST(missiontime,vehicleConfig,StageDV(),twr(),throttle,pitch_for(),(ship:q*constant:AtmToKPa),ship:altitude,ship:apoapsis,eta:apoapsis,ship:periapsis,currentstagenum,staginginprogress,runmode,numparts,circulariseDV_Periapsis(),circulariseDV_Apoapsis(),(BurnApoapsis_TargetPeriapsis(targetapoapsis)+ABS(circulariseDV_TargetPeriapsis(targetapoapsis,targetperiapsis)))),logPath).
	}

	// Countdown
	// Countdown function handles the 'empty' countdown seconds. Below are pre-launch checks. They produce terminal readouts written for a sense of realism. 
	If runmode = 0 {
		set cdown to Time:seconds - launchtime.		// Calculates time to launch. Used to ensure pre-launch events happen at specific times.
		Countdown(tminus,cdown).					// Displays the countdown on the terminal
		
		if cdown < -20 {
			print "T" + hud_missionTime(cdown) + "   " at (0,(printlist:length)+listlinestart).	// Will display a countdown if terminal input has set a specific launch time
		} else if tminus = 20 {
			scrollprint("Startup").
			set tminus to tminus-1.
		}
	
		// Electric charge check. Holds launch if vehicle has < 40% electric charge
		If cdown >= -18 and tminus = 18 {
			If Resourcecheck("Electriccharge",0.4) = false {					// Function for checking resource is above a threshold
				set cdownHoldReason to "Insufficient Power". 
				set runmode to -1.
			} else {
				scrollprint(Ship:name + " is on Internal Power").
			}
			set tminus to tminus-1.
		}
		
		// Detects presence of SRBs or 3 booster design and changes mode configuration
		If cdown >= -16 and tminus = 16 {
			SRBDetect(ship:parts).	PrelaunchEngList().											// Function for detecting SRBs
			If Ship:partstaggedpattern("^CentralEngine"):length > 0 {
				set CentralEngines to true.	
			}				
			scrollprint("Launch Mode " + vehicleConfig + " Configured").
			set tminus to tminus-1.
		}
		
		// Staging checks. Holds launch if clamps or decouplers are incorrectly staged, or clamps are not present. See required staging set-up above
		If cdown >= -14 and tminus = 14 {
			if launchClampCheck() = false {
				set cdownHoldReason to "No launch clamps detected". 
				set runmode to -1.
			} else if stagingCheck() =  false {
				set cdownHoldReason to "Subnominal Staging Detected". 
				set runmode to -1.
			} else {
				scrollprint("Staging Checks Complete").
			}
			set tminus to tminus-1.
		}
		
		// Determines main fuel tank and calculates its fuel capacity. Holds launch if this cant be determined. 
		If cdown >= -12 and tminus = 12 {
			PrimaryFuel(). fueltank(ResourceOne). PrimaryFuelMass(). SolidFuel().
			If FuelRemaining(stagetanks,ResourceOne) = 0 {
				set runmode to -1.
				set cdownHoldReason to "MFT Detect Issue".
			}
			scrollprint("Pressurization Checks Complete").
			set tminus to tminus-1.
		}
		
		// Detects LES or fairing configuration based on parts assigned to action group 10. Holds launch if there are no parts in action group 10 or if there are parts in action group 10 that shouldnt be.
		If cdown >= -10 and tminus = 10 {
			If Ship:partsingroup("AG10"):length > 0 {
				set PayloadProtection to true.
				For P in Ship:partsingroup("AG10") {
					set PayloadProtectionStage to P:Stage.
					If P:hasmodule("Moduleengines") or P:hasmodule("ModuleenginesFX") {
						set PayloadProtectionConfig to "LES".
					} else {
						set PayloadProtectionConfig to "Fairings".
					}
				}
				scrollprint(PayloadProtectionConfig + " Configured For Launch").
			} else {
				scrollprint("Fairing Checks Complete").
				set runmode to -1.
				set cdownHoldReason to "AG10 Advisory".				
			}
			set tminus to tminus-1.
		}
		
		// Checks abort procedures are ready
		If cdown >= -6 and tminus = 6 {
			if crewCount = 0 {
				scrollPrint("T" + hud_missionTime(cdown),false).
			} else {
				if Ship:partsingroup("abort"):length < 1 and crewAbortCheck {
					set runmode to -1.
					set cdownHoldReason to "Crew Abort Procedure Error".
				} else {
					scrollprint("Abort Systems Configured For Launch").
				}
			}
			set tminus to tminus-1.
		}
		
		// Ignition and calculation for main engine throttle up during countdown
		If cdown >= -3 and tminus = 3 {
			stage.
			Activeenginelist().
			scrollprint("Ignition").
			set throttletime to Time:seconds+1.
			lock throttle to min(TWRthrottle(LiftoffTWR),TWRthrottle(LiftoffTWR)*(Time:seconds-throttletime)/2).
			set tminus to tminus-1.
		}
		
		// Checks engines are producing thrust. Terminates script if they arent.
		If cdown >= -2 and tminus = 2 {
			if ship:availablethrust > 0.1 {
				scrollprint("Thrust Verified").
			} else {
				lock throttle to 0.
				scrollprint("Launch Aborted").
				scrollprint("Insufficient Thrust",false).
				set launchcomplete to true.
			}
			set tminus to tminus-1.
		}	
		
		// SRB ignition (if SRBs are present). Main engines reach lift-off thrust.
		If cdown >= -1 and tminus = 1 {
			if vehicleConfig = 0 {
				scrollPrint("T" + hud_missionTime(cdown),false).
				RemainingBurn().
			} else {
				stage.
				scrollprint("SRB Ignition").
				activeSRBlist(). RemainingBurnSRB().
			}
			set tminus to tminus-1.
		}
		
		// Checks vehicle TWR. Will terminate script if its below the threshold configured in TWR configuration. If TWR is ok, the vehicle will liftoff at the TWR configured in TWR configuration (if it has enough thrust).
		If cdown >= 0 and tminus = 0 and throttle >= TWRthrottle(LiftoffTWR) {
			If TWR() < minLiftoffTWR {
				lock throttle to 0.
				scrollprint("Launch Aborted").
				scrollprint("Insufficient Thrust",false).
				set launchcomplete to true.
			} else {
				Stage.
				set numparts to Ship:parts:length.
				scrollprint("Liftoff (" + T_O_D(time:seconds) + ")").
				set launchThrottle to TWRthrottle(LiftoffTWR).		// Records the throttle needed to achieve the launch TWR. Used to throttle engines during ascent.
				lock throttle to launchThrottle.
				if vehicleConfig = 1 {		
					lock throttle to max(0.01,min(1,launchThrottle + ((PartlistAvailableThrust(SRBs)-PartlistCurrentThrust(SRBs))/PartlistAvailableThrust(aelist)))).
				} 
				set gravityTurnVelocity to 100 + (100*(LiftoffTWR - twr())).		//Calculates vertical speed at which gravity turn will start. Based on ship TWR to make low twr vehicles go more vertical.
				set runmode to 1.
			}
		}
	}

	// Countdown hold for unplanned issues
	// Holds the countdown and gives you the choice to continue, recycle or abort the launch
	if runmode = -1 {
		scrollprint("Hold Hold Hold",false).
		scrollprint(cdownHoldReason,false).
		set proceedMode to scrubGUI(cdownHoldReason).
		
		if proceedMode = 1 {													// continue countdown
			set runmode to 0.
			set launchtime to time:seconds + tminus.
			Print "Target Launch Time: NET " + T_O_D(launchtime) at (0,1).
		} else if proceedMode = 2 {												// Recycle countdown
			set runmode to 0.
			set tminus to 20.
			set cdownreadout to 0.
			set launchtime to time:seconds + 23.
			Print "Target Launch Time: NET " + T_O_D(launchtime) at (0,1).
		} else if proceedMode = 3 {												// Scrub launch
			scrollprint("Launch Scrubbed",false).
			set launchcomplete to true.	
		}
	}
	
	// Initial ascent. Calculates when to start the gravity turn. Lower TWR vehicles start later.
	If runmode = 1 {
		//Ship will gradually pitch to 5 degrees while it builds vertical speed
		set trajectorypitch to 90-(5/(gravityTurnVelocity/ship:verticalspeed)).
		
		//Start of gravity turn - gravityTurnVelocity set at t-0
		if ship:verticalspeed > gravityTurnVelocity {
			set runmode to 2.
			set launchroll to launchroll + (launchazimuth - heading_for_vector(east_for())).
			scrollprint("Starting Ascent Trajectory").
		}
	}

	// Ascent trajectory program until reach desired apoapsis	
	If runmode = 2 {	
		
		if passedMaxQ = false { maxQ(dynamicPressure). }			// Function for detecting MaxQ
		Eventlog().										// Initiates mission log readouts in the body of the terminal

		//Azimuth calculation
		if abs(targetinclination) > 0.1 and currentstagenum > 1 and ship:orbit:inclination > (abs(targetinclination) * 0.99) {
			set launchazimuth to IncCorr(targetinclination).
		} else {
			set launchazimuth to LAZcalc(LAZcalc_init(targetapoapsis,targetinclination)).
		}
		
		//Pitch calculation
		set trajectorypitch to PitchProgram_Sqrt(currentstagenum).
		
		// Staging Pitch control
		If ImpendingStaging {
			local pDiff is abs(pitch_for_vector(Ship:srfprograde:forevector) - ImpendingStagingPitch).
			local tDiff is time:seconds - ImpendingStagingTime.
			if tDiff < 3 {
				if pitch_for_vector(Ship:srfprograde:forevector) > ImpendingStagingPitch {
					set trajectorypitch to ImpendingStagingPitch + ((pDiff*tDiff)/3).
				} else {
					set trajectorypitch to ImpendingStagingPitch - ((pDiff*tDiff)/3).
				}
			} else {
				set trajectorypitch to pitch_for_vector(Ship:srfprograde:forevector).
			}
		} 
		If staginginprogress or time:seconds < stagingEndTime+3 and time:seconds > stagingEndTime { 
			set trajectorypitch to pitch_for_vector(Ship:srfprograde:forevector).
			set ImpendingStagingTime to 0.
		}
		
		// Ascent TWR control for first stage
		If currentstagenum = 1 {
			
			// Throttle down of main engines so that TWR will not go above threshold set by maxAscentTWR during ascent
			If twr() > maxAscentTWR+0.01 and not ImpendingStaging {
				scrollprint("Maintaining TWR").
				lock throttle to twrthrottle(maxAscentTWR).
			}
			
			// Gradual throttle down of central engines in 3 booster config. Occurs when the vehicles maximum possible TWR reaches 2.
			If CentralEngines = true and not impendingstaging and not staginginprogress {
				local t is ((ship:availablethrust/aelist:length)*0.55)+(ship:availablethrust/aelist:length)*(aelist:length-1).			//Finds thrust of one engine * 0.55 (what the center engines throttle to) then adds thrust of other engines																				
				If (ship:mass*adtg())/t*twr() <= 1 or (ship:mass*adtg())/t*2.1 <= 1 {											//If vessel can throttle central engine to maintain twr or keep twr above 2.1
					If CentralEnginesCalculation = false {
						set throttletime to Time:seconds.
						set CentralEnginesCalculation to true.
						scrollprint("Throttling Central Engines").
						set currentthrottle to throttle.		
						set CentralEnginesThrottle to (ship:mass*adtg())/t*min(2.1,twr()).
						lock throttle to (CentralEnginesThrottle - currentthrottle)*((Time:seconds-throttletime)/5)+currentthrottle.							//Calculates throttle needed (after throttle) to maintain currenttwr.
					}
				}
				If CentralEnginesCalculation = true {
					For e in Ship:partstaggedpattern("^CentralEngine") {
						If Time:seconds - throttletime < 5 {
							set e:thrustlimit to ((55 - 100)*((Time:seconds-throttletime)/5)+100).
						} else {
							set e:thrustlimit to 55.
							lock throttle to CentralEnginesThrottle.
							set CentralEngines to false.
						}
					}								
				}
			} 
			
			If vehicleConfig = 1 {
				// Detection of SRB going below 25% rated thrust. Tells vehicle to stage.
				If PartlistCurrentThrust(SRBs)/PartlistAvailableThrust(SRBs)<0.25 {
					set SRBstagingOverride to true.
				}
				
				// Detection of impending SRB flameout
				If remainingBurnSRB() < 5 and remainingBurnSRB() > 0.1 and not staginginprogress and not ImpendingStaging {
					set ImpendingStaging to true.
					if srbFlameoutTime = 0 {
						set srbFlameoutTime to time:seconds.
						set currentthrottle to throttle.
					}
					lock throttle to min(TWRthrottle(maxAscentTWR),currentthrottle + ((TWRthrottle(maxAscentTWR)-currentthrottle)*(Time:seconds-srbFlameoutTime)/2)).
					if ImpendingStagingTime = 0 {
						set ImpendingStagingTime to time:seconds.
						set ImpendingStagingPitch to pitch_for_vector(ship:facing:forevector).
					}
				}
			}
		}
		
		// Ascent TWR control For second stage
		If currentstagenum > 1 and staginginprogress = false {
		
			//Limits upper stage to maxAscentTWR
			If twr() > maxAscentTWR+0.01 {
				scrollprint("Maintaining TWR").
				lock throttle to twrthrottle(maxAscentTWR).
			}
			
			// Checks whether it has been 5 seconds since staging and time to apoapsis is above 120 seconds and second stage has boosted eta:apoapsis by 30 seconds since sep before gradually throttling to TWR set by UpperAscentTWR			
			If eta:apoapsis < eta:periapsis and Eta:apoapsis > stagingApoapsisETA and ApoEtacheck = false and (Time:seconds - stagingEndTime) >= 5 {
				set ApoEtacheck to true.
				set throttletime to Time:seconds.
				set currentthrottle to throttle.
				scrollprint("Throttling Down").
			}
			If ApoEtacheck = true {
				If TWR() > UpperAscentTWR+0.01 {
					lock throttle to max(TWRthrottle(UpperAscentTWR),((TWRthrottle(UpperAscentTWR) - currentthrottle)*((Time:seconds-throttletime)/5)+currentthrottle)).
				}
				if Eta:apoapsis < 75 {								// If time to apoapsis drops below 75 seconds after engines have throttled down, this will throttle them back up
					set ApoEtacheck to false.
					lock throttle to TWRthrottle(maxAscentTWR).
				}
			}
		}
		
		// Detects imminent fuel depletion of current main fuel tank
		If RemainingBurn() < 5 and RemainingBurn() > 0.1 and not staginginprogress and not ImpendingStaging {
			set ImpendingStaging to true.
			if ImpendingStagingTime = 0 {
				set ImpendingStagingTime to time:seconds.
				set ImpendingStagingPitch to pitch_for_vector(ship:facing:forevector).
			}
		}
		
		//End of ascent detection
		if not staginginprogress {
			if eta:apoapsis < eta:periapsis {
				if orbitData >= (targetapoapsis-250) {
					set ascentComplete to true.
				}
			} else {
				if ship:periapsis >= atmAlt {
					if ship:apoapsis >= (targetapoapsis-250) {
						set ascentComplete to true.
					}
					if ship:apoapsis >= (targetapoapsis+1000) {
						set threeBurn to true.
						set LEO to true.
					}
				}
			}
			if LEO = true {
				//Apoapsis is getting too large. Vehicle has enough dV to stop burn, burn at apoapsis to raise periapsis and then circularise at periapsis with a retrograde burn.
				if ship:apoapsis >= 1.75*targetapoapsis and eta:apoapsis > 480 and eta:apoapsis < eta:periapsis {
					if ship:altitude > body:atm:height and BurnApoapsis_TargetPeriapsis(targetperiapsis)+circulariseDV_TargetPeriapsis(targetapoapsis,targetperiapsis) < StageDV() {
						set ascentComplete to true.
						set threeBurn to true.
					}
				}
			}
		}
		
		//Insufficient Dv detection 
		if ship:apoapsis > body:atm:height*1.05 and currentstagenum = MaxStages and (Time:seconds - stagingEndTime) >= 15 {
			if LEO = false {
				//Vehicle wont have enough deltaV to circularise if it raises its apoapsis any further. Cuts the burn short and will circularise at current apoapsis.
				if circulariseDV_Apoapsis() >= (StageDV()*0.95) {
					set insufficientDV to true.
				}
			} else {
				//Current periapsis is above atmosphere (we are in orbit). Vehicle wont have enough deltaV to circularise if it raises its apoapsis any further. Cuts the burn short and will circularise at current periapsis.
				if ship:periapsis > atmAlt and circulariseDV_Periapsis()>=(StageDV()*0.95) {
					set insufficientDV to true.
				}
				//Periapsis is in atmosphere and if we continue to burn we may not have enough dv left to burn at apo to bring peri outside atmosphere and achieve minimum orbit
				if ship:periapsis < atmAlt and BurnApoapsis_TargetPeriapsis(atmAlt) >= (StageDV()*0.95) {
					set insufficientDV to true.
					set threeBurn to true.
				}
			}
		}
		
		//End of ascent actions
		if ascentComplete or insufficientDV {
			scrollprint(enginereadout(currentstagenum) + " Cut-Off ").
			if ascentComplete {
				scrollprint("          Parking Orbit Confirmed",false).
			} else if insufficientDV {
				scrollprint("          Insufficient dV detected",false).
			}
			scrollprint("          Entering Coast Phase",false).
			lock throttle to 0.
			set runmode to 3.
		}
	}
	
	// Manuever Node creation for circularisation burn	
	If runmode = 3 and ship:availablethrust > 0.1 {
		if hasnode = false {
			if LEO = true {
				if threeBurn = true {
					if eta:apoapsis < eta:periapsis {
						set cnode to node(time:seconds + eta:apoapsis, 0, 0, BurnPeriapsis_TargetApoapsis(targetperiapsis)).
					} else {
						set cnode to node(time:seconds + eta:periapsis, 0, 0, BurnApoapsis_TargetPeriapsis(targetapoapsis)).
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
			set burnStartTime to time:seconds + cnode:eta - nodeBurnStart(cnode).
			set burnStarted to false.
			set burnDeltaV to cnode:deltav.
			set runmode to 4.
		} else {
			remove nextnode.
		}
	}
	
	//Post-ascent staging 
	If runmode = 4 {
		if currentstagenum = 1 or StageDV() < cnode:deltav:mag and currentstagenum < maxStages {
			Lock steering to heading(heading_for_vector(Ship:srfprograde:forevector),pitch_for_vector(Ship:srfprograde:forevector),launchroll).
			RCS on.
			if vang(steering:vector,ship:facing:vector) < 1 {
				set EngstagingOverride to true.
			}
		} else if not EngstagingOverride {
			if time:seconds < burnStartTime {
				lock steering to Ship:prograde:forevector.
				lowPowerMode().								// low power mode for coast
				set runmode to 5.
			} else {
				rcs on.
				set runmode to 6.
			}
		}
	}
	
	// Coast phase
	If runmode = 5 {
		//if ship:altitude > body:atm:height and time:seconds >= burnStartTime-45 {		// Will take the vehicle out of warp (and prevent further warping) 90 seconds before the circularisation burn is due to start
		if time:seconds >= burnStartTime-45 {		// Will take the vehicle out of warp (and prevent further warping) 90 seconds before the circularisation burn is due to start			lowPowerMode().								// return to full power mode
			scrollprint("Preparing for Burn").
			scrollprint("          Delta-v requirement: " + ceiling(cnode:deltav:mag,2) + "m/s",false).
			scrollprint("          Burn time: " + hud_missionTime(nodeBurnTime()),false).
			rcs on.
			
			//dV check in case boil-off losses could result in incomplete burn
			if StageDV() < cnode:deltav:mag {
				set cnode:prograde to stageDV()*0.99.
				set burnStartTime to time:seconds + cnode:eta - nodeBurnStart(cnode).
				set burnDeltaV to cnode:deltav.
			} else {
				set runmode to 6.
			}
		}
	}
	
	// Circularisation burn
	if runmode = 6 {
		lock steering to cnode:burnvector.
		if GimbalDetect() = true {
			if vang(steering,ship:facing:vector) > 5 and time:seconds >= burnStartTime-5 and burnStarted = false { 
				if throttle = 0 {
					lock throttle to twrthrottle(0.1).
					scrollprint("Correcting attitude with Thrust gimbal").
				}
			}
		}
		if time:seconds >= burnStartTime and burnStarted = false and ship:availablethrust > 0.1 {
			set burnStarted to true.
			lock throttle to 1.
			scrollprint(enginereadout(currentstagenum) + " Ignition").
		}

		// Handles throttle and burn end
		if burnStarted = true {
			lock throttle to min(cnode:deltav:mag/(ship:availablethrust/ship:mass),1).		// This will throttle the engine down when there is less than 1 second remaining in the burn
			if cnode:deltav:mag < 0.1 and vdot(burnDeltaV,cnode:deltav) < 0.1 {
				lock throttle to 0.
				scrollprint(enginereadout(currentstagenum) + " Cut-Off").
				set runmode to 7.
			}
		}
	}
	
	// Triggers program end
	If runmode = 7 {
		lock steering to Ship:prograde:forevector.
		if threeBurn = true {
			set runmode to 3.
			set threeBurn to false.
			remove cnode.
		} else {
			scrollprint("          Orbit Cicularised",false).	
			set launchcomplete to true.
		}
	}

	// Perform abort if conditions defined in Continuous abort detection logic (below) are met and terminates script
	If runmode = -666 {
		lock throttle to 0.
		set Ship:control:neutralize to true. 
		sas on.
		scrollprint("Launch Aborted").
		Hudtext("Launch Aborted!",5,2,100,red,false).
		set launchcomplete to true.
		if Ship:partsingroup("abort"):length > 0 {
			runpath("0:/Abort.ks").
		}
	}
	
	// Fairing separation
	If runmode > 1 and PayloadProtection = true {	
		// If the fairings need to be jettisoned before stage separation (eg Atlas V 5m configuration)  then the fairings will jettison as soon as staging is imminent
		If (Stage:number - PayloadProtectionStage)=1 and runmode = 2 and ImpendingStaging {
			set numparts to Ship:parts:length - Ship:partsingroup("AG10"):length.
			Stage.
			scrollprint(PayloadProtectionConfig + " Jettisoned").
			set PayloadProtection to false.
		}
		
		// Jettisons fairing/LES when the altitude pressure becomes insignificant and first stage has been jettisoned
		If Body:atm:altitudepressure(ship:altitude) < 0.00002 and currentstagenum > 1 {
			If not ImpendingStaging and not staginginprogress and Time:seconds - stagingEndTime >= 5 {
				set numparts to Ship:parts:length - Ship:partsingroup("AG10"):length.
				Toggle Ag10. 
				scrollprint(PayloadProtectionConfig + " Jettisoned").
				set PayloadProtection to false.
			}
		}
	}

	// Continuous staging check logic
	If runmode = 2 or SRBstagingOverride or EngstagingOverride {
		If staginginprogress = false and currentstagenum < MaxStages {
			
			// Engine flameout detection
			For e in elist {
				If EngstagingOverride or SRBstagingOverride or e:ignition and e:flameout {	
					set staginginprogress to true.
					set ImpendingStaging to false.
					rcs on.
					Wait 0.01.
					
					// If flameout is due to a booster shutdown only
					If ship:availablethrust >= 0.1 and not EngstagingOverride {
						set srbStagingStartTime to Time:seconds+stagedelay.
						If vehicleConfig = 1 {
							scrollprint("SRB Flameout").
						} else {
							scrollprint("External Tank Depletion").
						}
						Break.
					}
					
					// If flameout is entire stage engine shutdown
					If ship:availablethrust < 0.1 or EngstagingOverride {
						set stagingStartTime to Time:seconds+stagedelay.
						set stagingComplete to false.
						lock throttle to 0.
						if not EngstagingOverride {
							scrollprint(enginereadout(currentstagenum) + " Cut-Off").
						}
						Break.	
					}	
				}
			}
		}	
		
		// Booster or external tank staging (after specified delay)
		If Time:seconds >= srbStagingStartTime {
			Stage.
			FuelTank(ResourceOne).
			Activeenginelist(). ActiveSRBlist().
			set numparts to Ship:parts:length.
			set srbStagingStartTime to Time:seconds+100000.
			If vehicleConfig = 0 {
				scrollprint("External Tank Jettison").
				For e in Ship:partstaggedpattern("^CentralEngine") {
					set e:thrustlimit to 100.
				}
			} else {
				scrollprint("SRB Jettison").
				SRBDetect(ship:parts).
				SolidFuel().
			}
			if TWRthrottle(maxAscentTWR) < 1 {
				lock throttle to TWRthrottle(maxAscentTWR).
				scrollprint("Maintaining TWR").
			} else {
				lock throttle to 1.
			}
			set staginginprogress to false.
			set SRBstagingOverride to false.
			rcs off.
		}
		
		// Full staging
		// Checks for ullage & gradually throttles up engines
		If Time:seconds >= stagingStartTime {
			If stagingComplete = false {
				Stage.
				detectUllage().
				set numparts to Ship:parts:length.
				set stagingStartTime to Time:seconds.
				set stagingComplete to true.
				set currentstagenum to currentstagenum+1.
				scrollprint("Stage "+currentstagenum+" separation").
			}
			If UllageDetected = true {
				If ship:availablethrust < 0.01 {
					Stage.
					set numparts to Ship:parts:length.
					scrollprint("Ullage Motor Shutdown").
					set stagingStartTime to Time:seconds.
					set Ullagedetected to false.					
				}
			} else {
				// This accomodates upper stage engines that 'deploy'
				If Ship:availablethrust < 0.01 and stagingComplete = true {
					set stagingStartTime to Time:seconds+0.01.
					set throttledelay to throttledelay-0.01.
				} else If Ship:availablethrust >= 0.01 {
					Activeenginelist(). ActiveSRBlist().
					set staginginprogress to false.
					set EngstagingOverride to false.
					set stagingEndTime to Time:seconds.
					set stagingApoapsisETA to max(eta:apoapsis+30,120).
					rcs off.
					PrimaryFuel(). PrimaryFuelMass().
					FuelTankUpper(ResourceOne). FuelCellDetect().
					set stagingStartTime to Time:seconds+100000.
					if runmode = 2 {
						scrollprint("Stage "+currentstagenum+" Ignition").
						lock throttle to min(TWRthrottle(maxAscentTWR),(TWRthrottle(maxAscentTWR)*((Time:seconds-stagingEndTime)-throttledelay)/3)).
					} else {
						lock throttle to 0.
					}
				}
			}
		}
	}
	
	// Continuous abort detection logic - only checked for during ascent
	If runmode > 1 {
		// Angle to desired steering > 25 deg (i.e. steering control loss) during atmospheric ascent
		If runmode < 3 and Vang(Ship:facing:vector, steering:vector) > 25 and missiontime > 5 {
			set runmode to -666.
			scrollprint("Loss of Ship Control").
		}
		// Abort if number of parts less than expected (i.e. ship breaking up)
		If Ship:parts:length <= (numparts-1) and Stage:ready {
			set runmode to -666.
			scrollprint("Ship breaking apart").
		}
		// Abort if falling back toward surface (i.e. insufficient thrust)
		If runmode = 2 and ship:altitude < atmAlt and verticalspeed < -1.0 {
			set runmode to -666.
			scrollprint("Terminal Thrust").
		}
		// Abort due to insufficient electric charge
		If Resourcecheck("ElectricCharge",0.01) = false {
			set runmode to -666.
			scrollprint("Insufficient Internal Power").
		}
	}
	
	//If manual abort is triggered
	if ABORT = true {
		set runmode to -666.
		scrollprint("Manual Abort").
	}
	
	//Handles Activation and Deactivation of Fuel cells
	if FCList:length > 0 {
		if Resourcecheck("ElectricCharge",0.25) = false and FuelCellActive = false
			or Resourcecheck("ElectricCharge",0.75) = true and FuelCellActive = true { 
			FuelCellToggle().
		}
	}
wait 0.01.
}

// Main loop end
unlock all.
sas on. rcs off.

// End of the program
If launchcomplete {
	wait 10.
	if hasnode { remove cnode. }
	scrollprint("Program Completed").
	Print "                                              " at (0,0).
} 