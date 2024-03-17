//kOS terminal readouts
function chuteHUD {
	Print "Re-entry Procedure" at (0,0).
	Print "Status: " + shipStatus + " (" + runmode + ")               " at (0,1).
	Print "RCS Fuel: " + round(rcsFuel,2) + "% " at (0,2).
	Print "Battery:  " +  round(EC,2) + "%   " at (0,3).
	Print "------------------" at (0,4).
	Print "Dynamic Pressure: " + round(ship:Q*constant:atmtokpa*1000,2) + "Pa   " at (0,5).
	Print "Drogue Max-Q: " + round(drogueMaxQ,1) + "Pa   " at (0,6).
	Print "Chute Max-Q: " + round(chuteMaxQ,1) + "Pa   " at (0,7).
	Print "Alt Pressure: " + round(Body:atm:altitudepressure(ship:altitude),3) + "Atm   " at (0,8).
	Print "------------------" at (0,9).
	Print "Altitude: " + round(alt:radar,1) + "m   " at (0,10).
	Print "Descent Time: " + round(descentTime,1) + "s   " at (0,11).
	Print "Velocity: " + round(descentSpeed,2) + "m/s   " at (0,12).
	Print "------------------" at (0,13).
	Print "Drogue Status: " + drogueStatus + "        " at (0,14).
	Print "Chute Status: " + chuteStatus + "        " at (0,15).
	Print "Fuel Cell Status: " + fuelCellStatus + "      " at (0,16).
	if homeconnection:isconnected {
		Print "Signal Status: Connected" at (0,17).
	} else {
		Print "Signal Status: LoS      " at (0,17).
	}
	Print "------------------" at (0,18).
	Print "Drogue Chutes: " + DrogueList:length at (0,19).
	Print "Mains Chutes: " + ChuteList:length at (0,20).
}

//Tracks dynamic pressure to determine when chutes can be opened
function dynamicPressureTracker {
	parameter dyPr.

	if time:Seconds > dyPrTime {
		if ship:Q * constant:atmtokpa * 1000 < dyPr {
			global dyPr is ship:Q * constant:atmtokpa * 1000.
			global dyPrTime is time:seconds+0.5.
			return "Decreasing".
		} else {
			global dyPr is ship:Q * constant:atmtokpa * 1000.
			global dyPrTime is time:seconds+0.5.
			return "Increasing".
		}
	}
}

//Track status of all chutes on the vessel
function chuteStatusTracker {
	if ChuteList:length = 0 {
		set chuteStatus to "-".
	} else {
		for p in ChuteList {
			if p:getmodule("ModuleParachute"):allevents:join(","):contains("cut parachute") {
				set chuteStatus to "Deployed".
			}
		}
		if not chuteStatus:contains("Deployed") {
			if ship:Q*constant:atmtokpa*1000 > chuteMaxQ or ship:velocity:surface:mag > 340 {
				set chuteStatus to "Unsafe to deploy".
			} else {
				set chuteStatus to "Safe to deploy".
			}
		}
	}
	if DrogueList:length = 0 {
		set drogueStatus to "-".
	} else {
		for p in DrogueList {
			if p:getmodule("ModuleParachute"):allevents:join(","):contains("cut parachute") {
				set drogueStatus to "Deployed".
			} else if p:getmodule("ModuleParachute"):allevents:join(","):length = 0 {
				set drogueStatus to "Cut            ".
			}
		}
		if not drogueStatus:contains("Deployed") and not drogueStatus:contains("Cut            ") {
			if ship:Q*constant:atmtokpa*1000 > drogueMaxQ or ship:velocity:surface:mag > 880 {
				set drogueStatus to "Unsafe to deploy".
			} else {
				set drogueStatus to "Safe to deploy".
			}
		}
	}
}
	