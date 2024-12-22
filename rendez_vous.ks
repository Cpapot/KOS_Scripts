RUNPATH("0:/boot/lib/print.ks").
RUNPATH("0:/boot/lib/mission.ks").
RUNPATH("0:/boot/lib/math/orbit.ks").
RUNPATH("0:/boot/lib/engine.ks").
RUNPATH("0:/boot/orbital_launch.ks").

function main {
	set terminal:height to 70.
	//regarder toutes les stations en orbite et voir si elles ont un port de docking de libre
	// print les stations en orbite
	// attendre que l'user choisisse une station
    LOCAL availableStations IS LIST().

    LIST TARGETS IN allTargets.
	PRINT "Recherche des stations avec ports disponibles...".
    FOR randomtarget IN allTargets {
        IF targ:ISTYPE("Vessel") {
            LOCAL hasDockingPort IS FALSE.
            LOCAL hasFreeDockingPort IS FALSE.

			LIST ports IN randomtarget:PARTS.

			FOR port in ports {
				PRINT port.
			}

			// LOCAL ports IS targ:PARTSTAGGED("DockingPort").

            // IF ports:LENGTH > 0 {
            //     SET hasDockingPort TO TRUE.
            //     FOR port IN ports {
            //         IF NOT port:STATE = "Docked" {
            //             SET hasFreeDockingPort TO TRUE.
            //             BREAK.
            //         }
            //     }
            // }

            // IF hasDockingPort AND hasFreeDockingPort {
            //     availableStations:ADD(targ).
            // }
        }
    }

	// PRINT "Stations disponibles:".
    // FROM {LOCAL i IS 0.} UNTIL i >= availableStations:LENGTH STEP {SET i TO i + 1.} DO {
    //     PRINT i + ": " + availableStations[i]:NAME.
    // }

    // Attendre le choix de l'utilisateur
    PRINT "Entrez le numéro de la station cible:".
//    LOCAL choice IS TERMINAL:INPUT:GETCHAR().
//    LOCAL targetStation IS availableStations[choice:TONUMBER()].
//    SET TARGET TO targetStation.
	// verifier si le vaisseau a un port de docking (pas forcement libre)

	// recuperer l'altitude du periapsis de l'obite de la cible
	// recuperer l'inclinaison de l'orbite de la cible

	// attendre que le point de decollage passe sous l'orbite de la cible
	// lancer la fusée avec orbitalLaunch(target_altitude - 1000, target_inclination)

	// une fois en orbite faire un rendez-vous avec la station

	// une fois le rendez-vous fait,
	// commencer le docking
	// on devra attendre que l'user prenne pour cible un port de docking sur le vaisseau cible pour continuer (sauf si un seul port est libre)
	// on devra attendre que l'user controle le vaisseau actuel depuis un port de docking pour continuer (sauf si un seul port est libre)

	// aligner les vaisseaux et docker ()

}

main().
