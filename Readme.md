CLS (Common Launch Script)
==========================

An auto-launch script that handles everything from pre-launch through ascent to a final circular orbit for any desired apoapsis and inclination.

<b>Dependencies</b>

The only dependency of CLS is the <a href="https://forum.kerbalspaceprogram.com/index.php?/topic/165628-181-kos-v1210-kos-scriptable-autopilot-system/">kOS</a> mod

<b>Installation</b>

Copy everything from the zip into your main Kerbal Space Program folder

<b>Future Development</b>

Please refer to the <a href="https://github.com/Qwarkk6/CLS/issues">issue tracker</a> to find the future development plans for this script, such as new features, updated documentation or bug fixing.

<b>Instructions</b>

CLS can be run from the archive. If you dont have the 'start on the archive' setting enabled, switch the the archive with the kOS command 'switch to 0.' and then you will be able to run CLS.
More specific instructions for running CLS can be found at the top of CLS.ks. Many aspects of the script are configurable. Those that are can be found at the top of CLS.ks in the USER CONFIGURATION section.

<b>Bug Reporting</b>

If this script fails for you, please either comment on its forum post or open an issue on github in the <a href="https://github.com/Qwarkk6/CLS/issues">issue tracker.</a><br>
In both cases I will need to see a picture of the kOS terminal, the launch parameters inputted and when during ascent it failed. In some cases I may also need a modlist or craft file for further testing. 

<b>License</b>

This script is distributed under the CC-BY-SA-4.0 license, except where noted below, where those elements are distributed under their own license.<br>
License text can be found <a href="https://github.com/Qwarkk6/CLS/blob/main/LICENSE.txt">here.</a>

<b>License Exceptions</b>

lib_navball.ks | lib_lazcalc.ks | lib_num_to_formatted_str.ks - <a href="https://github.com/KSP-KOS/KSLib">KSLib</a> - <a href="https://opensource.org/licenses/MIT">MIT</a><br>
See entries at the bottom of the <a href="https://github.com/Qwarkk6/CLS/blob/main/LICENSE.txt">license</a> for more information.

<b>Special Thanks</b>

A huge thank you to /u/only_to_downvote / mileshatem for writing and sharing his amazing <a href="https://github.com/mileshatem/launchToCirc">launchtoCirc</a> script. CLS is based on his work. I taught myself kOS by deconstructing launchtoCirc bit by bit to understand it and how it works. Then I set about creating my own, but some of mileshatem's original code is in CLS. When i hit a roadblock with adcent profiles, I messaged him on reddit and recieved some fantastic help.<br> 
The kOS dev team for writing their fantastic <a href="https://ksp-kos.github.io/KOS/">documentation</a> for kOS. Incredibly useful for a new kOS user and taught me a lot.<br>
The kOS dev team (again) for their amazing <a href="https://github.com/KSP-KOS/KSLib">KSlib</a> libraries. CLS uses them, and seeing how their libraries work taught me a lot.<br>
The fantastic <a href="https://www.reddit.com/r/Kos/">kOS subreddit</a> and its community. I hit many roadblocks writing this script and I always found help there. Whether it was reading responses to other's troubles or posting myself, I always found someone with a suggestion. /u/Dunbaratu provided the compass_for_vect function.