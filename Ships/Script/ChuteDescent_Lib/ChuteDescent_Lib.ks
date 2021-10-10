//kOS terminal readouts
function ReentryHUD {
	Print "Re-entry Procedure" at (0,0).
	Print "Status: " + shipStat + "                    " at (0,1).
	Print "RCS: " + padding(rcsFuel,2,1,false) + "% | EC: " +  padding(EC,2,1,false) + "%   " at (0,2).
	Print "------------------" at (0,3).
	Print "Dynamic Pressure: " + padding(shipQ,5,1,false) + "Pa   " at (0,4).
	Print "Drogue Max-Q: " + padding(drogueMaxQ,5,1,false) + "Pa   " at (0,5).
	Print "Chute Max-Q: " + padding(chuteMaxQ,5,1,false) + "Pa   " at (0,6).
	Print "------------------" at (0,7).
	Print "Altitude: " + padding(alt:radar,4,1,false) + "m   " at (0,8).
	Print "Descent Time: " + padding(dt,3,1,false) + "s   " at (0,9).
	if addons:tr:hasimpact {
		Print "Remaining Time: " + padding(addons:tr:timetillimpact,3,1,false) + "s        " at (0,10).
	} else {
		Print "Remaining Time: Calcualting...     " at (0,10).
	}
	Print "Descent Speed: " + padding(descentSpeed,3,1,false) + "m/s   " at (0,11).
	Print "------------------" at (0,12).
	Print "Drogue Status: " + drogueStat + "        " at (0,13).
	Print "Chute Status: " + chuteStat + "        " at (0,14).
	Print "Fuel Cell Status: " + FCStatus + "      " at (0,15).
	if homeconnection:isconnected {
		Print "Signal Status: Connected" at (0,16).
	} else {
		Print "Signal Status: LoS      " at (0,16).
	}
}

//Main calculations
function ReentryCalc {
	set shipQ to ship:Q * constant:atmtokpa * 1000.
	if ship:altitude < body:atm:height and ship:verticalspeed < 0 {
		set descentSpeed to ship:velocity:surface:mag.
		set dt to time:seconds - entrytime.
	} else {
		set dt to 0.
		set descentSpeed to 0.
	}
}

//Resource monitoring
function ReentryResMonitor {	
	For res in ship:resources {
		If res:Name = "ElectricCharge" {
			set EC to (Res:Amount/Res:Capacity)*100.
		}
		if res:Name = "Aerozine50" {
			set rcsFuel to (Res:Amount/Res:Capacity)*100.
		}
	}
	if fuelCellList:length > 0 {
		if EC < 15 and FCStatus = "Inactive" {
			for p in fuelCellList {
				set FCStatus to "Active".
				p:getmodule("ModuleResourceConverter"):doevent("start fuel cell").
			}
		}
	}		
} 

//whether Q is increasing or decreasing
function shipQtest {
	parameter shipQ1.
	
	if shipQ1 = 99999999 {
		global shipQ1 is ship:Q * constant:atmtokpa * 1000.
	}
	if time:Seconds > shipQt {
		if ship:Q * constant:atmtokpa * 1000 < shipQ1 {
			return true.
		} else {
			global shipQ1 is ship:Q * constant:atmtokpa * 1000.
			global shipQt is time:seconds+0.2.
			return false.
		}
	} 
}