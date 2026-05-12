--
-- Bundle file
-- Code changes will be overwritten
--

-- title:   Sussudioku! (Sudoku for TIC-80)
-- author:  Hoss Fuller <hossfuller@proton.me>
-- version: 1.0
-- script:  lua
-- input:   mouse
-- saveid:  sussudioku_bang_bang

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

-- Button mappings
local BTN_P1_UP    = 0
local BTN_P1_DOWN  = 1
local BTN_P1_LEFT  = 2
local BTN_P1_RIGHT = 3
local BTN_P1_A     = 4  -- Primary action / Select
local BTN_P1_B     = 5  -- Secondary action / Back / Pause
local BTN_P1_X     = 6
local BTN_P1_Y     = 7

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



-- [/TQ-Bundler: src.constants]

-- [TQ-Bundler: src.helpers]

-- ==========================================
-- HELPERS
-- ==========================================

-- ==========================================
-- TIME HELPERS
-- ==========================================

local mdays_common = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }

local function get_unix_timestamp()
    return math.tointeger(tstamp())
end

local function convert_datetime_obj_to_string(datetime_obj)
    return string.format(
        "%04d-%02d-%02d",
        datetime_obj.year,
        datetime_obj.month,
        datetime_obj.day
    )
end

local function is_greg_leap(y)
    return (y % 4 == 0) and ((y % 100 ~= 0) or (y % 400 == 0))
end

local function greg_days_in_month(y, m)
    if m == 2 and is_greg_leap(y) then return 29 end
    return mdays_common[m]
end

-- Unix seconds -> Gregorian UTC date/time (year,month,day,hour,min,sec)
local function unix_to_greg_utc(ts)
    local sec_per_day = 86400
    local days        = math.floor(ts / sec_per_day)
    local sod         = ts - days * sec_per_day
    if sod < 0 then
        sod = sod + sec_per_day
        days = days - 1
    end

    local hour = math.floor(sod / 3600); sod = sod - hour * 3600
    local min  = math.floor(sod / 60)
    local sec  = sod - min * 60

    local y    = 1970
    if days >= 0 then
        while true do
            local diy = is_greg_leap(y) and 366 or 365
            if days >= diy then
                days = days - diy
                y = y + 1
            else
                break
            end
        end
    else
        while days < 0 do
            y = y - 1
            local diy = is_greg_leap(y) and 366 or 365
            days = days + diy
        end
    end

    local m = 1
    while true do
        local dim = greg_days_in_month(y, m)
        if days >= dim then
            days = days - dim
            m = m + 1
        else
            break
        end
    end

    local d = days + 1

    return {
        year  = y,
        month = m,
        day   = d,
        hour  = hour,
        min   = min,
        sec   = sec
    }
end

-- ==========================================
-- INPUT HELPERS
-- ==========================================

-- Input tracking for edge detection
local input = {
    prev = {},
    curr = {},
}

local function btnPressed(id)
    return input.curr[id] and not input.prev[id]
end

-- ==========================================
-- DRAWING HELPERS
-- ==========================================

local function drawCenteredText(text, y, color, fixed, scale, smallfont, shadow_color)
    if fixed == nil then
        fixed = false
    end
    if scale == nil then
        scale = 1
    end
    if smallfont == nil then
        smallfont = false
    end
    if shadow_color == nil then
        shadow_color = -1
    end
    local width = print(text, 0, -50, color, fixed, scale, smallfont)

    if shadow_color >= 0 then
        print(text, (EDGE_X_RIGHT - width) / 2 + 1, y + 1, shadow_color, fixed, scale, smallfont)
    end
    print(text, (EDGE_X_RIGHT - width) / 2, y, color, fixed, scale, smallfont)
end

local function drawOverlayBox(text_array)
    local boxW = 120
    local boxH = 40
    local boxX = math.floor((EDGE_X_RIGHT - boxW) / 2)
    local boxY = math.floor((EDGE_Y_BOTTOM - boxH) / 2)

    -- Draw box background
    rect(boxX, boxY, boxW, boxH, BLACK)
    rectb(boxX, boxY, boxW, boxH, WHITE)

    -- Draw text
    for i, text in ipairs(text_array) do
        drawCenteredText(text, boxY + (i * Y_PADDING), WHITE)
    end
end


-- [/TQ-Bundler: src.helpers]

-- [TQ-Bundler: src.timer]

-- ==========================================
-- TIMER OBJECT
-- ==========================================

TimerObj = {}
TimerObj.__index = TimerObj

-- Creates a new TimerObj instance
function TimerObj.new(params)
    params = params or {}
    local self = setmetatable({}, TimerObj)

    self.running       = false
    self.start_time    = params.start_time or 0
    self.saved_time    = params.saved_time or 0
    self.elapsed_time  = params.elapsed_time or 0
    self.max_mininutes = params.max_mininutes or 99
    self.max_seconds   = params.max_seconds or 59
    return self
end

-- Starts the timer
function TimerObj:start()
    if not self.running then
        self.running    = true
        self.start_time = time()
    end
end

-- Pauses the timer
function TimerObj:stop()
    if self.running then
        self.saved_time = self.saved_time + (time() - self.start_time)
        self.running    = false
    end
end

-- Resets timer to 00:00
function TimerObj:reset()
    self.running      = false
    self.start_time   = 0
    self.saved_time   = 0
    self.elapsed_time = 0
end

-- Updates elapsed time (call each frame)
function TimerObj:update()
    if self.running then
        self.elapsed_time = self.saved_time + (time() - self.start_time)
    else
        self.elapsed_time = self.saved_time
    end
end

-- Returns total elapsed seconds
function TimerObj:getSeconds()
    return math.floor(self.elapsed_time / 1000)
end

-- Returns total elapsed minutes
function TimerObj:getMinutes()
    return math.floor(self:getSeconds() / 60)
end

-- Returns time as "MM:SS" string
function TimerObj:getFormatted()
    local totalSeconds = self:getSeconds()
    local minutes      = math.floor(totalSeconds / 60)
    local seconds      = totalSeconds % 60

    if minutes > self.max_mininutes then
        minutes = self.max_mininutes
        seconds = self.max_seconds
    end

    return string.format("%02d:%02d", minutes, seconds)
end

-- Returns true if timer is active
function TimerObj:isRunning()
    return self.running
end


-- [/TQ-Bundler: src.timer]

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

    -- Calculate END_X properly: if CELL_WIDTH is given, use it; otherwise use default END_X
    if params.CELL_WIDTH then
        g.CELL_WIDTH = params.CELL_WIDTH
        g.END_X      = g.START_X + g.CELL_WIDTH
    else
        g.END_X      = params.END_X or (EDGE_X_RIGHT - FIXED_CHAR_WIDTH)
        g.CELL_WIDTH = g.END_X - g.START_X
    end

    g.CELL_HEIGHT  = params.CELL_HEIGHT  or (FIXED_CHAR_HEIGHT + Y_PADDING)
    g.END_Y        = params.END_Y        or (g.START_Y + g.CELL_HEIGHT)
    g.TEXT_START_X = params.TEXT_START_X or (g.START_X + math.floor(X_PADDING / 2))
    g.TEXT_START_Y = params.TEXT_START_Y or (g.START_Y + math.floor(Y_PADDING / 2))
    g.BG_COLOR     = params.BG_COLOR     or YELLOW
    g.COUNT_CLICKS = params.COUNT_CLICKS or false

    return g
end

local auto_note_btn = make_button({
    TEXT         = "AUTO-NOTE",
    START_X      = notes.END_X + X_PADDING,
    COUNT_CLICKS = true,
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
    BG_COLOR   = GREEN_MED,
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
    check_solution_btn,
    new_puzzle_btn,
    exit_btn,
}


-- [/TQ-Bundler: src.sudoku.buttons]

-- [TQ-Bundler: src.sudoku.logic]

-- ==========================================
-- SUDOKU LOGIC
-- ==========================================

local DIFFICULTY = {
    Easy       = { givens_min = 40, givens_max = 45, max_attempts = 1500, symmetric = true },
    Medium     = { givens_min = 32, givens_max = 39, max_attempts = 2500, symmetric = true },
    Hard       = { givens_min = 24, givens_max = 31, max_attempts = 6000, symmetric = true },
}

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
end


-- [/TQ-Bundler: src.sudoku.logic]

-- [TQ-Bundler: src.sudoku.undo]

-- ==========================================
-- UNDO FUNCTION
-- ==========================================

local checkAutoNote -- forward declaration, see src.states.puzzle

local undo_list = {}

local function register_action(x_pos, y_pos, new_value, prev_value)
    undo_list[#undo_list + 1] = {
        x    = x_pos,
        y    = y_pos,
        new  = new_value,
        prev = prev_value,
    }
end

local function undo_last_action()
    local last_action = table.remove(undo_list)
    if last_action ~= nil then
        if sudoku.cells[last_action.x][last_action.y].guess == last_action.new then
            sudoku.cells[last_action.x][last_action.y].guess = last_action.prev

            -- If the auto-note button has been pressed in the past, rerun the
            -- auto-note functionality without incrementing the auto-note counter.
            if game.play.autonotes > 0 then
                checkAutoNote()
            end
        end
    end
end

-- [/TQ-Bundler: src.sudoku.undo]

-- [TQ-Bundler: src.game_state]

-- ==========================================
-- GAME STATE
-- ==========================================

local loadHighScores
local sortHighScores
local buildLines
local scroll = 0


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

    elseif newState == STATE.STATISTICS then
        loadHighScores()
        sortHighScores()
        buildLines()
        scroll = 0
    end
end

-- [/TQ-Bundler: src.game_state]

-- [TQ-Bundler: src.states.title]

-- ==========================================
-- STATE: TITLE (Main Menu)
-- ==========================================

local function updateTitle()
    -- Menu navigation
    if btnPressed(BTN_P1_UP) then
        game.menu.selected = game.menu.selected - 1
        if game.menu.selected < 1 then
            game.menu.selected = #game.menu.options
        end
    end

    if btnPressed(BTN_P1_DOWN) then
        game.menu.selected = game.menu.selected + 1
        if game.menu.selected > #game.menu.options then
            game.menu.selected = 1
        end
    end

    -- Menu selection
    if btnPressed(BTN_P1_A) then
        local selected = game.menu.selected
        if selected == 1 then
            changeState(STATE.PUZZLE)
        elseif selected == 2 then
            changeState(STATE.OPTIONS)
        elseif selected == 3 then
            changeState(STATE.STATISTICS)
        end
    end
end

local function drawTitle()
    cls(BLACK)

    -- Draw the background.
    map(0, 0, 30, 17, 0, 0)

    -- Title
    drawCenteredText("SUSSUDIOKU!!", 20, ORANGE, nil, 3, nil, YELLOW)

    -- Menu options
    local start_y = 60
    local spacing = 2 * X_PADDING

    for i, option in ipairs(game.menu.options) do
        local y = start_y + (i - 1) * spacing
        local color = (i == game.menu.selected) and ORANGE or WHITE

        -- Draw selector
        if i == game.menu.selected then
            local textWidth = print(option, 0, -10)
            local x = (EDGE_X_RIGHT - textWidth) / 2
            print(">", x - 10 + 1, y + 1, BLACK) -- the shadow
            print(">", x - 10, y, WHITE)
        end

        -- drawCenteredText(option, y, color)
        drawCenteredText(option, y, color, nil, nil, nil, BLACK)
    end

    -- Instructions
    drawCenteredText("UP/DOWN: Select  A: Confirm", EDGE_Y_BOTTOM - Y_PADDING, WHITE, false, 1, true, BLACK)
end


-- [/TQ-Bundler: src.states.title]

-- [TQ-Bundler: src.states.options]

-- ==========================================
-- STATE: OPTIONS
-- ==========================================

local function updateOptions()
    local opts = game.options

    -- Navigation
    if btnPressed(BTN_P1_UP) then
        opts.selected = opts.selected - 1
        if opts.selected < 1 then
            opts.selected = #opts.items
        end
    end

    if btnPressed(BTN_P1_DOWN) then
        opts.selected = opts.selected + 1
        if opts.selected > #opts.items then
            opts.selected = 1
        end
    end

    -- Change option value
    local currentItem = opts.items[opts.selected]

    if btnPressed(BTN_P1_LEFT) and #currentItem.values > 1 then
        currentItem.current = currentItem.current - 1
        if currentItem.current < 1 then
            currentItem.current = #currentItem.values
        end
    end

    if btnPressed(BTN_P1_RIGHT) and #currentItem.values > 1 then
        currentItem.current = currentItem.current + 1
        if currentItem.current > #currentItem.values then
            currentItem.current = 1
        end
    end

    -- Select (for Back option) or Back button
    if btnPressed(BTN_P1_A) then
        if opts.items[opts.selected].name == "Back" then
            changeState(STATE.TITLE)
        end
    end

    if btnPressed(BTN_P1_B) then
        changeState(STATE.TITLE)
    end
end

local function drawOptions()
    cls(BLACK)

    -- Draw the background.
    map(30, 0, 30, 17, 0, 0)

    -- Title
    drawCenteredText("OPTIONS", EDGE_Y_TOP + Y_PADDING, ORANGE, nil, 3, nil, YELLOW)

    -- Options list
    local startY = 50
    local spacing = 20

    for i, item in ipairs(game.options.items) do
        local y = startY + (i - 1) * spacing
        local color = (i == game.options.selected) and ORANGE or WHITE

        -- Draw selector
        if i == game.options.selected then
            print(">", 30 + 1, y + 1, BLACK) -- the shadow
            print(">", 30, y, WHITE)
        end

        -- Draw option name and value
        print(item.name, 45 + 1, y + 1, BLACK) -- the shadow
        print(item.name, 45, y, color)

        if #item.values > 0 and item.values[1] ~= "" then
            local valueText = "< " .. item.values[item.current] .. " >"
            print(valueText, 140 + 1, y + 1, BLACK) -- the shadow
            print(valueText, 140, y, color)
        end
    end

    -- Instructions
    drawCenteredText("UP/DOWN: Select  LEFT/RIGHT: Change", EDGE_Y_BOTTOM - Y_PADDING, WHITE, false, 1, true, BLACK)
end


-- [/TQ-Bundler: src.states.options]

-- [TQ-Bundler: src.states.statistics]

-- ==========================================
-- STATE: STATISTICS
-- ==========================================

local MAX_PMEM_CHUNKS = 63

local lines = {}


-- Persistent memory has 255 slots. We want to save four pieces of data, so that
-- restricts us to 252 slots (63 chunks of 4 slots).

function loadHighScores()
    -- Don't sort here. Sorting happens when we want to print them.
    -- Convert game.play.date to a human-readable date after sort but before print.
    game.statistics = {}

    for idx = 0, MAX_PMEM_CHUNKS do
        local base = idx * 4
        local date = pmem(base + 0)
        if date ~= 0 then
            game.statistics[base] = {
                date       = date,
                difficulty = pmem(base + 1),
                timer      = pmem(base + 2),
                autonotes  = pmem(base + 3),
            }
        end
    end
end

function sortHighScores()
    -- Collect existing entries (0,4,8,...) into a dense list
    local list = {}
    for idx = 0, MAX_PMEM_CHUNKS do
        local base = idx * 4
        local d = game.statistics[base]
        if d then
            list[#list + 1] = d
        end
    end

    -- Sort by difficulty desc, then by time asc, then by autonotes asc.
    table.sort(list, function(a, b)
        if a.difficulty ~= b.difficulty then
            return a.difficulty > b.difficulty
        end
        if a.timer ~= b.timer then
            return a.timer < b.timer
        end
        if a.autonotes ~= b.autonotes then
            return a.autonotes < b.autonotes
        end
        -- optional tiebreaker so order is stable-ish
        return a.date > b.date
    end)

    -- Write back compacted into chunk keys 0,4,8,...
    game.statistics = {}
    for i = 1, #list do
        game.statistics[(i - 1) * 4] = list[i]
    end
end

local function saveCurrentScore()
    -- Always start from what is currently saved
    loadHighScores()

    -- Find next free chunk index in the CURRENT in-memory table
    local n = 0
    for idx = 0, MAX_PMEM_CHUNKS do
        if game.statistics[idx * 4] then n = n + 1 end
    end
    local base = n * 4
    if base > MAX_PMEM_CHUNKS * 4 then
        base = MAX_PMEM_CHUNKS * 4 -- will be trimmed after sort
    end

    -- Map difficulty string -> numeric rank for storage/sorting
    local diff = (game.play.difficulty == "Easy" and 0)
              or (game.play.difficulty == "Medium" and 1)
              or 2

    -- Add current result
    game.statistics[base] = {
        date       = game.play.date,
        difficulty = diff,
        timer      = game.play.timer:getSeconds(),
        autonotes  = game.play.autonotes,
    }

    -- Sort + compact keys to 0,4,8,...
    sortHighScores()

    -- Save the data.
    for i = 0, 255 do pmem(i, 0) end
    for idx = 0, MAX_PMEM_CHUNKS do
        local b = idx * 4
        local d = game.statistics[b]
        if d then
            pmem(b + 0, d.date)
            pmem(b + 1, d.difficulty)
            pmem(b + 2, d.timer)
            pmem(b + 3, d.autonotes)
        end
    end
end


function buildLines()
    -- Show only the saved/sorted entries (0,4,8,...,252)
    lines = {}
    for idx = 0, MAX_PMEM_CHUNKS do
        local k = idx * 4
        local d = game.statistics[k]
        if d then
            local dt_obj = unix_to_greg_utc(d.date)
            local dt_str = convert_datetime_obj_to_string(dt_obj)
            table.insert(lines, dt_str)

            local diff = (d.difficulty == 0 and "Easy")
                or (d.difficulty == 1 and "Medium")
                or (d.difficulty == 2 and "Hard")
            table.insert(lines, string.format("      Difficulty   %s", diff))

            local minutes = math.floor(d.timer / 60)
            local seconds = d.timer % 60
            table.insert(lines, string.format("      Clock         %02d:%02d", minutes, seconds))

            table.insert(lines, string.format("      Auto-Notes  %s", d.autonotes))
            table.insert(lines, "") -- blank spacer line
        end
    end
end


local function updateStatistics()
    if btnPressed(BTN_P1_A) or btnPressed(BTN_P1_B) then
        changeState(STATE.TITLE)
        return
    end
end


local function drawStatistics()
    cls(BLACK)

    -- Draw the background.
    map(0, 17, 30, 17, 0, 0)

    -- LAYOUT

    local header_y = EDGE_Y_TOP + Y_PADDING
    local line_h = FIXED_CHAR_HEIGHT + 1
    local view_top = header_y + FIXED_CHAR_HEIGHT + 2* Y_PADDING
    local view_bottom = EDGE_Y_BOTTOM - 2 * Y_PADDING
    local visible_lines = math.max(1, math.floor((view_bottom - view_top) / line_h))

    -- INPUT
    local mouse_x, mouse_y, left_click, middle_click, right_click, scroll_x, scroll_y = mouse()
    local max_scroll = math.max(0, #lines - visible_lines)

    -- keyboard (hold+repeat)
    if btnp(BTN_P1_UP, 15, 3) then
        scroll = scroll - 1
    end
    if btnp(BTN_P1_DOWN, 15, 3) then
        scroll = scroll + 1
    end

    -- mouse wheel (usually +1/-1 per notch)
    if scroll_y ~= 0 then
        scroll = scroll - scroll_y
    end

    -- clamp
    scroll = math.max(0, math.min(max_scroll, scroll))

    -- drawCenteredText("STATISTICS", EDGE_Y_TOP + Y_PADDING, WHITE)
    drawCenteredText("STATISTICS", EDGE_Y_TOP + Y_PADDING, ORANGE, nil, 3, nil, YELLOW)

    -- draw visible slice
    for i = 0, visible_lines - 1 do
        local line = lines[scroll + 1 + i] -- Lua arrays are 1-based
        if not line then break end
        local y = view_top + i * line_h
        print(line, X_PADDING + 1, y + 1, BLACK) -- the shadow
        print(line, X_PADDING, y, WHITE)
    end

    -- Small scrollbar indicator
    if max_scroll > 0 then
        local bar_x = EDGE_X_RIGHT - 4
        rect(bar_x, view_top, 2, view_bottom - view_top, GRAY_DARK)
        local thumb_h = math.max(4, math.floor((view_bottom - view_top) * (visible_lines / #lines)))
        local thumb_y = view_top + math.floor((view_bottom - view_top - thumb_h) * (scroll / max_scroll))
        rect(bar_x, thumb_y, 2, thumb_h, GREEN_LITE)
    end

    -- Instructions
    drawCenteredText("Press A or B to return", EDGE_Y_BOTTOM - Y_PADDING, WHITE, false, 1, true, BLACK)
end


-- [/TQ-Bundler: src.states.statistics]

-- [TQ-Bundler: src.states.puzzle]

-- ==========================================
-- STATE: PUZZLE
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

function checkAutoNote()
    for i = 1, sudoku.DIM_X do
        for j = 1, sudoku.DIM_Y do
            setSingleCellNotes(i, j)
        end
    end
end

local function checkPuzzle()
    local all_guesses_are_correct = false
    local all_cells_are_filled_in = true

    for i = 1, sudoku.DIM_X do
        for j = 1, sudoku.DIM_Y do
            local cell = sudoku.cells[i][j]
            if cell.guess == nil then
                all_cells_are_filled_in = false
            end
        end
    end

    -- Only if all cells are filled in do we check if solution is complete.
    if all_cells_are_filled_in then
        all_guesses_are_correct = true
        for i = 1, sudoku.DIM_X do
            for j = 1, sudoku.DIM_Y do
                local cell = sudoku.cells[i][j]
                if cell.guess ~= cell.solution then
                    all_cells_are_filled_in = false
                end
            end
        end
    end
    game.play.solved = all_guesses_are_correct

    -- Stop the clock and register "score" in high scores
    if all_guesses_are_correct then
        game.play.timer:stop()
        saveCurrentScore()
    end
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

local function undoLastNumber()
    undo_last_action()
end

local function setNewPuzzle()
    changeState(STATE.NEWPUZZLE)
end

local function exitToMainMenu()
    changeState(STATE.TITLE)
end

local function updatePuzzle()
    if game.play.timer:isRunning() then
        game.play.timer:update()
    end

    if auto_note_btn.PREV_CLICK == true then
        checkAutoNote()
    end

    if undo_btn.PREV_CLICK == true then
        undoLastNumber()
    end

    if clear_btn.PREV_CLICK == true then
        clearGuessesAndNotes()
    end

    if check_solution_btn.PREV_CLICK == true then
        checkPuzzle()
    end

    if new_puzzle_btn.PREV_CLICK == true then
        setNewPuzzle()
    end

    if exit_btn.PREV_CLICK == true then
        exitToMainMenu()
    end
end

local function getCompletedDigitsInAllHouses()
    local present = {}
    for d = 1, 9 do present[d] = {} end

    for i = 1, 9 do
        for j = 1, 9 do
            local guess = sudoku.cells[i][j].guess -- FIXED
            if guess then
                local hi          = math.floor((i - 1) / 3)
                local hj          = math.floor((j - 1) / 3)
                local h           = hi * 3 + hj -- 0..8
                present[guess][h] = true
            end
        end
    end

    local doneDigit = {}
    for d = 1, 9 do
        local ok = true
        for h = 0, 8 do
            if not present[d][h] then
                ok = false; break
            end
        end
        doneDigit[d] = ok
    end

    local doneCell = {}
    for r = 1, 9 do
        doneCell[r] = {}
        for c = 1, 9 do
            local v = sudoku.cells[r][c].guess
            doneCell[r][c] = (v ~= nil) and doneDigit[v] or false
        end
    end

    return doneDigit, doneCell
end

local function inSameRowColOrHouse(sel_i, sel_j, i, j)
    if sel_i == nil or sel_j == nil then
        return false
    end

    -- same row or same column
    if i == sel_i or j == sel_j then
        return true
    end

    -- same 3x3 house
    local sel_hi = math.floor((sel_i - 1) / 3)
    local sel_hj = math.floor((sel_j - 1) / 3)
    local hi     = math.floor((i - 1) / 3)
    local hj     = math.floor((j - 1) / 3)

    return (hi == sel_hi) and (hj == sel_hj)
end

function drawPuzzleGrid()
    local _, doneCell = getCompletedDigitsInAllHouses()

    -- We want to highlight all the cells in the same house, row, and column
    -- when a user clicks on an editable cell. This code starts the highlighting
    -- process.
    local sel_i, sel_j = sudoku.clicked.i, sudoku.clicked.j
    local highlight_ok = false
    if sel_i and sel_j then
        local sel_cell = sudoku.cells[sel_i][sel_j]
        highlight_ok = (sel_cell ~= nil) and (sel_cell.locked == false)
    end

    for i = 1, sudoku.DIM_X do
        for j = 1, sudoku.DIM_Y do
            local cell = sudoku.cells[i][j]

            local cell_bgcolor = GRAY_DARK
            local border_color = WHITE
            local number_color = WHITE

            local grid_x      = cell.x_left
            local grid_y      = cell.y_top
            local grid_width  = cell.x_right - cell.x_left + 1
            local grid_height = cell.y_bottom - cell.y_top + 1

            -- Background coloring.
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
                -- If the digit is complete in all houses, make it blue.
                number_color = doneCell[i][j] and BLUE_LITE or WHITE
                print(cell.guess, grid_x + 2, grid_y + 2, number_color, true, 2)
            end

            -- Change border color when selecting an unlocked cell.
            if highlight_ok and inSameRowColOrHouse(sel_i, sel_j, i, j) then
                border_color = ORANGE
            end

            -- Finally, draw the grid.
            rectb(grid_x, grid_y, grid_width, grid_height, border_color)
        end
    end
end


local function drawNotesGrid()
    local doneDigit = select(1, getCompletedDigitsInAllHouses())

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
            local number_color = GRAY_LITE

            -- if the digit is complete in all houses, make it blue.
            if doneDigit[n] then
                number_color = BLUE_LITE
            end

            local x = grid_x + (j - 1) * cell_w
            local y = grid_y + (i - 1) * cell_h

            if (active_cell_notes ~= nil) and (active_cell_notes[i][j] == true) then
                number_color = YELLOW
            end

            rectb(x, y, cell_w, cell_h, WHITE)     -- cell border
            print(n, x + 2, y + 2, number_color, true, 2) -- number

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
            bg_color = butt.BG_COLOR
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
    local sudoku_end_y = check_solution_btn.START_Y - Y_PADDING
    local box_height = sudoku_end_y - box_start_y + 1

    rect(box_start_x, box_start_y, box_width, box_height, BLACK)
    rectb(box_start_x, box_start_y, box_width, box_height, WHITE)

    -- Print active clock, num of auto-nots, and difficulty level.
    local start_x = box_start_x + math.floor(X_PADDING / 2)
    local start_y = box_start_y + Y_PADDING

    -- Add clock here.
    print(game.play.timer:getFormatted(), start_x, start_y, WHITE, true, 3)
    print(
        "Auto-Note: " .. tostring(game.play.autonotes),
        start_x,
        start_y + 3*Y_PADDING,
        WHITE
    )

    print(
        -- "Level: " .. difficultyName,
        "Level: " .. game.play.difficulty,
        start_x,
        box_start_y + box_height - Y_PADDING,
        WHITE
    )
end

local function drawSuccess()
    if game.play.solved then
        drawOverlayBox({ "SUCCESS!", "Click 'NEW' or", "'EXIT' to continue." })
        game.play.timer:stop()
    end
end


function drawPuzzle()
    cls(BLACK)

    -- Screen border
    rectb(
        EDGE_X_LEFT,
        EDGE_Y_TOP,
        EDGE_X_RIGHT,
        EDGE_Y_BOTTOM,
        WHITE
    )

    -- Puzzle elements
    drawPuzzleGrid()
    drawNotesGrid()
    drawPuzzleButtons()
    drawStatBox()
    drawSuccess()
end


-- [/TQ-Bundler: src.states.puzzle]

-- [TQ-Bundler: src.states.newpuzzle]

-- ==========================================
-- STATE: NEWPUZZLE
-- ==========================================

-- This state is just for switching from the current puzzle to a new puzzle.

local function updateNewPuzzle()
    changeState(STATE.PUZZLE)
end

local function drawNewPuzzle()
    cls(BLACK)
end


-- [/TQ-Bundler: src.states.newpuzzle]

-- [TQ-Bundler: src.state_machine]

-- ==========================================
-- STATE MACHINE
-- ==========================================

local states = {
    [STATE.TITLE] = {
        update = updateTitle,
        draw = drawTitle,
    },
    [STATE.OPTIONS] = {
        update = updateOptions,
        draw = drawOptions,
    },
    [STATE.STATISTICS] = {
        update = updateStatistics,
        draw = drawStatistics,
    },
    [STATE.PUZZLE] = {
        update = updatePuzzle,
        draw = drawPuzzle,
    },
    [STATE.NEWPUZZLE] = {
        update = updateNewPuzzle,
        draw = drawNewPuzzle,
    },
}


-- [/TQ-Bundler: src.state_machine]

-- [TQ-Bundler: src.input]

-- ==========================================
-- INPUT FUNCTIONS
-- ==========================================

-- State variable to make sure a single click doesn't repeatedly toggle a cell.
local prev_left_click = false

-- Creates an "edit session" so we can track when a cell that's being changed is
-- done being changed (for the undo functionality).
local edit = {
    active = false,
    i = nil,
    j = nil,
    start_value = nil,
}

-- Helper function to commit true edits to the undo history.
local function commit_edit_if_needed()
    if not edit.active then return end

    local cell = sudoku.cells[edit.i][edit.j]
    local final_value = cell.guess

    if final_value ~= edit.start_value then
        register_action(edit.i, edit.j, final_value, edit.start_value)
    end

    edit.active = false
    edit.i, edit.j = nil, nil
    edit.start_value = nil
end

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
                -- Clicking the currently-selected cell => deselect and commit
                -- edit.
                if sudoku.clicked.i == i and sudoku.clicked.j == j then
                    sudoku.clicked.i = nil
                    sudoku.clicked.j = nil
                    commit_edit_if_needed()
                else
                    -- Switching selection from one cell to another => commit
                    -- previous edit.
                    if sudoku.clicked.i ~= nil and sudoku.clicked.j ~= nil then
                        commit_edit_if_needed()
                    end

                    sudoku.clicked.i = i
                    sudoku.clicked.j = j

                    -- Start a new edit session for this cell, but only if it's
                    -- editable.
                    if not cell.locked then
                        edit.active = true
                        edit.i = i
                        edit.j = j
                        edit.start_value = cell.guess
                    end

                end
            end

            -- Is the user trying to change the number?
            if cell.locked == false and sudoku.clicked.i == i and sudoku.clicked.j == j then
                local prev_value = cell.guess

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

local function checkPuzzleButtonClicks(mouse_x, mouse_y, left_click, just_pressed)
    local handled = false

    for k, butt in pairs(puzzle_buttons) do
        -- Check if mouse is over this button
        local mouseover =
            (butt.START_X <= mouse_x and mouse_x <= butt.END_X) and
            (butt.START_Y <= mouse_y and mouse_y <= butt.END_Y)

        -- Button is clicked only while mouse is over and left button is held
        butt.CLICKED    = mouseover and left_click
        butt.PREV_CLICK = mouseover and just_pressed

        if mouseover and just_pressed then
            handled = true
            if butt.COUNT_CLICKS then
                game.play.autonotes = game.play.autonotes + 1
            end
        end
    end

    return handled
end

local function updateInput()
    input.prev = input.curr
    input.curr = {}
    for i = 0, 7 do
        input.curr[i] = btn(i)
    end

    -- Only process mouse input for puzzle when in PUZZLE state
    if game.state ~= STATE.PUZZLE then
        return
    end

    local mouse_x, mouse_y, left_click, middle_click, right_click, scroll_x, scroll_y = mouse()

    -- Clear all button states first
    for _, butt in ipairs(puzzle_buttons) do
        butt.CLICKED    = false
        butt.PREV_CLICK = false
    end

    local just_pressed = left_click and not prev_left_click
    prev_left_click = left_click

    -- If we're editing a cell and the user clicks somewhere, we may need to
    -- commit (button/notes clicks won't go through puzzle-grid selection).
    if just_pressed then
        -- We'll commit later if the click doesn't land on a puzzle cell
        -- selection, so do it when a button/notes click is handled:
    end

    -- Start the game clock if it hasn't already been started.
    if just_pressed and not game.play.timer:isRunning() then
        game.play.timer:start()
    end

    -- Only work on the notes grid or the puzzle grid. Not both.
    local notes_handled = checkInputOnNotesGrid(mouse_x, mouse_y, just_pressed)

    local puzzle_buttons_handled = false
    if not notes_handled then
        puzzle_buttons_handled = checkPuzzleButtonClicks(mouse_x, mouse_y, left_click, just_pressed)
    end

    -- If the click was used for notes or a button, commit any in-progress cell edit
    if just_pressed and (notes_handled or puzzle_buttons_handled) then
        commit_edit_if_needed()
    end

    local handled = not notes_handled and not puzzle_buttons_handled
    if handled then
        checkInputOnPuzzleGrid(mouse_x, mouse_y, left_click, scroll_y, just_pressed)
    end
end


-- [/TQ-Bundler: src.input]

-- ==========================================
-- MAIN GAME LOOP
-- ==========================================


function TIC()
    updateInput()

    local currentState = states[game.state]
    if currentState then
        currentState.update()
        currentState.draw()
    end
end
-- <TILES>
-- 001:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
-- </TILES>

-- <MAP>
-- 000:101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:100000000000000010000000000000001000000000000000101000000000000000100000000000000010000000000000001010000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 002:100000001010000010001010101010001000000000000000101000000000000000100000000000000010000000000000001010000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 003:100000101010000010000000001010001000000000000000101000000000000000100000000000000010000000000000001010000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 004:100000001010000010000000101000001000000000000000101000000000000000100000000000000010000000000000001010000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:100000001010000010000010100000001000000000000000101000000000000000100000000000000010000000000000001010000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:100000101010100010001010000000001000000000000000101000000000000000100000000000000010000000000000001010000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:100000000000000010000000000000001000000000000000101000000000000000100000000000000010000000000000001010000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:100000000000000010000000000000001000000000000000101000000000000000100000000000000010000000000000001010000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:100000000000000010000000101000001000001010100000101000101010100000100010101010100010000000000000001010000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:100000000000000010000010101000001000101000001000101000000000101000100000000010100010000000000000001010000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:100000000000000010001010001000001000001010100000101000001010100000100000001010000010000000000000001010000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:100000000000000010001010101010001000101000001000101000101000000000100000101000000010000000000000001010000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:100000000000000010000000001000001000001010100000101000101010101000100010100000000010000000000000001010000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:100000000000000010000000000000001000000000000000101000000000000000100000000000000010000000000000001010000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 016:101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 017:100000000000000010000000000000001000000000000000101000000000000000100000000000000010000000000000001010000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 018:100000000000000010000000000000001000000000000000101000000000000000100000000000000010000010101000001010000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 019:100000000000000010000000000000001000000000000000101000000000000000100000000000000010001010000000001010000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 020:100000000000000010000000000000001000000000000000101000000000000000100000000000000010001010101000001010000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 021:100000000000000010000000000000001000000000000000101000000000000000100000000000000010001010000010001010000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 022:100000000000000010000000000000001000000000000000101000000000000000100000000000000010000010101000001010000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 023:100000000000000010000000000000001000000000000000101000000000000000100000000000000010000000000000001010000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 024:101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 025:101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 026:100000000000000010000000000000001000000000000000101000000000000000100000000000000010000000000000001010000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 027:100010101010100010000000101000001000000000000000101000000000000000100000000000000010000000000000001010000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 028:100010100000000010000010101000001000000000000000101000000000000000100000000000000010000000000000001010000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 029:100010101010000010000000101000001000000000000000101000000000000000100000000000000010000000000000001010000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 030:100000000010100010000000101000001000000000000000101000000000000000100000000000000010000000000000001010000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 031:100010101010000010000010101010001000000000000000101000000000000000100000000000000010000000000000001010000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 032:100000000000000010000000000000001000000000000000101000000000000000100000000000000010000000000000001010000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 033:101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </MAP>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304000000000
-- </SFX>

-- <TRACKS>
-- 000:100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </TRACKS>

-- <PALETTE>
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

