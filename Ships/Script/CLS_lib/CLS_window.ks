function launchWindow {
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
    if time:seconds < lt-(body:rotationPeriod/2)-23 {
        return lt-(body:rotationPeriod/2).
    } else if time:seconds < lt-23 {
		global tInc is -1*tInc.
        return lt.
    } else {
		return lt+(body:rotationPeriod/2).
	}
}

function orbitnormal
{
  parameter inc, lan.
  
  local o_pos is r(0,-lan,0) * solarprimevector:normalized.
  local o_vec is angleaxis(-inc,o_pos) * vcrs(ship:body:angularvel,o_pos):normalized.
  return vcrs(o_vec,o_pos).
}