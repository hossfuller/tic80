-- title:   Sudoku for TIC-80
-- author:  Adam Fuller <the.adam.fuller@gmail.com>
-- version: rev1-0.1
-- script:  lua
-- input: mouse

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
local GAP_HOUSE              = 0 -- between houses (after col/row 3 and 6)


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


-- ==========================================
-- INITIALIZATION FUNCTIONS
-- ==========================================

local function newCell()
    return {
        x_left    = nil,
        x_right   = nil,
        y_top     = nil,
        y_bottom  = nil,
        solution  = nil,
        guess     = nil,
        locked    = false,
        notes     = { false, false, false, false, false, false, false, false, false },
        mouseover = false,
        clicked   = false,
    }
end

local function gapBefore(index) -- index is 1..9, returns pixels before this cell
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

function INIT()
    -- Initialize the cells
    initializeCells()

    -- Get a valid solution into the cells' 'value' settings.
    generateSolution()

    -- What is the difficulty? Copy the appropriate number of 'value' fields to 'guess' fields and lock those fields.
    finalizePuzzle('random')
end -- INIT()

-- ==========================================
-- INPUT FUNCTIONS
-- ==========================================


function INPUT()
end

-- ==========================================
-- UPDATE FUNCTIONS
-- ==========================================


function UPDATE()
end

-- ==========================================
-- DRAW FUNCTIONS
-- ==========================================

function draw_sudoku_puzzle()
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

-- local function newCell()
--     return {
--         x_left    = nil,
--         x_right   = nil,
--         y_top     = nil,
--         y_bottom  = nil,
--         solution  = nil,
--         guess     = nil,
--         locked    = false,
--         notes     = { false, false, false, false, false, false, false, false, false },
--         mouseover = false,
--         clicked   = false,
--     }
-- end

            -- Print the guess if there is one.
            if sudoku.cells[i][j].guess ~= nil then
                print(sudoku.cells[i][j].guess, grid_x + 2, grid_y + 2, WHITE, true, 2)
            end


            -- If there isn't a guess, print the notes.


            -- Finally, draw the grid.
            rectb(grid_x, grid_y, grid_width, grid_height, WHITE)
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

    draw_sudoku_puzzle()
end

-- ==========================================
-- MAIN GAME LOOP
-- ==========================================



INIT()

function TIC()
    INPUT()
    UPDATE()
    DRAW()
end
