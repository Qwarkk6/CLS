// CLS.ks - An auto-launch script that handles everything from pre-launch through ascent to a final circular orbit for any desired apoapsis and inclination.
// Copyright © 2021 Qwarkk6
// Lic. CC-BY-SA-4.0 

// Massive credit to /u/only_to_downvote / mileshatem for his launchtoCirc script on which CLS.ks is based.
// Some of his code remains in CLS.
// launchtoCirc can be found here:	https://github.com/mileshatem/launchToCirc

//			run CLS.									// Only required input, will use default launch parameters found below.
//		   (Desired orbit altitude,		 				// 3 options for entry:
														// 		any number in km (will presume a 2 stage rocket)
														//		0 - will launch a 2 stage rocket into the highest possible circular orbit
														//		1 - will launch a 3 stage rocket into the highest possible circular orbit
//       	desired orbit inclination,      			// in degrees (positive number = ascending launch azimuth, negative number = descending launch azimuth)
//			launch time or seconds until launch)		// Can either be "hh:mm:ss" of the specific launch time (including quotation marks) or number of seconds until launch (no quotation marks necessary). 
														// If inputted time is earlier than current time, it will presume a the launch will happen at that time the following day.

// Example:	run cls(250,28,60).							// Will launch into a 250km circular orbit with an inclination of 28 degrees. Liftoff will occur in 60 seconds time.
// Example:	run cls(90,58,"02:36:48").					// Will launch into a 90km circular orbit with an inclination of 58 degrees. Liftoff will occur at 02:36:48.

// Required staging / vehicle set-up:
//   - Initial launch engines must be placed into stage 1.
//   - SRBs (if present) must be placed into stage 2.
//	 - Launch clamps must be placed into stage 3 (if the rocket has SRBs) or stage 2 (if the rocket has no SRBs).
//   - Without ullage motors: stage seperation and next stage ignition must be grouped into one stage.
//	 - With ullage motors that pull jettisoned stage away from the next stage: stage seperation, ullage ignition and next stage ignition must be grouped into one stage.
//	 - With ullage motors that push the next stage away from jettisoned stage: stage seperation and ullage ignition must be grouped into one stage, with next stage ignition in the following stage.
//	 - In a 3 booster config (i.e Falcon Heavy or Delta Heavy), all engines on the central booster should be tagged "CentralEngine". This allows them to be individually throttled down during ascent.
//	 - Will not work with SSTOs. Could be modified to do so though.
//	 - Uses RCS during stage seperation so upper stage(s) should have RCS fuel/thrusterss. Not a hard requirement though.
//	 - Lifoff thrust to weight ratio (TWR) must be above 1.2 (this number can be configured in TWR configuration) but should be 1.6 for efficiency

// Action groups:
//   - Place any fairing or LES jettison into action group 10. Will jettison based on atmopshere pressure (usually at 60km altitude mark).
//   - Abort action group will be automatically triggered if conditions defined under runmode 666 are met.

// Notes:
//	 - This script has no dependant mods, however the script checks for parts from the Procedural Fairing mod and can be configured below for non-stock fuels.
//   - Variable identifiers which are no longer needed or have not been defined yet are set to "-".
//	 - Can detect SRBs with thrust curves and will:		a) decouple them when they reach a low trust percentage		b) throttle main engine up to cover thrust losses due to throttle curve
//	 - This script uses the fuel remaining in tanks to calculate time to staging / deltaV. It measures oxidizer as both Cryogenic and LiquidFuel engines require oxidizer.
//	 - If the script progresses far enough to activate any stages, but then the script is terminated (either manually or due to anomaly detection) you will need to 'revert to launchpad' before using the script again in order to reset the stages.
//	 - The script will throttle engines to achieve a liftoff TWR of 1.4 (this number can be configured in TWR configuration).

//////////////////////////////////////////////////////////////////////
//////////////////////////USER CONFIGURATION//////////////////////////
//////////////////////////////////////////////////////////////////////
	
// Default launch parameters (changed with terminal input above)
// This launches vehicle to a 200,000m circular orbit along the equator
Parameter targetapoapsis is 200.
Parameter targetinclination is ship:orbit:inclination. 
Parameter SecondsUntilLaunch is 23.			//Script initialises for 3 seconds, then performs essential pre-launch checks during a 20 seconds countdown. Value must be greater than 20.

// Fuel configuration
// Change these to configure non-stock fuels. Do not remove CryoFuelName (Even if you are using stock fuels).
// If you do change them, make sure to change the corresponding fuel mass (you may have to dig in resource config files)
Set OxidizerFuelName to "Oxidizer".
Set LiquidFuelName to "LiquidFuel".
Set CryoFuelName to "LqdHydrogen".
Set SolidFuelName to "SolidFuel".
Set OxidizerFuelMass to 0.005.
Set LiquidFuelMass to 0.005.
Set CryoFuelMass to 0.00007085.

// TWR configuration
Set minLiftoffTWR to 1.2.			// Minimum liftoff TWR. Launch will abort just before liftoff if the vehicle attempts to launch with anything lower.
Set LiftoffTWR to 1.6.				// Liftoff TWR. Engines will be throttled to achieve this TWR at liftoff (if there is sufficient thrust). There are deltaV savings to be had with a higher TWR, 1.6 was best for a 'one size fits all' approach
Set maxAscentTWR to 3.5.			// Maximum TWR during ascent. The rocket will throttle down to maintain this when it is reached. There are deltaV savings to be had with a higher TWR, but be careful of vehicle heating.
Set UpperAscentTWR to 0.7.			// When time to apoapsis is above 90 seconds, the engines will throttle to maintain this TWR.

// Staging delays
Set stagedelay to 0.5. 					// Delay after engine shutdown or previous staging before staging will occur. Must be >= 1
Set throttledelay to 1.5. 				// Delay after stage seperation before engine throttles up

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
Set dpitch to Pidloop(0,0,0.1,-1,1).		// D loop for calculating pitch to account for falling eta:apospsis

// Script Library
// Important to change the paths below if you choose to reorganise how CLS is organised
runpath("0:/cls_lib/CLS_dv.ks"). 
runpath("0:/cls_lib/CLS_gen.ks").
runpath("0:/cls_lib/CLS_hud.ks").
runpath("0:/cls_lib/CLS_nav.ks").
runpath("0:/cls_lib/CLS_res.ks").
runpath("0:/cls_lib/CLS_twr.ks").
runpath("0:/cls_lib/CLS_ves.ks").
runpath("0:/cls_lib/lib_lazcalc.ks").
runpath("0:/cls_lib/lib_navball.ks").
runpath("0:/cls_lib/lib_num_to_formatted_str.ks").

// One-time variables
If Ship:name:length > 16 { Set Ship:name to "Vehicle". }	// Ensures vehicle name fits on terminal width
Set MaxStages to 2.											// Number of stages the rocket has. Presumes 2. Can be changed with terminal input. 
Set InputAbort to false.									// Variable used later to detect if user input is incorrect (i.e user sets orbit alitude below atmosphere altitude)
Set logtimeincrement to 60.									// Increment between mission log updates
Set launchloc to Ship:geoposition.							// Used to calculate downrage distance for log readouts
Set launchalt to altitude.									// Used to calculate altitude for log readouts
Set maxlinestoprint to 34. 									// Max number of lines in scrolling print list
Set listlinestart to 6.										// First line For scrolling print list
Set SecondsUntilLaunch to SecToLaunch(SecondsUntilLaunch).	// Checks input for SecondsUntilLaunch parameter and recalculates if necessary

// Target orbit configuration based on terminal input
If targetapoapsis = 0 {
	set targetapoapsis to 84000.					// Will result in a target apoapsis of 84,000,000 - the edge of Kerbin's SOI
} else if targetapoapsis = 1 {
	set targetapoapsis to 84000.					// Will result in a target apoapsis of 84,000,000 - the edge of Kerbin's SOI
	set MaxStages to 3.								// Number of stages the rocket has
} else {
	set targetapoapsis to targetapoapsis*1000.		// Default - converts targetapoapsis from km to m
}

// Calculates launch azimuth
Set launchazimuth to LaunchAzm(targetapoapsis,targetinclination,"Ascent").

// List creation
Set printlist to List(). Set printlisthistory to List(). printlisthistory:add("*").															// Scrolling print function
Set elist to list(). Set aelist to list().																									// Engine list function
Set SRBlist to list(). Set SRBs to List().																									// SRB list function
Set MFT to list(). MFT:add(List()). MFT:add(List()). MFT:add(List()). Set stagetanks to list().	 Set usrl to list().						// Fuel resource function
Set UllageScan to list(). set nseList to list().																							// Ullage detection fucntion
set cdlist to list(list(20,19,17,15,13,11,9,8,7,6,3),list("Startup","$","$","$","$","$","$","All Systems Go For Launch","$","$","$")).		// A ridiculous system of reducing the countdown code

// Loop variables 
set throt to 0. Lock throttle to throt.											
set trajectorypitch to 90.														// Ensures rocket will initially go vertical.
set steerto to heading(launchazimuth,trajectorypitch).	 
set launchroll to rollLock(roll_for(ship)) - steerto:roll.						// Rocket will launch so that its 'roll orientation' remains the same from launch to orbit.
set vessEast to compass_for_vect(ship,east_for(ship)).							// Finds East and makes sure whichever side of the vehicle starts facing east will be the 'bottom' side during ascent
set steerto to heading(launchazimuth,trajectorypitch,launchroll).
Lock steering to Steerto.
Set launchtime to Time:seconds + SecondsUntilLaunch.							// Script takes 23 seconds between initialisation and launch
Set logtime to 60.																// Calculates time for first log readout
Set cdownreadout to 0.															// Countdown function
Set tminus to 20.																// Countdown timer
Set mode to "-".																// Mode 0 = no SRBs present. Mode 1 = SRBs present. Set during pre-launch checks.
Set currentstagenum to 1.														// Tracks current stage number
Set ImpendingStaging to false.													// Boolean. True when rocket is about to stage
Set staginginprogress to false.													// Boolean. True during staging
Set launchcomplete to false.													// Terminates script on completion
Set runmode to -1.																// Tracks ascent phase
Set numparts to Ship:parts:length.												// Tracks the number of parts. If this decreases unexpectedly, the script assumes a RUD and triggers an abort.
Set booststagetime to Time:seconds+100000.										// Tracks staging start time of SRBs / boosters. Set to high number while unused
Set booststagetime2 to Time:seconds+100000.										// Tracks staging end time of SRBs / boosters. Set to high number while unused
Set stagesep to false.															// Tracks whether staging has succesfully occured
Set stagetime to Time:seconds+100000.											// Tracks staging start time. Set to high number while unused
Set stagefinishtime to Time:seconds+100000.										// Tracks staging end time. Set to high number while unused
Set SRBtime to 0.																// Tracks impending SRB burn out
Set throttletime to 0.															// Tracks time of engine throttling
Set PayloadProtection to false.													// Tracks whether the vehicle has fairings or a LES. Set during pre-launch checks.
Set PayloadProtectionConfig to "-".												// Detects which is being used (fairing or LES). Set during pre-launch checks.
Set CentralEngines to false.													// Detects if the vehicles has 'Central Engines' and is therefore a 3 booster design. See Required staging set-up above.
Set CentralEnginesThrottle to false.											// Tracks central booster throttling for 3 booster lifter configurations
Set ullageignition to false.													// Detects whether lifter used ullage motors during staging
Set SRBstagingOverride to false.												// Overrides staging detection and forces staging when SRB thrust curve is < 0.4.
Set EngstagingOverride to false.												// Overrides staging detection for engines.
set nodecheck to false.															// Detects whether the circularisation manuever node has been 'checked' in case apoapsis has fallen due to aerobraking as the vehicle exits the atmosphere.
set apoapsis95 to false.														// Detects when vehicle's apoapsis is within 5% of the target apoapsis 
set broke90 to false.															// Detects when the vehicle's time to apoapsis passes over 90 seconds															
set Stagingthrottle to false.													// Used to throttle main engines down when approaching stage seperation
set StagingSteerHold to false.													// Used with RCS to keep vehicle's orientation during staging
set steerhold to false.															// SteeringHold function. Boolean. True when stage remains settled for a duration of time during staging.
Set tuning to "Ascent".															// LaunchAzm function. Detects when target inclination is achieved and locks azimuth to prograde. 

// Bad input checks terminate script
If InputAbort = false {
	If targetapoapsis < body:atm:height {			// Target orbit must be above atmosphere
		Print "Input Error" at (0,2).
		Print "Target Orbit (" + targetapoapsis/1000 + "km) below atmosphere altitude (" + body:atm:height/1000 + "km)" at (0,3).
		Set InputAbort to true.
	}
	If ABS(targetinclination) < Floor(ABS(latitude)) or ABS(targetinclination) > (180 - Ceiling(ABS(latitude))) {	// Inclination can't be less than launch latitude or greater than 180 - launch latitude
		Print "Input Error" at (0,2).
		Print "Target Inclination (" + targetinclination + "°) Impossible." at (0,3).
		Set InputAbort to true.
	}
	HUDinit(launchtime,targetapoapsis,targetinclination).						// Initiates the HUD information at the top of the terminal.
}

// Main loop begin
Until launchcomplete or InputAbort {

	// Initiate looping functions
	Eventlog().							// Initiates mission log readouts in the body of the terminal
	AscentHUD().						// Initiates the HUD information at the bottom of the terminal.
	If warp > 0 Warpcontrol().			// Activates warp control function anytime warp speed is manually adjusted

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
			Modedetect().														// Function for detecting SRBs
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
			If PartlistFuelCapacity(stagetanks,OxidizerFuelName) > 0 {
				Set MFTCap to PartlistFuelCapacity(stagetanks,OxidizerFuelName).
			} else {
				Set MFTCap to 0.
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
		
		// Ignition of main engines
		If cdown >= -5 and tminus = 5 {
			stage.
			scrollprint("Ignition").
			set throt to 0.01.
			Set tminus to tminus-1.
		}
		
		// Handles calculations for main engine throttle up during countdown
		If cdown >= -4 and tminus = 4 {
			Set throttletime to Time:seconds.
			Set launchThrot to TWRthrottle(LiftoffTWR).
			Lock throt to launchThrot*(Time:seconds-throttletime)/3.
			Set tminus to tminus-1.
			scrollprint("Terminal Count").
		}
		
		// Checks engines are producing thrust. Terminates script if they arent.
		If cdown >= -2 and tminus = 2 {
			if ship:availablethrust > 0.1 {
				Activeenginelist().
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
				set throt to launchThrot.
				scrollprint("$").
			} else {
				stage.
				scrollprint("SRB Ignition").
			}
			Set tminus to tminus-1.
		}
		
		// Checks vehicle TWR. Will terminate script if its below the threshold configured in TWR configuration. If TWR is ok, the vehicle will liftoff at the TWR configured in TWR configuration (if it has enough thrust).
		If cdown >= 0 and tminus = 0 {
			If TWR() < minLiftoffTWR {
				set throt to 0.
				scrollprint("Launch Aborted").
				scrollprint("Insufficient Thrust").
				Set launchcomplete to true.
			} else {
				Stage.
				Set numparts to Ship:parts:length.
				scrollprint("Liftoff").
				If mode = 1	{
					set throt to SRBtwrthrottle(LiftoffTWR).
					set launchtwr to twrsrb().					// Records the actual TWR the vehicle achieved at liftoff. Used to calculate the gravity turn later.		
					Set launchThrot to throt.					// Records the throttle needed to achieve the launch TWR. Used to throttle engines during ascent.
				} else {
					set launchtwr to twr().						// Records the actual TWR the vehicle achieved at liftoff. Used to calculate the gravity turn later.
				}
				Set runmode to 0.
			}
		}
	}

	// Countdown hold for minor issues
	// Holds the countdown and gives you the choice to scrub (press N) or continue (press A) the launch.
	if runmode = -2 {
		Set ContinueYN to false.
		scrollprint("Hold Hold Hold").
		scrollprint(scrubreason).
		scrollprint("Continue?").
		scrollprint("[A] to Continue Countdown").
		scrollprint("[N] to Scrub Launch").
		
		until ContinueYN = true {
			If ship:control:pilotyaw = -1 {						// Detects pilot steering input - aka pressing A or N.
				set ContinueYN to true.
				set runmode to -1.
				set launchtime to time:seconds + tminus.
				Print "Target Launch Time: NET " + T_O_D(launchtime) at (0,1).
			} else if ship:control:pilotfore = -1 {				// Detects pilot steering input - aka pressing A or N.
				set ContinueYN to true.
				scrollprint("Launch Scrubbed").
				set launchcomplete to true.
			}
		}
	}
	
	// Countdown hold and Launch sequence recycle for major issues
	// Holds the countdown and gives you the choice to scrub (press N) or restart (press A) the launch sequence.
	If runmode = -3 {
		printlisthistory:clear.
		Set ContinueYN to false.
		scrollprint("Hold Hold Hold").
		scrollprint(scrubreason).
		scrollprint("Recycle Launch Sequence?").
		scrollprint("[A] to Recycle Countdown").
		scrollprint("[N] to Scrub Launch").
		
		until ContinueYN = true {
			If ship:control:pilotyaw = -1 {					// Detects pilot steering input - aka pressing A or N.
				set ContinueYN to true.
				set runmode to -1.
				Set tminus to 20.
				Set cdownreadout to 0.
				set launchtime to time:seconds + 23.
				Print "Target Launch Time: NET " + T_O_D(launchtime) at (0,1).
			} else if ship:control:pilotfore = -1 {			// Detects pilot steering input - aka pressing A or N.
				set ContinueYN to true.
				scrollprint("Launch Scrubbed").
				set launchcomplete to true.
			}
		}
	}
	
	// Initial ascent. Calculates when to start the gravity turn. Lower TWR vehicles start later.
	If runmode = 0 {
	
		If launchtwr >= (LiftoffTWR-0.01) {
			if ship:verticalspeed >= 70 {
				Set turnstart to ship:altitude.			// Records altitude at which gravity turn starts. Used to calculate gravity turn progress later on.
				Set runmode to 1.
			}
		} else {
			if ship:verticalspeed > 70+((LiftoffTWR-launchtwr)/0.2*30) {
				Set turnstart to ship:altitude.			// Records altitude at which gravity turn starts. Used to calculate gravity turn progress later on.
				Set runmode to 1.
			}
		}
		If mode = 1 {
			set throt to launchThrot + ((partlistavthrust(SRBs)-partlistcurthrust(SRBs))/partlistavthrust(aelist)).			// Throttles engines to compensate for SRB thrust curve
		}
	}
	
	// One-time actions 
	If runmode = 1 {	
		
		If launchtwr < (LiftoffTWR-0.01) {
			Set turnend to (LiftoffTWR-launchtwr)*0.165*Ship:body:atm:height+(Ship:body:atm:height*0.525).		// Lower TWR vehicles finish the gravity turn higher.
		} else {
			Set turnend to Ship:body:atm:height*0.525.
		}
		
		// Gravity turn calculations.
		Set turnexponent to 0.575.
		Set halfPitchAlt to turnend*0.4.
		Activeenginelist().
		set launchroll to launchroll + (launchazimuth - vessEast).
	
		scrollprint("Starting Ascent Trajectory:").
		scrollprint("          Turn End Alt. = "+Round(turnend)).
		scrollprint("          Turn Exponent = "+Round(turnexponent,3)).
		Set runmode to 2.
	}

	// Ascent trajectory program until reach desired apoapsis	
	If runmode = 2 {	

		Set AscentAlt to ship:altitude-turnstart.
		
		// Calculates launch azimuth
		If ship:orbit:inclination > ABS(targetinclination)-0.05 and ship:orbit:inclination < ABS(targetinclination)+0.05 {
			if staginginprogress = false and ImpendingStaging = false {
				Set tuning to "Fine".
			}
		} else if tuning = "Fine" and ship:orbit:inclination > ABS(targetinclination)+0.1 and ship:orbit:inclination < ABS(targetinclination)-0.1 {
			Set tuning to "Ascent".
		}
		Set launchazimuth to LaunchAzm(targetapoapsis,targetinclination,tuning).
		
		
		// Ship pitch control
		// Pitches gradually to reach 45 degrees at the altitude set by halfPitchAlt. Then pitches to 5 degrees until time to apoapsis is above 90. Then pitches to 0 degrees.
		If AscentAlt < halfPitchAlt {
			Set trajectorypitch to max(min(max(90-((AscentAlt/halfPitchAlt)^turnexponent*45),45),pitch_for_vect(Ship,Ship:srfprograde:forevector)+5),pitch_for_vect(Ship,Ship:srfprograde:forevector)-5).
		} else if AscentAlt < turnend or currentstagenum = 1 {
			Set trajectorypitch to max(45-((AscentAlt-halfPitchAlt)/(turnend-halfPitchAlt)*40),pitchlimit(1,targetapoapsis,eta:apoapsis)).
		} else {
			if staginginprogress or ImpendingStaging {
				set trajectorypitch to 0.
			} else {
				set dpitch:setpoint to eta:apoapsis.
				set trajectorypitch to max(0,min(trajectorypitch+dpitch:update(missiontime,eta:apoapsis),pitchlimit(2,targetapoapsis,eta:apoapsis))).
			}
		}
		
		// Staging Pitch control
		// During staging the vehicle will pitch towards surface prograde (but not fully to surface prograde) to reduce the affect of aero forces 
		If staginginprogress or ImpendingStaging {
			RCS on.
			if body:atm:altitudepressure(ship:altitude) <= 0.004 {
				set trajectorypitch to (trajectorypitch + (pitch_for_vect(ship,Ship:srfprograde:forevector) - trajectorypitch)/3).
			} else if body:atm:altitudepressure(ship:altitude) <= 0.0009 {
				set trajectorypitch to (trajectorypitch + (pitch_for_vect(ship,Ship:srfprograde:forevector) - trajectorypitch)/6).
			} else {
				set trajectorypitch to pitch_for_vect(ship,Ship:srfprograde:forevector).
			}
		} else {
			RCS off.
		}
		
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
				
				// Gradual throttle down when approaching burnout
				If RemainingBurn(PartlistFuelCapacity(stagetanks,OxidizerFuelName)+PartlistFuelCapacity(stagetanks,CryoFuelName)+PartlistFuelCapacity(stagetanks,LiquidFuelName)) < 5 and Stagingthrottle = false {
					NextStageEngineList().
					for e in nseList {
						if e:allowshutdown and e:allowrestart and not e:throttlelock {
							Set Stagingthrottle to true.
							Set throttletime to Time:seconds.
							Set currentthrottle to throttle.
						}
					}
				}
				If Stagingthrottle {
					If Time:seconds - throttletime < 6 {
						set throt to ((TWRthrottle(1.5) - currentthrottle)*((Time:seconds-throttletime)/6)+currentthrottle).
					}
				}
				
			} else {
			
				// Throttle up of main engine to account for SRB thrust curve
				If TWRSRB() < maxAscentTWR and SRBtime = 0 {	
					set throt to launchThrot + ((partlistavthrust(SRBs)-partlistcurthrust(SRBs))/partlistavthrust(aelist)).
				}
				
				// Throttle down of main engines so that TWR will not go above threshold set by maxAscentTWR during ascent
				If TWRSRB() > maxAscentTWR and SRBtime = 0 {
					set throt to SRBtwrthrottle(maxAscentTWR).
					scrollprint("Maintaining TWR").
				}
				
				// Detection of SRB going below 20% rated thrust. Tells vehicle to stage.
				If partlistcurthrust(SRBs)/partlistavthrust(SRBs)<0.2 {
					Set SRBstagingOverride to true.
				}
			
				// Detection of impending SRB flameout
				If Partlistfuelpercent(SRBs,SolidFuelName,0) < 3 and not SRBstagingOverride {
					Set ImpendingStaging to true.
					if SRBtime = 0 {
						set SRBtime to time:seconds.
						set launchThrot to throt.
					}
					if time:seconds-SRBtime < 2 {
						set throt to launchThrot + ((srbsepthrottle(maxAscentTWR)-launchThrot)*(time:seconds-SRBtime)/2).
					}
				} 
			}
		}
		
		// Ascent TWR control For second stage
		// Checks whether it has been 5 seconds since staging and time to apoapsis is above 90 seconds before gradually throttling to TWR set by UpperAscentTWR
		If currentstagenum > 1 and staginginprogress = false {
			If Eta:apoapsis > 90 and broke90 = false and (Time:seconds - stagefinishtime) >= 5 {
				Set broke90 to true.
				Set throttletime to Time:seconds.
				Set currentthrottle to throttle.
			}
			If apoapsis >= (targetapoapsis*0.95) and apoapsis95 = false {
				Set apoapsis95 to true.
				Set throttletime to Time:seconds.
				Set currentthrottle to throttle.
			}
			If broke90 = true and (Time:seconds - stagefinishtime) >= 5 {
				If apoapsis95 = false {
					If TWR() > UpperAscentTWR {
						If Time:seconds - throttletime < 5 {
							set throt to ((TWRthrottle(UpperAscentTWR) - currentthrottle)*((Time:seconds-throttletime)/5)+currentthrottle).
						}
						scrollprint("Throttling Down").
					}
					If Time:seconds - throttletime > 5 {
						set throt to TWRthrottle(UpperAscentTWR).
					}
				} else {
					If warp > 0 Set warp to 0.
					If TWR() > 0.1 {							// Throttles down to 0.1 TWR when <5% away from target apoapsis to ensure accuracy of parking orbit
						If Time:seconds - throttletime < 2 {
							set throt to ((TWRthrottle(0.1) - currentthrottle)*((Time:seconds-throttletime)/2)+currentthrottle).
						}
						scrollprint("Throttling Down").
					}
					If Time:seconds - throttletime > 2 {
						set throt to TWRthrottle(0.1).
					}
				}
			}
			// If time to apoapsis drops below 45 seconds after engines have throttled down, this will throttle them back up
			If broke90 = true and Eta:apoapsis < 45 {
				Set broke90 to false.
				set throt to 1.
			}
		}
		
		// Detects imminent fuel depletion of current main fuel tank
		If Partlistfuelpercent(stagetanks,OxidizerFuelName,MFTCap) < 4 {
			Set ImpendingStaging to true.
		} else {
			Set ImpendingStaging to false.
		}
		
		// If the vehicle reaches its target apoapsis without staging, this forces it to stage so that upper stages handle circularisation
		if ship:apoapsis >= (targetapoapsis*0.998) {
			if currentstagenum < MaxStages {
				Set EngstagingOverride to true.
			}
			Set runmode to 3.
		}
		
		// This detects if the vehicle wont have enough deltaV to circularise if it raises its apoapsis any further. Cuts the burn short and will circularise at current apoapsis.
		if ship:apoapsis > body:atm:height*1.05 and currentstagenum = MaxStages and (Time:seconds - stagefinishtime) >= 5 {
			if CircDV() >= (StageDV(currentstagenum)*0.975) {
				scrollprint("Insufficient dV detected").
				Set runmode to 3.
			}
		}
	}
	
	// Manuever Node creation for circularisation burn	
	If runmode = 3 {
		
		//Manuever node creation for cicular orbit
		if hasnode = false {
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
		if time:seconds < burnStartTime {
			set throt to 0.
			if CircDV() >= (StageDV(currentstagenum)*0.95) {
				scrollprint("          " + enginereadout() + " Cut-Off ").
			} else {
				scrollprint(enginereadout() + " Cut-Off ").
			}
			scrollprint("          Parking Orbit Confirmed").
			scrollprint("          Entering Coast Phase").
			set runmode to 4.
		} else {
			set runmode to 5.
		}
	}
	
	// Coast phase
	If runmode = 4 {
		set steerto to Ship:prograde:forevector.
		if nodecheck = false and ship:altitude > Ship:body:atm:height {			// This removes and recreates the manuever node when the vehicle passes the karman line, as aero forces will have affected the apoapsis / time to apoapsis
			remove cnode.
			set runmode to 3.
		}
		if time:seconds >= burnStartTime-90 {			// Will take the vehicle out of warp (and prevent further warping) 90 seconds before the circularisation burn is due to start
			set warp to 0.
			set steerto to cnode:burnvector.
			rcs on.
			scrollprint("Preparing for Circularisation Burn").
			scrollprint("          Delta-v requirement: " + ceiling(cnode:deltav:mag,2) + "m/s").
			scrollprint("          Burn time: " + d_mt(burntime)).
			set runmode to 5.
		}
	}
	
	// Circularisation burn
	if runmode = 5 {
		if time:seconds >= burnStartTime and burnstart = false {
			if throt = 0 {
				scrollprint("Stage "+currentstagenum+" Re-ignition").
			}
			set throt to 1.
			set burnstart to true.
		} 
		
		// Handles throttle and burn end
		if burnstart = true {
			set max_acc to ship:availablethrust/ship:mass.			// continuous calculation of max acceleration as it changes as fuel is burned
			set throt to min(cnode:deltav:mag/max_acc,1).			// This will throttle the engine down when there is less than 1 second remaining in the burn
			
			// Detects when cnode:deltav and initial deltav start facing opposite directions, showing the burn is finished
			if vdot(dv0,cnode:deltav) < 0 {
				set throt to 0.
				set steerto to Ship:prograde:forevector.
				scrollprint(enginereadout() + " Cut-Off  ").
				scrollprint("          Orbit Cicularised").
				Set runmode to 6.
			}
			
			// When remaining deltaV is low, detects when node vector drifts significantly, showing the burn is finished
			if cnode:deltav:mag < 0.1 {
				if vdot(dv0,cnode:deltav) < 0.5 {
					set throt to 0.
					set steerto to Ship:prograde:forevector.
					scrollprint(enginereadout() + " Cut-Off  ").
					scrollprint("          Orbit Cicularised").
					Set runmode to 6.
				}
			}
		}
	}
	
	// Triggers program end
	If runmode = 6 {
		wait 10.
		Set launchcomplete to true.
	}

	// Perform abort if conditions defined in Continuous abort detection logic (below) are met and terminates script
	If runmode = -666 {
		set throt to 0.
		Set Ship:control:neutralize to true. 
		sas on.
		Toggle abort.
		scrollprint("Launch Aborted").
		Hudtext("Launch Aborted!",5,2,100,red,false).
		Set launchcomplete to true.
	}
	
// Fairing seperation
	If PayloadProtection = true {	
		
		// If the fairings need to be jettisoned before stage deperation (eg Atlas V 5m configuration)  then the fairings will jettison as soon as staging is imminent
		If ((Stage:number - fairingstage)=1) and runmode = 2 {
			If  ImpendingStaging {
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
					Wait 0.01.
					
					// If flameout is due to a booster shutdown only
					If ship:availablethrust >= 0.1 and not EngstagingOverride {
						Set booststagetime to Time:seconds+stagedelay.
						Set booststagetime2 to Time:seconds+stagedelay+1.
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
							scrollprint(enginereadout() + " Override").
						} else {
							set throt to 0.01.
							scrollprint(enginereadout() + " Cut-Off").
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
			Set MFTCap to 0.
			Activeenginelist().
			Set numparts to Ship:parts:length.
			Set throt to TWRthrottle(maxAscentTWR).
			Set booststagetime to Time:seconds+100000.
			If mode = 0 {
				scrollprint("External Tank Jettison").
				For engine in Ship:partstaggedpattern("^CentralEngine") {
					Set engine:thrustlimit to 100.
				}
			} else {
				scrollprint("SRB Jettison").
				Modedetect().
			}
		}
		
		If Time:Seconds >= booststagetime2 {
			Set staginginprogress to false.
			set SRBstagingOverride to false.
			Set booststagetime2 to Time:seconds+100000.
		}
		
		// Full staging
		// Checks for ullage & gradually throttles up engines
		If Time:seconds >= stagetime {
		
			// Will stage after vehicle remains settled for 1.5 seconds
			if SteeringHold(1.5) {
				set steerhold to true.
			}
	
			If steerhold {
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
					If runmode = 2 {
					
						// This accomodates upper stage engines that 'deploy'
						If Ship:availablethrust < 0.01 and stagesep = true {
							Set stagetime to Time:seconds+0.01.
							Set throttledelay to throttledelay-0.01.
						}
						else If Ship:availablethrust >= 0.01 and ((Time:seconds-stagetime)-throttledelay) < 3 {
							scrollprint("Stage "+currentstagenum+" Ignition").
							set throt to (1*((Time:seconds-stagetime)-throttledelay)/3).
							if ((Time:seconds-stagetime)-throttledelay) > 0.75 {
								Set staginginprogress to false.
								Set EngstagingOverride to false.
								Set stagefinishtime to Time:seconds.
							}
						}
						else If Ship:availablethrust >= 0.01 and ((Time:seconds-stagetime)-throttledelay) >= 3 {
							Set stagetime to Time:seconds+100000.
							set throt to 1.
						}
					} else {
						Set staginginprogress to false.
						Set EngstagingOverride to false.
						Set stagefinishtime to Time:seconds.
					}
					FuelTankUpper(OxidizerFuelName).
					Set MFTCap to PartlistFuelCapacity(stagetanks,OxidizerFuelName).
					Activeenginelist().
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
sas on.

// End of the program
If launchcomplete {
	If runmode = 6 {
		scrollprint("Program Completed").
		Remove cnode.
	}
	Print "                                              " at (0,0).
} 
