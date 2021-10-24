//kOS terminal readouts
function HUD {
	Print "Re-entry Procedure" at (0,0).
	Print "Status: " + shipStat + "                    " at (0,1).
	Print "RCS: " + padding(rcsFuel,2,1,false) + "% | EC: " +  padding(EC,2,1,false) + "%   " at (0,2).
	Print "------------------" at (0,3).
	Print "Dynamic Pressure: " + padding(shipDynamicPressure,5,1,false) + "Pa   " at (0,4).
	Print "Drogue Max-Q: " + padding(drogueMaxQ,5,1,false) + "Pa   " at (0,5).
	Print "Chute Max-Q: " + padding(chuteMaxQ,5,1,false) + "Pa   " at (0,6).
	Print "------------------" at (0,7).
	Print "Altitude: " + padding(alt:radar,4,1,false) + "m   " at (0,8).
	Print "Descent Time: " + padding(descentTime,3,1,false) + "s   " at (0,9).
	Print "Remaining Time: " + padding(max(impactTime,0),3,1,false) + "s        " at (0,10).
	Print "Descent Speed: " + padding(descentSpeed,3,1,false) + "m/s   " at (0,11).
	Print "------------------" at (0,12).
	Print "Drogue Status: " + drogueStatus + "        " at (0,13).
	Print "Chute Status: " + chuteStatus + "        " at (0,14).
	Print "Fuel Cell Status: " + fuelCellStatus + "      " at (0,15).
	if homeconnection:isconnected {
		Print "Signal Status: Connected" at (0,16).
	} else {
		Print "Signal Status: LoS      " at (0,16).
	}
}

//Main calculations
function Calculations {
	set shipDynamicPressure to ship:Q * constant:atmtokpa * 1000.
	if ship:altitude < body:atm:height and ship:verticalspeed < 0 {
		set descentSpeed to ship:velocity:surface:mag.
		set descentTime to time:seconds - entrytime.
		set impactDistance to (ship:altitude-ship:geoposition:terrainheight)*(SIN(90)/SIN(pitch_for_vector(ship:srfretrograde:vector))).
		set impactTime to impactDistance / descentSpeed.
	} else {
		set descentTime to 0.
		set descentSpeed to 0.
		set impactTime to 0.
	}
}

//Resource monitoring
function ResourceTracker {	
	For res in ship:resources {
		If res:Name = "ElectricCharge" {
			set EC to (Res:Amount/Res:Capacity)*100.
		}
		if res:Name = "Aerozine50" {
			set rcsFuel to (Res:Amount/Res:Capacity)*100.
		}
	}
	if fuelCellList:length > 0 {
		if EC < 15 and fuelCellStatus = "Inactive" {
			for p in fuelCellList {
				set fuelCellStatus to "Active".
				p:getmodule("ModuleResourceConverter"):doevent("start fuel cell").
			}
		}
	}		
} 

//Tracks dynamic pressure to determine when chutes can be opened
function dynamicPressureTracker {
	parameter dynamicPressure.
	
	if dynamicPressure = 99999999 {
		global dynamicPressure is ship:Q * constant:atmtokpa * 1000.
	}
	if time:Seconds > dynamicPressureTime {
		if ship:Q * constant:atmtokpa * 1000 < dynamicPressure {
			return true.
		} else {
			global dynamicPressure is ship:Q * constant:atmtokpa * 1000.
			global dynamicPressureTime is time:seconds+0.2.
			return false.
		}
	} 
}