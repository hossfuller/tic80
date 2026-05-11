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

    -- Statistics: load from memory every time we go to the high scores screen,
    -- and save to memory every time we hit a solve a puzzle.
    statistics = {},

    -- Gameplay state
    play = nil,
}

local function initializeNewGamePlayState()
    game.play = {
        date       = get_unix_timestamp(),  -- convert to a string on display
        difficulty = nil,
        solved     = false,
        autonotes  = 0,
        timer      = TimerObj.new(),
    }
end

local function saveCurrentScore()
    -- Need to save the following:
    --  1. game.play.date - stored as the unix timestamp.
    --  2. game.play.difficulty - convert to an integer for storage.
    --  3. game.play.timer:getSeconds() - integer of total seconds.
    --  4. game.play.autonotes - already an integer.


end

local function loadHighScores()
    -- Don't sort here. Sorting happens when we want to print them.
    -- Convert game.play.date to a human-readable date after sort but before print.

end

local function sortHighScores()
    -- Sort by difficulty, then by time, then by autonotes.

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