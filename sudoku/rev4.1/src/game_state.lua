-- ==========================================
-- GAME STATE
-- ==========================================

local STATE = {
    TITLE    = "TITLE",
    OPTIONS  = "OPTIONS",
    HISCORES = "HISCORES",
    PUZZLE   = "PUZZLE",
}

local game = {
    state = STATE.TITLE,
    prevState = nil,
    
    -- Menu state
    menu = {
        selected = 1,
        options = {"New Puzzle", "Options", "High Scores"},
    },
    
    -- Options state
    options = {
        selected = 1,
        items = {
            -- {name = "Sound", values = {"On", "Off"}, current = 1},
            {name = "Difficulty", values = {"Easy", "Medium", "Hard"}, current = 2},
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
    play = {},
}

local function changeState(newState)
    game.prevState = game.state
    game.state = newState
    
    -- State entry logic
    if newState == STATE.PUZZLE then
        -- Initialize new puzzle.

    end
end
