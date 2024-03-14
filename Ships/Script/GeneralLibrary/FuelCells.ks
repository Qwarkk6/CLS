function fuelCellControl {
	if fuelCellList:length > 0 {
		if EC < 15 and fuelCellStatus = "Inactive" {
			for p in fuelCellList {
				set fuelCellStatus to "Active".
				p:getmodule("ModuleResourceConverter"):doaction("start fuel cell",true).
			}
		}
		if EC > 75 and fuelCellStatus = "Active" {
			for p in fuelCellList {
				set fuelCellStatus to "Inactive".
				p:getmodule("ModuleResourceConverter"):doaction("stop fuel cell",false).
			}
		}
	}
}	

//Detect fuel cells
set fuelCellList to list().
for p in ship:parts {
	if p:hasmodule("ModuleResourceConverter") {
		fuelCellList:add(p).
	}
}
if fuelCellList:length = 0 {
	set fuelCellStatus to "No Fuel Cells Detected".
} else {
	set fuelCellStatus to "Inactive".
}

//Detect whether fuel cells are active or inactive
for p in fuelCellList {
	if p:getmodule("ModuleResourceConverter"):hasevent("stop fuel cell") {
		set fuelCellStatus to "Active".
	}
} 

//if one is active, make all active
if fuelCellStatus = "Active" {
	for p in fuelCellList {
		p:getmodule("ModuleResourceConverter"):doaction("start fuel cell",true).
	}
}
