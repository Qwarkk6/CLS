//Monitors engines for flameout
Function EngineFlameout {
	local check is false.
	
	if engList:length > 0 {
		For e in engList {
			If e:flameout {
				set check to true. break.
			}
		}
	} 
	return check.
}

//Detect whether seperation engine in LES.
Function lesDetect {
	local check is false.
	local lesListTemp is list().
	local lesList is list().
	For e in engList {
		if e:ignition and not e:flameout {
			if e:throttlelock = true {
				lesListTemp:add(e).
			}
		}
	}
	For p in lesListTemp {
		if p:wetmass > p:drymass {
			lesList:add(p).
			set check to true.
		}
	}
	return check.
}

//Checks for thrust indicating succesful abort motor ignition
Function thrustCheck {
	local check is false.
	For e in engList {
		If e:ignition and not e:flameout {
			if e:thrust > 0 and e:fuelflow > 0 {
				set check to true. break.
			}
		}
	}
	return check.
}

//Enables all vessel resources
function enableResources {
	for p in ship:parts {
		for r in p:resources {
			if r:enabled = false {
				set r:enabled to true.
			}
		}
	}
}

//kOS terminal readouts
function abortHUD {
	Print "Abort Procedure Active    " at (0,0).
	Print "Status: " + shipStatus + "                    " at (0,1).
	Print "------------------" at (0,2).
	Print "Battery Charge: " + round(EC,1) + "%     " at (0,3).
	Print "Fuel Remaining: " + round(FuelRem,1) + "%     " at (0,4).
	Print "Fuel Cells: " + fuelCellStatus + "          " at (0,5).
}

//Initialise
clearscreen.
RCS on. SAS off. enableResources().
abort on. lock throttle to 1.
runpath("0:/GeneralLibrary/Resources.ks").
runpath("0:/GeneralLibrary/FuelCells.ks").

//Resources
list resources in resList.
list engines in engList.
set activeResource to Active_Resource().
set batteryCapacity to Resource_Capacity("electriccharge").
lock EC to ship:electriccharge / batteryCapacity * 100.
if activeResource = false {
	set FuelRem to 0.
} else {
	lock FuelRem to Resource_Remaining(activeResource) / Resource_Capacity(activeResource) * 100.
}

//HUD setup
if lesDetect() {
	set shipStatus to "LES Active".
} else {
	set shipStatus to "Abort Burn".
}

wait until thrustCheck().

//Steering setup
//System of slowing pitching and yawing away from original steering atitude to ensure aborted capsule is clear of previous stages
set yaw to ship:facing:yaw.
set roll to ship:facing:roll.
set pitch to ship:facing:pitch.
set entrytime to time:seconds.
lock turnRate to (time:seconds - entrytime)*3.
lock steering to R(pitch+turnRate,yaw+turnRate,roll).

until EngineFlameout() and ship:verticalspeed < 0 {
	abortHUD(). fuelCellControl().
	
	if EngineFlameout() { 
		lock throttle to 0.
		set shipStatus to "Coasting".
		if Ship:partsingroup("AG10"):length > 0 {
			toggle Ag10. 
		}
	}
	wait 0.01.
}

runpath("0:/ChuteDescent.ks").