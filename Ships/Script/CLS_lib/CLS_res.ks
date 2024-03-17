// CLS_res.ks - A library of functions specific to resource calculation / identification in the CLS (Common Launch Script)
// Copyright © 2021 Qwarkk6
// Lic. CC-BY-SA-4.0 

@lazyglobal off.

// Checks if a resource is above a specified threshold
Function batteryCheck {
	Parameter threshold.
	if ship:electriccharge/BatteryCapacity <= threshold {
		return false.
	} else {
		return true.
	}
}

// Detects the fuel capacity of a given partlist
Function FuelRemaining {
	Parameter plist.
	local rMass is 0.
	for p in plist {
		set rMass to rMass + (p:mass - p:drymass).
	}
	return rMass.
}

// Identifies the fuel tanks(s) providing fuel for the stage. First creates a list of all fuel tanks and the stage they are assocated with. Then compares the associated stages to find the tanks(s) associated with the largest/current stage.
Function FuelTank {	
	Parameter resourceName.
	local MFT is list(list(),list(),list()).
	global stagetanks is list().
	for tank in ship:parts {
		for res in tank:resources {
			if res:name = resourceName and res:amount > 1 and res:enabled = true {
				MFT[0]:add(tank).
				MFT[2]:add(tank).
			}
		}
	}
	for p in MFT[0] {
		MFT[1]:add(p:stage).
	}
	Until MFT[1]:length = 1 {
		if MFT[1][0] <= MFT [1][1] {
			MFT[1]:remove(0).
			MFT[0]:remove(0).
		} else if MFT[1][0] >= MFT[1][1] {
			MFT[1]:remove(1).
			MFT[0]:remove(1).
		}
	}
	stagetanks:add(MFT[0][0]).
	for p in MFT[2] {
		if p:uid = stagetanks[0]:uid {
		} else {
			if p:stage = stagetanks[0]:stage {
				stagetanks:add(p).
			}
		}
	}
}

// Identifies the fuel tanks(s) providing fuel for the stage. First creates a list of all fuel tanks and the stage they are assocated with. Then compares the associated stages to find the tanks(s) with the most amount of a given fuel type.
Function FuelTankUpper {	
	Parameter resourceName.
	local MFT is list(list(),list(),list()).
	global stagetanks is list().
	for tank in ship:parts {
		for res in tank:resources {
			if res:name = resourceName and res:amount > 1 and res:enabled = true {
				MFT[0]:add(tank).
				MFT[1]:add(res:amount).
				MFT[2]:add(tank).
			}
		}
	}
	Until MFT[1]:length = 1 {
		if MFT[1][0] <= MFT [1][1] {
			MFT[1]:remove(0).
			MFT[0]:remove(0).
		} else if MFT[1][0] > MFT[1][1] {
			MFT[1]:remove(1).
			MFT[0]:remove(1).
		}
	}
	stagetanks:add(MFT[0][0]).
	for p in MFT[2] {
		if p:uid = stagetanks[0]:uid {
		} else {
			if p:stage = stagetanks[0]:stage {
				stagetanks:add(p).
			}
		}
	}
}

//Detect main fuel 
Function PrimaryFuel {
	local PFe is 0.
	if runmode > 0 {
		Activeenginelist(). wait 0.01.
		set PFe to aelist[0].
	} else {
		local tempelist is ship:engines.
		for p in tempelist {
			if p:stage = stage:number-1 {
				set PFe to p. break.
			}
		}
	}
	
	//First Resource
	local res1 is PFe:consumedResources:values[0]:tostring.
	local res1 is res1:substring(17,res1:length-17).
	global ResourceOne is res1:remove(res1:length-1,1).
	
	//Second Resource
	local res2 is PFe:consumedResources:values[1]:tostring.
	local res2 is res2:substring(17,res2:length-17).
	global ResourceTwo is res2:remove(res2:length-1,1).
}