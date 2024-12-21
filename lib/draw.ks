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
