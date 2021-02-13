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
//   - Without ullage motors: stage seperation and next stage ignition must be grouped into one stage.
//	 - With ullage motors that pull jettisoned stage away from the next stage: stage seperation, ullage ignition and next stage ignition must be grouped into one stage.
//	 - With ullage motors that push the next stage away from jettisoned stage: stage seperation and ullage ignition must be grouped into one stage, with next stage ignition in the following stage.
//	 - In a 3 booster config (i.e Falcon Heavy or Delta Heavy), all engines on the central booster should be tagged "CentralEngine". This allows them to be individually throttled down during ascent.
//	 - Uses RCS during stage seperation so upper stage(s) should have RCS fuel/thrusters. Not a hard requirement though.
//	 - Lifoff thrust to weight ratio (TWR) must be above 1.2 (this number can be configured in TWR configuration).

// Action groups:
//   - Place any fairing or LES jettison into action group 10. Will jettison based on atmopshere pressure (usually at 60km altitude).
//   - Abort action group will be automatically triggered if conditions defined under runmode -666 are met.

// Notes:
//	 - This script has no dependant mods, however the script checks for parts from the Procedural Fairing mod and can be configured below for non-stock fuels.
//   - Variable identifiers which are no longer needed or have not been defined yet are set to "-".
//	 - Can detect SRBs with thrust curves and will:		a) decouple them when they reach a low trust percentage		b) throttle main engine up to cover thrust losses due to throttle curve
//	 - If the script progresses far enough to activate any stages, but then the script is terminated (either manually or due to anomaly detection) you will need to 'revert to launchpad' before using the script again in order to reset the stages.
//	 - The script will throttle engines to achieve a liftoff TWR of 1.6 (this number can be configured in TWR configuration).

//////////////////////////////////////////////////////////////////////
//////////////////////////USER CONFIGURATION//////////////////////////
//////////////////////////////////////////////////////////////////////

//Runs GUI for user to input launch parameters
runpath("0:/cls_lib/CLS_parameters.ks").
clearscreen. print "Define Launch Parameters" at (0,0).
set launchParameters to launchParam().

// Default launch parameters (changed with GUI input above)
set targetapoapsis to launchParameters[0].			//200,000m
set targetinclination to launchParameters[1].		//0°
set SecondsUntilLaunch to launchParameters[2].		//23 Seconds
set MaxStages to launchParameters[3].				//2
set csvLog to launchParameters[4].					//false

//Ascent guidance
set ascentFactor to 0.7.		//Specifies the altitude at which the gravity turn will end (i.e atmosphere height x 0.65)

// Fuel configuration
// Change these to configure non-stock fuels. Do not remove CryoFuelName (Even if you are using stock fuels).
// If you do change them, make sure to change the corresponding fuel mass (you may have to dig in resource config files)
Set LiquidFuelName to "LiquidFuel".
Set OxidizerFuelName to "Oxidizer".
Set CryoFuelName to "LqdHydrogen".
Set SolidFuelName to "SolidFuel".
Set OxidizerFuelMass to 0.005.
Set LiquidFuelMass to 0.005.
Set CryoFuelMass to 0.00007085.

// TWR configuration
Set minLiftoffTWR to 1.2.			// Minimum liftoff TWR. Launch will abort just before liftoff if the vehicle attempts to launch with anything lower.
Set LiftoffTWR to 1.6.				// Liftoff TWR. Engines will be throttled to achieve this TWR at liftoff (if there is sufficient thrust). There are deltaV savings to be had with a higher TWR, 1.6 was best for a 'one size fits all' approach
Set maxAscentTWR to 3.				// Maximum TWR during ascent. The rocket will throttle down to maintain this when it is reached. There are deltaV savings to be had with a higher TWR, but be careful of vehicle heating.
Set UpperAscentTWR to 0.7.			// When time to apoapsis is above 90 seconds, the engines will throttle to maintain this TWR.

// Staging delays
Set stagedelay to 0.5.					// Delay after engine shutdown or previous staging before staging will occur.
Set throttledelay to 0.5. 				// Delay after stage seperation before engine throttles up

// Crew abort check
// Whether or not to check if there is anything in the abort action group prior to crewed launches. If true, CLS will abort any crewed launch with no abort action groups.
set crewAbortCheck to true.

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

// Initiate settings
clearscreen. unlock all. sas off. rcs off.
Set Ship:control:pilotmainthrottle to 0.
Set terminal:width to 52. Set terminal:height to 43.
Set config:ipu to 1000.

// Steering manager / PID setup
Set SteeringManager:RollTS to 5.			// Reduces oversensitive roll correction during ascent

// Script Library
// Important to change the paths below if you choose to reorganise how CLS is organised
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

// One-time variables
If Ship:name:length > 16 { Set Ship:name to "Vehicle". }	// Ensures vehicle name fits on terminal width
Set logtime to 60.											// Increment between mission log updates
Set SecondsUntilLaunch to SecToLaunch(SecondsUntilLaunch).	// Checks input for SecondsUntilLaunch parameter and recalculates if necessary
fueltank(OxidizerFuelName). remainingBurn().				// Run during initialisation for HUD

// Calculates initial launch azimuth
Set data to LAZcalc_init(targetapoapsis,targetinclination).
Set launchazimuth to LAZcalc(data).

// Scrolling print list creation
Set printlist to List(). Set printlisthistory to List(). printlisthistory:add("*").

// Loop variables 
set throt to 0. Lock throttle to throt.											
set trajectorypitch to 90.																	// Ensures rocket will initially go vertical.
set launchroll to rollLock(roll_for(ship)) - heading(launchazimuth,trajectorypitch):roll.	// Rocket will launch so that its 'roll orientation' remains the same from launch to orbit.
set steerto to heading(launchazimuth,trajectorypitch,launchroll). Lock steering to Steerto.
Set launchtime to Time:seconds + SecondsUntilLaunch.										// Script takes 23 seconds between initialisation and launch
Set cdownreadout to 0.																		// Countdown function
Set tminus to 20.																			// Countdown timer
Set mode to 0.																				// Mode 0 = no SRBs present. Mode 1 = SRBs present. 0 as default.
Set currentstagenum to 1.																	// Tracks current stage number
Set ImpendingStaging to false.																// Boolean. True when rocket is about to stage
Set staginginprogress to false.																// Boolean. True during staging
Set launchcomplete to false.																// Terminates script on completion
Set runmode to -1.																			// Tracks ascent phase
Set numparts to Ship:parts:length.															// Tracks the number of parts. If this decreases unexpectedly, the script assumes a RUD and triggers an abort.
Set booststagetime to Time:seconds+100000.													// Tracks staging start time of SRBs / boosters. Set to high number while unused
Set stagesep to false.																		// Tracks whether staging has succesfully occured
Set stagetime to Time:seconds+100000.														// Tracks staging start time. Set to high number while unused
Set stagefinishtime to Time:seconds+100000.													// Tracks staging end time. Set to high number while unused
Set throttletime to 0.																		// Tracks time of engine throttling
Set PayloadProtection to false.																// Tracks whether the vehicle has fairings or a LES. Set during pre-launch checks.
Set PayloadProtectionConfig to "-".															// Detects which is being used (fairing or LES). Set during pre-launch checks.
Set CentralEngines to false.																// Detects if the vehicles has 'Central Engines' and is therefore a 3 booster design. See Required staging set-up above.
Set CentralEnginesThrottle to false.														// Tracks central booster throttling for 3 booster lifter configurations
Set SRBstagingOverride to false.															// Overrides staging detection and forces staging when SRB thrust curve is < 0.4.
Set EngstagingOverride to false.															// Overrides staging detection for engines.
set nodecheck to false.																		// Detects whether the circularisation manuever node has been 'checked' in case apoapsis has fallen due to aerobraking as the vehicle exits the atmosphere.
set apoapsis975 to false.																	// Detects when vehicle's apoapsis is within 5% of the target apoapsis 
set broke90 to false.																		// Detects when the vehicle's time to apoapsis passes over 90 seconds															
set impStagingtime to 0.																	// Logs time at which CLS detects imminent staging
set impStagingPitch to 0.																	// Logs current pitch when imminent staging is detected for a gradual pitch to prograde
set SRBtime to 0.																			// Tracks impending SRB burn out
set circTime to 0.																			// Tracks the time the circularisation burn ends

// Date logging
if csvLog {
	LogInitialise(targetapoapsis,targetinclination).	//Creates an external csv file with launch data
}
HUDinit(launchtime,targetapoapsis,targetinclination,csvLog).					// Initiates the HUD information at the top of the terminal.

// Main loop begin
Until launchcomplete {

	// Initiate looping functions
	Eventlog().								// Initiates mission log readouts in the body of the terminal
	AscentHUD().							// Initiates the HUD information at the bottom of the terminal.
	warpControl(runmode).		// Activates warp control function anytime warp speed is manually adjusted

	//Log feature - logs data to the csv file created by LogInitialise()
	if csvLog and missiontime > 0 {
		log_data(missiontime,LIST(missiontime,mode,StageDV(PayloadProtection),twr(),throt,pitch_for(ship),(ship:q*constant:AtmToKPa),ship:altitude,ship:apoapsis,eta:apoapsis,ship:periapsis,currentstagenum,staginginprogress,runmode,numparts),logPath).
	}

	// Countdown
	// Countdown function handles the 'empty' countdown seconds. Below are pre-launch checks. They produce terminal readouts written for a sense of realism. 
	If runmode = -1 {
		set cdown to Time:seconds - launchtime.		// Calculates time to launch. Used to ensure pre-launch events happen at specific times.
		Countdown(tminus,cdown).					// Displays the countdown on the terminal
		
		if cdown < -20 and tminus >= 20 {
			print "T" + d_mt(cdown) + "   " at (0,6).	// Will display a countdown if terminal input has set a specific launch time
		}
	
		// Electric charge check. Holds launch if vehicle has < 40% electric charge
		If cdown >= -18 and tminus = 18 {
			If Resourcecheck("Electriccharge",0.4) = false {					// Function for checking resource is above a threshold
				Set scrubreason to "Insufficient Power". 
				Set runmode to -3.
			} else {
				scrollprint(Ship:name + " is on Internal Power").
			}
			Set tminus to tminus-1.
		}
		
		// Detects presence of SRBs or 3 booster design and changes mode configuration
		If cdown >= -16 and tminus = 16 {
			SRBDetect(ship:parts).														// Function for detecting SRBs
			If Ship:partstaggedpattern("^CentralEngine"):length > 0 {
				Set CentralEngines to true.
				For engine in Ship:partstaggedpattern("^CentralEngine") {
					Set Engine:thrustlimit to 100.								// I design 3 core lifters in the VAB with the central engines already throttled for more accurate d/V calculation. This throttles them back to 100% for launch.
				}		
			}				
			scrollprint("Launch Mode " + mode + " Configured").
			Set tminus to tminus-1.
		}
		
		// Staging checks. Holds launch if clamps or decouplers are incorrectly staged. See required staging set-up above
		If cdown >= -14 and tminus = 14 {
			For P in ship:parts {
				If mode = 1 and P:hasmodule("launchclamp") and P:stage <> (stage:number-3) or mode = 0 and P:hasmodule("launchclamp") and P:stage <> (stage:number-2) or P:hasmodule("proceduralfairingdecoupler") and P:stage = (stage:number-1) or P:hasmodule("moduledecouple") and P:stage = (stage:number-1){
					Set scrubreason to "Subnominal Staging Detected". 
					Set runmode to -3.
				}
			}
			If runmode = -1 {
				scrollprint("Staging Checks Complete").
			}
			Set tminus to tminus-1.
		}
		
		// Determines main fuel tank and calculates its fuel capacity. Holds launch if this cant be determined. 
		If cdown >= -12 and tminus = 12 {
			fueltank(OxidizerFuelName).
			If plistFuelRem(stagetanks,OxidizerFuelName) = 0 {
				set runmode to -2.
				set scrubreason to "MFT Detect Issue".
			}
			scrollprint("Pressurization Checks Complete").
			Set tminus to tminus-1.
		}
		
		// Detects LES or fairing configuration based on parts assigned to action group 10. Holds launch if there are no parts in action group 10 or if there are parts in action group 10 that shouldnt be.
		If cdown >= -10 and tminus = 10 {
			If Ship:partsingroup("AG10"):length > 0 {
				Set PayloadProtection to true.
				For P in Ship:partsingroup("AG10") {
					Set fairingstage to P:Stage.
					If P:hasmodule("ProceduralFairingSide") OR P:hasmodule("ModuleProceduralFairing") {
						Set PayloadProtectionConfig to "Fairings".
					} else If P:hasmodule("Moduleengines") or P:hasmodule("ModuleenginesFX") {
						Set PayloadProtectionConfig to "LES".
					}
				}
				If PayloadProtectionConfig = "-" {
					Set scrubreason to "Major AG10 Advisory".
					Set runmode to -3.
				} else {
					scrollprint(PayloadProtectionConfig + " Configured For Launch").
				}
			} else {
				scrollprint("Fairing Checks Complete").
				set runmode to -2.
				set scrubreason to "AG10 Advisory".				
			}
			Set tminus to tminus-1.
		}
		
		// Checks abort procedures are ready
		If cdown >= -6 and tminus = 6 {
			if crewAbortCheck {
				if ship:crew():length < 1 {
					scrollprint("$").
				} else {
					if Ship:partsingroup("abort"):length < 1 {
						Set runmode to -3.
						Set scrubreason to "Crew Abort Procedure Error".
					} else {
						scrollprint("Abort Systems Configured For Launch").
					}
				}
			} else {
				scrollprint("$").
			}
			Set tminus to tminus-1.
		}
		
		// Ignition and calculation for main engine throttle up during countdown
		If cdown >= -3 and tminus = 3 {
			stage.
			Activeenginelist().
			scrollprint("Ignition").
			Set throttletime to Time:seconds+1.
			Lock throt to TWRthrottle(LiftoffTWR)*(Time:seconds-throttletime)/2.
			Set tminus to tminus-1.
		}
		
		// Checks engines are producing thrust. Terminates script if they arent.
		If cdown >= -2 and tminus = 2 {
			if ship:availablethrust > 0.1 {
				scrollprint("Thrust Verified").
			} else {
				set throt to 0.
				scrollprint("Launch Aborted").
				scrollprint("Insufficient Thrust").
				Set launchcomplete to true.
			}
			Set tminus to tminus-1.
		}	
		
		// SRB ignition (if SRBs are present). Main engines reach lift-off thrust.
		If cdown >= -1 and tminus = 1 {
			if mode = 0 {
				scrollprint("$").
			} else {
				stage.
				scrollprint("SRB Ignition").
			}
			Set tminus to tminus-1.
		}
		
		// Checks vehicle TWR. Will terminate script if its below the threshold configured in TWR configuration. If TWR is ok, the vehicle will liftoff at the TWR configured in TWR configuration (if it has enough thrust).
		If cdown >= 0 and tminus = 0 {
			set throt to twrthrottle(LiftoffTWR).
			If TWR() < minLiftoffTWR {
				set throt to 0.
				scrollprint("Launch Aborted").
				scrollprint("Insufficient Thrust").
				Set launchcomplete to true.
			} else {
				Stage.
				Set numparts to Ship:parts:length.
				scrollprint("Liftoff").
				set launchtwr to twr().							// Records the actual TWR the vehicle achieved at liftoff. Used to calculate the gravity turn later.
				If mode = 1	{
					Set launchThrot to throt.					// Records the throttle needed to achieve the launch TWR. Used to throttle engines during ascent.
				} 
				Set runmode to 0.
			}
		}
	}

	// Countdown hold for unplanned issues
	// Holds the countdown and gives you the choice to continue, recycle or abort the launch
	if runmode = -2 or runmode = -3 {
		scrollprint("Hold Hold Hold").
		scrollprint(scrubreason).
		set proceedMode to scrubGUI(scrubreason,runmode).
		
		if proceedMode = 1 {
			set runmode to -1.
			set launchtime to time:seconds + tminus.
			Print "Target Launch Time: NET " + T_O_D(launchtime) at (0,1).
		} else if proceedMode = 2 {
			printlisthistory:clear.
			set runmode to -1.
			Set tminus to 20.
			Set cdownreadout to 0.
			set launchtime to time:seconds + 23.
			Print "Target Launch Time: NET " + T_O_D(launchtime) at (0,1).
		} else if proceedMode = 3 {
			scrollprint("Launch Scrubbed").
			set launchcomplete to true.	
		}
	}
	
	// Initial ascent. Calculates when to start the gravity turn. Lower TWR vehicles start later.
	If runmode = 0 {
		
		//Calculates vertical speed at which gravity turn will start. Based on ship TWR to make low twr vehicles go more vertical.
		set turnVel to 100 + (100*(LiftoffTWR - launchtwr)).
		
		//Ship will gradually pitch to 5 degrees which it builds vertical speed
		set trajectorypitch to 90-(5/(turnVel/ship:verticalspeed)).
		set steerto to heading(launchazimuth,trajectorypitch,launchroll).
		
		//Start of gravity turn
		if ship:verticalspeed > turnVel {
			set runmode to 1.
			Set turnstart to ship:altitude.
		}
		If mode = 1 {
			set throt to launchThrot + ((partlistavthrust(SRBs)-partlistcurthrust(SRBs))/partlistavthrust(aelist)).			// Throttles engines to compensate for SRB thrust curve
		}
	}
	
	// One-time actions 
	If runmode = 1 {	
		Activeenginelist().
		set launchroll to launchroll + (launchazimuth - compass_for_vect(ship,east_for(ship))).
		scrollprint("Starting Ascent Trajectory").
		Set runmode to 2.
	}

	// Ascent trajectory program until reach desired apoapsis	
	If runmode = 2 {	

		//Azimuth calculation
		if abs(targetinclination) > 0.1 and currentstagenum > 1 and ship:orbit:inclination > (abs(targetinclination) * 0.99) {
			Set launchazimuth to IncCorr(targetinclination).
		} else {
			Set launchazimuth to LAZcalc(data).
		}
		
		//Pitch calculation
		set trajectorypitch to PitchProgram_Sqrt(turnstart,ascentFactor).

		// Staging Pitch control
		If ImpendingStaging {
			local pDiff is pitch_for_vect(ship,Ship:srfprograde:forevector) - impStagingPitch.
			local tDiff is time:seconds - impStagingtime.
			if tDiff < 3 {
				set trajectorypitch to impStagingPitch + ((pDiff*tDiff)/3).
			} else {
				set trajectorypitch to pitch_for_vect(ship,Ship:srfprograde:forevector).
			}
		} 
		
		// Staging Pitch control
		If staginginprogress { 
			set trajectorypitch to pitch_for_vect(ship,Ship:srfprograde:forevector).
			set impStagingtime to 0.
		}
		
		//Final steering command
		set steerto to heading(launchazimuth,trajectorypitch,launchroll).
		
		// Ascent TWR control for first stage
		If currentstagenum = 1 {
			If mode = 0 {
			
				// Throttle down of main engines so that TWR will not go above threshold set by maxAscentTWR during ascent
				If TWR() > maxAscentTWR {
					set throt to TWRthrottle(maxAscentTWR).
					scrollprint("Maintaining TWR").
				}
				
				// Gradual throttle down of central engines in 3 booster config. Occurs when the vehicles maximum possible TWR reaches 2.
				If CentralEngines = true {
					If maxtwr() > 2 {
						If CentralEnginesThrottle = false {
							Set throttletime to Time:seconds.
							Set CentralEnginesThrottle to true.
							scrollprint("Throttling Central Engines").
							Set currentthrottle to throttle.
						}
					}
					If CentralEnginesThrottle = true {
						For engine in Ship:partstaggedpattern("^CentralEngine") {
							If Time:seconds - throttletime < 5 {
								Set Engine:thrustlimit to ((55 - 100)*((Time:seconds-throttletime)/5)+100).
								set throt to ((1 - currentthrottle)*((Time:seconds-throttletime)/5)+currentthrottle).
							} else {
								Set Engine:thrustlimit to 55.
								Set throt to 1.
								Set CentralEngines to false.
							}
						}								
					}
				}
			} else {
						
				// Throttle up of main engine to account for SRB thrust curve
				If twr() < maxAscentTWR and not ImpendingStaging {	
					set throt to launchThrot + ((partlistavthrust(SRBs)-partlistcurthrust(SRBs))/partlistavthrust(aelist)).
				}
				
				// Throttle down of main engines so that TWR will not go above threshold set by maxAscentTWR during ascent
				If twr() > maxAscentTWR and not ImpendingStaging {
					set throt to twrthrottle(maxAscentTWR).
					scrollprint("Maintaining TWR").
				}
				
				// Detection of SRB going below 20% rated thrust. Tells vehicle to stage.
				If partlistcurthrust(SRBs)/partlistavthrust(SRBs)<0.2 {
					Set SRBstagingOverride to true.
				}
				
				// Detection of impending SRB flameout
				If remainingBurnSRB() < 5 and remainingBurnSRB() > 0.1 and not staginginprogress {
					Set ImpendingStaging to true.
					if SRBtime = 0 {
						set SRBtime to time:seconds.
						set launchThrot to throt.
					}
					if time:seconds-SRBtime < 2 {
						set throt to launchThrot + ((srbsepthrottle(maxAscentTWR)-launchThrot)*(time:seconds-SRBtime)/2).
					}
					if impStagingtime = 0 {
						set impStagingtime to time:seconds.
						set impStagingPitch to pitch_for_vect(ship,ship:facing:forevector).
					}
				}
			}
		}
		
		// Ascent TWR control For second stage
		If currentstagenum > 1 and staginginprogress = false {
		
			//Limits upper stage to maxAscentTWR
			If twr() > maxAscentTWR {
				set throt to twrthrottle(maxAscentTWR).
				scrollprint("Maintaining TWR").
			}
			
			// Checks whether it has been 5 seconds since staging and time to apoapsis is above 90 seconds before gradually throttling to TWR set by UpperAscentTWR			
			If Eta:apoapsis > 90 and broke90 = false and (Time:seconds - stagefinishtime) >= 5 {
				Set broke90 to true.
				Set throttletime to Time:seconds.
				Set currentthrottle to throttle.
			}
			If broke90 = true and apoapsis975 = false {
				If TWR() > UpperAscentTWR {
					If Time:seconds - throttletime < 5 {
						set throt to ((TWRthrottle(UpperAscentTWR) - currentthrottle)*((Time:seconds-throttletime)/5)+currentthrottle).
					} else {
						set throt to TWRthrottle(UpperAscentTWR).
					}
					scrollprint("Throttling Down").
				}
			}
			
			// If time to apoapsis drops below 45 seconds after engines have throttled down, this will throttle them back up
			If broke90 = true and Eta:apoapsis < 45 {
				Set broke90 to false.
				set throt to TWRthrottle(maxAscentTWR).
			}
		}
		
		//Throttles to 0.1 for fine tuning final apoapsis
		If ship:apoapsis >= (targetapoapsis-2500) and apoapsis975 = false and not staginginprogress {
			Set apoapsis975 to true.
			Set throttletime to Time:seconds.
			Set currentthrottle to throttle.
		}
		if apoapsis975 = true and not staginginprogress {
			Set warp to 0.
			If TWR() > 0.1 {							// Throttles down to 0.1 TWR when <5% away from target apoapsis to ensure accuracy of parking orbit
				If Time:seconds - throttletime < 2 {
					set throt to ((TWRthrottle(0.1) - currentthrottle)*((Time:seconds-throttletime)/2)+currentthrottle).
				} else {
					set throt to TWRthrottle(0.1).
				}
				scrollprint("Throttling Down").
			}
		}
		
		// Detects imminent fuel depletion of current main fuel tank
		If RemainingBurn() < 5 and RemainingBurn() > 0.1 and not staginginprogress {
			Set ImpendingStaging to true.
			if impStagingtime = 0 {
				set impStagingtime to time:seconds.
				set impStagingPitch to pitch_for_vect(ship,ship:facing:forevector).
			}
		}
		
		//End of ascent
		if ship:apoapsis >= (targetapoapsis*0.9998) {
			if throt > 0 {
				scrollprint(enginereadout(currentstagenum) + " Cut-Off ").
				scrollprint("          Parking Orbit Confirmed").
			} else {
				scrollprint("Parking Orbit Confirmed").
			}
			set throt to 0.
			set runmode to 3.
		}
		
		// This detects if the vehicle wont have enough deltaV to circularise if it raises its apoapsis any further. Cuts the burn short and will circularise at current apoapsis.
		if ship:apoapsis > body:atm:height*1.05 and currentstagenum = MaxStages and (Time:seconds - stagefinishtime) >= 5 {
			if CircDV() >= (StageDV(PayloadProtection)*0.975) {
				scrollprint(enginereadout(currentstagenum) + " Cut-Off ").
				scrollprint("Insufficient dV detected").
				set throt to 0.
				Set runmode to 3.
			}
		}
	}
	
	// Manuever Node creation for circularisation burn	
	If runmode = 3 and ship:availablethrust > 0.1 {
		
		//Manuever node creation for cicular orbit
		if hasnode = false and currentstagenum > 1 {
			set cnode to node(time:seconds + eta:apoapsis, 0, 0, CircDV()). 																								
			add cnode.
			If ship:altitude > Ship:body:atm:height {
				set nodecheck to true.
			}
			set burnStartTime to time:seconds + cnode:eta - nodeBurnStart(cnode).
			set burntime to nodeBurnTime().
			set burnstart to false.
			set dv0 to cnode:deltav.
		}
		if hasnode {
			if time:seconds < burnStartTime {
				set runmode to 4.
			} else {
				if currentstagenum < MaxStages {
					Set EngstagingOverride to true.
				} 
				rcs on.
				set runmode to 5.
			}
		} else {
			set runmode to 4.
		}
	}
	
	// Coast phase
	If runmode = 4 {
		set steerto to Ship:prograde:forevector.
		scrollprint("          Entering Coast Phase").
		if ship:altitude > body:atm:height {
			if currentstagenum > 1 {
				if nodecheck = false {
					if hasnode {
						remove cnode.
					}
					set runmode to 3.
				} else if hasnode {
					if time:seconds >= burnStartTime-90 {			// Will take the vehicle out of warp (and prevent further warping) 90 seconds before the circularisation burn is due to start
						scrollprint("Preparing for Circularisation Burn").
						scrollprint("          Delta-v requirement: " + ceiling(cnode:deltav:mag,2) + "m/s").
						scrollprint("          Burn time: " + d_mt(burntime)).
						rcs on.
						set runmode to 5.
					}
				}
				stagingRCS(stagefinishtime).			// Activates RCS systems for 10 seconds after staging only if throttle is < 0.1.
			} else {
				Set EngstagingOverride to true.
			}
		}
	}
	
	// Circularisation burn
	if runmode = 5 {
		set steerto to cnode:burnvector.
		if time:seconds >= burnStartTime and burnstart = false {
			if ship:availablethrust > 0.1 {
				set burnstart to true.
				set throt to 1.
				scrollprint(enginereadout(currentstagenum) + " Ignition").
			}
		}
		if time:seconds >= burnStartTime-5 and vang(steerto,ship:facing:vector) > 5 and burnstart = false {
			scrollprint("Correcting attitude with Thrust gimbal").
			set throt to 0.1.
		}

		// Handles throttle and burn end
		if burnstart = true {
			set max_acc to ship:availablethrust/ship:mass.			// continuous calculation of max acceleration as it changes as fuel is burned
			set throt to min(cnode:deltav:mag/max_acc,1).			// This will throttle the engine down when there is less than 1 second remaining in the burn
			
			// When remaining deltaV is low, detects when node vector drifts significantly or faces the opposite direction, showing the burn is finished
			if cnode:deltav:mag < 0.1 or vdot(dv0,cnode:deltav) < 0 {
				if vdot(dv0,cnode:deltav) < 0.5 {
					set throt to 0.
					scrollprint(enginereadout(currentstagenum) + " Cut-Off").
					scrollprint("          Orbit Cicularised").
					Set runmode to 6.
					set circTime to time:seconds.
				}
			}
		}
	}
	
	// Triggers program end
	If runmode = 6 {
		set steerto to Ship:prograde:forevector.
		if time:seconds - circTime > 10 {
			remove cnode.
			Set launchcomplete to true.
		}
	}

	// Perform abort if conditions defined in Continuous abort detection logic (below) are met and terminates script
	If runmode = -666 {
		set throt to 0.
		Set Ship:control:neutralize to true. 
		sas on.
		scrollprint("Launch Aborted").
		Hudtext("Launch Aborted!",5,2,100,red,false).
		Set launchcomplete to true.
		if Ship:partsingroup("abort"):length > 0 {
			runpath("0:/Abort.ks").
		}
	}
	
	// Fairing seperation
	If PayloadProtection = true {	
		
		// If the fairings need to be jettisoned before stage seperation (eg Atlas V 5m configuration)  then the fairings will jettison as soon as staging is imminent
		If ((Stage:number - fairingstage)=1) and runmode = 2 {
			If ImpendingStaging {
				Set numparts to Ship:parts:length - Ship:partsingroup("AG10"):length.
				Stage.
				scrollprint(PayloadProtectionConfig + " Jettisoned").
				Set PayloadProtection to false.
			}
		}
		
		// Jettisons fairing/LES when the altitude pressure becomes insignificant (around 60km altitude)
		If Body:atm:altitudepressure(ship:altitude) < 0.00002 and currentstagenum > 1 {
			If not ImpendingStaging and not staginginprogress {
				If (Time:seconds - stagefinishtime) >= 5 {
					Set numparts to Ship:parts:length - Ship:partsingroup("AG10"):length.
					Toggle Ag10. 
					scrollprint(PayloadProtectionConfig + " Jettisoned").
					Set PayloadProtection to false.
				}
			}
		}
	}

	// Continuous staging check logic
	If runmode = 2 or SRBstagingOverride or EngstagingOverride {
		If staginginprogress = false and currentstagenum < MaxStages {
			
			// Engine flameout detection
			For e in elist {
				If EngstagingOverride or SRBstagingOverride or e:ignition and e:flameout {	
					Set staginginprogress to true.
					Set ImpendingStaging to false.
					rcs on.
					Wait 0.01.
					
					// If flameout is due to a booster shutdown only
					If ship:availablethrust >= 0.1 and not EngstagingOverride {
						Set booststagetime to Time:seconds+stagedelay.
						If mode = 1 {
							scrollprint("SRB Flameout").
						} else {
							scrollprint("External Tank Depletion").
						}
						Break.
					}
					
					// If flameout is entire stage engine shutdown
					If ship:availablethrust < 0.1 or EngstagingOverride {
						Set stagetime to Time:seconds+stagedelay.
						Set stagesep to false.
						if EngstagingOverride {
							set throt to 0.
						} else {
							set throt to 0.
							scrollprint(enginereadout(currentstagenum) + " Cut-Off").
						}
						Break.	
					}	
				}
			}
		}	
		
		// Booster or external tank staging (after specified delay)
		If Time:seconds >= booststagetime {
			Stage.
			FuelTank(OxidizerFuelName).
			Activeenginelist().
			Set numparts to Ship:parts:length.
			Set throt to TWRthrottle(maxAscentTWR).
			Set booststagetime to Time:seconds+100000.
			If mode = 0 {
				scrollprint("External Tank Jettison").
				For engine in Ship:partstaggedpattern("^CentralEngine") {
					Set engine:thrustlimit to 100.
				}
				for p in Ship:partstaggedpattern("^CentralEngine") {
					set p:tag to "".
				}
			} else {
				scrollprint("SRB Jettison").
				SRBDetect(ship:parts).
			}
			set staginginprogress to false.
			set SRBstagingOverride to false.
			rcs off.
		}
		
		// Full staging
		// Checks for ullage & gradually throttles up engines
		If Time:seconds >= stagetime {
			If stagesep = false {
				Stage.
				Ullagedetectfunc().
				Set numparts to Ship:parts:length.
				Set stagetime to Time:seconds.
				Set stagesep to true.
				Set currentstagenum to currentstagenum+1.
				scrollprint("Stage "+currentstagenum+" Seperation").
			}
			If UllageDetect = true {
				If ship:availablethrust > 0.01 {
					scrollprint("Ullage Motor Ignition").
				}
				If ship:availablethrust < 0.01 {
					Stage.
					Set numparts to Ship:parts:length.
					scrollprint("Ullage Motor Shutdown").
					Set stagetime to Time:seconds.
					Set Ullagedetect to false.					
				}
			} else {
				// This accomodates upper stage engines that 'deploy'
				If Ship:availablethrust < 0.01 and stagesep = true {
					Set stagetime to Time:seconds+0.01.
					Set throttledelay to throttledelay-0.01.
				}
				else If Ship:availablethrust >= 0.01 and ((Time:seconds-stagetime)-throttledelay) < 3 {
					if runmode = 2 {
						scrollprint("Stage "+currentstagenum+" Ignition").
						if apoapsis975 {
							set throt to (TWRthrottle(0.1)*((Time:seconds-stagetime)-throttledelay)/3).
						} else {
							set throt to (TWRthrottle(maxAscentTWR)*((Time:seconds-stagetime)-throttledelay)/3).
						}
					} else {
						set throt to 0.
					}
					if ((Time:seconds-stagetime)-throttledelay) > 0.75 {
						Set staginginprogress to false.
						Set EngstagingOverride to false.
						Set stagefinishtime to Time:seconds.
						rcs off.
						FuelTankUpper(OxidizerFuelName).
						Activeenginelist().
					}
				}
				// Caps throttle to maxAscentTWR, is reduced to 0.7 in upper atmopshere
				else If Ship:availablethrust >= 0.01 and ((Time:seconds-stagetime)-throttledelay) >= 3 {
					Set stagetime to Time:seconds+100000.
					if runmode = 2{
						if apoapsis975 {
							set throt to TWRthrottle(0.1).
						} else {						
							set throt to TWRthrottle(maxAscentTWR).
						}	
					} else {
						set throt to 0.
					}
				}
			}
		}
	}
	
	// Continuous abort detection logic - only checked for during ascent
	If runmode > 1 {
		// Angle to desired steering > 25 deg (i.e. steering control loss) during atmospheric ascent
		If runmode < 3 and Vang(Ship:facing:vector, steering:vector) > 25 and missiontime > 5 {
			Set runmode to -666.
			scrollprint("Loss of Ship Control").
		}
		// Abort if number of parts less than expected (i.e. ship breaking up)
		If Ship:parts:length <= (numparts-1) and Stage:ready {
			Set runmode to -666.
			scrollprint("Ship breaking apart").
		}
		// Abort if falling back toward surface (i.e. insufficient thrust)
		If runmode < 3 and verticalspeed < -1.0 {
			Set runmode to -666.
			scrollprint("Terminal Thrust").
		}
		// Abort due to insufficient electric charge
		If Resourcecheck("ElectricCharge",0.01) = false {
			Set runmode to -666.
			scrollprint("Insufficient Internal Power").
		}
	}
wait 0.001.
}

// Main loop end
unlock all.
sas on. rcs off.

// End of the program
If launchcomplete {
	If runmode = 6 {
		scrollprint("Program Completed").
		Remove cnode.
	}
	Print "                                              " at (0,0).
} 