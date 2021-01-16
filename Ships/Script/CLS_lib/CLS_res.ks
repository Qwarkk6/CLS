// CLS_res.ks - A library of functions specific to resource calculation / identification in the CLS (Common Launch Script)
// Copyright © 2021 Qwarkk6
// Lic. CC-BY-SA-4.0 

@lazyglobal off.

// checks if a resource is above a specified threshold
Function ResourceCheck {
	Parameter CheckRes.
	Parameter Threshold.
	For Res in ship:resources {
		If Res:Name = CheckRes {
			If (Res:Amount/Res:Capacity) <= Threshold {
				return false.
			} else {
				return true.
			}
		}
	}
}

// Detects the fuel capacity of a given partlist
Function PartlistFuelCapacity {
	Parameter plist.
	Parameter rname.
	local fuelcap is 0.
	For tank in plist {
		For res in tank:resources {
			if res:name = rname and res:enabled = true {
				set fuelcap to (fuelcap + res:amount).
			}
		}
	}
	Return fuelcap.
}

// Detects the percentage of fuel remaining in a given partlist
Function PartlistFuelPercent {
	Parameter plist.
	Parameter rname.
	Parameter fuelcap is 0.
	local fuelrem is 0.
	If fuelcap = 0 {
		For tank in plist {
			For res in tank:resources {
				if res:name = rname and res:enabled = true {
					set fuelcap to (fuelcap + res:capacity).
					set fuelrem to (fuelrem + res:amount).
				}
			}
		}
	} else {
		For tank in plist {
			For res in tank:resources {
				if res:name = rname and res:enabled = true {
					set fuelrem to (fuelrem + res:amount).
				}
			}
		}
	}
	Return (((fuelrem+0.01)/(fuelcap+0.01))*100).
}

// Identifies the fuel tanks(s) providing fuel for the stage. First creates a list of all fuel tanks and the stage they are assocated with. Then compares the associated stages to find the tanks(s) associated with the largest/current stage.
Function FuelTank {	
	Parameter rname.
	MFT[0]:clear(). MFT[1]:clear(). MFT[2]:clear(). stagetanks:clear().
	for tank in ship:parts {
		for res in tank:resources {
			if res:name = rname and res:amount > 1 and res:enabled = true {
				MFT[0]:add(tank).
			}
		}
	}
	for p in MFT[0] {
		MFT[1]:add(p:stage).
		MFT[2]:add(p:stage).
	}
	Until MFT[2]:length = 1 {
		if MFT[2][0] <= MFT [2][1] {
			MFT[2]:remove(0).
		} else if MFT[2][0] >= MFT[2][1] {
			MFT[2]:remove(1).
		}
	}	
	until MFT[0]:length = 0 {
		if MFT[1][0] = MFT[2][0] {
			stagetanks:add(MFT[0][0]).
			MFT[0]:remove(0).
			MFT[1]:remove(0).
		} else {
			MFT[0]:remove(0).
			MFT[1]:remove(0).
		}
	}
}

// Identifies the fuel tanks(s) providing fuel for the stage. First creates a list of all fuel tanks and the stage they are assocated with. Then compares the associated stages to find the tanks(s) with the most amount of a given fuel type.
Function FuelTankUpper {	
	Parameter rname.
	MFT[0]:clear(). MFT[1]:clear(). MFT[2]:clear(). stagetanks:clear().
	for tank in ship:parts {
		for res in tank:resources {
			if res:name = rname and res:amount > 1 and res:enabled = true {
				MFT[0]:add(tank).
				MFT[1]:add(res:amount).
				MFT[2]:add(res:amount).
			}
		}
	}
	Until MFT[2]:length = 1 {
		if MFT[2][0] <= MFT [2][1] {
			MFT[2]:remove(0).
		} else if MFT[2][0] >= MFT[2][1] {
			MFT[2]:remove(1).
		}
	}	
	until MFT[0]:length = 0 {
		if MFT[1][0] = MFT[2][0] {
			stagetanks:add(MFT[0][0]).
			MFT[0]:remove(0).
			MFT[1]:remove(0).
		} else {
			MFT[0]:remove(0).
			MFT[1]:remove(0).
		}
	}
}