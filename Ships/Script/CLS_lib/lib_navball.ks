// lib_navball.ks - A library of functions to calculate navball-based directions.
// Copyright © 2015,2017,2019 KSLib team 
// Lic. MIT

// This library of functions is taken from the KSLib - a community supported standard library for Kerboscript language. 
// I have adapted the work below for my needs, and removed some functions that were not necessary for CLS to run.
// The KSLib team have built an incrible library of Kerboscript, available at https://github.com/KSP-KOS/KSLib

@lazyglobal off.

//Finds east 
function east_for {
  return vcrs(ship:up:vector, ship:north:vector).
}

//Finds current compass heading 
function compass_for {
  local pointing is ship:facing:forevector.
  local east is east_for().
  local trig_x is vdot(ship:north:vector, pointing).
  local trig_y is vdot(east, pointing).
  local result is arctan2(trig_y, trig_x).

  if result < 0 { 
    return 360 + result.
  } else {
    return result.
  }
}

//Finds current pitch
function pitch_for {
  return 90 - vang(ship:up:vector, ship:facing:forevector).
}

//Finds current roll
function roll_for {
	local r is ship:facing:roll.
	if r > 360 {
		return r-360.
	} else {
		return r.
	}
}