//Initial script setup
clearscreen.
runpath("0:/cls_lib/lib_num_to_formatted_str.ks").
runpath("0:/ChuteDescent_Lib/ChuteDescent_Lib.ks").
SAS off. RCS on. Brakes on.
lock steering to ship:srfretrograde.
set script to "Running".

//Variables creation
set chuteMaxQ to 20000.
set drogueMaxQ to 30000.
//set t to 0.
set shipQ1 to 99999999.
set shipQt to 0.

//HUD Initialisation
print "Awaiting Free-fall" at (0,0).
set shipStat to "Re-entry".
set chuteStat to "-".
set drogueStat to "-".
set FCStatus to "Inactive".

//Detect if ship has aborted
if alt:radar < 5000 {
	set abortOverride to true.
} else {
	set abortOverride to false.
}

//Part list creation for different parachute modules
set plist to ship:parts.
set sstuList to list(). set stockChuteList to list(). set stockDrogueList to list(). set fuelCellList to list().
for p in plist {
	if p:hasmodule("SSTUModularParachute") {
		sstuList:add(p).
		p:getmodule("SSTUModularParachute"):setfield("drogue deploy alt",2500).
		p:getmodule("SSTUModularParachute"):setfield("main deploy alt",750).
	} else if p:hasmodule("ModuleParachute") {
		if p:title:contains("Drogue") {
			stockDrogueList:add(p).
			set drogueStat to "Unsafe to deploy".
			p:getmodule("ModuleParachute"):setfield("altitude",5000).
		} else {
			stockChuteList:add(p).
			set chuteStat to "Unsafe to deploy".
			p:getmodule("ModuleParachute"):setfield("altitude",1000).
		}
	}
	if p:hasmodule("ModuleResourceConverter") {
		fuelCellList:add(p).
	}
}

when script = "Running" then {
	ReentryResMonitor(). ReentryCalc(). ReentryHUD().
	return true.
}

wait until ship:altitude < body:atm:height and ship:verticalspeed < 0. 
set entrytime to time:seconds.
wait until shipQtest(shipQ1) = false.
wait until shipQtest(shipQ1) = true or abortOverride = true.

//Drogue Deploy - 
if stockDrogueList:length > 0 or sstuList:length > 0 {
	set shipStat to "Awaiting Drogue Deploy".
	wait until Body:atm:altitudepressure(ship:altitude) > 0.02 and shipQ < drogueMaxQ.
	if sstuList:length > 0 {
		for p in sstuList {
			p:getmodule("SSTUModularParachute"):setfield("drogue deploy alt",ship:altitude+1000).
			p:getmodule("SSTUModularParachute"):doaction("deploy chute",true).
		}
		set runMode to 3.
	} else if stockDrogueList:length > 0 {
		for p in stockDrogueList {
			p:getmodule("ModuleParachute"):setfield("altitude",ship:altitude+1000).
			p:getmodule("ModuleParachute"):doaction("deploy chute",true).
		}
		set runMode to 1.
	}
	RCS off.
	unlock all.
	set drogueStat to "Deployed".
} else {
	set runMode to 1.
}

//Descent under Drogues - will advance to mains early if it thinks drogues are deployed, dynamic pressure is still rising and its close to unsafe mains threshold
if runmode = 1 {
	wait until Body:atm:altitudepressure(ship:altitude) > 0.04 and alt:radar < 4500.
	until alt:radar < 1050 {
		if shipQ*1.1 > chuteMaxQ and shipQtest(shipQ1) = false {
			set runMode to 2.
		}
	}
	set runmode to 2.
}

//Mains deploy
if runmode = 2 {
	if stockChuteList:length > 0 {
		set shipStat to "Awaiting Chute Deploy".
		wait until Body:atm:altitudepressure(ship:altitude) > 0.04 and shipQ < chuteMaxQ.
		for p in stockChuteList {
			p:getmodule("ModuleParachute"):doaction("deploy chute",true).
		}
		set chuteStat to "Deployed".
		set shipStat to "Chute controlled descent".
		set runMode to 3.
	} else {
		set runMode to 3.
	}
}

//Final descent
if runMode = 3 {
	//lock t to alt:radar / abs(ship:verticalspeed).
	if stockDrogueList:length > 0 and abortOverride = false {
		until stockDrogueList:length = 0 {
			if alt:radar < 1050 {
				stockDrogueList[0]:getmodule("ModuleParachute"):doevent("cut parachute").
				stockDrogueList:remove(0).
			}
		}
		set chuteStat to "Cut               ".
	}
	wait until ship:status = "LANDED" or ship:status = "SPLASHED".
}

RCS off. unlock all.
print "                                       " at (0,0).