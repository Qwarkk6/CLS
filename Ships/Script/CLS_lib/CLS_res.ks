// CLS_res.ks - A library of functions specific to resource calculation / identification in the CLS (Common Launch Script)
// Copyright © 2021 Qwarkk6
// Lic. CC-BY-SA-4.0 

@lazyglobal off.

// Checks if a resource is above a specified threshold
Function resourceCheck {
	Parameter rname.
	Parameter threshold.
	For res in ship:resources {
		If res:name = rname {
			If (res:amount/res:capacity) <= threshold {
				return false.
			} else {
				return true.
			}
		}
	}
}

// Detects the fuel capacity of a given partlist
Function plistFuelRem {
	Parameter plist.
	Parameter rname.
	local f is 0.
	For tank in plist {
		For res in tank:resources {
			if res:name = rname and res:enabled = true {
				set f to (f + res:amount).
			}
		}
	}
	Return f.
}

// Identifies the fuel tanks(s) providing fuel for the stage. First creates a list of all fuel tanks and the stage they are assocated with. Then compares the associated stages to find the tanks(s) associated with the largest/current stage.
Function FuelTank {	
	Parameter rname.
	local MFT is list(list(),list(),list()).
	global stagetanks is list().
	for tank in ship:parts {
		for res in tank:resources {
			if res:name = rname and res:amount > 1 and res:enabled = true {
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
	Parameter rname.
	local MFT is list(list(),list(),list()).
	global stagetanks is list().
	for tank in ship:parts {
		for res in tank:resources {
			if res:name = rname and res:amount > 1 and res:enabled = true {
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
Function MainFuelDetect {
	if runmode > -1 {
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
Function MainFuelMass {
	local resMass is list().
	local resName is list().
	For res in ship:resources {
		resName:add(res:name).
	}
	for res in ship:resources {
		resMass:add(res:density).
	}
	Global ResourceOneMass is resMass[resName:find(ResourceOne)].
	Global ResourceTwoMass is resMass[resName:find(ResourceTwo)].
}

//Detects solid fuel type 
Function SolidFuelDetect {
	ActiveSRBlist().
	local resCheck is false.
	
	if asrblist:length > 0 {
		global srb is asrblist[0].
		set resCheck to true.
	} else if SRBs:length > 0 {
		For p in SRBs {
			if p:stage = stage:number-1 {
				global srb is p.
				set resCheck to true.
			} else if p:stage = stage:number-2 {
				global srb is p.
				set resCheck to true.
			}
		}
	}
	if resCheck = true {
		local res is srb:consumedResources:values[0]:tostring.
		local res is res:substring(17,res:length-17).
		global SolidFuelName is res:remove(res:length-1,1).
	}
}