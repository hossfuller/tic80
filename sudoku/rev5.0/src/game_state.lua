-- ==========================================
-- GAME STATE
-- ==========================================

local STATE = {
    TITLE      = "TITLE",
    OPTIONS    = "OPTIONS",
    STATISTICS = "STATISTICS",
    PUZZLE     = "PUZZLE",
    NEWPUZZLE  = "NEWPUZZLE",
}

local game = {
    state = STATE.TITLE,
    prevState = nil,

    -- Menu state
    menu = {
        selected = 1,
        options = {"New Puzzle", "Options", "Statistics"},
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

    -- Statistics
    -- Load this from memory when game boots up.
    statistics = {
        {name = "AAA", score = 10000},
        {name = "BBB", score = 7500},
        {name = "CCC", score = 5000},
        {name = "DDD", score = 2500},
        {name = "EEE", score = 1000},
    },

    -- Gameplay state
    play = nil,
}

local function initializeNewGamePlayState()
    local cur_dt     = get_unix_timestamp()
    local cur_std_dt = unix_to_greg_utc(cur_dt)

    game.play = {
        date       = convert_datetime_obj_to_string(cur_std_dt), -- implemented
        difficulty = nil,    -- implemented
        solved     = false,  -- implemented
        autonotes  = 0,      -- implemented
        timer      = TimerObj.new(),
    }
end

local function changeState(newState)
    game.prevState = game.state
    game.state = newState

    -- State entry logic
    if newState == STATE.PUZZLE then
        initializeNewGamePlayState()

        -- Reset game state for new puzzle
        game.play.timer:reset()

        -- Initialize the cells
        initializeCells()

        -- Update sudoku.END_Y to reflect actual grid dimensions
        sudoku.END_Y = sudoku.cells[sudoku.DIM_X][sudoku.DIM_Y].y_bottom + 1

        -- Get the difficulty name from options
        local difficultyItem = game.options.items[1]  -- First item is Difficulty
        game.play.difficulty = difficultyItem.values[difficultyItem.current] -- "Easy", "Medium", or "Hard"

        -- Get a valid solution into the cells' 'value' settings.
        generateSolution()
        generatePuzzleByTier(game.play.difficulty)
    end
end