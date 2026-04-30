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
        notes     = { {true, false, false}, {false, true, false}, {true, false, true} },
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

-- State variable to make sure a single click doesn't repeatedly toggle a cell.
local prev_left_click = false

local function clearAllCellClicks()
    for i = 1, 9 do
        for j = 1, 9 do
            sudoku.cells[i][j].clicked = false
        end
    end
end

local function checkInputOnPuzzleGrid(mouse_x, mouse_y, left_click, scroll_y)
    local just_pressed = left_click and not prev_left_click
    prev_left_click = left_click

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

            sudoku.cells[i][j] = cell
        end
    end
end

function INPUT()
    local mouse_x, mouse_y, left_click, middle_click, right_click, scroll_x, scroll_y = mouse()

    checkInputOnPuzzleGrid(mouse_x, mouse_y, left_click, scroll_y)
end


-- ==========================================
-- UPDATE FUNCTIONS
-- ==========================================


function UPDATE()
end

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

-- <TILES>
-- 001:eccccccccc888888caaaaaaaca888888cacccccccacc0ccccacc0ccccacc0ccc
-- 002:ccccceee8888cceeaaaa0cee888a0ceeccca0ccc0cca0c0c0cca0c0c0cca0c0c
-- 003:eccccccccc888888caaaaaaaca888888cacccccccacccccccacc0ccccacc0ccc
-- 004:ccccceee8888cceeaaaa0cee888a0ceeccca0cccccca0c0c0cca0c0c0cca0c0c
-- 017:cacccccccaaaaaaacaaacaaacaaaaccccaaaaaaac8888888cc000cccecccccec
-- 018:ccca00ccaaaa0ccecaaa0ceeaaaa0ceeaaaa0cee8888ccee000cceeecccceeee
-- 019:cacccccccaaaaaaacaaacaaacaaaaccccaaaaaaac8888888cc000cccecccccec
-- 020:ccca00ccaaaa0ccecaaa0ceeaaaa0ceeaaaa0cee8888ccee000cceeecccceeee
-- </TILES>

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

