//Initial script setup
clearscreen.
set terminal:width to 40. set terminal:height to 25.
runpath("0:/ChuteDescent_lib/ChuteDescent_lib.ks").
runpath("0:/GeneralLibrary/FuelCells.ks").
runpath("0:/GeneralLibrary/Resources.ks").
SAS off. RCS on. Brakes on.
lock steering to ship:srfretrograde.
lock entryTime to time:seconds.
on sas { sas off. preserve. }

//Variables creation
set chuteMaxQ to 20000.		//340m/s
set drogueMaxQ to 30000.	//880m/s
set runmode to 0.
lock descentSpeed to ship:velocity:surface:mag.
lock descentTime to time:seconds - entrytime.

//Resources
set rcsFuelName to RCS_Resource().
set batteryCapacity to Resource_Capacity("electriccharge").
lock EC to ship:electriccharge / batteryCapacity * 100.
if rcsFuelName = false {
	set rcsFuel to 0.
} else {
	lock rcsFuel to Resource_Remaining(rcsFuelName) / Resource_Capacity(rcsFuelName) * 100.
}

//HUD Initialisation
set shipStatus to "Re-entry".
set chuteStatus to "-".
set drogueStatus to "-".

//Detect if ship has aborted
if alt:radar < ship:body:atm:height/2 {
	set abortMode to true.
} else {
	set abortMode to false.
}

//Part list creation for different parachute modules
set ChuteList to list(). set DrogueList to list().
for p in ship:parts {
	if p:hasmodule("ModuleParachute") {
		if p:title:contains("Drogue") {
			DrogueList:add(p).
			p:getmodule("ModuleParachute"):setfield("altitude",5000).
			p:getmodule("ModuleParachute"):setfield("min pressure",0.01).
		} else {
			ChuteList:add(p).
			p:getmodule("ModuleParachute"):setfield("altitude",1000).
			p:getmodule("ModuleParachute"):setfield("min pressure",0.01).
		}
	}
}

if chuteList:length > 0 or DrogueList:length > 0 {

	set runmode to 1.
	print "Awaiting Entry Interface" at (0,0).
	wait until ship:altitude < body:atm:height and ship:verticalspeed < 0. 
	set entryTime to time:seconds.
	if abortMode = false {
		set dyPrTime to 0.
		set dyPr to ship:Q * constant:atmtokpa * 1000.
		until dynamicPressureTracker(dyPr) = "Increasing" { chuteHUD(). fuelCellControl(). chuteStatusTracker(). wait 0.01. }
		until dynamicPressureTracker(dyPr) = "Decreasing" { chuteHUD(). fuelCellControl(). chuteStatusTracker(). wait 0.01. }
	}

	//Drogue Deploy
	if DrogueList:length > 0 {
		set shipStatus to "Awaiting Drogue Deploy".
		until Body:atm:altitudepressure(ship:altitude) > 0.02 and ship:Q*constant:atmtokpa*1000 < drogueMaxQ { chuteHUD(). fuelCellControl(). chuteStatusTracker(). wait 0.01. }
		until alt:radar < 10000 or (ship:Q*constant:atmtokpa*1000)*1.1 > drogueMaxQ and dynamicPressureTracker(dyPr) = "Increasing" { chuteHUD(). fuelCellControl(). chuteStatusTracker(). wait 0.01. }
		if DrogueList:length > 0 {
			for p in DrogueList {
				p:getmodule("ModuleParachute"):setfield("altitude",ship:altitude+1000).
				p:getmodule("ModuleParachute"):doaction("deploy chute",true).
			}
			set runmode to 2.
		}
		RCS off.
		unlock steering.
	} else {
		set runmode to 2.
	}

	//Descent under Drogues - will advance to mains early if it thinks drogues are deployed, dynamic pressure is still rising and its close to unsafe mains threshold
	if runmode = 2 {
		if DrogueList:length > 0 {
			set shipStatus to "Drogue chutes Deployed".
		} else {
			set shipStatus to "Awaiting Chute Deploy".
		}
		until alt:radar < 1050 or (ship:Q*constant:atmtokpa*1000)*1.1 > chuteMaxQ and dynamicPressureTracker(dyPr) = "Increasing" { chuteHUD(). fuelCellControl(). chuteStatusTracker(). wait 0.01. }
		set runmode to 3.
	}

	//Mains deploy
	if runmode = 3 {
		if ChuteList:length > 0 {
			set shipStatus to "Awaiting Chute Deploy".
			until Body:atm:altitudepressure(ship:altitude) > 0.01 and ship:Q*constant:atmtokpa*1000 < chuteMaxQ { chuteHUD(). fuelCellControl(). chuteStatusTracker(). wait 0.01. }
			if DrogueList:length > 0 {
				From {local x is DrogueList:length-1.} until x < 0 step { set x to x - 1. } Do {
					DrogueList[x]:getmodule("ModuleParachute"):doevent("cut parachute").
					DrogueList:remove(x).
				}
			}
			for p in ChuteList {
				p:getmodule("ModuleParachute"):doaction("deploy chute",true).
			}
			set shipStatus to "Chute controlled descent".
			set runmode to 4.
		} else {
			set runmode to 4.
		}
	}

	//Final descent
	if runmode = 4 {
		until ship:status = "LANDED" or ship:status = "SPLASHED" { chuteHUD(). fuelCellControl(). chuteStatusTracker(). wait 0.01. }
	}

	RCS off. unlock all. wait 5.
	print "                                       " at (0,0).
} else {
	print "No Chutes detected on Vessel" at (0,0).
	print "Script will remain active until Impact" at (0,1).
	wait until ship:status = "LANDED" or ship:status = "SPLASHED".
}	