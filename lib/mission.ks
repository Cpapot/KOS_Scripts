RUNPATH("0:/boot/lib/print.ks").

FUNCTION abortMission {
	parameter message.

	betterPrint( "Mission aborted: " + message, 0).
	betterPrint("gl", 1).

	SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
}

FUNCTION printMissionInfo {
	parameter orbit_altitude, orbit_inclination.

	betterPrint("Mission information:", 0).
	betterPrint("Launch to an orbit", 0).
	betterPrint("Orbit altitude: " + orbit_altitude + "m", 0).
	betterPrint("Orbit inclination: " + orbit_inclination + "°", 1).

	//draw_target_orbit(orbit_altitude, orbit_inclination).
}
