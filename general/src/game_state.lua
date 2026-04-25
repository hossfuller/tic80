-- ==========================================
-- GAME STATE
-- ==========================================

local STATE = {
    START    = "START",
    OPTIONS  = "OPTIONS",
    HISCORES = "HISCORES",
    READY    = "READY",
    PLAY     = "PLAY",
    PAUSE    = "PAUSE",
    GAMEOVER = "GAMEOVER",
}

local game = {
    state = STATE.START,
    prevState = nil,
    
    -- Menu state
    menu = {
        selected = 1,
        options = {"New Game", "Options", "High Scores"},
    },
    
    -- Options state
    options = {
        selected = 1,
        items = {
            {name = "Sound", values = {"On", "Off"}, current = 1},
            {name = "Difficulty", values = {"Easy", "Normal", "Hard"}, current = 2},
            {name = "Back", values = {""}, current = 1},
        },
    },
    
    -- High scores
    hiscores = {
        {name = "AAA", score = 10000},
        {name = "BBB", score = 7500},
        {name = "CCC", score = 5000},
        {name = "DDD", score = 2500},
        {name = "EEE", score = 1000},
    },
    
    -- Gameplay state
    play = {
        score = 0,
        -- Add your game-specific state here
        playerX = EDGE_X_RIGHT / 2,
        playerY = EDGE_Y_BOTTOM / 2,
    },
}


-- ==========================================
-- STATE CHANGE
-- ==========================================

local function changeState(newState)
    game.prevState = game.state
    game.state = newState
    
    -- State entry logic
    if newState == STATE.READY then
        -- Reset game state for new game
        game.play.score = 0
        game.play.playerX = EDGE_X_RIGHT / 2
        game.play.playerY = EDGE_Y_BOTTOM / 2
    end
end

