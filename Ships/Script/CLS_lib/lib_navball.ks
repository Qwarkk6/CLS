// lib_navball.ks - A library of functions to calculate navball-based directions.
// Copyright © 2015,2017,2019 KSLib team 
// Lic. MIT

// This library of functions is taken from the KSLib - a community supported standard library for Kerboscript language. 
// I have adapted the work below for my needs, and removed some functions that were not necessary for CLS to run.
// The KSLib team have built an incrible library of Kerboscript, available at https://github.com/KSP-KOS/KSLib

@lazyglobal off.

//Finds east 
function east_for {
  parameter ves.

  return vcrs(ves:up:vector, ves:north:vector).
}

//Finds current compass heading 
function compass_for {
  parameter ves.

  local pointing is ves:facing:forevector.
  local east is east_for(ves).

  local trig_x is vdot(ves:north:vector, pointing).
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
  parameter ves.

  return 90 - vang(ves:up:vector, ves:facing:forevector).
}

//Finds current roll
function roll_for {
	parameter ves.

	local raw is ves:facing:roll.
	if raw > 360 {
		return raw-360.
	} else {
		return raw.
	}
}