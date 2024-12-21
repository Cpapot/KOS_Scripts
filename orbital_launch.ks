RUNPATH("0:/boot/lib/print.ks").
RUNPATH("0:/boot/lib/mission.ks").
RUNPATH("0:/boot/lib/math/orbit.ks").
RUNPATH("0:/boot/lib/engine.ks").
RUNPATH("0:/boot/lib/launch.ks").


// should be run in the KSP console
// Purpose: Launch a rocket into orbit
// parametres: orbit_altitude, orbit_inclination

// Set up the orbit altitude and inclination

SET abort TO FALSE.

SET orientation_start_altitude TO 500.
SET orientation_end_altitude TO 5000.

// Print a message and set is_finish to true
FUNCTION incorrectParams {
	parameter error.
	PRINT error.
	SET abort TO TRUE.
	PRINT "".
	PRINT "Purpose: Launch a rocket into any orbital inclination".
	PRINT "Parameters:".
	PRINT "  orbit_altitude: desired orbital altitude in meters".
	PRINT "  orbit_inclination: desired orbital inclination in degrees (0-180)".
	PRINT "  - 90° = equatorial orbit (eastward)".
	PRINT "  - 0° = polar orbit".
	PRINT "  - -90° = equatorial orbit (westward)".
	PRINT "".
}

// Check the parameters
FUNCTION checkParams {
	parameter orbit_altitude, orbit_inclination.

	IF orbit_altitude < 70000 {
		incorrectParams("Orbit altitude must be at least 100km").
	}
	IF orbit_inclination < 0 {
		incorrectParams("Orbit inclination must be at least 0").
	}
	IF orbit_inclination > 180 {
		incorrectParams("Orbit inclination must be at most 180").
	}
}

function CirculizeOrbit {
	parameter orbit_altitude.
	parameter orbit_inclination.

	SET v_circular TO getSpeedAtAltitude(orbit_altitude).
	SET delta_v TO getDeltaVToCircularize(orbit_altitude).

	IF delta_v > 0 {
		betterPrint("Delta-V required for circularization: " + delta_v + " m/s", 0).

		SET burn_time TO (SHIP:MASS * delta_v) / SHIP:AVAILABLETHRUST.
		betterPrint("Estimated burn time: " + burn_time + " seconds", 1).

		betterPrint("Waiting until apoapsis", 3).
		WAIT UNTIL ETA:APOAPSIS < burn_time / 2 + 10.

		betterPrint("Aligning with prograde", 3).
		LOCK STEERING TO SHIP:VELOCITY:ORBIT.
		WAIT 5.

		betterPrint("engines turning on", 3).
		SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 1.

		// Boucle principale avec ajustement fin
		SET apoapsis_phase TO 1.
		UNTIL ABS(SHIP:ORBIT:APOAPSIS - SHIP:ORBIT:PERIAPSIS) < 2000 {
			LOCAL apoapsis_error TO SHIP:ORBIT:APOAPSIS - orbit_altitude.
			LOCAL periapsis_error TO SHIP:ORBIT:PERIAPSIS - orbit_altitude.

			IF apoapsis_phase {
				IF apoapsis_error > 0 {
					LOCK STEERING TO RETROGRADE.
				} ELSE {
					LOCK STEERING TO PROGRADE.
				}
				IF periapsis_error > 0 {
					LOCK STEERING TO RETROGRADE.
				} ELSE {
					LOCK STEERING TO PROGRADE.
				}
				IF SHIP:orbit:periapsis > orbit_altitude {
					betterPrint("periapsis at the right altitude", 1).
					SET apoapsis_phase TO 0.
				}
			}
			ELSE {
				// Calculate which orbit point (Ap or Pe) we should burn at
				IF ABS(apoapsis_error) > ABS(periapsis_error) {
					// If apoapsis needs more correction, wait until periapsis
					IF ABS(ETA:PERIAPSIS) < 30 OR ETA:PERIAPSIS > TIME:SECONDS + 30 {
						LOCK STEERING TO RETROGRADE.
					} ELSE {
						SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
						betterPrint("Waiting until periapsis", 3).
						WAIT UNTIL ETA:PERIAPSIS < 30.
					}
				} ELSE {
					// If periapsis needs more correction, wait until apoapsis
					IF ABS(ETA:APOAPSIS) < 30 OR ETA:APOAPSIS > TIME:SECONDS + 30 {
						LOCK STEERING TO PROGRADE.
					} ELSE {
						SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
						betterPrint("Waiting until apoapsis", 3).
						WAIT UNTIL ETA:APOAPSIS < 30.
					}
				}
			}

			IF SHIP:VELOCITY:ORBIT:MAG > v_circular
			{
				SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.3. // Réduction de la poussée pour un ajustement fin
			} ELSE {
				SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 1.
			}

			stageIfOneThrustEmpty().
			WAIT 0.1.
		}
	}

	SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
	betterPrint("Orbit circularized", 1).
	betterPrint("Error Margin : " + ABS(SHIP:ORBIT:APOAPSIS - SHIP:ORBIT:PERIAPSIS) + " meters", 1).
}

FUNCTION main {
	parameter orbit_altitude.
	parameter orbit_inclination.

	set orbit_altitude to orbit_altitude * 1000.

	checkParams(orbit_altitude, orbit_inclination).
	IF abort = 1 {
		abortMission("Incorrect parameters").
		RETURN.
	}

	printMissionInfo(orbit_altitude, orbit_inclination).

	lauching(orientation_start_altitude).

	gradualTurn(orientation_start_altitude ,orientation_end_altitude, orbit_inclination).

	betterPrint("Acceleration until the apoasis height is at the desired orbit", 3).
	UNTIL apoapsis > orbit_altitude {
		stageIfOneThrustEmpty().
		SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 1.
		LOCK STEERING TO HEADING(orbit_inclination, 45).
		WAIT 0.1.
	}
	betterPrint("Apoasis has reached orbit height, engines shut down", 3).
	wait 0.1.
	SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.

	CirculizeOrbit(orbit_altitude, orbit_inclination).
}

main(100, 80).
