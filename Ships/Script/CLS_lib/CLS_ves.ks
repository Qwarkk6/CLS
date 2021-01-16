// CLS_ves.ks - A library of functions specific to identifying / calculatting information regarding the active vessel for the CLS (Common Launch Script)
// Copyright © 2021 Qwarkk6
// Lic. CC-BY-SA-4.0 

@lazyglobal off.

// Detects the presence of SRBs
Function SRBDetect {
	Parameter SRBPartlist.
	SRBList:Clear(). SRBs:Clear().
	For P in SRBPartlist {
		If P:stage = (stage:number - 2) and P:HasModule("ModuleEnginesFX") and P:DryMass < P:WetMass and not P:HasModule("ModuleDecouple") and not P:HasModule("SSTUInterstageDecoupler") and not P:HasModule("ModuleAnchoredDecoupler") and not P:HasModule("SSTUCustomRadialDecoupler") {
			SRBList:add(p).
		}	
	}
	For tank in SRBList {
		For res in tank:resources {
			If res:name = SolidFuelName and res:amount > 1 {
				SRBs:add(tank).
			}
		}
	}
	return SRBs.
}

// Sets mode based on presence of SRBs
Function ModeDetect {
	If SRBdetect(Ship:parts):length > 0 {
		Set mode to 1.
	} else {
		Set mode to 0.
	}
}

// Creates a list of all engines
Function EngineList {
	elist:clear().
	For P in ship:parts {
		If P:hasmodule("ModuleEngines") or P:hasmodule("ModuleEnginesFX") or P:hasmodule("ModuleEnginesRF"){
			If not P:HASMODULE("MODULEDECOUPLE") and not P:hasmodule("SSTUAutoDepletionDecoupler") {
				elist:add(p).
			}
		}
	}
}

// Creates a list of all active engines
Function Activeenginelist {
	Enginelist().
	aelist:clear().
	For e in elist {
		If e:ignition and e:allowshutdown {
			aelist:add(e).
		}
	}
}

// Creates a list of engines in the next stage
Function NextStageEngineList {
	EngineList().
	nseList:clear().
	For P in elist {
		if p:stage = (stage:number-1) {
			nseList:add(p).
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
	declare local msum to 0.
	For p in custompartlist {
		set msum to msum + p:mass.
	}
	return msum.
}

// calculates total available thrust of a partlist
Function Partlistavthrust {
	Parameter custompartlist.
	declare local avtsum to 0.
	For e in custompartlist {
		set avtsum to avtsum + e:availablethrust.
	}
	return avtsum+0.1.
}

// calculates total current thrust of a partlist accounting for thrust limits or thrust curves
Function Partlistcurthrust {
	Parameter custompartlist.
	declare local curtsum to 0.
	For e in custompartlist {
		set curtsum to curtsum + e:thrust.
	}
	return curtsum+0.1.
}