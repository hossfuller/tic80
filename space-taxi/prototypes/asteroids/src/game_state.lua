-- ==========================================
-- GAME STATE
-- ==========================================

local STATE = {
    START    = "START",
    PLAY     = "PLAY",
    GAMEOVER = "GAMEOVER",
}

local game = {
    state = STATE.START,
    prevState = nil,

    -- Gameplay state
    play = {
        score = 0,
    },
}


-- ==========================================
-- STATE CHANGE
-- ==========================================

local function changeState(newState)
    game.prevState = game.state
    game.state = newState

    -- State entry logic
    if newState == STATE.PLAY then
        -- Reset game state for new game
        game.play.score = 0
    end
end
