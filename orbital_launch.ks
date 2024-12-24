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

		SET kuniverse:timewarp:rate TO 100.  // Vous pouvez ajuster le niveau de warp selon vos besoins
		WAIT UNTIL ETA:APOAPSIS < burn_time / 2 + 10.
		SET kuniverse:timewarp:rate TO 1.  // Retour à la vitesse normale

		betterPrint("Aligning with prograde", 3).
		LOCK STEERING TO SHIP:VELOCITY:ORBIT.
		WAIT 5.

		betterPrint("engines turning on", 3).
		SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 1.

		// Boucle principale avec ajustement fin
		SET apoapsis_phase TO 1.
		SET stop_phase TO 0.
		UNTIL ABS(SHIP:ORBIT:APOAPSIS - SHIP:ORBIT:PERIAPSIS) < 2000 {
			LOCAL apoapsis_error TO SHIP:ORBIT:APOAPSIS - orbit_altitude.
			LOCAL periapsis_error TO SHIP:ORBIT:PERIAPSIS - orbit_altitude.

			IF apoapsis_phase {
				IF periapsis_error > 0 {
					LOCK STEERING TO HEADING(orbit_inclination, 180). //retrograde
				} ELSE IF apoapsis_error > 0 {
					LOCK STEERING TO HEADING(orbit_inclination, 0). //prograde
				}
				IF SHIP:orbit:periapsis > orbit_altitude {
					betterPrint("periapsis at the right altitude", 1).
					SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
					SET apoapsis_phase TO 0.
					SET stop_phase TO 1.
				}
			}
			ELSE {
				// Calculate which orbit point (Ap or Pe) we should burn at
				IF ABS(apoapsis_error) > ABS(periapsis_error) {
					// If apoapsis needs more correction, wait until periapsis
					IF ABS(ETA:PERIAPSIS) < 30 OR ETA:PERIAPSIS > TIME:SECONDS + 30 {
						LOCK STEERING TO HEADING(orbit_inclination, 180). //retrograde
					} ELSE {
						set stop_phase to 0.
						SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
						betterPrint("Waiting until periapsis", 3).
						IF ETA:PERIAPSIS > 30 {
							IF ETA:PERIAPSIS > 1000 {
								SET kuniverse:timewarp:rate TO 100.
							} ELSE IF  ETA:PERIAPSIS > 500 {
								SET kuniverse:timewarp:rate TO 10.
							}
							WAIT UNTIL ETA:PERIAPSIS < 200.
							SET kuniverse:timewarp:rate TO 5.
							WAIT UNTIL ETA:PERIAPSIS < 60.
							SET kuniverse:timewarp:rate TO 1.  // Retour à la vitesse normale
							UNTIL ETA:PERIAPSIS < 30 {
								LOCK STEERING TO HEADING(orbit_inclination, 180). //retrograde
								WAIT 0.1.
							}
						}
					}
				} ELSE {
					// If periapsis needs more correction, wait until apoapsis
					IF ABS(ETA:APOAPSIS) < 30 OR ETA:APOAPSIS > TIME:SECONDS + 30 {
						LOCK STEERING TO HEADING(orbit_inclination, 0). //prograde
					} ELSE {
						set stop_phase to 0.
						SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
						betterPrint("Waiting until apoapsis", 3).
						IF ETA:APOAPSIS > 30 {
							IF ETA:APOAPSIS > 1000 {
								SET kuniverse:timewarp:rate TO 100.
							} ELSE IF  ETA:APOAPSIS > 500 {
								SET kuniverse:timewarp:rate TO 10.
							}
							WAIT UNTIL ETA:APOAPSIS < 200.
							SET kuniverse:timewarp:rate TO 5.
							WAIT UNTIL ETA:APOAPSIS < 60.
							SET kuniverse:timewarp:rate TO 1.  // Retour à la vitesse normale
							UNTIL ETA:APOAPSIS < 30 {
								LOCK STEERING TO HEADING(orbit_inclination, 0). //prograde
								WAIT 0.1.
							}
						}
					}
				}
			}
			IF (stop_phase = 0) {
				IF SHIP:VELOCITY:ORBIT:MAG > v_circular {
					SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.3. // Réduction de la poussée pour un ajustement fin
				} ELSE {
					SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 1.
				}
			}

			if (stageIfOneThrustEmpty() = FALSE) {
				RETURN FALSE.
			}
			WAIT 0.1.
		}
	}

	SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
	betterPrint("Orbit circularized", 1).
	betterPrint("Error Margin : " + ABS(SHIP:ORBIT:APOAPSIS - SHIP:ORBIT:PERIAPSIS) + " meters", 1).
	RETURN TRUE.
}

function orbitalLaunch {
	parameter orbit_altitude.
	parameter orbit_inclination.
	parameter info.

	set orbit_altitude to orbit_altitude * 1000.

	checkParams(orbit_altitude, orbit_inclination).
	IF abort = 1 {
		abortMission("Incorrect parameters").
		RETURN.
	}

	if (info = TRUE) {
		printMissionInfo(orbit_altitude, orbit_inclination).
	}

	if (lauching(orientation_start_altitude) = FALSE) {
		RETURN.
	}

	if (gradualTurn(orientation_start_altitude ,orientation_end_altitude, orbit_inclination) = FALSE) {
		RETURN.
	}

	betterPrint("Acceleration until the apoasis height is at the desired orbit", 3).
	UNTIL apoapsis > orbit_altitude {
		IF stageIfOneThrustEmpty() = FALSE {
			RETURN.
		}
		SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 1.
		LOCK STEERING TO HEADING(orbit_inclination, 45).
		WAIT 0.1.
	}
	betterPrint("Apoasis has reached orbit height, engines shut down", 3).
	wait 0.1.
	SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.

	if (CirculizeOrbit(orbit_altitude, orbit_inclination) = FALSE) {
		RETURN.
	}
}


FUNCTION RunOrbitalLaunch {
	parameter orbit_altitude.
	parameter orbit_inclination.

	orbitalLaunch(orbit_altitude, orbit_inclination, TRUE).
}

RunOrbitalLaunch(250, 90).
