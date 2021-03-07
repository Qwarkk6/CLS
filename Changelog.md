Changelog
==========================

<b>v1.0.0 (16/01/21)</b>

- First public release

<b>v1.0.1 (31/01/21)</b>

- Fixed error in azimuth calculations when handling launches into high apoapsis.
- Added an abort script (Abort.ks) which automatically runs if CLS detects an abort parameter has been met.

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

<b>v1.2.1 (07/03/21)</b>

- Fixed an error caused when target apoapsis is reached prior to stage seperation, causing an undefined variable to be called.
- Updated mode detection to better determine if the vessel is using SRBs and adjust its twr calculations accordingly.