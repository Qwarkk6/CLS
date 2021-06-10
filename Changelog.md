Changelog
==========================

<b>v1.3.0 (14/06/21)</b>

Compatibility

- The script no longer relies on a pre-set list of fuels and fuel masses which would have to be manually edited by a user wanting to switch to non-stock fuels. Instead the script now automatically determines the fuel type being used and its mass (for dV calculations). This allows CLS to work (theoretically) with any resource pack such as realFuels.
- Moved all ‘static’ numbers regarding kerbin & its atmosphere to kOS body variables. This ensures CLS is compatible with rescale mods or planet packs such as RSS.
- Functions which handle time now calculate the length of a day, rather than presume it is 6 hours as in stock. This is necessary for compatibility with rescale mods or planet packs.
- The script now determines its geolocation rather than use manually set geo-coordinates of the KSC. This ensures compatibility with rescale mods and planet packs.
- Reworked part module searches to maximise compatibility with mods that replace stock modules. Parts were being excluded from part lists due to inconsistent module names across mods (eg realFuels using the moduleEnginesRF module).
<br>
Tidy Up

- General tidy and reformat of a lot of code. Things look tidier, are easier to understand and will hopefully run smoother. 
- Increased my use of local variables to reduce long, single line equations / calculations.
- I continuously try to add comments to everything to explain how it works. I do this for my sake, so I can understand it next time I return to it, but also for you to understand how it works and adapt it as you like.
- Huge rewrite of the scrollprint function to make it concise & run a whole lot smoother.
- Included a second parameter with scrollprint function which controls whether to print a timestamp or not.
- Finally moved away from using ‘steerto’ and ‘throt’ as variables to control steering and throttle (this was originally done in response to a bug in early kOS versions). By locking steering & throttle to a value directly, I could reduce the code length significantly in places. 
- Added a separate loop to handle the HUD and monitor resources in Abort script. This removed the need to call those functions multiple times throughout the script.
- Removed the ‘vess’ parameter from cls_nav functions. Makes the code look cleaner and I never did find any reason to use the nav functions for any vessel other than the active one.
- The staging check that occurs during countdown is now a function instead of one line of messy code. This makes it far easier to read, understand and manipulate if necessary.
- Finally learned how to use BIDMAS to get rid of unnecessary brackets in the formulas.
<br>

Bug fixes

- Fixed the bug where dV and burn time calculations were inaccurate for vessels with multiple upper stage fuel tanks.
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

<b>v1.2.1 (07/03/21)</b>

- Fixed an error caused when target apoapsis is reached prior to stage seperation, causing an undefined variable to be called.
- Updated mode detection to better determine if the vessel is using SRBs and adjust its twr calculations accordingly.
<br>

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
<br>

<b>v1.0.1 (31/01/21)</b>

- Fixed error in azimuth calculations when handling launches into high apoapsis.
- Added an abort script (Abort.ks) which automatically runs if CLS detects an abort parameter has been met.
<br>

<b>v1.0.0 (16/01/21)</b>

- First public release
