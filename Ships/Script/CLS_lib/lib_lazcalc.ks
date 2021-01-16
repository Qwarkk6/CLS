// lib_lazcalc.ks - provides the user with a launch azimuth based on a desired target orbit altitude and inclination and can continued to be used throughout ascent to update the heading. It bases this calculation on the vessel's launch and current geoposition.
// Copyright © 2015,2017 KSLib team 
// Lic. MIT

// This library of functions is taken from the KSLib - a community supported standard library for Kerboscript language. 
// I have adapted the work below for my needs, and removed some functions that were not necessary for CLS to run.
// The KSLib team have built an incrible library of Kerboscript, available at https://github.com/KSP-KOS/KSLib

@lazyglobal off.

//Launch Azimuth Calculation
Function LaunchAzm {
	Parameter tapoapsis.
	Parameter tinclination.
	Parameter tuning.
	
	Local autoNodeSwitch is 10.
	Local NorthComponent is Vdot(Ship:velocity:orbit, Ship:north:vector).
	Local EastComponent is Vdot(Ship:velocity:orbit, east_for(ship)).
	if tinclination >= 0 or NorthComponent > autoNodeSwitch {
		Global launchNode is "Ascending".
	} else if tinclination < 0 or NorthComponent < -autoNodeSwitch {
		Global launchNode is "Descending".
	}
	
	If EastComponent > autoNodeSwitch {
		Global launchDir is "East".
	} else if EastComponent < -autoNodeSwitch {
		Global launchDir is "West".
	}
	
	Local targetorbSMA is tapoapsis + Ship:body:radius.													// Semi-major axis of the desired target orbit
	Local targetorbVel is Sqrt(Ship:body:Mu / targetorbSMA).											// Orbital velocity of the desired target orbit
	Local equatorialvel is (2 * constant():Pi * body:radius) / body:rotationperiod.						// Velocity of the planet's equator
	Local inertialazimuth is Arcsin(max(min(Cos(ABS(tinclination)) / Cos(launchloc:lat),1),-1)). 		// Launch azimuth before taking into account the rotation of the planet
	Local VYrot is targetorbVel * Cos(inertialazimuth).
	
	if tuning = "Ascent" {
		Global VXrot is (targetorbvel*Sin(inertialazimuth))-(equatorialvel*Cos(ABS(launchloc:lat)))*Cos(launchloc:lat).
		Global azimuth is Mod(Arctan2(VXrot, VYrot) + 360, 360).													// Launch azimuth after taking into account the rotation of the planet
	} else if tuning = "Fine" {
		Global azimuth is compass_for_vect(ship,ship:prograde:forevector).
	}
	if launchDir = "West" {
		Global azimuth is ABS(azimuth-360).
	}
	
	If launchNode = "Ascending" {
		Return azimuth.
	} else if launchNode = "Descending" {
		if azimuth <= 90 {
			Return 180 - azimuth.
		} else if azimuth >= 270 {
			Return 540 - azimuth.
		} else {
			Return azimuth.
		}
	}
}