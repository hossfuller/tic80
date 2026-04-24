-- ==========================================
-- STATE MACHINE
-- ==========================================

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
        playerX = SCREEN_W / 2,
        playerY = SCREEN_H / 2,
    },
}


local states = {
    [STATE.START] = {
        update = updateStart,
        draw = drawStart,
    },
    [STATE.OPTIONS] = {
        update = updateOptions,
        draw = drawOptions,
    },
    [STATE.HISCORES] = {
        update = updateHiscores,
        draw = drawHiscores,
    },
    [STATE.READY] = {
        update = updateReady,
        draw = drawReady,
    },
    [STATE.PLAY] = {
        update = updatePlay,
        draw = drawPlay,
    },
    [STATE.PAUSE] = {
        update = updatePause,
        draw = drawPause,
    },
    [STATE.GAMEOVER] = {
        update = updateGameover,
        draw = drawGameover,
    },
}


local function changeState(newState)
    game.prevState = game.state
    game.state = newState
    
    -- State entry logic
    if newState == STATE.READY then
        -- Reset game state for new game
        game.play.score = 0
        game.play.playerX = SCREEN_W / 2
        game.play.playerY = SCREEN_H / 2
    end
end
