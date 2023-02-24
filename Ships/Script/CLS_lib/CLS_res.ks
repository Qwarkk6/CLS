// CLS_res.ks - A library of functions specific to resource calculation / identification in the CLS (Common Launch Script)
// Copyright © 2021 Qwarkk6
// Lic. CC-BY-SA-4.0 

@lazyglobal off.

// Checks if a resource is above a specified threshold
Function resourceCheck {
	Parameter resourceName.
	Parameter threshold.
	For res in ship:resources {
		If res:name = resourceName {
			If (res:amount/res:capacity) <= threshold {
				return false.
			} else {
				return true.
			}
		}
	}
}

// Detects the fuel capacity of a given partlist
Function FuelRemaining {
	Parameter plist.
	Parameter resourceName.
	local rCap is 0.
	For tank in plist {
		For res in tank:resources {
			if res:name = resourceName and res:enabled = true {
				set rCap to (rCap + res:amount).
			}
		}
	}
	return rCap.
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
	if runmode > 0 {
		Activeenginelist().
		global engine is aelist[0].
	} else {
		list engines in elist.
		for p in elist {
			if p:stage = stage:number-1 {
				global engine is p.
			}
		}
	}
	
	//First Resource
	local res1 is engine:consumedResources:values[0]:tostring.
	local res1 is res1:substring(17,res1:length-17).
	global ResourceOne is res1:remove(res1:length-1,1).
	
	//Second Resource
	local res2 is engine:consumedResources:values[1]:tostring.
	local res2 is res2:substring(17,res2:length-17).
	global ResourceTwo is res2:remove(res2:length-1,1).
}

//Determines mass of main fuel
Function PrimaryFuelMass {
	global resourceMass is list().
	global resourceName is list().
	For res in ship:resources {
		resourceName:add(res:name).
		resourceMass:add(res:density).
	}
	Global ResourceOneMass is resourceMass[resourceName:find(ResourceOne)].
	Global ResourceTwoMass is resourceMass[resourceName:find(ResourceTwo)].
}

//Detects solid fuel type 
Function SolidFuel {
	
	if asrblist:length > 0 or SRBs:length > 0 {
		if asrblist:length > 0 {
			global srb is asrblist[0].
		} else if SRBs:length > 0 {
			For p in SRBs {
				if p:stage = stage:number-1 {
					global srb is p.
				} else if p:stage = stage:number-2 {
					global srb is p.
				}
			}
		}
		local res is srb:consumedResources:values[0]:tostring.
		local res is res:substring(17,res:length-17).
		global SolidFuelName is res:remove(res:length-1,1).
		for res in ship:resources {
			if res:name = SolidFuelName {
				global SolidFuelMass is res:density.
			}
		}
	}
}