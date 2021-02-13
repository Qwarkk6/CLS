// CLS_twr.ks - A library of functions specific to calculating twr / throttle in the CLS (Common Launch Script)
// Copyright © 2021 Qwarkk6
// Lic. CC-BY-SA-4.0 

// Creates new log file for flight data
Function logInitialise {
	parameter apo.
	parameter inc.
	local logcount is 0.
	local y is (time:year):tostring().
	local d is (time:day):tostring().
	local h is (time:hour):tostring().
	local m is (time:minute):tostring().
	local n is ship:name.
	local logname is "Y"+y+"."+"D"+d+"_"+h+"."+m+"_"+n.
	until not exists(path("0:/logs/" + logname + " (" + logcount + ").csv")) {
		set logcount to logcount + 1.
	}
	global logpath is path("0:/logs/" + logname + " (" + logcount + ").csv").
	global pmt is 0.
	Log ("Apoapsis,"+(apo/1000)+"km"+" ,Inc,"+round(inc,2)) to logPath.
	Log (" ") to logPath. 
	Log ("MET,Mode,dV,TWR,Throttle,Pitch,Q,Alt,Apoapsis,Eta:apo,Periapsis,Stage,Staging,Runmode,Parts") to logPath.
}

// example use - log_data(LIST(newTime,newAlt,newVel:MAG,newDynamicP,dragForce,newAtmPressure,atmDencity*1000,dragCoef,thermalMassIsh,atmTemp,mach),logPath).
// Logs data from list to log file specified
function log_data {
	Parameter mt,logData,logpth.
	if mt > pmt {
		local logString is "".
		For data in logData {
			if (data):typename() = "String" or (data):typename() = "Boolean" {
				set logString to logString + data + ",".
			} else {
				set logString to logString + round(data,2) + ",".
			}
		}
		logString:remove((logString:length - 1),1).
		Log logString TO logpth.
		set pmt to missiontime+0.5.
	}
}