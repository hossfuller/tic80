-- ==========================================
-- GAME STATE
-- ==========================================

STATE = {
    START      = "START",
    PLAY       = "PLAY",
    GAMEOVER   = "GAMEOVER",
    HIGHSCORES = "HIGHSCORES",
}

game = {
    state = STATE.START,
    prevState = nil,

    -- Gameplay state
    play = {
        player = {},
        score  = 0,
    },

    high_scores = {},
}


-- ==========================================
-- STATE CHANGE
-- ==========================================

function changeState(newState)
    game.prevState = game.state
    game.state = newState

    -- State entry logic
    if newState == STATE.PLAY then
        -- Reset game state for new game
        game.play.player = SpaceShip.new()
        game.play.score  = 0

    elseif newState == STATE.HIGHSCORES then
        loadHighScores()
        sortHighScores()
        buildLines()
        scroll = 0
    end
end
