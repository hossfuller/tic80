--
-- Bundle file
-- Code changes will be overwritten
--

-- title:   Sudoku for TIC-80
-- author:  Adam Fuller <the.adam.fuller@gmail.com>
-- version: rev2.2
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


-- [/TQ-Bundler: src.constants]

-- [TQ-Bundler: src.sudoku_grid]

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

local sudoku   = make_grid()
sudoku.clicked = { i = nil, j = nil }
sudoku.cells   = {}
sudoku.solved  = false

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


-- [/TQ-Bundler: src.sudoku_grid]

-- [TQ-Bundler: src.sudoku_buttons]

-- ==========================================
-- SUDOKU BUTTON DATA STRUCTURES
-- ==========================================

local function make_button(overrides)
    local g = {
        TEXT       = "BUTTON",
        CLICKED    = false,
        PREV_CLICK = false,
        START_X    = EDGE_X_LEFT + X_PADDING,
        START_Y    = EDGE_Y_TOP + Y_PADDING,
    }

    for k, v in pairs(overrides or {}) do g[k] = v end

    g.END_X        = EDGE_X_RIGHT - FIXED_CHAR_WIDTH  -- All buttons end at same X
    g.CELL_WIDTH   = g.END_X - g.START_X
    g.CELL_HEIGHT  = FIXED_CHAR_HEIGHT + Y_PADDING
    g.END_Y        = g.START_Y + g.CELL_HEIGHT
    g.TEXT_START_X = g.START_X + math.floor(X_PADDING / 2)
    g.TEXT_START_Y = g.START_Y + math.floor(Y_PADDING / 2)

    return g
end


local auto_note_btn = make_button({
    TEXT = "Auto-Note",
    START_X = notes.END_X + X_PADDING,
})
local check_solution_btn = make_button({
    TEXT = "Check",
    START_X = notes.END_X + X_PADDING,
    START_Y = auto_note_btn.END_Y,
})
local clear_btn = make_button({
    TEXT = "Clear",
    START_X = notes.END_X + X_PADDING,
    START_Y = check_solution_btn.END_Y,
})

local puzzle_buttons = {
    auto_note_btn,
    check_solution_btn,
    clear_btn,
}

-- [/TQ-Bundler: src.sudoku_buttons]

-- [TQ-Bundler: src.sudoku_logic]

-- ==========================================
-- SUDOKU LOGIC
-- ==========================================

local function generateSolution()
    for i = 1, sudoku.DIM_X do
        for j = 1, sudoku.DIM_Y do
            sudoku.cells[i][j].solution = math.random(1, 9)
            if math.random() < 0.5 then
                sudoku.cells[i][j].guess = sudoku.cells[i][j].solution
                sudoku.cells[i][j].locked = true
            end
        end
    end
end

--[[
  Currently we just want to display
--]]
local function setPuzzleDifficulty(difficulty)
    if difficulty == nil then
        difficulty = 'random'
    end
    for i = 1, sudoku.DIM_X do
        for j = 1, sudoku.DIM_Y do
            if difficulty == 'random' and math.random() < 0.5 then
                sudoku.cells[i][j].guess = sudoku.cells[i][j].solution
                sudoku.cells[i][j].locked = true
            end
        end
    end
end


-- [/TQ-Bundler: src.sudoku_logic]

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

local function setSingleCellNotes(i, j)
    local starting_notes = {
        { true, true, true },
        { true, true, true },
        { true, true, true }
    }

    -- Check this row's values
    for y = 1, 9 do
        if sudoku.cells[i][y].guess == 1 then
            starting_notes[1][1] = false
        elseif sudoku.cells[i][y].guess == 2 then
            starting_notes[1][2] = false
        elseif sudoku.cells[i][y].guess == 3 then
            starting_notes[1][3] = false
        elseif sudoku.cells[i][y].guess == 4 then
            starting_notes[2][1] = false
        elseif sudoku.cells[i][y].guess == 5 then
            starting_notes[2][2] = false
        elseif sudoku.cells[i][y].guess == 6 then
            starting_notes[2][3] = false
        elseif sudoku.cells[i][y].guess == 7 then
            starting_notes[3][1] = false
        elseif sudoku.cells[i][y].guess == 8 then
            starting_notes[3][2] = false
        elseif sudoku.cells[i][y].guess == 9 then
            starting_notes[3][3] = false
        end
    end

    -- -- Check this column's values
    for x = 1, 9 do
        if sudoku.cells[x][j].guess == 1 then
            starting_notes[1][1] = false
        elseif sudoku.cells[x][j].guess == 2 then
            starting_notes[1][2] = false
        elseif sudoku.cells[x][j].guess == 3 then
            starting_notes[1][3] = false
        elseif sudoku.cells[x][j].guess == 4 then
            starting_notes[2][1] = false
        elseif sudoku.cells[x][j].guess == 5 then
            starting_notes[2][2] = false
        elseif sudoku.cells[x][j].guess == 6 then
            starting_notes[2][3] = false
        elseif sudoku.cells[x][j].guess == 7 then
            starting_notes[3][1] = false
        elseif sudoku.cells[x][j].guess == 8 then
            starting_notes[3][2] = false
        elseif sudoku.cells[x][j].guess == 9 then
            starting_notes[3][3] = false
        end
    end

    -- Check this house's values
    local house_start_x = 1
    local house_start_y = 1

    if 4 <= i and i <= 6 then
        house_start_x = 4
    elseif 7 <= i then
        house_start_x = 7
    end
    if 4 <= j and j <= 6 then
        house_start_y = 4
    elseif 7 <= j then
        house_start_y = 7
    end
    for x = house_start_x, house_start_x + 2 do
        for y = house_start_y, house_start_y + 2 do
            if sudoku.cells[x][y].guess == 1 then
                starting_notes[1][1] = false
            elseif sudoku.cells[x][y].guess == 2 then
                starting_notes[1][2] = false
            elseif sudoku.cells[x][y].guess == 3 then
                starting_notes[1][3] = false
            elseif sudoku.cells[x][y].guess == 4 then
                starting_notes[2][1] = false
            elseif sudoku.cells[x][y].guess == 5 then
                starting_notes[2][2] = false
            elseif sudoku.cells[x][y].guess == 6 then
                starting_notes[2][3] = false
            elseif sudoku.cells[x][y].guess == 7 then
                starting_notes[3][1] = false
            elseif sudoku.cells[x][y].guess == 8 then
                starting_notes[3][2] = false
            elseif sudoku.cells[x][y].guess == 9 then
                starting_notes[3][3] = false
            end
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

local function drawButtons()
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

local function drawStatBox()
    local box_start_x = notes.START_X
    local box_start_y = notes.END_Y + Y_PADDING
    local box_width = (EDGE_X_RIGHT - FIXED_CHAR_WIDTH) - box_start_x

    -- Line the stat box up with the bottom of the sudoku grid.
    local sudoku_end_y = sudoku.cells[sudoku.DIM_X][sudoku.DIM_Y].y_bottom
    local box_height = sudoku_end_y - box_start_y + 1

    rect(box_start_x, box_start_y, box_width, box_height, BLACK)
    rectb(box_start_x, box_start_y, box_width, box_height, WHITE)

    -- Now print all the stats there are to print.
    -- ...
    local start_x = box_start_x + X_PADDING
    local start_y = box_start_y + Y_PADDING
    for k, butt in pairs(puzzle_buttons) do
        print(butt.TEXT .. " = " .. tostring(butt.CLICKED), start_x, start_y, WHITE, false, 1, true)
        start_y = start_y + Y_PADDING
    end
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
    drawButtons()
    drawStatBox()
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

    -- What is the difficulty? Copy the appropriate number of 'value' fields to 'guess' fields and lock those fields.
    setPuzzleDifficulty('random')
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
