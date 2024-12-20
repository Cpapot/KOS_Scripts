// should be run in the KSP console
// Purpose: Launch a rocket into orbit
// parametres: orbit_altitude, orbit_inclination

// Set up the orbit altitude and inclination

SET abort TO 0.
SET orientation_start_altitude TO 10000.
SET orientation_end_altitude TO 20000.

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
	PRINT "  - 0° = equatorial orbit (eastward)".
	PRINT "  - 90° = polar orbit".
	PRINT "  - 180° = equatorial orbit (westward)".
	PRINT "".
}

FUNCTION abortMission {
	parameter message.

	betterPrint( "Mission aborted: " + message, 0).
	betterPrint("gl", 1).
}

// Check the parameters
FUNCTION checkParams {
	parameter orbit_altitude, orbit_inclination.

	IF orbit_altitude < 70000 {
		incorrectParams("Orbit altitude must be at least 70km").
	}
	IF orbit_inclination < 0 {
		incorrectParams("Orbit inclination must be at least 0").
	}
	IF orbit_inclination > 180 {
		incorrectParams("Orbit inclination must be at most 180").
	}
}

function betterPrint {
	parameter message. // string to print
	parameter newline. // 1 if a newline should be added, 0 otherwise

	PRINT SHIP:shipname + ":		" + message.
	IF newline = 2 {
		PRINT "...".
	}
	IF newline = 1 {
		PRINT SHIP:shipname + ": ...".
	}
}

function countdown {
	parameter seconds.

	DECLARE i TO seconds.
	FROM {SET i TO seconds.} UNTIL i < 0 STEP {SET i TO i - 1.} DO {
		betterPrint("T-" + i + " seconds", 0).
		WAIT 1.
	}
}

function countup {
	parameter seconds.

	DECLARE i TO seconds.
	FROM {SET i TO 0.} UNTIL i <= second STEP {SET i TO i + 1.} DO {
		betterPrint("T+" + i + " seconds", 0).
		WAIT 1.
	}
}

FUNCTION stageIfOneThrustEmpty { // a mettre dans les boucle ou l'on utilise les moteurs
	FOR engine IN SHIP:PARTS:ENGINES {
		IF engine:RESOURCES:LIQUIDFUEL:AMOUNT <= 0 {
			betterPrint("Thrust empty, staging", 2).
			STAGE.
		}
	}
}


// gradully turn the rocket to be at the target inclination at the max altitude
FUNCTION gradualTurn {
	parameter max_altitude.
	parameter target_inclination.

	betterPrint("start turning gradually at 45° towards the target", 2).

	UNTIL SHIP:ALTITUDE >= max_altitude {
		SET current_pitch TO 90 - (SHIP:ALTITUDE / max_altitude * 45).
		SET current_heading TO 90. // Direction est pour orbite prograde.

		LOCK STEERING TO HEADING(current_heading, current_pitch) + R(0, 0, target_inclination).
		stageIfOneThrustEmpty().
		WAIT 0.1.
	}

	betterPrint("Orientation reached", 1).
}

FUNCTION draw_target_orbit {
	parameter orbit_altitude, orbit_inclination.

    SET target_orbit TO SHIP:BODY:GEOPOSITIONOF(
        LATLNG(orbit_inclination, 0)
    ):ALTITUDEOF(orbit_altitude).
    VECDRAW(
        V(0,0,0),
        target_orbit:NORMALIZED * orbit_altitude,
        RGB(0,1,0),
        "Target Orbit",
        1.0,
        TRUE
    ).
}

FUNCTION printMissionInfo {
	parameter orbit_altitude, orbit_inclination.

	betterPrint("Mission information:", 0).
	betterPrint("Launch to an orbit", 0).
	betterPrint("Orbit altitude: " + orbit_altitude + "m", 0).
	betterPrint("Orbit inclination: " + orbit_inclination + "°", 1).

	draw_target_orbit(orbit_altitude, orbit_inclination).
}

FUNCTION lauching {
	LOCK STEERING TO UP + R(0,0,0).
	// activer RCS et SAS setup le bails

	countdown(5).

	// Ignite the engines
	betterPrint("Igniting engines", 2).
	LOCK THROTTLE TO 1.
	STAGE.

	countup(3).

	// separate the launch clamps
	betterPrint("Separating launch clamps", 2).
	STAGE.

	WAIT 1.
	betterPrint("LIFTOFF!", 1).

	UNTIL SHIP:ALTITUDE > orientation_start_altitude {
		LOCK STEERING TO UP + R(0,0,0).
		stageIfOneThrustEmpty().
		WAIT 0.1.
	}
}

FUNCTION main {
	parameter orbit_altitude, orbit_inclination.

	checkParams(orbit_altitude, orbit_inclination).
	IF abort = 1 {
		abortMission("Incorrect parameters").
		RETURN.
	}

	printMissionInfo(orbit_altitude, orbit_inclination).

	lauching().

	gradualTurn(orientation_end_altitude, orbit_inclination).

	
}

main(80000, 0).
