function launchWindowContract {
	parameter Inc, Lan.
    local lat is ship:latitude.
    local eclipticNormal is orbitNormal(Inc,Lan).
    local planetNormal is heading(0,lat):vector.
    local bodyInc is vang(planetNormal, eclipticNormal).
    local beta is arccos(max(-1,min(1,cos(bodyInc) * sin(lat) / sin(bodyInc)))).
    local intersectDir is vcrs(planetNormal, eclipticNormal):normalized.
    local intersectPos is -vxcl(planetNormal, eclipticNormal):normalized.
    local launchtimeDir is (intersectDir * sin(beta) + intersectPos * cos(beta)) * cos(lat) + sin(lat) * planetNormal.
    local launchtime is vang(launchtimeDir, ship:position - body:position) / 360 * body:rotationPeriod.
    if vcrs(launchtimeDir, ship:position - body:position)*planetNormal < 0 {
        set launchtime to body:rotationperiod - launchtime.
    }
    local lt is launchtime+time:seconds.
    if time:seconds < lt-(body:rotationPeriod/2)-23 {		//Descending Node
		global launchNode is " (Descending Node)".
		return lt-(body:rotationPeriod/2).
    } else if time:seconds < lt-23 {			//Ascending Node
		global tInc is -1*tInc.
		global launchNode is " (Ascending Node)".
        return lt.
    } else {									//Descending Node
		return lt+(body:rotationPeriod/2).
		global launchNode is " (Descending Node)".
	}
}

function launchWindowRendezvous {
    parameter tgt.
    local lat is ship:latitude.
    local eclipticNormal is vcrs(tgt:obt:velocity:orbit,tgt:body:position-tgt:position):normalized.
    local planetnormal is heading(0,lat):vector.
    local bodyinc is vang(planetnormal, eclipticnormal).
    local beta is arccos(max(-1,min(1,cos(bodyinc) * sin(lat) / sin(bodyinc)))).
    local intersectdir is vcrs(planetnormal, eclipticnormal):normalized.
    local intersectpos is -vxcl(planetnormal, eclipticnormal):normalized.
    local launchtimedir is (intersectdir * sin(beta) + intersectpos * cos(beta)) * cos(lat) + sin(lat) * planetnormal.
    local launchtime is vang(launchtimedir, ship:position - body:position) / 360 * body:rotationperiod.
    if vcrs(launchtimedir, ship:position - body:position)*planetnormal < 0 {
        set launchtime to body:rotationperiod - launchtime.
    }
    global tminusAscending is launchtime.
    global tminusDescending1 is launchtime-tgt:body:rotationperiod/2.
	
	if tminusDescending1 > 0 {
		global tInc is -1*target:orbit:inclination.
		return tminusDescending1.
	} else {
		global tInc is target:orbit:inclination.
		return tminusAscending.
	}
}

function orbitNormal
{
  parameter inc, lan.
  
  local o_pos is r(0,-lan,0) * solarprimevector:normalized.
  local o_vec is angleaxis(-inc,o_pos) * vcrs(ship:body:angularvel,o_pos):normalized.
  return vcrs(o_vec,o_pos).
}