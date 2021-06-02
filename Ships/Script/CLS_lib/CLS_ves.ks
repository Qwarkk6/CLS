// CLS_ves.ks - A library of functions specific to identifying / calculatting information regarding the active vessel for the CLS (Common Launch Script)
// Copyright © 2021 Qwarkk6
// Lic. CC-BY-SA-4.0 

@lazyglobal off.

//Checks for common errors in staging
Function stagingCheck {
	For P in ship:parts {
		If mode = 1 {
			if P:hasmodule("launchclamp") and P:stage <> (stage:number-3) {
				return false.
			}
			if p:stage >= (stage:number-2) and not P:hasmodule("ModuleenginesFX") {
				return false.
			}
		} else if mode = 0 {
			if P:hasmodule("launchclamp") and P:stage <> (stage:number-2) {
				return false.
			}
			if p:stage >= (stage:number-1) and not P:hasmodule("ModuleenginesFX") {
				return false.
			}
		} 
		if P:hasmodule("moduledecouple") and P:stage > (stage:number-2) {
			return false.
		}
	}
}

// Detects the presence of SRBs
Function SRBDetect {
	Parameter plist.
	local SRBList is list().
	global SRBs is list().
	For P in plist {
		if runMode = -1 {
			If P:stage = (stage:number - 2) and P:modules:join(","):contains("ModuleEngine") and P:DryMass < P:WetMass and not P:HasModule("ModuleDecouple") { 
				SRBList:add(p).
			}	
		} else {
			If P:modules:join(","):contains("ModuleEngine") and P:DryMass < P:WetMass and not P:HasModule("ModuleDecouple") { 
				SRBList:add(p).
			}
		}
	}
	For e in SRBList {
		if runMode = -1 {
			if e:allowshutdown = false and e:throttlelock = true {
				SRBs:add(e).
			}
		} else {
			if e:allowshutdown = false and e:throttlelock = true and e:ignition = true {
				SRBs:add(e).
			}
		}
	}
	if SRBs:length > 0 {
		set mode to 1.
	} else {
		set mode to 0.
	}
}

// Creates a list of all engines
Function EngineList {
	global elist is list().
	For P in ship:parts {
		If P:modules:join(","):contains("ModuleEngine") {
			If not P:hasmodule("moduledecouple") {
				elist:add(p).
			}
		}
	}
}

// Creates a list of all active engines
Function Activeenginelist {
	Enginelist().
	global aelist is list().
	For e in elist {
		If e:ignition and e:allowshutdown {
			aelist:add(e).
		}
	}
}

// Creates a list of all active engines
Function ActiveSRBlist {
	Enginelist().
	global asrblist is list().
	For e in elist {
		If e:ignition and e:allowshutdown = false and e:throttlelock = true {
			asrblist:add(e).
		}
	}
}

// Detects whether staging has ignited Ullage motors.
Function Ullagedetectfunc {
	global UllageDetect is false.
	EngineList().
	For e in elist {
		if e:ignition = true and e:thrust > 0.01 and e:allowshutdown = false and e:resources:length > 0 {
			Set UllageDetect to true.
		}
	}
}

// calculates total mass of a partlist
Function Partlistmass {
	Parameter plist.
	local msum is 0.
	//if plist:length > 0 {
		For p in plist {
			set msum to msum + p:mass.
		}
	//}
	return msum.
}

// calculates total available thrust of a partlist
Function Partlistavthrust {
	Parameter plist.
	local avtsum is 0.
	For e in plist {
		set avtsum to avtsum + e:availablethrust.
	}
	return avtsum+0.1.
}

// calculates total current thrust of a partlist accounting for thrust limits or thrust curves
Function Partlistcurthrust {
	Parameter plist.
	local t is 0.
	For e in plist {
		set t to t + e:thrust.
	}
	return t+0.1.
}