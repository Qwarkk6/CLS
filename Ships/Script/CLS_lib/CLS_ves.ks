// CLS_ves.ks - A library of functions specific to identifying / calculatting information regarding the active vessel for the CLS (Common Launch Script)
// Copyright © 2021 Qwarkk6
// Lic. CC-BY-SA-4.0 

@lazyglobal off.

//Checks for common errors in staging
Function stagingCheck {
	local check is true.
	local plist is list().
	For P in ship:parts {
		if not P:hasmodule("MuMechModuleHullCameraZoom") {
			plist:add(p).
		}
	}
	For P in plist {
		If vehicleConfig = 1 {
			//If launch clamps arent in the correct stage
			if P:hasmodule("launchclamp") and P:stage <> (stage:number-3) {
				set check to false.
			}
			//If there is a part in the next 2 stages that isnt an engine
			if p:stage >= (stage:number-2) and not P:modules:join(","):contains("ModuleEngine") {
				set check to false.
			}
		} else if vehicleConfig = 0 {
			//If launch clamps arent in the correct stage
			if P:hasmodule("launchclamp") and P:stage <> (stage:number-2) {
				set check to false.
			}
			//If there is a part in the next stage that isnt an engine
			if p:stage >= (stage:number-1) and not P:modules:join(","):contains("ModuleEngine") {
				set check to false.
			}
		} 
	}
	return check.
}

//Checks for presence of launch clamps
Function launchClampCheck {
	local plist is ship:parts.
	local clampList is list().
	For P in plist {
		if P:hasmodule("launchclamp") or P:modules:join(","):contains("LaunchClamp"){
			clampList:add(p).
		}
	}
	if clampList:length = 0 {
		return false.
	} else {
		return true.
	}
}

// Detects the presence of SRBs
Function SRBDetect {
	Parameter plist.
	local SRBList is list().
	global SRBs is list().
	For P in plist {
		if runMode = 0 {
			If P:stage >= (stage:number - 2) and P:modules:join(","):contains("ModuleEngine") and P:DryMass < P:WetMass and not P:HasModule("ModuleDecouple") { 
				SRBList:add(p).
			}	
		} else {
			If P:modules:join(","):contains("ModuleEngine") and P:DryMass < P:WetMass and not P:HasModule("ModuleDecouple") { 
				SRBList:add(p).
			}
		}
	}
	For e in SRBList {
		if runMode = 0 {
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
		set vehicleConfig to 1.
	} else {
		set vehicleConfig to 0.
	}
}

//Creates a list of fuel cells
Function FuelCellDetect {
	global FCList is list().
	For p in ship:parts {
		if p:hasmodule("ModuleResourceConverter") {
			if p:getmodule("ModuleResourceConverter"):allactions:join(","):contains("toggle converter") {
				FCList:add(p).
			}
		}
	}
}

//Activates any fuel cells on board
Function FuelCellToggle {
	For p in FCList {
		p:getmodule("ModuleResourceConverter"):doaction("toggle converter",true).
	}
	if fuelCellActive = false {
		set fuelCellActive to true.
		scrollprint("Activating Fuel Cells").
	} else {
		set fuelCellActive to false.
		scrollprint("Deactivating Fuel Cells").
	}
}

//Turns Control Part hibernation on
Function lowPowerModeOn {
	for p in ship:parts {
		if p:hasmodule("ModuleCommand") {
			if p:getmodule("ModuleCommand"):hasaction("toggle hibernation") {
				p:getmodule("ModuleCommand"):doaction("toggle hibernation",true).
				set hibernationEnabled to true.
			}
		}
	}
}

//Turns Control Part hibernation off
Function lowPowerModeOff {
	for p in ship:parts {
		if p:hasmodule("ModuleCommand") {
			if p:getmodule("ModuleCommand"):hasaction("toggle hibernation") {
				p:getmodule("ModuleCommand"):doaction("toggle hibernation",false).
				set hibernationEnabled to false.
			}
		}
	}
}

//Used in pre-launch to gather info about first stage engines prior to ignition
Function PrelaunchEngList {
	EngineList().
	Activeenginelist().
	ActiveSRBlist().
	local pleList is list().
	for p in elist {
		if p:stage = stage:number -1 {
			pleList:add(p).
		} 
		if vehicleConfig = 1 {
			if p:stage = stage:number -2 {
				pleList:add(p).
			}
		}
	}
	for e in pleList {
		if e:allowshutdown {
			aelist:add(e).
			set e:thrustlimit to 100.
		} else {
			asrblist:add(e).
		}
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

// Creates a list of all active SRBs
Function ActiveSRBlist {
	Enginelist().
	global asrblist is list().
	For e in elist {
		If e:ignition and e:allowshutdown = false and e:throttlelock = true {
			asrblist:add(e).
		}
	}
}

//Detects if the vehicle has gimballing ability & if the gimbal is unlocked (locked = true)
Function GimbalDetect {
	Activeenginelist().
	local check is false.
	For p in aelist {
		If P:modules:join(","):contains("ModuleGimbal") {
			if P:getmodule("modulegimbal"):getfield("gimbal") = false {
				set check to true.
			}
		}
	}
	return check.
}

// Detects whether staging has ignited Ullage motors.
Function detectUllage {
	//global UllageDetected is false.
	EngineList().
	For e in elist {
		if e:ignition = true and e:thrust > 0.01 and e:allowshutdown = false and e:resources:length > 0 {
			Set UllageDetected to true.
		}
	}
}

// calculates total mass of a partlist
Function PartlistMass {
	Parameter plist.
	local mass is 0.
	For p in plist {
		set mass to mass + p:mass.
	}
	return mass.
}

// calculates total available thrust of a partlist
Function PartlistAvailableThrust {
	Parameter plist.
	local thrust is 0.01.
	For e in plist {
		set thrust to thrust + e:availablethrust.
	}
	return thrust.
}

// calculates total current thrust of a partlist accounting for thrust limits or thrust curves
Function PartlistCurrentThrust {
	Parameter plist.
	local thrust is 0.01.
	For e in plist {
		set thrust to thrust + e:thrust.
	}
	return thrust.
}

//Calculates potential thrust of a partlist
Function PartlistPotentialThrust {
	Parameter plist.
	local thrust is 0.01.
	For e in plist {
		set thrust to thrust + e:possiblethrust.
	}
	return thrust.
}