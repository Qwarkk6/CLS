// CLS_ves.ks - A library of functions specific to identifying / calculatting information regarding the active vessel for the CLS (Common Launch Script)
// Copyright © 2021 Qwarkk6
// Lic. CC-BY-SA-4.0 

@lazyglobal off.

// Detects the presence of SRBs
Function SRBDetect {
	Parameter plist.
	local SRBList1 is list().
	local SRBList2 is list().
	global SRBs is list().
	For P in plist {
		if runMode = -1 {
			If P:stage = (stage:number - 2) and P:HasModule("ModuleEnginesFX") and P:DryMass < P:WetMass and not P:HasModule("ModuleDecouple") { 
				SRBList1:add(p).
			}	
		} else {
			If P:HasModule("ModuleEnginesFX") and P:DryMass < P:WetMass and not P:HasModule("ModuleDecouple") { 
				SRBList1:add(p).
			}
		}
	}
	For e in SRBList1 {
		if runMode = -1 {
			if e:allowshutdown = false and e:throttlelock = true {
				SRBList2:add(e).
			}
		} else {
			if e:allowshutdown = false and e:throttlelock = true and e:ignition = true {
				SRBList2:add(e).
			}
		}
	}
	For tank in SRBList2 {
		For res in tank:resources {
			If res:name = SolidFuelName and res:amount > 1 {
				SRBs:add(tank).
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
	//elist:clear().
	For P in ship:parts {
		If P:hasmodule("ModuleEngines") or P:hasmodule("ModuleEnginesFX") or P:hasmodule("ModuleEnginesRF") {
			If not P:hasmodule("moduledecouple") and not P:hasmodule("SSTUAutoDepletionDecoupler") {
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
	//asrblist:clear().
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
			for r in e:resources {
				If res:name = SolidFuelName {
					Set UllageDetect to true.
				}
			}
		}
	}
}

// calculates total mass of a partlist
Function Partlistmass {
	Parameter custompartlist.
	local msum is 0.
	For p in custompartlist {
		set msum to msum + p:mass.
	}
	return msum.
}

// calculates total available thrust of a partlist
Function Partlistavthrust {
	Parameter custompartlist.
	local avtsum is 0.
	For e in custompartlist {
		set avtsum to avtsum + e:availablethrust.
	}
	return avtsum+0.1.
}

// calculates total current thrust of a partlist accounting for thrust limits or thrust curves
Function Partlistcurthrust {
	Parameter custompartlist.
	local curtsum is 0.
	For e in custompartlist {
		set curtsum to curtsum + e:thrust.
	}
	return curtsum+0.1.
}