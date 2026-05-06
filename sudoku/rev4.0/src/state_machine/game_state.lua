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
    state = STATE.START,
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
    
    -- Come back to this. Do we need it?
    -- Gameplay state
    play = {
        -- score = 0,
        -- -- Add your game-specific state here
        -- playerX = EDGE_X_RIGHT / 2,
        -- playerY = EDGE_Y_BOTTOM / 2,
    },
}


-- ==========================================
-- STATE CHANGE
-- ==========================================

local function changeState(newState)
    game.prevState = game.state
    game.state = newState
    
    -- State entry logic
    if newState == STATE.PUZZLE then
        -- Reset game state for new puzzle
        
        -- Initialize the cells
        initializeCells()

        -- Update sudoku.END_Y to reflect actual grid dimensions
        sudoku.END_Y = sudoku.cells[sudoku.DIM_X][sudoku.DIM_Y].y_bottom + 1

        -- Get a valid solution into the cells' 'value' settings.
        generateSolution()
        generatePuzzleByTier(SELECTED_DIFFICULTY)
    end
end

