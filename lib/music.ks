FUNCTION keyToHertz {
	parameter key.
	parameter octave.

    set note_offsets to lexicon(
        "C", -9,
        "C#", -8,
        "D", -7,
        "D#", -6,
        "E", -5,
        "F", -4,
        "F#", -3,
        "G", -2,
        "G#", -1,
        "A", 0,
        "A#", 1,
        "B", 2
    ).

    if not note_offsets:haskey(key) {
        print "Erreur : note invalide".
        return 0.
    }

    set semitone_offset to note_offsets[key] + 12 * (octave - 4).

    set frequency to 440 * 2^(semitone_offset / 12).

    return frequency.
}


FUNCTION createNote {
	parameter key.
	parameter octave.
	parameter note_duration.

	IF (note_duration = 0) {
		SET note_duration TO 0.1.
	}

	SET hertz TO keyToHertz(key, octave).

	if hertz = 0 {
		return 0.
	}

	// Create the note
	return NOTE(hertz, note_duration).
}
