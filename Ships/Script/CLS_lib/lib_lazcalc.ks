// lib_lazcalc.ks - provides the user with a launch azimuth based on a desired target orbit altitude and inclination and can continued to be used throughout ascent to update the heading. It bases this calculation on the vessel's launch and current geoposition.
// Copyright © 2015,2017 KSLib team 
// Lic. MIT

//~~Version 2.2~~
//~~Created by space-is-hard~~
//~~Updated by TDW89~~
//~~Auto north/south switch by undercoveryankee~~

// These functions are taken from the KSLib - a community supported standard library for Kerboscript language. 
// I have adapted the functions below slightly for use in CLS.
// The KSLib team have built an incrible library of Kerboscript, available at https://github.com/KSP-KOS/KSLib

// To use: set data to LAZcalc_init([desired circular orbit altitude in meters],[desired orbital inclination; negative if launching from descending node, positive otherwise]). Then loop SET myAzimuth TO LAZcalc(data).

@lazyglobal off.

Function LAZcalc_init {
    Parameter desiredAlt.		 	//Altitude of desired target orbit (in *meters*)
    Parameter desiredInc. 			//Inclination of desired target orbit
	
    local autoNodeEpsilon is 10. 		// How many m/s north or south will cause a north/south switch
    local launchLatitude is ship:latitude.
    local data is list().  			// A list is used to store information used by LAZcalc
    
    //Determines whether we're trying to launch from the ascending or descending node
    local launchNode is "Ascending".
    if desiredInc < 0 {
	set launchNode to "Descending".
        set desiredInc to abs(desiredInc).       //We'll make it positive for now and convert to southerly heading later
    }
	
    //Does all the one time calculations and stores them in a list to help reduce the overhead or continuously updating
    local equatorialVel is (2 * constant():pi * body:radius) / body:rotationPeriod.
    local targetOrbVel is sqrt(body:mu/ (body:radius + desiredAlt)).
    data:add(desiredInc).       //[0]
    data:add(launchLatitude).   //[1]
    data:add(equatorialVel).    //[2]
    data:add(targetOrbVel).     //[3]
    data:add(launchNode).       //[4]
    data:add(autoNodeEpsilon).  //[5]
    return data.
}

Function LAZcalc {
    Parameter data.		//list created by LAZcalc_init
    local inertialAzimuth is arcsin(max(min(cos(data[0]) / cos(ship:latitude), 1), -1)).
    local VXRot is data[3] * sin(inertialazimuth) - data[2] * cos(data[1]).
    local VYRot is data[3] * cos(inertialazimuth).
    
    //This clamps the result to values between 0 and 360.
    local azimuth is mod(arctan2(VXRot, VYRot) + 360, 360).

    local NorthComponent is vdot(ship:velocity:orbit, ship:north:vector).
    if NorthComponent > data[5] {
        set data[4] TO "Ascending".
    } else if NorthComponent < -data[5] {
        set data[4] to "Descending".
    }
	    
    //Returns azimuth based on the ascending node
    if data[4] = "Ascending" {
        return azimuth.
    } else if data[4] = "Descending" {
        if azimuth <= 90 {
            return 180 - azimuth.   
        } else if azimuth >= 270 {
            return 540 - azimuth.
        } else {
			return azimuth.
		}
    }
}