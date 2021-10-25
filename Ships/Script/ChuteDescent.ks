//Initial script setup
clearscreen.
runpath("0:/cls_lib/lib_num_to_formatted_str.ks").
runpath("0:/ChuteDescent_Lib/ChuteDescent_Lib.ks").
runpath("0:/cls_lib/lib_navball.ks").
runpath("0:/cls_lib/CLS_nav.ks").
SAS off. RCS on. Brakes on.
lock steering to ship:srfretrograde.
set scriptStatus to "Running".

//Variables creation
set chuteMaxQ to 20000.
set drogueMaxQ to 30000.
set dynamicPressure to 99999999.
set dynamicPressureTime to 0.
//lock shipDynamicPressure to ship:Q * constant:atmtokpa * 1000.

//HUD Initialisation
print "Awaiting Free-fall" at (0,0).
set shipStatus to "Re-entry".
set chuteStatus to "-".
set drogueStatus to "-".
set fuelCellStatus to "Inactive".

//Detect if ship has aborted
if alt:radar < ship:body:atm:height/2 {
	set abortMode to true.
} else {
	set abortMode to false.
}

//Part list creation for different parachute modules
set sstuChuteList to list(). set stockChuteList to list(). set stockDrogueList to list(). set fuelCellList to list().
for p in ship:parts {
	if p:hasmodule("SSTUModularParachute") {
		sstuChuteList:add(p).
		p:getmodule("SSTUModularParachute"):setfield("drogue deploy alt",2500).
		p:getmodule("SSTUModularParachute"):setfield("main deploy alt",750).
	} else if p:hasmodule("ModuleParachute") {
		if p:title:contains("Drogue") {
			stockDrogueList:add(p).
			set drogueStatus to "Unsafe to deploy".
			p:getmodule("ModuleParachute"):setfield("altitude",5000).
		} else {
			stockChuteList:add(p).
			set chuteStatus to "Unsafe to deploy".
			p:getmodule("ModuleParachute"):setfield("altitude",1000).
		}
	}
	if p:hasmodule("ModuleResourceConverter") {
		fuelCellList:add(p).
	}
}

when scriptStatus = "Running" then {
	chuteResourceTracker(). Calculations(). chuteHUD().
	return true.
}

wait until ship:altitude < body:atm:height and ship:verticalspeed < 0. 
set entryTime to time:seconds.
if not abortMode {
	wait until dynamicPressureTracker(dynamicPressure) = false.
	wait until dynamicPressureTracker(dynamicPressure) = true.
}

//Drogue Deploy
if stockDrogueList:length > 0 or sstuChuteList:length > 0 {
	set shipStatus to "Awaiting Drogue Deploy".
	wait until Body:atm:altitudepressure(ship:altitude) > 0.02 and ship:Q*constant:atmtokpa*1000 < drogueMaxQ.
	if sstuChuteList:length > 0 {
		for p in sstuChuteList {
			p:getmodule("SSTUModularParachute"):setfield("drogue deploy alt",ship:altitude+1000).
			p:getmodule("SSTUModularParachute"):doaction("deploy chute",true).
		}
		set runmode to 3.
	} else if stockDrogueList:length > 0 {
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
	set shipStatus to "Drogue chutes Deployed".
	wait until Body:atm:altitudepressure(ship:altitude) > 0.04 and alt:radar < 4500.
	until alt:radar < 1050 {
		if (ship:Q*constant:atmtokpa*1000)*1.1 > chuteMaxQ and dynamicPressureTracker(dynamicPressure) = false {
			set runmode to 2.
		}
	}
	set runmode to 2.
}

//Mains deploy
if runmode = 2 {
	if stockChuteList:length > 0 {
		set shipStatus to "Awaiting Chute Deploy".
		wait until Body:atm:altitudepressure(ship:altitude) > 0.04 and ship:Q*constant:atmtokpa*1000 < chuteMaxQ.
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
	if stockDrogueList:length > 0 and abortMode = false {
		until stockDrogueList:length = 0 {
			if alt:radar < 1050 {
				stockDrogueList[0]:getmodule("ModuleParachute"):doevent("cut parachute").
				stockDrogueList:remove(0).
			}
		}
		set chuteStatus to "Cut               ".
	}
	wait until ship:status = "LANDED" or ship:status = "SPLASHED".
}

RCS off. unlock all.
print "                                       " at (0,0).