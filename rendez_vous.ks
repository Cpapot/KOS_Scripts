RUNPATH("0:/boot/lib/print.ks").
RUNPATH("0:/boot/lib/mission.ks").
RUNPATH("0:/boot/lib/math/orbit.ks").
RUNPATH("0:/boot/lib/engine.ks").
//RUNPATH("0:/boot/orbital_launch.ks").

function main {
	set terminal:height to 70.
	//regarder toutes les stations en orbite et voir si elles ont un port de docking de libre
	// print les stations en orbite
	// attendre que l'user choisisse une station
    //LOCAL availableStations IS LIST().

    //LIST TARGETS IN allTargets.
	//PRINT "Recherche des stations avec ports disponibles...".
	//FOR randomtarget IN allTargets {
	//	IF randomtarget:ISTYPE("Vessel") {
	//		LOCAL hasDockingPort IS FALSE.
	//		LOCAL hasFreeDockingPort IS FALSE.

	//		LOCAL vesselString IS randomtarget:tostring.
	//		SET vesselName TO "".
	//		IF vesselString:CONTAINS("VESSEL(") {
	//			LOCAL startIndex IS vesselString:INDEXOF("(") + 2.
	//			LOCAL endIndex IS vesselString:INDEXOF(")") - 1.
	//			SET vesselName TO vesselString:SUBSTRING(startIndex, endIndex - startIndex).
	//		}

	//		IF (vesselName) {
	//			print vesselName.
	//			SET actualVessel TO VESSEL(vesselName).
	//			SET par TO actualVessel:PARTS.

	//			print vessel:orbit.

	//			IF actualVessel:PARTS:length > 0 {
	//				print "ok".
	//				IF actualVessel:PARTS:CONTAINS("DC125") {
	//					print "detected leego".
	//					SET hasDockingPort TO TRUE.
	//					FOR port IN actualVessel:DOCKINGPORTS {
	//						IF NOT port:STATE = "Docked" {
	//							SET hasFreeDockingPort TO TRUE.
	//							BREAK.
	//						}
	//					}
	//				}
	//				IF hasDockingPort AND hasFreeDockingPort {
	//					availableStations:ADD(actualVessel).
	//				}
	//			}
	//		}
	//	}
	//}
	// Script pour vérifier les ports d'amarrage sur tous les vaisseaux en orbite
	CLEARSCREEN.
	PRINT "Vérification des ports d'amarrage sur les vaisseaux orbitaux...".
	PRINT " ".

	// Fonction pour vérifier si un vaisseau a un port d'amarrage
	FUNCTION has_docking_port {
		PARAMETER check_vessel.

		SET TARGET TO check_vessel.
		WAIT 0.1.

		// Debug info
		PRINT "Checking vessel: " + TARGET:NAME.
		//PRINT "Number of parts: " + TARGET:PARTCOUNT.
		PRINT "Available modules: ".
		LIST MODULES IN modlist.
		FOR mod IN modlist {
			PRINT "Module found: " + mod.
		}

		FOR mod IN MODULES {
			IF mod:HASDATA("ModuleDockingNode") {
				RETURN TRUE.
			}
		}
		RETURN FALSE.
	}

	// Liste des vaisseaux avec leurs statuts
	LOCAL vessels_with_ports IS LIST().
	LOCAL vessels_without_ports IS LIST().

	// Obtenir la liste des vaisseaux
	LIST TARGETS IN target_list.

	// Vérification de tous les vaisseaux
	FOR target_vessel IN target_list {
		IF target_vessel:ISTYPE("Vessel") { // Vérifie si c'est bien un vaisseau
			IF target_vessel:OBT:APOAPSIS > 70000 { // Vérifie si le vaisseau est en orbite
				IF has_docking_port(target_vessel) {
					vessels_with_ports:ADD(target_vessel:NAME).
				} ELSE {
					vessels_without_ports:ADD(target_vessel:NAME).
				}
			}
		}
	}

	// Affichage des résultats
	PRINT "=== Vaisseaux avec ports d'amarrage ===".
	IF vessels_with_ports:LENGTH = 0 {
		PRINT "Aucun vaisseau avec port d'amarrage trouvé.".
	} ELSE {
		FOR name IN vessels_with_ports {
			PRINT "- " + name.
		}
	}

	PRINT " ".
	PRINT "=== Vaisseaux sans port d'amarrage ===".
	IF vessels_without_ports:LENGTH = 0 {
		PRINT "Aucun vaisseau sans port d'amarrage trouvé.".
	} ELSE {
		FOR name IN vessels_without_ports {
			PRINT "- " + name.
		}
	}

	PRINT " ".
	PRINT "Analyse terminée.".

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
