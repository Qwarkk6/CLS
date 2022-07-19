// lib_num_to_formatted_str.ks provides several functions for changing numbers (scalers) into strings with specified formats
// Copyright © 2018,2019,2020 KSLib team 
// Lic. MIT

// This library of functions is taken from the KSLib - a community supported standard library for Kerboscript language. 
// I have removed some functions that were not necessary for CLS to run.
// The KSLib team have built an incrible library of Kerboscript, available at https://github.com/KSP-KOS/KSLib

function padding {
	Parameter num.               			// number to be formatted
	Parameter leadingLength.                // minimum digits to the left of the decimal
	Parameter trailingLength.               // digits to the right of the decimal
	Parameter positiveLeadingSpace is true. // whether to prepend a single space to the output
	Parameter roundType is 0.               // 0 for normal rounding, 1 for floor, 2 for ceiling

	Local returnString is "".
	If roundType = 0 {
		set returnString to ABS(round(num,trailingLength)):tostring.
	} else if roundType = 1 {
		set returnString to ABS(adv_floor(num,trailingLength)):tostring.
	} else {
		set returnString to ABS(adv_ceiling(num,trailingLength)):tostring.
	}
	
	if num < 0 {
		set leadingLength to leadingLength-1.
	}

	If trailingLength > 0 {
		If not returnString:CONTAINS(".") {
			set returnString to returnString + ".0".
		}
		until returnString:split(".")[1]:length >= trailingLength { set returnString to returnString + "0". }
		until returnString:split(".")[0]:length >= leadingLength { set returnString to "0" + returnString. }
	} else {
		until returnString:length >= leadingLength { set returnString to "0" + returnString. }
	}

	If num < 0 {
		return "-" + returnString.
	} else {
		If positiveLeadingSpace {
			return " " + returnString.
		} else {
			return returnString.
		}
	}
}

Local function adv_floor {
	Parameter num.
	Parameter dp.
	Local multiplier is 10^dp.
	return Floor(num * multiplier)/multiplier.
}

Local function adv_ceiling {
	Parameter num.
	Parameter dp.
	Local multiplier is 10^dp.
	return CEILING(num * multiplier)/multiplier.
}

//Converts number with an exponent (eg 5.413E-12) to a decimal string
function expDecimal {
	parameter number.
	parameter rounding is 0.
	
	local n is number:tostring.
	if n:contains("E-") {
		global output is "0.".
		local decimalPlaces is n:remove(0,n:find("E-")+2).
		set n to n:remove(n:find("E-"),2+n:remove(0,n:find("E-")+2):length).
		set n to n:remove(n:find("."),1).
		
		until output:length = decimalPlaces:tonumber()+1 {
			set output to output:insert(output:length,"0").
			wait 0.001.
		}
		set output to output:insert(output:length,n).
		if rounding > 0 {
			set output to output:remove(2+rounding,output:length-(2+rounding)).
		}
	} else {
		global output is number.
		if rounding > 0 {
			set output to floor(output,rounding).
		}
	}
	return output.
}