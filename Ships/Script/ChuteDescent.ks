//Initial script setup
clearscreen.
set terminal:width to 40. set terminal:height to 25.
runpath("0:/CLS_lib/lib_num_to_formatted_str.ks").
runpath("0:/ChuteDescent_lib/ChuteDescent_lib.ks").
runpath("0:/CLS_lib/lib_navball.ks").
runpath("0:/CLS_lib/CLS_nav.ks").
runpath("0:/FuelCell_Lib.ks").
SAS off. RCS on. Brakes on.
lock steering to ship:srfretrograde.
lock entryTime to time:seconds.
set scriptStatus to "Running".
on sas { sas off. preserve. }

//Variables creation
set chuteMaxQ to 20000.		//340m/s
set drogueMaxQ to 30000.	//880m/s
set dyPr to 99999999.
set dyPrTime to 0.

//HUD Initialisation
print "Awaiting Free-fall" at (0,0).
set shipStatus to "Re-entry".
set chuteStatus to "-".
set drogueStatus to "-".
set runmode to 0.

//Detect if ship has aborted
if alt:radar < ship:body:atm:height/2 {
	set abortMode to true.
} else {
	set abortMode to false.
}

//Part list creation for different parachute modules
set stockChuteList to list(). set stockDrogueList to list().
for p in ship:parts {
	if p:hasmodule("ModuleParachute") {
		if p:title:contains("Drogue") {
			stockDrogueList:add(p).
			set drogueStatus to "Unsafe to deploy".
			p:getmodule("ModuleParachute"):setfield("altitude",5000).
			p:getmodule("ModuleParachute"):setfield("min pressure",0.01).
		} else {
			stockChuteList:add(p).
			set chuteStatus to "Unsafe to deploy".
			p:getmodule("ModuleParachute"):setfield("altitude",1000).
			p:getmodule("ModuleParachute"):setfield("min pressure",0.01).
		}
	}
}

when scriptStatus = "Running" then {
	chuteResourceTracker(). Calculations(). ECmonitor(). chuteHUD(). fuelCellControl().
	if warp > 2 {
		set warp to 2.
	}
	return true.
}

wait until ship:altitude < body:atm:height and ship:verticalspeed < 0. 
set entryTime to time:seconds.
if abortMode = false {
	wait until dynamicPressureTracker(dyPr) = "Increasing".
	wait until dynamicPressureTracker(dyPr) = "Decreasing".
}

//Drogue Deploy
if stockDrogueList:length > 0 {
	set shipStatus to "Awaiting Drogue Deploy".
	wait until Body:atm:altitudepressure(ship:altitude) > 0.02 and ship:Q*constant:atmtokpa*1000 < drogueMaxQ.
	wait until alt:radar < 10000 or (ship:Q*constant:atmtokpa*1000)*1.1 > drogueMaxQ and dynamicPressureTracker(dyPr) = "Increasing".
	if stockDrogueList:length > 0 {
		for p in stockDrogueList {
			p:getmodule("ModuleParachute"):setfield("altitude",ship:altitude+1000).
			p:getmodule("ModuleParachute"):doaction("deploy chute",true).
		}
		set runmode to 1.
	}
	RCS off.
	unlock all.
	set drogueStatus to "Deployed".
} else {
	set runmode to 1.
}

//Descent under Drogues - will advance to mains early if it thinks drogues are deployed, dynamic pressure is still rising and its close to unsafe mains threshold
if runmode = 1 {
	if stockDrogueList:length > 0 {
		set shipStatus to "Drogue chutes Deployed".
	}
	wait until alt:radar < 1050 or (ship:Q*constant:atmtokpa*1000)*1.1 > chuteMaxQ and dynamicPressureTracker(dyPr) = "Increasing".
	set runmode to 2.
}

//Mains deploy
if runmode = 2 {
	if stockChuteList:length > 0 {
		set shipStatus to "Awaiting Chute Deploy".
		wait until Body:atm:altitudepressure(ship:altitude) > 0.01 and ship:Q*constant:atmtokpa*1000 < chuteMaxQ.
		for p in stockChuteList {
			p:getmodule("ModuleParachute"):doaction("deploy chute",true).
		}
		set chuteStatus to "Deployed".
		set shipStatus to "Chute controlled descent".
		set runmode to 3.
	} else {
		set runmode to 3.
	}
}

//Final descent
if runmode = 3 {
	if stockDrogueList:length > 0 and stockChuteList:length > 0 {
		until stockDrogueList:length = 0 {
			if alt:radar < 1050 {
				stockDrogueList[0]:getmodule("ModuleParachute"):doevent("cut parachute").
				stockDrogueList:remove(0).
			}
		}
		set drogueStatus to "Cut               ".
	}
	wait until ship:status = "LANDED" or ship:status = "SPLASHED".
}

RCS off. unlock all.
print "                                       " at (0,0).