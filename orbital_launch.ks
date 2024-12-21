RUNPATH("0:/boot/lib/print.ks").
RUNPATH("0:/boot/lib/mission.ks").


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

FUNCTION stageIfOneThrustEmpty {
    LOCAL needStage IS FALSE.

    IF STAGE:READY{
        IF MAXTHRUST = 0 {
            SET needStage TO TRUE.
        } ELSE {
            LOCAL engineList IS LIST().
            LIST ENGINES IN engineList.
            FOR engine IN engineList {
                IF engine:IGNITION AND engine:FLAMEOUT {
                    SET needStage TO TRUE.
                    BREAK.
                }
            }
        }
        IF needStage    {
            STAGE.
            betterPrint("Staging", 2).
        }
    } ELSE {
        SET needStage TO TRUE.
    }
    RETURN needStage.
}

// gradully turn the rocket to be at the target inclination at the max altitude
FUNCTION gradualTurn {
	parameter start_altitude.
	parameter end_altitude.
	parameter target_inclination.

	SET pitch TO (45 - (45 * 0)) + 45.
	betterPrint("start turning gradually at 45° towards the target", 2).
	SET altitude_ratio TO end_altitude - start_altitude.
	UNTIL (SHIP:altitude >= end_altitude){
		SET percentage TO ((SHIP:altitude - start_altitude) / altitude_ratio).
		SET pitch TO (45 - (45 * percentage)) + 45.

		SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 1.
		LOCK STEERING TO HEADING(target_inclination, pitch).
		stageIfOneThrustEmpty().
		WAIT 0.1.
	}

	betterPrint("Orientation reached", 1).
}

FUNCTION draw_target_orbit {
    parameter orbit_altitude, orbit_inclination.

    // Define the degree-to-radian conversion factor
    SET DEG_TO_RAD TO CONSTANT():PI / 180.

    // Calculate the target vector for the orbit
    SET inclination_rad TO orbit_inclination * DEG_TO_RAD.
    SET x TO orbit_altitude * COS(inclination_rad).
    SET y TO orbit_altitude * SIN(inclination_rad).

    SET target_orbit TO V(x, y, 0). // Target orbit vector
    VECDRAW(
        V(0, 0, 0),               // Origin
        target_orbit:NORMALIZED * orbit_altitude, // Scaled vector
        RGB(0, 1, 0),            // Color
        "Target Orbit",          // Label
        1.0,                     // Width
        TRUE                     // Persistent
    ).
}

FUNCTION lauching {
	LOCK STEERING TO UP + R(0,0,0).
	// activer RCS et SAS setup le bails

	RCS ON.
	SAS OFF.

	countdown(5).

	// Ignite the engines
	betterPrint("Igniting engines", 2).
	SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 1.
	STAGE.

	countup(3).

	// separate the launch clamps
	betterPrint("Separating launch clamps", 2).
	STAGE.

	WAIT 0.5.
	betterPrint("LIFTOFF!", 1).

	UNTIL SHIP:ALTITUDE > orientation_start_altitude {
		LOCK STEERING TO UP + R(0,0,0).
		stageIfOneThrustEmpty().
		SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 1.
		WAIT 0.1.
	}
}

FUNCTION getActiveEnginesISP {
    LOCAL totalThrust IS 0.
    LOCAL weightedISP IS 0.

    LIST ENGINES IN enginesList.
    FOR engine IN enginesList {
        IF engine:IGNITION {  // Vérifie si le moteur est actif
            SET totalThrust TO totalThrust + engine:THRUST.
            SET weightedISP TO weightedISP + (engine:THRUST * engine:ISP).
        }
    }

    // Retourne l'ISP moyenne pondérée
    IF totalThrust > 0 {
        RETURN weightedISP / totalThrust.
    } ELSE {
        RETURN 0.  // Retourne 0 si aucun moteur n'est actif
    }
}

function testNODE {
	parameter orbit_altitude.
	parameter orbit_inclination.


	SET mu TO BODY:MU.
	SET orbite_rayon TO orbit_altitude + BODY:RADIUS.

    // Calcul de la vitesse orbitale circulaire
	SET v_circular TO SQRT(mu / orbite_rayon).

    // Calcul de la vitesse actuelle à l'apoapsis
	SET aa TO SHIP:ORBIT:semimajoraxis.
	SET v_current TO SQRT(mu * (2 / orbite_rayon - 1 / aa)).

    // Delta-V requis pour circulariser
	SET delta_v TO v_circular - v_current.

	IF delta_v > 0 {
		PRINT "Delta-V requis pour circularisation : " + delta_v + " m/s".

		// Calcul du temps de poussée
		SET thrust TO SHIP:AVAILABLETHRUST.
		SET isp TO getActiveEnginesISP().
		SET g0 TO 9.81.
		SET exhaust_velocity TO isp * g0.
		SET total_mass TO SHIP:MASS.
		SET burn_time TO (total_mass * delta_v) / thrust.

		PRINT "Temps estimé pour la poussée : " + burn_time + " secondes.".

		// Attente jusqu'à l'apoapsis
		PRINT "En attente de l'apoapsis...".
		WAIT UNTIL ETA:APOAPSIS < burn_time / 2.

		// Alignement prograde
		PRINT "Alignement direction prograde...".
		LOCK STEERING TO SHIP:VELOCITY:ORBIT.  // Changed to orbital velocity instead of surface
		WAIT 5. // Attendre l'alignement complet

		// Exécution de la poussée principale
		PRINT "Exécution de la poussée...".
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
					SET apoapsis_phase TO 0.
					PRINT "periaspsis a la bonne altitude".
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
						PRINT "en attente jusquau periapsis".
						WAIT UNTIL ETA:PERIAPSIS < 30.
					}
				} ELSE {
					// If periapsis needs more correction, wait until apoapsis
					IF ABS(ETA:APOAPSIS) < 30 OR ETA:APOAPSIS > TIME:SECONDS + 30 {
						LOCK STEERING TO PROGRADE.
					} ELSE {
						SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
						PRINT "en attente jusqua l'apoapsis".
						WAIT UNTIL ETA:APOAPSIS < 30.
					}
				}
			}

			IF SHIP:VELOCITY:ORBIT:MAG > v_circular
			{
				SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.1. // Réduction de la poussée pour un ajustement fin
			} ELSE {
				SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 1.
			}

			stageIfOneThrustEmpty().

			// Mise à jour des paramètres pour la prochaine itération
			SET orbite_rayon TO (SHIP:ORBIT:APOAPSIS + SHIP:ORBIT:PERIAPSIS) / 2 + BODY:RADIUS.
			SET v_circular TO SQRT(mu / orbite_rayon).

			WAIT 0.1.
		}
	}

	SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
	PRINT "Circularisation terminée !".
	PRINT "Différence Ap-Pe : " + ABS(SHIP:ORBIT:APOAPSIS - SHIP:ORBIT:PERIAPSIS) + " mètres".

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

	lauching().

	gradualTurn(orientation_start_altitude ,orientation_end_altitude, orbit_inclination).

	betterPrint("Acceleration until the apoasis height is at the desired orbit", 3).
	UNTIL apoapsis > orbit_altitude {
		IF apoapsis * 100 / orbit_altitude > 90 {
			SET SHIP:CONTROL:PILOTMAINTHROTTLE TO ((apoapsis * 100 / orbit_altitude) / 10 + 90) / 100.
		}
		ELSE {
			SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 1.
		}
		stageIfOneThrustEmpty().
		WAIT 0.1.
	}
	betterPrint("Apoasis has reached orbit height, engines shut down", 3).
	print "inclination :" + SHIP:ORBIT:INCLINATION.
	wait 0.1.
	SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.

	testNODE(orbit_altitude, orbit_inclination).
}

main(100, 100).
