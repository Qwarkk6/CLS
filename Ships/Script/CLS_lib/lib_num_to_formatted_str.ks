// lib_num_to_formatted_str.ks provides several functions for changing numbers (scalers) into strings with specified formats
// Copyright © 2018,2019,2020 KSLib team 
// Lic. MIT

// This library of functions is taken from the KSLib - a community supported standard library for Kerboscript language. 
// I have removed some functions that were not necessary for CLS to run.
// The KSLib team have built an incrible library of Kerboscript, available at https://github.com/KSP-KOS/KSLib

FUNCTION padding {
	PARAMETER num,                // number to be formatted
	leadingLength,                // minimum digits to the left of the decimal
	trailingLength,               // digits to the right of the decimal
	positiveLeadingSpace IS TRUE, // whether to prepend a single space to the output
	roundType IS 0.               // 0 for normal rounding, 1 for floor, 2 for ceiling

	LOCAL returnString IS "".
	//LOCAL returnString IS ABS(ROUND(num,trailingLength)):TOSTRING.
	IF roundType = 0 {
		SET returnString TO ABS(ROUND(num,trailingLength)):TOSTRING.
	} ELSE IF roundType = 1 {
		SET returnString TO ABS(adv_floor(num,trailingLength)):TOSTRING.
	} ELSE {
		SET returnString TO ABS(adv_ceiling(num,trailingLength)):TOSTRING.
	}

	IF trailingLength > 0 {
		IF NOT returnString:CONTAINS(".") {
			SET returnString TO returnString + ".0".
		}
		UNTIL returnString:SPLIT(".")[1]:LENGTH >= trailingLength { SET returnString TO returnString + "0". }
		UNTIL returnString:SPLIT(".")[0]:LENGTH >= leadingLength { SET returnString TO "0" + returnString. }
	} ELSE {
		UNTIL returnString:LENGTH >= leadingLength { SET returnString TO "0" + returnString. }
	}

	IF num < 0 {
		RETURN "-" + returnString.
	} ELSE {
		IF positiveLeadingSpace {
			RETURN " " + returnString.
		} ELSE {
			RETURN returnString.
		}
	}
}

LOCAL FUNCTION adv_floor {
	PARAMETER num,dp.
	LOCAL multiplier IS 10^dp.
	RETURN FLOOR(num * multiplier)/multiplier.
}

LOCAL FUNCTION adv_ceiling {
	PARAMETER num,dp.
	LOCAL multiplier IS 10^dp.
	RETURN CEILING(num * multiplier)/multiplier.
}