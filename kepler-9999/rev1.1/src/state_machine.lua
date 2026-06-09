-- ==========================================
-- STATE MACHINE
-- ==========================================

states = {
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
    [STATE.HIGHSCORES] = {
        input  = inputHighScores,
        update = updateHighScores,
        draw   = drawHighScores,
    },
    [STATE.READY] = {
        input  = inputReady,
        update = updateReady,
        draw   = drawReady,
    },
    [STATE.PLAY] = {
        input  = inputPlay,
        update = updatePlay,
        draw   = drawPlay,
    },
    [STATE.PAUSE] = {
        input  = inputPause,
        update = updatePause,
        draw   = drawPause,
    },
    [STATE.SHOP] = {
        input  = inputShop,
        update = updateShop,
        draw   = drawShop,
    },
    [STATE.GAMEOVER] = {
        input  = inputGameover,
        update = updateGameover,
        draw   = drawGameover,
    },
}
