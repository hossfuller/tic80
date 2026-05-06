--
-- Bundle file
-- Code changes will be overwritten
--

-- title:   Sudoku for TIC-80
-- author:  Adam Fuller <the.adam.fuller@gmail.com>
-- version: rev3
-- script:  lua
-- input: mouse

-- ==========================================
-- INCLUDES
-- ==========================================

-- [TQ-Bundler: src.constants]

-- ==========================================
-- CONSTANTS
-- ==========================================

-- Colors
local BLACK                  = 0
local PURPLE                 = 1
local RED                    = 2
local ORANGE                 = 3
local YELLOW                 = 4
local GREEN_LITE             = 5
local GREEN_MED              = 6
local GREEN_DARK             = 7
local BLUE_DARK              = 8
local BLUE_MED               = 9
local BLUE_LITE              = 10
local CYAN                   = 11
local WHITE                  = 12
local GRAY_LITE              = 13
local GRAY_MED               = 14
local GRAY_DARK              = 15

-- Screen dimensions
local EDGE_X_LEFT            = 0
local EDGE_X_RIGHT           = 240
local EDGE_Y_TOP             = 0
local EDGE_Y_BOTTOM          = 136

-- Character dimensions (these scale linearly)
local FIXED_CHAR_WIDTH       = 6
local FIXED_CHAR_HEIGHT      = 6

local X_PADDING              = FIXED_CHAR_WIDTH + 2
local Y_PADDING              = FIXED_CHAR_HEIGHT + 2
local CELL_WIDTH_MULTIPLIER  = 1.75
local CELL_HEIGHT_MULTIPLIER = 1.75
local GAP_CELL               = -1 -- between cells inside a house
local GAP_HOUSE              = 0  -- between houses (after col/row 3 and 6)

-- Game settings
local DIFFICULTY             = {
    easy       = { givens_min = 40, givens_max = 45, max_attempts = 1500, symmetric = true },
    medium     = { givens_min = 32, givens_max = 39, max_attempts = 2500, symmetric = true },
    hard       = { givens_min = 24, givens_max = 31, max_attempts = 6000, symmetric = true },
}


-- [/TQ-Bundler: src.constants]

-- [TQ-Bundler: src.sudoku.grid]

-- ==========================================
-- SUDOKU GRID DATA STRUCTURES
-- ==========================================

-- I could do this as a series of classes, but at this point in development I
-- just want to get this working rather than look pretty.

local function make_grid(overrides)
    local g = {
        DIM_X       = 9,
        DIM_Y       = 9,
        START_X     = EDGE_X_LEFT + X_PADDING,
        START_Y     = EDGE_Y_TOP + Y_PADDING,
        CELL_WIDTH  = CELL_WIDTH_MULTIPLIER * X_PADDING,
        CELL_HEIGHT = CELL_HEIGHT_MULTIPLIER * Y_PADDING,
        CELL_OFFSET = 2,
    }

    for k, v in pairs(overrides or {}) do g[k] = v end

    g.END_X = g.START_X + (g.DIM_X * g.CELL_WIDTH)
    g.END_Y = g.START_Y + (g.DIM_Y * g.CELL_HEIGHT)

    return g
end

local sudoku      = make_grid()
sudoku.clicked    = { i = nil, j = nil }
sudoku.cells      = {}
sudoku.difficulty = nil
sudoku.solved     = false

-- This one is just a convenience table for drawing a numeric representation of
-- the sudoku.notes grid.
local notes = make_grid({
    DIM_X   = 3,
    DIM_Y   = 3,
    START_X = sudoku.END_X + math.floor(FIXED_CHAR_WIDTH / 2)
})

local function newCell()
    return {
        x_left    = nil,
        x_right   = nil,
        y_top     = nil,
        y_bottom  = nil,
        solution  = nil,
        guess     = nil,
        locked    = false,
        notes     = { { false, false, false }, { false, false, false }, { false, false, false } },
        mouseover = false,
    }
end

local function gapBefore(index)
    -- index is 1..9, returns pixels before this cell
    -- There is a 1px gap before every cell except the first in each house.
    -- There is a 2px gap before the first cell of house 2 and 3 (i.e. index 4 and 7).
    if index == 1 then return 0 end
    if index == 4 or index == 7 then
        return GAP_HOUSE
    else
        return GAP_CELL
    end
end

local function initializeCells()
    for i = 1, sudoku.DIM_X do
        sudoku.cells[i] = {}
        for j = 1, sudoku.DIM_Y do
            local cell = newCell()

            local x = sudoku.START_X
            for c = 1, j - 1 do
                x = x + sudoku.CELL_WIDTH + gapBefore(c + 1)
            end

            local y = sudoku.START_Y
            for r = 1, i - 1 do
                y = y + sudoku.CELL_HEIGHT + gapBefore(r + 1)
            end

            cell.x_left        = x
            cell.y_top         = y
            cell.x_right       = x + sudoku.CELL_WIDTH - 1
            cell.y_bottom      = y + sudoku.CELL_HEIGHT - 1

            sudoku.cells[i][j] = cell
        end
    end
end


-- [/TQ-Bundler: src.sudoku.grid]

-- [TQ-Bundler: src.sudoku.buttons]

-- ==========================================
-- SUDOKU BUTTON DATA STRUCTURES
-- ==========================================

local function make_button(params)
    local g = {}

    g.TEXT         = params.TEXT         or "BUTTON"
    g.CLICKED      = params.CLICKED      or false
    g.PREV_CLICK   = params.PREV_CLICK   or false
    g.START_X      = params.START_X      or (EDGE_X_LEFT + X_PADDING)
    g.START_Y      = params.START_Y      or (EDGE_Y_TOP + Y_PADDING)
    g.END_X        = params.END_X        or (EDGE_X_RIGHT - FIXED_CHAR_WIDTH)
    g.CELL_WIDTH   = params.CELL_WIDTH   or (g.END_X - g.START_X)
    g.CELL_HEIGHT  = params.CELL_HEIGHT  or (FIXED_CHAR_HEIGHT + Y_PADDING)
    g.END_Y        = params.END_Y        or (g.START_Y + g.CELL_HEIGHT)
    g.TEXT_START_X = params.TEXT_START_X or (g.START_X + math.floor(X_PADDING / 2))
    g.TEXT_START_Y = params.TEXT_START_Y or (g.START_Y + math.floor(Y_PADDING / 2))
    g.BG_COLOR     = params.BG_COLOR     or YELLOW

    return g
end


local auto_note_btn = make_button({
    TEXT    = "AUTO-NOTE",
    START_X = notes.END_X + X_PADDING,
})
local undo_btn = make_button({
    TEXT    = "UNDO",
    START_X = notes.END_X + X_PADDING,
    START_Y = auto_note_btn.END_Y,
})
local clear_btn = make_button({
    TEXT    = "CLEAR",
    START_X = notes.END_X + X_PADDING,
    START_Y = undo_btn.END_Y,
})

local game_ctl_btn_width = math.floor((EDGE_X_RIGHT - FIXED_CHAR_WIDTH - notes.START_X) / 3)

local check_solution_btn = make_button({
    TEXT       = "CHECK",
    START_X    = notes.START_X,
    START_Y    = EDGE_Y_BOTTOM - (FIXED_CHAR_HEIGHT + (2 * Y_PADDING)),
    CELL_WIDTH = game_ctl_btn_width,
})
local new_puzzle_btn = make_button({
    TEXT       = "NEW",
    START_X    = check_solution_btn.START_X + check_solution_btn.CELL_WIDTH,   -- Chain from previous button
    START_Y    = check_solution_btn.START_Y,                                   -- Same row
    CELL_WIDTH = game_ctl_btn_width,
    BG_COLOR   = GREEN,
})
local exit_btn = make_button({
    TEXT       = "EXIT",
    START_X    = new_puzzle_btn.START_X + new_puzzle_btn.CELL_WIDTH,   -- Chain from previous button
    START_Y    = check_solution_btn.START_Y,                           -- Same row
    CELL_WIDTH = game_ctl_btn_width,
    BG_COLOR   = RED,
})

local puzzle_buttons = {
    auto_note_btn,
    undo_btn,
    clear_btn,
}
local game_ctl_buttons = {
    check_solution_btn,
    new_puzzle_btn,
    exit_btn,
}


-- [/TQ-Bundler: src.sudoku.buttons]

-- [TQ-Bundler: src.sudoku.logic]

-- ==========================================
-- SUDOKU LOGIC
-- ==========================================

-- God, I wish I'd paid more attention in linear algebra class....

--[[
## Generate a Valid Complete Grid
Starting with an empty 9x9 board, use a backtracking algorithm to fill it.
    1. Diagonal Fill (Optional for Speed): Fill the three diagonal 3x3 sub-grids
       first. Since they don't share rows or columns with each other, you can
       fill them with a random shuffle of numbers 1–9 without needing complex
       checks.
    2. Backtracking Search:
        1. Find the next empty cell.
        2. Pick a random number from 1 to 9.
        3. Check if it is "safe" (not present in the current row, column, or
           3x3 sub-grid).
        4. If safe, place it and move to the next cell.
        5. If you hit a dead end (no numbers are valid), backtrack to the
           previous cell and try a different number.
    3. Shuffle for Variety: You can also take a pre-existing valid board and
       apply transformations like swapping rows within a block, rotating the
       grid, or permuting the numbers (e.g., swapping all 1s with 5s).
--]]

-- Copies a grid instead of creating references to a pre-exisitng grid.
local function copy_grid(g)
    local out = {}
    for i = 1, 9 do
        out[i] = {}
        for j = 1, 9 do
            out[i][j] = g[i][j]
        end
    end
    return out
end

-- Shuffles a table with values 1..9
local function shuffled_1_to_9()
    local t = { 1, 2, 3, 4, 5, 6, 7, 8, 9 }
    for i = 9, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end

-- Kinda does the same thing as shuffled_1_to_9(), but instead of filling in an
-- empty grid, this lets us shift around a pre-exisitng grid.
local function shuffled_positions()
    local pos = {}
    for k = 1, 81 do
        pos[k] = k
    end
    for i = 81, 2, -1 do
        local j = math.random(i)
        pos[i], pos[j] = pos[j], pos[i]
    end
    return pos
end

-- Checks if a number can safely go into a specific cell of the grid.
local function isSafe(grid_cells, r, c, n)
    -- Checks the row
    for j = 1, 9 do
        if grid_cells[r][j] == n then
            return false
        end
    end

    -- Checks the col
    for i = 1, 9 do
        if grid_cells[i][c] == n then
            return false
        end
    end

    local r0 = math.floor((r - 1) / 3) * 3 + 1
    local c0 = math.floor((c - 1) / 3) * 3 + 1
    for i = r0, r0 + 2 do
        for j = c0, c0 + 2 do
            if grid_cells[i][j] == n then
                return false
            end
        end
    end
    return true
end

-- Finds an empty cell in the grid worth inserting a solution. Returns the
-- coordinates of an empty cell. When the grid is full, it returns nil.
local function findEmpty(grid_cells)
    for i = 1, 9 do
        for j = 1, 9 do
            if grid_cells[i][j] == 0 then
                return i, j
            end
        end
    end
    return nil
end

-- Recursively fill in the grid until we have a valid sudoku board.
local function fillGrid(grid_cells)
    local r, c = findEmpty(grid_cells)
    if not r then
        return true
    end -- solved

    local nums = shuffled_1_to_9()
    for k = 1, 9 do
        local n = nums[k]
        if isSafe(grid_cells, r, c, n) then
            grid_cells[r][c] = n
            if fillGrid(grid_cells) then
                return true
            end
            grid_cells[r][c] = 0
        end
    end

    return false
end

local function generateSolution()

    local init_grid = {
        { 0, 0, 0,  0, 0, 0,  0, 0, 0 },
        { 0, 0, 0,  0, 0, 0,  0, 0, 0 },
        { 0, 0, 0,  0, 0, 0,  0, 0, 0 },

        { 0, 0, 0,  0, 0, 0,  0, 0, 0 },
        { 0, 0, 0,  0, 0, 0,  0, 0, 0 },
        { 0, 0, 0,  0, 0, 0,  0, 0, 0 },

        { 0, 0, 0,  0, 0, 0,  0, 0, 0 },
        { 0, 0, 0,  0, 0, 0,  0, 0, 0 },
        { 0, 0, 0,  0, 0, 0,  0, 0, 0 },
    }

    -- This tracks whether or not each of the 3x3 diagonal houses have been
    -- filled.
    local filled = { [0] = false, [1] = false, [2] = false }

    for i = 1, 9 do
        for j = 1, 9 do
            -- We only want rows 1..3 with cols 1..3, rows 4..6 with cols 4..6,
            -- and rows 7..9 with col 7..9. As we iterate over i and j, we can
            -- calculate a "block index" of the row and column.
            local bi = math.floor((i-1)/3)
            local bj = math.floor((j-1)/3)
            -- These block indices will come out to either 0 (row/col 1..3),
            -- 1 (row/col 4..6), or 2 (row/col 7..9). If the block indices are
            -- the same, then we're working in one of the diagonal houses.
            if (
                bi == bj             -- block indices match, so we're on a diag.
                and not filled[bi]   -- we haven't filled this diag house.
                and (i - 1) % 3 == 0 -- we're on the left-most i of the house.
                and (j - 1) % 3 == 0 -- we're on the top-most j of the house.
            ) then
                filled[bi] = true

                local nums = shuffled_1_to_9()
                local k = 1

                -- This is the magic diagonal part.
                for r = i, i+2 do
                    for c = j, j+2 do
                        init_grid[r][c] = nums[k]
                        k = k + 1
                    end
                end
            end
        end
    end

    -- Fill in the rest of the grid now:
    assert(fillGrid(init_grid), "failed to generate a full grid")

    -- Now copy our unique, valid sudoku puzzle into the main sudoku structure.
    for i = 1, sudoku.DIM_X do
        for j = 1, sudoku.DIM_Y do
            sudoku.cells[i][j].solution = init_grid[i][j]
        end
    end
end

--[[
## Create the Puzzle by Removing Numbers
Simply removing X random numbers might result in a board that is unsolvable or
has multiple solutions. So we aim for strategic removal.
    1. Create a list of all 81 cell positions and shuffle it.
    2. Pick a cell and remove its value.
    3. Uniqueness Check: Use a Sudoku solver (often the same backtracking
       algorithm used in Step 1) to check if the board still has exactly one
       unique solution.
    4. If there is more than one solution, put the number back.
    5. Repeat until you have reached the desired difficulty or tested all cells.
--]]

-- As we hide cells, we want to count up the number of potential solutions. This
-- will work recursively to make sure there's only 1 solution. The moment it
-- hits 2, it reverses back and punts out.

local function countSolutions(g, limit)
    local r, c = findEmpty(g)
    if not r then
        return 1
    end -- found a complete solution

    local total = 0
    local nums = shuffled_1_to_9() -- random order; helps vary puzzles
    for k = 1, 9 do
        local n = nums[k]
        if isSafe(g, r, c, n) then
            g[r][c] = n
            total = total + countSolutions(g, limit - total)
            g[r][c] = 0
            if total >= limit then
                return total
            end -- early stop
        end
    end
    return total
end

-- Allows for symmetric clue removal.
local function symPos(r, c)
    return 10 - r, 10 - c
end

-- Remove clues while also keeping the puzzle's solution unique.
-- Parameters:
--   sol: fully solved puzzle
--   target_givens: how many filled cells we want left (e.g. 30-40)
--   max_attempts: cap on removal tries (prevents long runs)
--   symmetric: enables/disables symmetric clue removal.
local function makePuzzleUnique(sol, target_givens, max_attempts, symmetric)
    local puz = copy_grid(sol)
    local givens = 81
    local attempts = 0

    local order = shuffled_positions()
    local idx = 1

    while givens > target_givens and attempts < max_attempts do
        if idx > 81 then
            order = shuffled_positions()
            idx = 1
        end

        local k = order[idx]; idx = idx + 1
        local r = math.floor((k - 1) / 9) + 1
        local c = ((k - 1) % 9) + 1

        if puz[r][c] ~= 0 then
            local r2, c2 = symPos(r, c)

            -- If doing symmetry, we try to remove a pair.
            -- If the symmetric cell is already empty, we can either:
            --   * treat it as a single removal, or
            --   * skip to preserve "paired" removals.
            -- Here we allow single removal when the pair is already empty.
            local backup1 = puz[r][c]
            local backup2 = puz[r2][c2]

            local removing_two = symmetric and not (r == r2 and c == c2) and (backup2 ~= 0)

            puz[r][c] = 0
            if removing_two then puz[r2][c2] = 0 end

            local test = copy_grid(puz)
            local nsol = countSolutions(test, 2)

            if nsol ~= 1 then
                -- revert
                puz[r][c] = backup1
                if removing_two then puz[r2][c2] = backup2 end
            else
                -- keep
                givens = givens - 1
                if removing_two then givens = givens - 1 end
            end

            attempts = attempts + 1
        end
    end

    return puz
end

local function solutionCellsToGrid()
    local sol = {}
    for i = 1, 9 do
        sol[i] = {}
        for j = 1, 9 do
            sol[i][j] = sudoku.cells[i][j].solution
        end
    end
    return sol
end

local function applyPuzzleGridToCells(puzzle_grid)
    for i = 1, 9 do
        for j = 1, 9 do
            local cell = sudoku.cells[i][j]
            local clue = puzzle_grid[i][j] -- 0 means empty

            if clue ~= 0 then
                cell.guess  = clue
                cell.locked = true
                -- Clear notes for locked cells
                cell.notes  = { { false, false, false }, { false, false, false }, { false, false, false } }
            else
                cell.guess  = nil
                cell.locked = false
                cell.notes  = { { false, false, false }, { false, false, false }, { false, false, false } }
            end
        end
    end

    sudoku.clicked.i, sudoku.clicked.j = nil, nil
    sudoku.solved = false
end

-- Sets the difficulty target.
local function pickTargetGivens(tier)
    local a, b = tier.givens_min, tier.givens_max
    return a + math.random(b - a)
end

local function generatePuzzleByTier(name)
    local tier = DIFFICULTY[name] or DIFFICULTY.medium
    local target = pickTargetGivens(tier)

    local sol_grid = solutionCellsToGrid()
    local puzzle_grid = makePuzzleUnique(sol_grid, target, tier.max_attempts, tier.symmetric)

    applyPuzzleGridToCells(puzzle_grid)
    sudoku.difficulty = name
end


-- [/TQ-Bundler: src.sudoku.logic]

-- [TQ-Bundler: src.input]

-- ==========================================
-- INPUT FUNCTIONS
-- ==========================================

-- State variable to make sure a single click doesn't repeatedly toggle a cell.
local prev_left_click = false


local function checkInputOnPuzzleGrid(mouse_x, mouse_y, left_click, scroll_y, just_pressed)
    scroll_options = {nil, 1, 2, 3, 4, 5, 6, 7, 8, 9}
    for i = 1, sudoku.DIM_X do
        for j = 1, sudoku.DIM_Y do
            local cell = sudoku.cells[i][j]

            -- Is this a mouseover event?
            cell.mouseover =
                (cell.x_left <= mouse_x and mouse_x <= cell.x_right) and
                (cell.y_top <= mouse_y and mouse_y <= cell.y_bottom)

            -- Did the user click on this cell?
            if cell.mouseover and just_pressed then
                if sudoku.clicked.i == i and sudoku.clicked.j == j then
                    sudoku.clicked.i = nil
                    sudoku.clicked.j = nil
                else
                    sudoku.clicked.i = i
                    sudoku.clicked.j = j
                end
            end

            -- Is the user trying to change the number?
            if cell.locked == false and sudoku.clicked.i == i and sudoku.clicked.j == j then
                if scroll_y > 0 then
                    if cell.guess == nil then
                        cell.guess = 1
                    elseif cell.guess == 9 then
                        cell.guess = nil
                    else
                        cell.guess = cell.guess + 1
                    end
                elseif scroll_y < 0 then
                    if cell.guess == nil then
                        cell.guess = 9
                    elseif cell.guess == 1 then
                        cell.guess = nil
                    else
                        cell.guess = cell.guess - 1
                    end
                end
            end

            sudoku.cells[i][j] = cell
        end
    end
end


local function checkInputOnNotesGrid(mouse_x, mouse_y, just_pressed)
    -- First check to make sure a cell has been clicked. Otherwise we don't know
    -- what to work on.
    if sudoku.clicked.i == nil and sudoku.clicked.j == nil then
        return false
    end

    -- Here's the cell to work on.
    local cell = sudoku.cells[sudoku.clicked.i][sudoku.clicked.j]

    -- Is this cell locked (set at puzzle generation) or has a guess? Skip it.
    if cell.locked or cell.guess ~= nil then
        return false
    end

    -- Is the mouse over the notes grid? If so, nothing to do here.
    if mouse_x < notes.START_X or mouse_x >= notes.END_X then
        return false
    end
    if mouse_y < notes.START_Y or mouse_y >= notes.END_Y then
        return false
    end

    -- Only toggle on a fresh click
    if not just_pressed then
        return false
    end

    -- Calculate which note cell was clicked (1-3 for both row and column)
    local rel_x = mouse_x - notes.START_X
    local rel_y = mouse_y - notes.START_Y
    local n_j = math.floor(rel_x / notes.CELL_WIDTH) + 1
    local n_i = math.floor(rel_y / notes.CELL_HEIGHT) + 1

    -- Bounds check to make sure we're still working over the notes grid.
    if n_i < 1 or n_i > 3 or n_j < 1 or n_j > 3 then
        return false
    end

    -- Toggle the note
    cell.notes[n_i][n_j] = not cell.notes[n_i][n_j]

    return true -- Click was handled
end

local function checkButtonClicks(mouse_x, mouse_y, left_click, just_pressed)
    local handled = false

    for k, butt in pairs(puzzle_buttons) do
        -- Check if mouse is over this button
        local mouseover =
            (butt.START_X <= mouse_x and mouse_x <= butt.END_X) and
            (butt.START_Y <= mouse_y and mouse_y <= butt.END_Y)

        -- Button is clicked only while mouse is over and left button is held
        butt.CLICKED = mouseover and left_click

        if mouseover and just_pressed then
            handled = true
        end
    end

    return handled
end


function INPUT()
    local mouse_x, mouse_y, left_click, middle_click, right_click, scroll_x, scroll_y = mouse()

    local just_pressed = left_click and not prev_left_click
    prev_left_click = left_click

    -- Only work on the notes grid or the puzzle grid. Not both.
    local notes_handled   = checkInputOnNotesGrid(mouse_x, mouse_y, just_pressed)

    local buttons_handled = false
    if not notes_handled then
        buttons_handled = checkButtonClicks(mouse_x, mouse_y, left_click, just_pressed)
    end

    if not notes_handled and not buttons_handled then
        checkInputOnPuzzleGrid(mouse_x, mouse_y, left_click, scroll_y, just_pressed)
    end
end


-- [/TQ-Bundler: src.input]

-- [TQ-Bundler: src.update]

-- ==========================================
-- UPDATE FUNCTIONS
-- ==========================================


local function markNoteFalse(starting_notes, guess)
    if guess ~= nil and guess >= 1 and guess <= 9 then
        local row = math.ceil(guess / 3)
        local col = (guess - 1) % 3 + 1
        starting_notes[row][col] = false
    end
end

local function setSingleCellNotes(i, j)
    local starting_notes = {
        { true, true, true },
        { true, true, true },
        { true, true, true }
    }

    -- Check row
    for y = 1, 9 do
        markNoteFalse(starting_notes, sudoku.cells[i][y].guess)
    end

    -- Check column
    for x = 1, 9 do
        markNoteFalse(starting_notes, sudoku.cells[x][j].guess)
    end

    -- Check house
    local house_start_x = math.floor((i - 1) / 3) * 3 + 1
    local house_start_y = math.floor((j - 1) / 3) * 3 + 1

    for x = house_start_x, house_start_x + 2 do
        for y = house_start_y, house_start_y + 2 do
            markNoteFalse(starting_notes, sudoku.cells[x][y].guess)
        end
    end

    sudoku.cells[i][j].notes = starting_notes
end

local function checkAutoNote()
    for i = 1, sudoku.DIM_X do
        for j = 1, sudoku.DIM_Y do
            setSingleCellNotes(i, j)
        end
    end
end

local function checkPuzzle()
    local all_guesses_are_correct = true
    for i = 1, sudoku.DIM_X do
        for j = 1, sudoku.DIM_Y do
            local cell = sudoku.cells[i][j]
            if cell.guess ~= nil and cell.guess ~= cell.solution then
                all_guesses_are_correct = false
            end
        end
    end
    sudoku.solved = all_guesses_are_correct
end

local function clearGuessesAndNotes()
    for i = 1, sudoku.DIM_X do
        for j = 1, sudoku.DIM_Y do
            if sudoku.cells[i][j].locked == false then
                sudoku.cells[i][j].guess = nil
                sudoku.cells[i][j].notes = { { false, false, false }, { false, false, false }, { false, false, false } }
            end
        end
    end
end

function UPDATE()
    if auto_note_btn.CLICKED == true then
        checkAutoNote()
    end

    if check_solution_btn.CLICKED == true then
        checkPuzzle()
    end

    if clear_btn.CLICKED == true then
        clearGuessesAndNotes()
    end
end


-- [/TQ-Bundler: src.update]

-- [TQ-Bundler: src.draw]

-- ==========================================
-- DRAW FUNCTIONS
-- ==========================================

function drawPuzzle()
    for i = 1, sudoku.DIM_X do
        for j = 1, sudoku.DIM_Y do
            local cell = sudoku.cells[i][j]

            local cell_bgcolor = GRAY_DARK
            local grid_x       = cell.x_left
            local grid_y       = cell.y_top
            local grid_width   = cell.x_right - cell.x_left + 1
            local grid_height  = cell.y_bottom - cell.y_top + 1

            -- Check cell status and change the cell's background color.
            if cell.locked == true then
                cell_bgcolor = BLACK
            elseif sudoku.clicked.i == i and sudoku.clicked.j == j then
                cell_bgcolor = YELLOW
            elseif cell.mouseover == true then
                cell_bgcolor = PURPLE
            elseif check_solution_btn.CLICKED == true then
                if cell.guess ~= nil and cell.guess ~= cell.solution then
                    cell_bgcolor = RED
                end
            end
            rect(grid_x, grid_y, grid_width, grid_height, cell_bgcolor)

            -- If there isn't a guess, print the notes.
            if cell.guess == nil then
                local note_w = math.floor(grid_width / 3)
                local note_h = math.floor(grid_height / 3)

                for n_i = 1, 3 do
                    for n_j = 1, 3 do
                        if cell.notes[n_i][n_j] then
                            local nx = 1 + grid_x + (n_j - 1) * note_w
                            local ny = 1 + grid_y + (n_i - 1) * note_h
                            rect(nx, ny, note_w, note_h, GRAY_LITE)
                        end
                    end
                end

                -- Otherwise print the guess if there is one.
            else
                print(cell.guess, grid_x + 2, grid_y + 2, WHITE, true, 2)
            end

            -- Finally, draw the grid.
            rectb(grid_x, grid_y, grid_width, grid_height, WHITE)
        end
    end
end


local function drawNotesGrid()
    local grid_x = notes.START_X
    local grid_y = notes.START_Y

    local cell_w = notes.CELL_WIDTH
    local cell_h = notes.CELL_HEIGHT

    local active_cell_notes = nil
    if (sudoku.clicked.i ~= nil) and (sudoku.clicked.j ~= nil) then
        active_cell_notes = sudoku.cells[sudoku.clicked.i][sudoku.clicked.j].notes
    end

    local n = 1
    for i = 1, notes.DIM_X do
        for j = 1, notes.DIM_Y do
            local num_color = GRAY_LITE

            local x = grid_x + (j - 1) * cell_w
            local y = grid_y + (i - 1) * cell_h

            if (active_cell_notes ~= nil) and (active_cell_notes[i][j] == true) then
                num_color = YELLOW
            end

            rectb(x, y, cell_w, cell_h, WHITE)     -- cell border
            print(n, x + 2, y + 2, num_color, true, 2) -- number

            n = n + 1
        end
    end
end

local function drawPuzzleButtons()
    for i, butt in ipairs(puzzle_buttons) do 
        local text_color = WHITE
        local bg_color   = GRAY_DARK
        if butt.CLICKED then
            text_color = GRAY_DARK
            bg_color = YELLOW
        end
        rect(butt.START_X, butt.START_Y, butt.CELL_WIDTH, butt.CELL_HEIGHT, bg_color)
        rectb(butt.START_X, butt.START_Y, butt.CELL_WIDTH, butt.CELL_HEIGHT, WHITE)
        print(butt.TEXT, butt.TEXT_START_X, butt.TEXT_START_Y, text_color, false, 1, true)
    end
end

local function drawGameButtons()
    for i, butt in ipairs(game_ctl_buttons) do 
        local text_color = WHITE
        local bg_color   = GRAY_DARK
        if butt.CLICKED then
            text_color = GRAY_DARK
            bg_color = YELLOW
        end
        rect(butt.START_X, butt.START_Y, butt.CELL_WIDTH, butt.CELL_HEIGHT, bg_color)
        rectb(butt.START_X, butt.START_Y, butt.CELL_WIDTH, butt.CELL_HEIGHT, WHITE)
        print(butt.TEXT, butt.TEXT_START_X, butt.TEXT_START_Y, text_color, false, 1, true)
    end
end

local function drawStatBox()
    local box_start_x = notes.START_X
    local box_start_y = notes.END_Y + Y_PADDING
    local box_width = (EDGE_X_RIGHT - FIXED_CHAR_WIDTH) - box_start_x

    -- Line the stat box up with the bottom of the sudoku grid.
    local sudoku_end_y = sudoku.cells[sudoku.DIM_X][sudoku.DIM_Y].y_bottom
    local box_height = sudoku_end_y - box_start_y + 1

    rect(box_start_x, box_start_y, box_width, box_height, BLACK)
    rectb(box_start_x, box_start_y, box_width, box_height, WHITE)

    -- -- Now print all the stats there are to print.
    -- -- ...
    -- local start_x = box_start_x + X_PADDING
    -- local start_y = box_start_y + Y_PADDING
    -- for k, butt in pairs(puzzle_buttons) do
    --     print(butt.TEXT .. " = " .. tostring(butt.CLICKED), start_x, start_y, WHITE, false, 1, true)
    --     start_y = start_y + Y_PADDING
    -- end
end


function DRAW()
    cls(BLACK)

    -- Screen border
    rectb(
        EDGE_X_LEFT,
        EDGE_Y_TOP,
        EDGE_X_RIGHT,
        EDGE_Y_BOTTOM,
        WHITE
    )

    drawPuzzle()
    drawNotesGrid()
    drawPuzzleButtons()
    -- drawStatBox()
    drawGameButtons()
end




-- [/TQ-Bundler: src.draw]

-- ==========================================
-- INITIALIZATION FUNCTIONS
-- ==========================================

function INIT()
    -- Initialize the cells
    initializeCells()

    -- Update sudoku.END_Y to reflect actual grid dimensions
    sudoku.END_Y = sudoku.cells[sudoku.DIM_X][sudoku.DIM_Y].y_bottom + 1

    -- Get a valid solution into the cells' 'value' settings.
    generateSolution()
    generatePuzzleByTier('easy')
end -- INIT()

-- ==========================================
-- MAIN GAME LOOP
-- ==========================================

INIT()

function TIC()
    INPUT()
    UPDATE()
    DRAW()
end
