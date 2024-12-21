RUNPATH("0:/boot/lib/print.ks").

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
