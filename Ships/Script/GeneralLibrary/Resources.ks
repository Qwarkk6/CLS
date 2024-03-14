// Use to set a Capacity Variable for a resource
function Resource_Capacity {
	parameter resName.
	list resources in resList.
	For res in resList {
		If res:Name = resName {
			return Res:Capacity. break.
		}
	}
	return false.
}

// Use to return amount of a resource 
function Resource_Remaining {
	parameter resName.
	list resources in resList.
	For res in resList {
		If res:Name = resName {
			return Res:amount. break.
		}
	}
	return false.
}

//Finds one of the resources required for on board RCS systems
function RCS_Resource {
	local rcsList is ship:rcs.
	if rcsList:length > 0 {
		for rcs in rcsList {
			if rcs:enabled {
				return rcs:consumedresources:keys[0]. break.
			}
		}
	}
	return false.
}

//Finds one of the resources required for on board RCS systems
function Active_Resource {
	parameter templist is ship:engines.
	if templist:length > 0 {
		for e in templist {
			if e:ignition {
				local rname is e:consumedResources:values[0]:tostring.
				local rname is rname:substring(17,rname:length-17).
				return rname:remove(rname:length-1,1).
			}
		}
	}
	return false.
}