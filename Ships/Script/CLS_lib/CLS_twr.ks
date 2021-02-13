// CLS_twr.ks - A library of functions specific to calculating twr / throttle in the CLS (Common Launch Script)
// Copyright © 2021 Qwarkk6
// Lic. CC-BY-SA-4.0 

@lazyglobal off.

// determines acceleration due to gravity
Function adtg {
	return(constant:g*body:mass)/((body:radius+ship:altitude)^2).
}
	
// calculates twr based on mode
Function twr {
	if mode = 0 {
		return min(throttle,1)*((ship:availablethrust+0.1)/(ship:mass*adtg())).
	} else {
		return ((min(throttle,1)*(Partlistavthrust(aelist)+0.1))+PartlistCurThrust(SRBs))/(ship:mass*adtg()).
	}
}
	
// calculates maximum twr if all engines were at max thrust
Function maxtwr {
	return (Ship:availablethrust+0.1)/(ship:mass*adtg()).
}
	
// calculates throttle required to achieve a given TWR based on mode
Function twrthrottle {
	parameter targetTWR.
	if mode = 0 {
		return Max(0.01,Min(1,((ship:mass*adtg())/(ship:availablethrust+0.1))*targetTWR)).
	} else {
		return Max(0.01,Min(1,((ship:mass*adtg()*targetTWR)-PartlistCurThrust(SRBs))/partlistavthrust(aelist))).
	}
}
	
// calculates post SRB seperation throttle required to achieve a given TWR
Function srbsepthrottle {
	parameter targetTWR.
	return Max(0.01,Min(1,(((ship:mass-Partlistmass(SRBs))*adtg())/(partlistavthrust(aelist)+0.1))*targetTWR)).
}