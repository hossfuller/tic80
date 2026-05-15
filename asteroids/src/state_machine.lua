-- ==========================================
-- STATE MACHINE
-- ==========================================

local states = {
    [STATE.START] = {
        input  = inputStart,
        update = updateStart,
        draw   = drawStart,
    },
    [STATE.OPTIONS] = {
        input  = inputOptions,
        update = updateOptions,
        draw   = drawOptions,
    },
    [STATE.PLAY] = {
        input  = inputPlay,
        update = updatePlay,
        draw   = drawPlay,
    },
    [STATE.GAMEOVER] = {
        input  = inputGameover,
        update = updateGameover,
        draw   = drawGameover,
    },
    [STATE.HIGHSCORES] = {
        input  = inputHighScores,
        update = updateHighScores,
        draw   = drawHighScores,
    },
}
