--
-- Bundle file
-- Code changes will be overwritten
--

-- title:   Sudoku for TIC-80
-- author:  Adam Fuller <the.adam.fuller@gmail.com>
-- version: rev2
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

-- Button mappings
local BTN_P1_UP              = 0
local BTN_P1_DOWN            = 1
local BTN_P1_LEFT            = 2
local BTN_P1_RIGHT           = 3
local BTN_P1_A               = 4 -- Primary action / Select
local BTN_P1_B               = 5 -- Secondary action / Back / Pause
local BTN_P1_X               = 6
local BTN_P1_Y               = 7
local BTN_P2_UP              = 8
local BTN_P2_DOWN            = 9
local BTN_P2_LEFT            = 10
local BTN_P2_RIGHT           = 11
local BTN_P2_A               = 12
local BTN_P2_B               = 13
local BTN_P2_X               = 14
local BTN_P2_Y               = 15

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
-- SUDOKU GRID DATA STRUCTURE
-- ==========================================

local sudoku = {
    START_X     = EDGE_X_LEFT + X_PADDING,
    START_Y     = EDGE_Y_TOP + Y_PADDING,
    CELL_WIDTH  = CELL_WIDTH_MULTIPLIER * X_PADDING,
    CELL_HEIGHT = CELL_HEIGHT_MULTIPLIER * Y_PADDING,
    CELL_OFFSET = 2,
    END_X       = EDGE_X_LEFT + X_PADDING + (9 * CELL_WIDTH_MULTIPLIER * X_PADDING),
    END_Y       = EDGE_Y_TOP + Y_PADDING + (9 * CELL_HEIGHT_MULTIPLIER * Y_PADDING),
    cells       = {}
}

local notes_grid = {
    START_X     = sudoku.END_X + 10,
    START_Y     = sudoku.START_Y,
    CELL_WIDTH  = sudoku.CELL_WIDTH,
    CELL_HEIGHT = sudoku.CELL_HEIGHT,
    CELL_OFFSET = 2,
    END_X       = sudoku.END_X + 10  + (3 * CELL_WIDTH_MULTIPLIER * X_PADDING),
    END_Y       = sudoku.START_Y + (3 * CELL_HEIGHT_MULTIPLIER * Y_PADDING),
}

local function newCell()
    return {
        x_left    = nil,
        x_right   = nil,
        y_top     = nil,
        y_bottom  = nil,
        solution  = nil,
        guess     = nil,
        locked    = false,
        notes     = { { false, true, false }, { true, false, false }, { false, false, true } },
        mouseover = false,
        clicked   = false,
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
    for i = 1, 9 do
        sudoku.cells[i] = {}
        for j = 1, 9 do
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

-- [TQ-Bundler: src.sudoku_logic]

-- ==========================================
-- SUDOKU LOGIC
-- ==========================================

local function generateSolution()
    for i = 1, 9 do
        for j = 1, 9 do
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
local function finalizePuzzle(difficulty)
    if difficulty == nil then
        difficulty = 'random'
    end
    for i = 1, 9 do
        for j = 1, 9 do
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
local clicked_cell = {
    i = nil,
    j = nil
}

local function clearAllCellClicks()
    for i = 1, 9 do
        for j = 1, 9 do
            sudoku.cells[i][j].clicked = false
        end
    end
    clicked_cell.i = nil
    clicked_cell.j = nil
end

local function checkInputOnPuzzleGrid(mouse_x, mouse_y, left_click, scroll_y, just_pressed)
    for i = 1, 9 do
        for j = 1, 9 do
            local cell = sudoku.cells[i][j]

            -- Is this a mouseover event?
            cell.mouseover =
                (cell.x_left <= mouse_x and mouse_x <= cell.x_right) and
                (cell.y_top <= mouse_y and mouse_y <= cell.y_bottom)

            -- Did the user click on this cell?
            if cell.mouseover and just_pressed then
                if not cell.clicked then
                    clearAllCellClicks()
                    cell.clicked = true
                    clicked_cell.i = i
                    clicked_cell.j = j
                else
                    cell.clicked = false
                end
            end

            -- Is the user trying to change the number?
            if cell.clicked and scroll_y > 0 then
                if cell.guess == nil or cell.guess >= 9 then
                    cell.guess = 1
                else
                    cell.guess = cell.guess + 1
                end
            elseif cell.clicked and scroll_y < 0 then
                if cell.guess == nil or cell.guess <= 1 then
                    cell.guess = 9
                else
                    cell.guess = cell.guess - 1
                end
            end
            -- if cell.guess ~= nil then
            --     cell.notes = { { false, false, false }, { false, false, false }, { false, false, false } }
            -- end

            sudoku.cells[i][j] = cell
        end
    end
end


local function checkInputOnNotesGrid(mouse_x, mouse_y, just_pressed)
    -- Do a bunch of checks before proceeding.

    -- Only work on a cell that was clicked.
    if clicked_cell.i ~= nil or clicked_cell.j ~= nil then
        return false
    end

    local cell = sudoku.cells[clicked_cell.i][clicked_cell.j]

    -- Don't allow notes on locked cells or cells with guesses
    if cell.locked or cell.guess ~= nil then
        return false
    end

    -- Check if mouse is within the notes grid bounds
    if mouse_x < notes_grid.START_X or mouse_x >= notes_grid.END_X then
        return false
    end
    if mouse_y < notes_grid.START_Y or mouse_y >= notes_grid.END_Y then
        return false
    end

    -- Only toggle on a fresh click
    if not just_pressed then
        return false
    end

    -- Calculate which note cell was clicked (1-3 for both row and column)
    local rel_x = mouse_x - notes_grid.START_X
    local rel_y = mouse_y - notes_grid.START_Y

    local n_j = math.floor(rel_x / notes_grid.CELL_WIDTH) + 1
    local n_i = math.floor(rel_y / notes_grid.CELL_HEIGHT) + 1

    -- Bounds check
    if n_i < 1 or n_i > 3 or n_j < 1 or n_j > 3 then
        return false
    end

    -- Toggle the note
    cell.notes[n_i][n_j] = not cell.notes[n_i][n_j]

    return true -- Click was handled
end


function INPUT()
    local mouse_x, mouse_y, left_click, middle_click, right_click, scroll_x, scroll_y = mouse()

    local just_pressed = left_click and not prev_left_click
    prev_left_click = left_click

    -- Only work on the notes grid or the puzzle grid. Not both.
    local handled = checkInputOnNotesGrid(mouse_x, mouse_y, just_pressed)
    if not handled then
        checkInputOnPuzzleGrid(mouse_x, mouse_y, left_click, scroll_y, just_pressed)
    end
end


-- [/TQ-Bundler: src.input]

-- [TQ-Bundler: src.update]

-- ==========================================
-- UPDATE FUNCTIONS
-- ==========================================


function UPDATE()
end


-- [/TQ-Bundler: src.update]

-- [TQ-Bundler: src.draw]

-- ==========================================
-- DRAW FUNCTIONS
-- ==========================================

function drawPuzzle()
    for i = 1, 9 do
        for j = 1, 9 do
            local cell_bgcolor = GRAY_DARK
            local grid_x       = sudoku.cells[i][j].x_left
            local grid_y       = sudoku.cells[i][j].y_top
            local grid_width   = sudoku.cells[i][j].x_right - sudoku.cells[i][j].x_left + 1
            local grid_height  = sudoku.cells[i][j].y_bottom - sudoku.cells[i][j].y_top + 1

            -- Check cell status and change the cell's background color.
            if sudoku.cells[i][j].locked == true then
                cell_bgcolor = BLACK
            elseif sudoku.cells[i][j].clicked == true then
                cell_bgcolor = YELLOW
            elseif sudoku.cells[i][j].mouseover == true then
                cell_bgcolor = PURPLE
            end
            rect(grid_x, grid_y, grid_width, grid_height, cell_bgcolor)

            -- If there isn't a guess, print the notes.
            if sudoku.cells[i][j].guess == nil then
                local cell = sudoku.cells[i][j]

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
                print(sudoku.cells[i][j].guess, grid_x + 2, grid_y + 2, WHITE, true, 2)
            end

            -- Finally, draw the grid.
            rectb(grid_x, grid_y, grid_width, grid_height, WHITE)
        end
    end
end


-- local notes_grid = {
--     START_X     = sudoku.END_X + 10,
--     START_Y     = sudoku.START_Y,
--     CELL_WIDTH  = sudoku.CELL_WIDTH,
--     CELL_HEIGHT = sudoku.CELL_HEIGHT,
--     CELL_OFFSET = 2,
--     END_X       = sudoku.END_X + 10 + (3 * CELL_WIDTH_MULTIPLIER * X_PADDING),
--     END_Y       = sudoku.START_Y + (3 * CELL_HEIGHT_MULTIPLIER * Y_PADDING),
-- }


local function drawNotesGrid()
    local grid_x = notes_grid.START_X
    local grid_y = notes_grid.START_Y

    local cell_w = notes_grid.CELL_WIDTH
    local cell_h = notes_grid.CELL_HEIGHT

    local active_cell = nil
    if (clicked_cell.i ~= nil) and (clicked_cell.j ~= nil) then
        active_cell = sudoku.cells[clicked_cell.i][clicked_cell.j].notes
    end

    local n = 1
    for i = 1, 3 do
        for j = 1, 3 do
            local num_color = GRAY_LITE

            local x = grid_x + (j - 1) * cell_w
            local y = grid_y + (i - 1) * cell_h

            if (active_cell ~= nil) and (active_cell[i][j] == true) then
                num_color = YELLOW
            end

            rectb(x, y, cell_w, cell_h, WHITE)     -- cell border
            print(n, x + 2, y + 2, num_color, true, 2) -- number

            n = n + 1
        end
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
end


-- [/TQ-Bundler: src.draw]

-- ==========================================
-- INITIALIZATION FUNCTIONS
-- ==========================================

function INIT()
    -- Initialize the cells
    initializeCells()

    -- Get a valid solution into the cells' 'value' settings.
    generateSolution()

    -- What is the difficulty? Copy the appropriate number of 'value' fields to 'guess' fields and lock those fields.
    finalizePuzzle('random')
end -- INIT()

-- ==========================================
-- MAIN GAME LOOP
-- ==========================================

INIT()

function TIC()
    INPUT()
    UPDATE()
    DRAW()
    print("Rethink notes grid", EDGE_X_RIGHT - 80, EDGE_Y_BOTTOM - 10, WHITE)
end
