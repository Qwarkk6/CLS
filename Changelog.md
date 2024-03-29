Changelog
==========================

<b>v2.0 (14/03/24)</b>

Key Points
- Remove callouts for downrange & altitude due to high hardware strain
- New staging pitch control to avoid sudden pitch inputs before, during and after staging
- Pre-flight input box now allows you to specify the chance of a random failure on ascent if enabled, and define longitude of Ascending Node for precise launches
- Ships with SRBs will now lift off at a TWR of 1.8 (previously used 1.4, but this required unrealistic & aggressive throttling of Main engines)
- Script now ignores children parts of attached SRBs during staging checks, which was throwing a warning if SRBs had parts attached (Thanks u/StreitLeak)
- Initial countdown now happens on a single HUD line to conserve space and limit use of scrollprint due to its hardware strain
- New compatibility with the TAC Self Destruct Continued Mod - add a whole ship destruction part to the ship and the Flight Termination System will deploy if a mid-flight abort occurs - no need to add them to the abort AG
- New compatibility with the Hullcam VDS Continued mod to add a cinematic element to your launches!
- The script will auto switch to Hullcam VDS cameras at various points. Cameras for launch need to be tagged "CameraLaunch". Cameras for Stage sep need to be tagged "CameraSep". Cameras for onboard views need tagged "Camera1" or "camera2" with the number associated with their stage.
- CLS now checks that a crewed pod has chutes attached in case of an abort scenario and will hold the launch if no chutes are detected.
- If the user decides to continue with a countdown for a crewed vessel after CLS identifies issues with the abort AG or no chutes are detected, the random launch failure feature is automatically deactived, to avoid the script throwing an error later down the line if an abort occurs.

Main CLS Script
- Complete rewrite to make code cleaner and more efficient
- Move away from looping system to functions for each phase of flight
- New system of scrubbing a launch on the pad which intentionally powers down the kOS terminal rather than finishing the script. This is an unfortunate side effect of moving away from the loop system but is necessary for the significant gains in script efficiency. 
- Tweak of time delays around staging for reliability
- Warp limit now handled in main script rather than external function
- depreciation of multiple variables no longer required
- huge reduction of script activity during coast phase 
- CLS now checks that a crewed pod has chutes attached in case of an abort scenario and will hold the launch if no chutes are detected.
- If the user decides to continue with a countdown for a crewed vessel after CLS identifies issues with the abort AG or no chutes are detected, the random launch failure feature is automatically deactived, to avoid the script throwing an error later down the line if an abort occurs.

Abort Script
- Makes use of centralised engList to avoid unnecessary calls to list active engines
- Simplifies detection of LES using solid fuels
- Switches to new resource tracking method from a general library
- Switches to new fuel cell control method from a general library
- New HUD readouts
- Moves away from hardware-heavy string formatting printout method

Chute Descent Script
- Switches to new resource tracking method from a general library
- Switches to new fuel cell control method from a general library
- Moves away from hardware-heavy string formatting printout method
- New variable naming system
- More reliable system of cutting drogue parachutes if multiple are deployed
- Rewrite of functions in Chute Descent Library

CLS_lib/CLS_dv
- Clean up of all circularation burn calculations
- stageDV function now provides Burn Remaining & dVRemaining variables called throughout rest of code, rather than stand alone functions for both
- nodeBurnData replaces burnTime & burnStart functions, storing all info in a list

CLS_lib/CLS_gen
- Time warp is now controlled within the main script
- added Camera control function which will add a cinematic element to your launches!

CLS_lib/CLS_hud
- Now functions to handle printouts for countdown
- Remove callouts for downrange & altitude due to high hardware strain
- rewrite of HUD code to significantly reduce hardware strain

CLS_lib/CLS_log
- Now logs during countdown
- Now logs time

CLS_lib/CLS_nav
- pitch program has been tweaked for reliability
- inclination control has been tweaked for reliability
- New staging pitch control to avoid sudden pitch inputs before, during and after staging

CLS_lib/CLS_parameters
- Change of "Contract" to "LAN" allowing to control launch to meet defined longitude of Ascending Node
- Now allows you to specify the chance of a random failure on ascent if enabled

CLS_lib/CLS_res
- Move away from fuel mass calculations

CLS_lib/CLS_twr
- cleaner calculations across multiple functions
- Ships with SRBs will now lift off at a TWR of 1.8 (previously used 1.4, but this required unrealistic & aggressive throttling of Main engines)

CLS_lib/CLS_ves
- cleaner code for pre-flight checks
- Script now ignores children parts of attached SRBs during staging checks, which was throwing a warning if SRBs had parts attached (Thanks u/StreitLeak)
- Simplified launch clamp check
- Move of fuel cell control to general library
- Low power mode now toggles rather than individual functions to turn on & off
- New system to detect if attached SRBs will sage at different times

New GeneralLibrary
- I have moved to try and use shared libraries where possible, so now functions in this folder are used by the abort, chute descent and main script
- Resources has multiple default functions to calculate resource capacity & name as well as how much is remaining and determine which resources are being actively used
- Fuel cells has multiple functions to detect, use and provide hud readouts for fuel cells
<br><br>

<b>v1.5.1 (24/02/22)</b>

Happy KSP2 release day!

This will be the final release made for CLS supporting KSP 1. I do not know the future of kOS in KSP 2 but will hopefully get the chance to continue developing this script for the new game.

kOS v1.4 made some script breaking changes, and this update fixes the following:

 - 'Clobbered builtins' issue raised by u/MaxHeadroom68 - around 15 variables have been renamed
 - Specifying a launch time now works as expected.
 
Please note, I have given this update very limited play testing. I hope I have caught all the variables requiring a rename.
<br><br>

<b>v1.5.0 (27/01/22)</b>

- Ship will now throttle down as its apoapsis  approaches the target to ensure better orbit accuracy. Note: there are conditions under which this will not happen.
- Altered the way CLS detects thrust curves for SRBs. The old method was more accurate but the performance hit was huge. The new method is less accurate but much more compatible and performs much faster.
- Moved to my own method of fine tuning inclination. The old method was math heavy, difficult to tweak and there was a specific condition under which it would mistakenly force a launch abort. As a result <b>lib_instaz.ks is now obsolete and should be deleted.</b>
- The new method of tweaking inclination is way more simple and compares inclination with target inclination to adjust the heading accordingly.
- SRBs will now jettison when thrust curves dip below 15% instead of 25%.
- The HUD readout for throttling down the upper stage now doesn't occur until the vehicle has a high enough twr for throttling to be necessary.
- Default liftoffTWR changed to 1.4 for better ship design compatibility following some feedback.
- Steering tweak to avoid a 'kick' at the start of the gravity turn.
- The CLS menu for choosing orbital parameters now has an 'Instantaneous' launch window option. If provided with the inclination & longitude of the ascending node, CLS will calculate the instantaneous launch window needed to reach this orbit.
- New library (CLS_window.ks) included to calculate the instantaneous launch window. Thanks to u/ElWanderer_KSP on reddit and u/Rybec as the library is just a slight tweak to their work from reddit.
- When using the instantaneous feature, the HUD will show whether the launch is scheduled for the ascending node or descending node.
- Fixed an error during orbital insertion where CLS may incorrectly calculate whether to burn at apoapsis or periapsis.
- CLS will now perform a quicksave on the pad prior to launch. 
- More accurate calculation of the maximum possible apoapsis that is compatible to any planet pack or rescale mod.
- User can now define the launch time as a countdown in minutes, seconds or a combination of both.
- Fixed bug where CLS does not jettison fairings / LES if orbital insertion occurs on the first stage.
- Fixed multiple bugs with the HUD.
<br>

<b>v1.4.5 (28/11/21)</b>

- Another change to hibernation mode - this time it has a check to ensure the parts have the necessary module actions to use hibernation mode, and wont enable it if they don't.
- Tidy up of staging that occurs if target orbit is achieved via first stage alone.
<br>

<b>v1.4.4 (26/11/21)</b>

- Adjusted method of enabling and disabling hibernation mode on probes during coast to improve reliability.
<br>

<b>v1.4.3 (24/11/21)</b>

- Adjusted method of detecting launch clamps to increase compatibility with mods that do not use the stock LaunchClamp module. Thanks to u/Astrofoo for this.
<br>

<b>v1.4.2 (16/11/21)</b>

- Changed capitalisation of runpath commands for the benefit of Linux users. Thanks to u/ruiluth and u/jwbrase for the help here. I don't linux so I cannot test this - feedback from linux users would be very much appreciated.
- Added a command to CLS & abort modes to instantly deactivate SAS if it is activated mid-script. SAS does not play nicely with the steering commands these scripts use.
<br>

<b>v1.4.1 (25/10/21)</b>

- Fixed a potential issue for parts without moduleEngineFX when calculating thrust.
<br>

<b>v1.4.0 (25/10/21)</b>

Abort

- The abort procedure included in CLS v1.3.0 relied upon another script (ChuteDescent.ks) which I completely forgot to upload. Apologies!
- ChuteDescent handles chute deploy on the aborted capsules descent. I split it into it's own script as it can also be used for a capsule re-entering the atmosphere.
<br>

Minor Changes

- Improved CLS logic for detecting incorrect staging where SRBs are incorrectly placed in first stage.
- CLS now has a system of excluding hullcam parts from its staging checks and part counts.
- CLS can now detect the presence of fuel cells on the vehicle and will activate them automatically if EC is below 25%.
- I can't spell separation/separated/separate it seems. Corrected the spelling (thank you jefferyharrell)
- Added a check to confirm engines are throttling correctly at T-0. I found that the script was aborting some launches when it didn't need to due to throttle 'lag'.
- The ship will hold pitch a for 3 seconds after staging to ensure the next stage is clear of the previous stage before pitching.
- Staging will now occur when SRBs are below 25% thrust, not 20% (for SRBs with thrust curves).
- More accurate launch throttle calculations and ascent throttling when using SRBs with thrust curves.
- Warp limit increased during coast phases. The script will also reduce the warp level progressively approaching a burn.
- CLS will now hold the launch if launch clamps aren't detected and suggest a scrub (Thanks go to Tacombel for highlighting this issue)
- Staging at ascent completion has been adjusted to make it smoother and less chaotic.
- Removed throttle down when approaching target apoapsis.
- General script writing tweaks
- Ascent profile is more aggressive resulting in improved efficiency.
- CLS now checks if the circularising engine has an unlocked gimbal before using it for attitude control if the vessel isn't correctly orientated for circularisation burn. Also only throttles to 0.1twr rather than 10% thrust (which may have been overkill for upper stages with high thrust engines)
- Pretty extensive renaming of variables and functions so that their names indicate what they do.
- CLS logs are now named with the real world time of launch.
<br>

EC Consumption 

- Complete review of the script in an attempt to reduce the amount of electrical charge CLS requires to run.
- 33% reduction in EC consumption during launch and ascent.
- 50% reduction in EC consumption during coast due to CLS now entering a 'low-power' mode.
- CLS will now also put all control parts into hibernation mode during the coast phase.
<br>

HUD

- Complete redesign of the bottom HUD elements.
- During pre-launch, if a scrub/hold occurs there is now a 'More info' button which will explain the cause of the hold to assist you in solving the issue and successfully recycling the launch sequence.
- Added a readout to show which runmode the script is in next to the Mission Elapsed Time on the HUD.
- The fuel readout has been updated. It used engine fuel flow to calculate remaining fuel - accurate when the engines are burning, but inaccurate during coast phases when fuel flow is 0. So now it will show remaining fuel if engines were to burn at 100% thrust while in coast phases.
- Time to apoapsis/periapsis readout now shifts over to show minutes when it would exceed 999 seconds.
- CLS will now detect precise moment of Max Q rather than a time frame in which it happens.
- CLS now gathers more information for the HUD during pre-launch.
<br>

dV changes on Orbit

- The concern here is that boil-off or use of fuel cells will reduce the vehicles remaining dV which means it will not be able to complete circularisation burns.
- CLS accounts for this by ensuring the vehicle has around a 5% dV margin for upcoming burns. 
- 1.4.0 adds a fail safe so that if boil-off or fuel cell usage has reduced the vehicle's dV to below a burn's dV requirement, it will not cause script failure. This is done by recalculating vehicle dV just before a burn and amending the maneuever node's properties if necessary.
- In these scenarios, the final orbit achieved by CLS will not be circular.
<br>

Achieving Orbit

- This is a major change and the code to implement this system is spread all through CLS and its libraries - I will summarise what it does below.
- Previous versions of CLS were very basic in that the vehicle would burn until apoapsis reached a target orbit altitude, cut-off its engines and then burn at apoapsis to circularise the orbit. This presented issues with low orbit altitudes just outside the karman line or situations where it left the upper stages with unrealistic circularisation burns.
- Now, the script has multiple methods of circularising:
    1. As before, circularising at apoapsis.
    2. First burn is longer and stops when periapsis reaches the target orbit altitude. Then at periapsis, the vehicle burns retrograde to achieve a circular orbit.
    3. Same approach as number 2, but the script sees the apoapsis is getting extremely large, so it cuts the engine, burns at apoapsis to raise the periapsis to target orbit, and then burns retrograde at periapsis to circualrise the orbit.
- The script continuously monitors multiple data streams to determine which approach is best.

<b>v1.3.0 (10/06/21)</b>

Compatibility

- CLS can now automatically determine the fuel type and mass, even for non-stock resources. This allows CLS to work (theoretically) with any resource pack such as realFuels.
- Ensured CLS is compatible with all rescale mods and planet packs by altering how it handles atmospheric calculations, gelocation and time variables
- Ensured any calls for the vessel's geolocation will be accurate across rescale mods and planet packs.
- Reworked part module searches to maximise compatibility with mods that replace stock modules. This was done specifically with realFuels' moduleEnginesRF in mind.
<br>

Tidy Up

- Widespread tidy and reformat of a lot of code. Things look tidier, are easier to understand and will hopefully run smoother. 
- Increased the use of local variables to reduce long, single line equations / calculations.
- Finally learned how to use BIDMAS to get rid of unnecessary brackets in the formulas.
- Rewrite of the scrollprint function to make it concise & run a smoother.
- Removed ‘steerto’ and ‘throt’ variables for steering and throttle control (this was originally done in response to a bug in early kOS versions).
- Added a separate loop to handle the HUD and monitor resources in Abort script. This removed the need to call those functions multiple times throughout the script.
- Removed the ‘vess’ parameter from cls_nav functions.
- The staging check during countdown is now a function instead of one line of messy code.
<br>

TWR

- Overhaul of defualt TWR values (all user configurable). Mininimum take off TWR has been increased to 1.3, Upper stage TWR has been increased to 0.8 and max TWR has increased to 4. These changes were made so that CLS can function across stock and rescaled installs in its default configuration.
- The central engine in a 3-booster configuration now throttles down to 55% slightly different. If the rocket can do this and maintain TWR (by increasing overall throttle) it will do so as early as possible. If not, it will do so when it can maintain a TWR above 2.1 throughout the throttle down. 
<br>

New Features

- CLS now gives two new hud readouts during ascent (experiencing max-q and passed through max-q). The code behind this is lightweight, 'hacky' and may not always show up.
- The abort script is now activated in response to a manual abort during CLS.
- Any hold scenario that occurs during countdown now gives the option to scrub, continue to launch & abort. Originally it did not give the option to continue in some scenarios. This was a mistake, the player should have final say over whether the rocket launches.
<br>

Bug fixes

- Fixed the bug where dV and burn time calculations were inaccurate for vessels with multiple upper stage fuel tanks.
______________________


<b>v1.2.1 (07/03/21)</b>

- Fixed an error caused when target apoapsis is reached prior to stage seperation, causing an undefined variable to be called.
- Updated mode detection to better determine if the vessel is using SRBs and adjust its twr calculations accordingly.
______________________


<b>v1.2.0 (13/02/21)</b>

Major Changes:
- New GUI system for adjusting launch parameters, handled by a new CLS_parameters library. Instead of running 'CLS(250,90 etc).' all that is needed now is 'run cls.'
- Rewrote the ascent program to use the square root method. This new system improves reliability but may not be as efficient.
- It is now recommended to avoid a target apoapsis below 100km, as an apoapsis this low is reached too early in ascent, causing the first stage to be discarded and a high dV circularisation burn.
- Added a new azimuth function for fine tuning inclination. Thanks to u/BriarAndRye for his Instantaneous Azimuth Function. Initial testing suggests this code can reach a target inclination to within 0.001 degrees.
- Added maxStages as a script parameter allowing more flexibility for SSTOs and 3+ stage rockets.
- Added a logging function which can log data each 0.5 seconds to a csv file in the logs directory if the user wishes.
- Redesigned the countdown hold function to use kOS's GUI system and give the user on screen buttons rather than the improvised pilot input method.
- Rewrote the Abort script steering code. The pod will now perform a slow pitch maneuver away from the rocket to ensure it is clear from any RUDs.
- Added pre-launch check which determines if there is crew present and holds the launch if there is nothing in the abort action group. This is configurable.
- Added a contingency if the vehicle loses attitude control and cannot orientate itself for circularisation burn. Engines will throttle up a tiny amount and gimbal to the correct attitude prior to the burn.
- Limited CLS to a maximum apoapsis of 500km. This fixes an error where direct launches to higher orbits miscalculated the azimuth needed. 

Minor Changes:
- Fixed an error in CLS_hud which occurred when an abort was triggered. 
- CLS_hud new shows remaining fuel as seconds rather than percent.
- Changed twr calculations during countdown/liftoff to be more accurate.
- Changed default inclination to 0 rather than 0.1.
- CLS now automatically removes the circularisation maneuver node before the script completes.
- Rewrote script initialisation to keep as many variables 'local' to their functions as possible. Should improve initial performance.
- Much more robust error detection for user input. Previous script was very weak at catching incorrect user input and holding the launch.
- Tidied up functions and libraries.
- Changed the method of detecting imminent staging to use fuel flow. This fixed an issue where CLS miscalculated remaining fuel in certain rocket configurations.
- Vehicle will now pitch gradually to surface prograde just prior to staging. This ensures discarded stages are not subject to unpredictable aero forces.
- Tuned the script to achieve target apoapsis more accurately. The script now attempts to achieve an apoapsis within 0.02% of its target.
- Implemented a control to limit upper stage engines to the same max TWR as first stage engines. 
- Various tweaks to make the launch and ascent more efficient.
- Abort action group only fires if there is crew is on the vehicle.
- Multi-stage vehicles (Not SSTOs) that reach the target apoapsis without staging will now stage at once out of the atmosphere so that upper stages handle circularisation. 
- Fixed an error in calculating circularisation burn time if the script is waiting to leave the atmopshere before staging (as explained above). Script will now wait until after staging before creating the maneuver node.
- Removed the throttle down prior to stage seperation. This was in place to limit sudden g-force spikes but interfered with other throttle up/down code in the script.

______________________

<b>v1.0.1 (31/01/21)</b>

- Fixed error in azimuth calculations when handling launches into high apoapsis.
- Added an abort script (Abort.ks) which automatically runs if CLS detects an abort parameter has been met.
______________________


<b>v1.0.0 (16/01/21)</b>

- First public release
