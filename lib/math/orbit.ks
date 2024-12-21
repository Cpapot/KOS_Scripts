FUNCTION getSpeedAtAltitude {
	parameter _altitude.

	SET mu TO BODY:MU.
	SET radius TO _altitude + BODY:RADIUS.

	RETURN SQRT(mu / radius).
}

FUNCTION getDeltaVToCircularize {
	parameter orbit_altitude.

	SET mu TO BODY:MU.
	SET orbite_rayon TO orbit_altitude + BODY:RADIUS.

	// Calcul de la vitesse orbitale circulaire
	SET v_circular TO getSpeedAtAltitude(orbit_altitude).

	// Calcul de la vitesse actuelle à l'apoapsis
	SET semimajoraxis TO SHIP:ORBIT:semimajoraxis.
	SET v_current TO SQRT(mu * (2 / orbite_rayon - 1 / semimajoraxis)).

	// Delta-V requis pour circulariser
	SET delta_v TO v_circular - v_current.

	IF delta_v > 0 {
		RETURN delta_v.
	} ELSE {
		RETURN 0.
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
