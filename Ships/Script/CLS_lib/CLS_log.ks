// CLS_twr.ks - A library of functions specific to calculating twr / throttle in the CLS (Common Launch Script)
// Copyright © 2021 Qwarkk6
// Lic. CC-BY-SA-4.0 

// Creates new log file for flight data
Function logInitialise {
	parameter apoapsis.
	parameter periapsis.
	parameter inclination.
	local year is (time:year):tostring().
	local day is (time:day):tostring().
	local hour is (time:hour):tostring().
	local minute is (time:minute):tostring().
	local vesselName is ship:name.
	local realTime is realWorldTime():tostring().
	if hour:length < 2 {
		set hour to "0" + hour.
	}
	if minute:length < 2 {
		set minute to "0" + minute.
	}
	local logname is "Y"+year+"_"+"D"+day+"_"+hour+"."+minute+"_"+vesselName+"_"+realTime.
	global logpath is path("0:/CLS_lib/logs/" + logname + ".csv").
	global missionTimeLog is 0.
	Log ("Apoapsis,"+(apoapsis/1000)+"km"+" Periapsis,"+(periapsis/1000)+"km"+" ,Inc,"+round(inclination,2)) to logPath.
	Log (" ") to logPath. 
	Log ("MET,vehicleConfig,dV,TWR,Throttle,Pitch,Q,Alt,Apoapsis,Eta:apo,Periapsis,Stage,Staging,Runmode,Parts,Peri Circ,Apo Circ,3burn Circ,Est Rem dV") to logPath.
}

// example use - log_data(LIST(newTime,newAlt,newVel:MAG,newDynamicP,dragForce,newAtmPressure,atmDencity*1000,dragCoef,thermalMassIsh,atmTemp,mach),logPath).
// Logs data from list to log file specified
function log_data {
	Parameter missiontime,logData,logpath.
	if missiontime > missionTimeLog {
		local logString is "".
		For data in logData {
			if (data):typename() = "String" or (data):typename() = "Boolean" {
				set logString to logString + data + ",".			//Rounds all scaler values to 2 sign numbers
			} else {
				set logString to logString + round(data,2) + ",".
			}
		}
		logString:remove((logString:length - 1),1).
		Log logString TO logpath.
		set missionTimeLog to missiontime+0.5.
	}
}