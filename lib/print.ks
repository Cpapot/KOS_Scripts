function betterPrint {
	parameter message. // string to print
	parameter newline. // 1 if a newline should be added, 0 otherwise

	PRINT SHIP:shipname + ":   " + message.
	IF newline = 2 {
		PRINT SHIP:shipname + ":   ...".
	}
	IF newline = 1 {
		PRINT " ".
	}
	IF newline = 3 {
		PRINT SHIP:shipname + ":   ...".
		PRINT " ".
	}
}

function countdown {
	parameter seconds.

	DECLARE i TO seconds.
	FROM {SET i TO seconds.} UNTIL i < 0 STEP {SET i TO i - 1.} DO {
		WAIT 1.
		betterPrint("T-" + i + " seconds", 0).
	}
	print "".
}

function countup {
	parameter seconds.

	DECLARE i TO 1.
	print "".
	FROM {SET i TO 1.} UNTIL i > seconds STEP {SET i TO i + 1.} DO {
		WAIT 1.
		betterPrint("T+" + i + " seconds", 0).
	}
}
