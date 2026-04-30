-- title:   Sudoku for TIC-80
-- author:  Adam Fuller <the.adam.fuller@gmail.com>
-- version: rev2.1
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
local GAP_HOUSE              = 0  -- between houses (after col/row 3 and 6)

-- ==========================================
-- CLASSES
-- ==========================================

--[[ BEGIN CellObj ]]--

CellObj = {}
CellObj.__index = CellObj

function CellObj:new(params)
    params = params or {}
    local obj = {
        x_left    = params.x_left or nil,
        x_right   = params.x_right or nil,
        y_top     = params.y_top or nil,
        y_bottom  = params.y_bottom or nil,
        solution  = params.solution or nil,
        guess     = params.guess or nil,
        locked    = params.locked or false,
        notes     = params.notes or { { false, true, false }, { true, false, false }, { false, false, true } },
        mouseover = params.mouseover or false,
        clicked   = params.clicked or false,
    }
    setmetatable(obj, self)
    return obj
end

--[[ END CellObj ]]--

--[[ BEGIN GridObj ]]--

GridObj = {}
GridObj.__index = GridObj

function GridObj:new(params)
    params = params or {}
    local obj = {
        dim_x       = params.dim_x or 9,
        dim_y       = params.dim_y or 9,
        cell_width  = params.cell_width or CELL_WIDTH_MULTIPLIER * X_PADDING,
        cell_height = params.start_x or CELL_HEIGHT_MULTIPLIER * Y_PADDING,
        cell_offset = params.cell_offset or 2,
    }
    if obj.dim_x < 1 then
        obj.dim_x = 1
    end
    if obj.dim_y < 1 then
        obj.dim_y = 1
    end
    setmetatable(obj, self)

    obj.start_x = params.start_x or EDGE_X_LEFT + X_PADDING
    obj.start_y = params.start_x or EDGE_Y_TOP + Y_PADDING
    obj.end_x   = params.end_x or obj.start_x + (obj.dim_x * obj.cell_width)
    obj.end_y   = params.end_y or obj.start_y + (obj.dim_y * obj.cell_height)
    -- obj.cells   = {}

    return obj
end

--[[ END GridObj ]]--

--[[ BEGIN PuzzleObj ]]--

PuzzleObj = setmetatable({}, { __index = GridObj })
PuzzleObj.__index = PuzzleObj

function PuzzleObj:new(params)
    params = params or {}
    params.dim_x = 9
    params.dim_y = 9
    local obj = GridObj.new(self, params)
    setmetatable(obj, self)

    obj.cells = {}

    return obj
end

function PuzzleObj:_gapBefore(index)
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

function PuzzleObj:initializePuzzleCells()
    for i = 1, self.dim_x do
        self.cells[i] = {}
        for j = 1, self.dim_y do
            local cell = CellObj:new({})

            local x = self.start_x
            for c = 1, j - 1 do
                x = x + self.cell_width + self._gapBefore(c + 1)
            end

            local y = self.start_y
            for r = 1, i - 1 do
                y = y + self.cell_height + self._gapBefore(r + 1)
            end

            cell.x_left        = x
            cell.y_top         = y
            cell.x_right       = x + self.cell_width - 1
            cell.y_bottom      = y + self.cell_height - 1

            self.cells[i][j] = cell
        end
    end
end

function PuzzleObj:generateSolution()
    for i = 1, 9 do
        for j = 1, 9 do
            self.cells[i][j].solution = math.random(1, 9)
            if math.random() < 0.5 then
                self.cells[i][j].guess = self.cells[i][j].solution
                self.cells[i][j].locked = true
            end
        end
    end
end

function PuzzleObj:finalizePuzzle(difficulty)
    if difficulty == nil then
        difficulty = 'random'
    end
    for i = 1, 9 do
        for j = 1, 9 do
            if difficulty == 'random' and math.random() < 0.5 then
                self.cells[i][j].guess = self.cells[i][j].solution
                self.cells[i][j].locked = true
            end
        end
    end
end
--[[ END PuzzleObj ]]--

--[[ BEGIN NotesObj ]]--

NotesObj = setmetatable({}, { __index = GridObj })
NotesObj.__index = NotesObj

function NotesObj:new(params)
    params = params or {}
    params.dim_x = 3
    params.dim_y = 3
    local obj = GridObj.new(self, params)
    setmetatable(obj, self)

    return obj
end







-- include "src.input"
-- include "src.update"
-- include "src.draw"


-- ==========================================
-- INITIALIZATION
-- ==========================================

local sudoku = PuzzleObj:new({ dim_x = 9, dim_y = 9 })
local notes = GridObj:new({
    dim_x = 3,
    dim_y = 3,
    start_x = sudoku.end_x + 10,
    start_y = sudoku.end_y,
})

-- function INIT()
--     -- Initialize the cells
--     initializeCells()

--     -- Get a valid solution into the cells' 'value' settings.
--     generateSolution()

--     -- What is the difficulty? Copy the appropriate number of 'value' fields to 'guess' fields and lock those fields.
--     finalizePuzzle('random')
-- end -- INIT()

-- ==========================================
-- MAIN GAME LOOP
-- ==========================================

-- INIT()

function TIC()
    cls(0)
    -- INPUT()
    -- UPDATE()
    -- DRAW()
    -- print("Rethink notes grid", EDGE_X_RIGHT - 80, EDGE_Y_BOTTOM - 10, WHITE)
end
