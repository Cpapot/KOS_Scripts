RUNPATH("0:/boot/lib/print.ks").
RUNPATH("0:/boot/lib/engine.ks").

FUNCTION lauching {
	parameter start_altitude.

	LOCK STEERING TO UP + R(0,0,0).

	betterPrint("Turning RCS on", 3).
	RCS ON.
	betterPrint("Turning SAS off", 3).
	SAS OFF.

	countdown(5).
	betterPrint("Igniting engines", 3).
	SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 1.
	STAGE.
	countup(3).
	betterPrint("Separating launch clamps", 3).
	STAGE.

	WAIT 0.5.
	betterPrint("LIFTOFF!", 1).

	UNTIL SHIP:ALTITUDE > start_altitude {
		LOCK STEERING TO UP + R(0,0,0).
		IF stageIfOneThrustEmpty() = FALSE {
			RETURN FALSE.
		}
		SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 1.
		WAIT 0.1.
	}
	RETURN TRUE.
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

		LOCK STEERING TO HEADING(target_inclination, pitch).
		SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 1.
		IF stageIfOneThrustEmpty() = FALSE {
			RETURN FALSE.
		}
		WAIT 0.1.
	}
	betterPrint("Orientation reached", 1).
	RETURN TRUE.
}
