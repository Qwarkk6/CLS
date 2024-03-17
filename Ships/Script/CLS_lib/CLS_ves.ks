// CLS_ves.ks - A library of functions specific to identifying / calculatting information regarding the active vessel for the CLS (Common Launch Script)
// Copyright © 2021 Qwarkk6
// Lic. CC-BY-SA-4.0 

@lazyglobal off.

//Checks for common errors in staging
Function stagingCheck {
	local tempplist is list().
	For P in ship:parts {
		if not P:hasmodule("MuMechModuleHullCameraZoom") or not P:hasmodule("CModuleLinkedMesh"){
			tempplist:add(p).
		}
	}
	For P in tempplist {
		If vehicleConfig = 1 {
			//If launch clamps arent in the correct stage
			if P:hasmodule("launchclamp") and P:stage <> (stage:number-3) {
				return true.
			}
			//If there is a part in the next 2 stages that isnt an engine
			if p:stage >= (stage:number-2) and not P:modules:join(","):contains("ModuleEngine") and SRBignoreList:find(p) = -1 {
				return true.
			}
		} else if vehicleConfig = 0 {
			//If launch clamps arent in the correct stage
			if P:hasmodule("launchclamp") and P:stage <> (stage:number-2) {
				return true.
			}
			//If there is a part in the next stage that isnt an engine
			if p:stage >= (stage:number-1) and not P:modules:join(","):contains("ModuleEngine") {
				return true.
			}
		} 
	}
	return false.
}

//Checks for presence of launch clamps
Function launchClampCheck {
	local plist is ship:parts.
	For P in plist {
		if P:hasmodule("launchclamp") or P:modules:join(","):contains("LaunchClamp"){
			return true.
		}
	}
	return false.
}

// Detects the presence of SRBs
Function SRBDetect {
	local tempelist is ship:engines.
	local SRBList is list().
	global SRBs is list().
	global SRBignoreList is list().
	For P in tempelist {
		if runMode = 0 {
			If P:stage >= (stage:number - 2) and P:DryMass < P:WetMass and not P:HasModule("ModuleDecouple") { 
				SRBList:add(p).
			}	
		} else {
			If P:DryMass < P:WetMass and not P:HasModule("ModuleDecouple") { 
				SRBList:add(p).
			}
		}
	}
	For p in SRBList {
		for p in p:children {
			SRBignoreList:add(p).
		}
	}
	For e in SRBList {
		if runMode = 0 {
			if e:allowshutdown = false and e:throttlelock = true {
				SRBs:add(e). break.
			}
		} else {
			if e:allowshutdown = false and e:throttlelock = true and e:ignition = true {
				SRBs:add(e). break.
			}
		}
	}
	if SRBs:length > 0 {
		set vehicleConfig to 1.
		set LiftoffTWR to 1.8.
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

// Control Part hibernation control
Function lowPowerMode {
	parameter mode.
	for p in ship:parts {
		if p:hasmodule("ModuleCommand") {
			if p:getmodule("ModuleCommand"):hasaction("toggle hibernation") {
				p:getmodule("ModuleCommand"):doaction("toggle hibernation",mode).
			}
		}
	}
}

//Used in pre-launch to gather info about first stage engines prior to ignition
Function PrelaunchEngList {
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

//Finds the SRBs that will stage first on rockets with multiple SRBs of different sizes/burn durations
Function stageSRBlist {
	local itt0 is 0.		//itterator through list
	local itt1 is 1.		//itterator through list
	local templist is list(list(),list(),list()).
	global ssrb is asrblist:copy.
	for e in asrblist {		//adds part info to list 0 & massflow to list 1
		templist[0]:add(e).
		templist[1]:add(e:maxmassflow*(e:thrustlimit/100)).
	}
	for p in asrblist {		//adds fuel mass to list 2
		templist[2]:add((p:wetmass - p:drymass)).
	}

	until itt1 >= ssrb:length {
		local remBurn0 is templist[2][0]/templist[1][0].	//calculates remaining burn via fuelmass / massflow
		local remBurn1 is templist[2][1]/templist[1][1].	//calculates remaining burn via fuelmass / massflow
		if remBurn0 < remBurn1 {
			ssrb:remove(1).
			templist[0]:remove(1).
			templist[1]:remove(1).
			templist[2]:remove(1).
		} else if remBurn0 > remBurn1 {
			ssrb:remove(0).
			templist[0]:remove(0).
			templist[1]:remove(0).
			templist[2]:remove(0).
		} else {
			set itt0 to itt0+1.
			set itt1 to itt1+1.
		}
	}
}
	

// Creates a list of all engines
Function EngineList {
	global elist is list().
	local tempelist is ship:engines.
	For P in tempelist {
		If not P:hasmodule("moduledecouple") {
			elist:add(p).
		}
	}
}

// Creates a list of all active engines
Function Activeenginelist {
	Enginelist().
	global aelist is list().
	local tempelist is ship:engines.
	For e in tempelist {
		If e:ignition and e:allowshutdown and not e:flameout {
			aelist:add(e).
		}
	}
}

// Creates a list of all active SRBs
Function ActiveSRBlist {
	global asrblist is list().
	local tempelist is ship:engines.
	For e in tempelist {
		If e:ignition and e:allowshutdown = false and e:throttlelock = true {
			asrblist:add(e).
		}
	}
}

//Detects if the vehicle has gimballing ability & if the gimbal is unlocked (locked = true)
Function GimbalDetect {
	For p in aelist {
		If P:modules:join(","):contains("ModuleGimbal") {
			if P:getmodule("modulegimbal"):getfield("gimbal") = false {
				return true.
			}
		}
	}
	return false.
}

// Detects whether staging has ignited Ullage motors.
Function detectUllage {
	local tempelist is ship:engines.
	For e in tempelist {
		if e:ignition = true and e:thrust > 0.01 and e:allowshutdown = false and e:resources:length > 0 {
			return true.
		}
	}
	return false.
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

