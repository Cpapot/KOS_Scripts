RUNPATH("0:/boot/lib/print.ks").

FUNCTION abortMission {
	parameter message.

	betterPrint( "Mission aborted: " + message, 0).
	betterPrint("gl", 1).

	SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
}

FUNCTION printMissionInfo {
	set Terminal:WIDTH to 70.
	set Terminal:HEIGHT to 10.

	parameter orbit_altitude, orbit_inclination.

	betterPrint("Mission information:", 0).
	betterPrint("Launch to an orbit", 0).
	betterPrint("Orbit altitude: " + orbit_altitude + "m", 0).
	betterPrint("Orbit inclination: " + orbit_inclination + "°", 1).
}
