
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


local sudoku = {
    START_X     = EDGE_X_LEFT + X_PADDING,
    START_Y     = EDGE_Y_TOP + Y_PADDING,
    CELL_WIDTH  = CELL_WIDTH_MULTIPLIER * X_PADDING,
    CELL_HEIGHT = CELL_HEIGHT_MULTIPLIER * Y_PADDING,
    CELL_OFFSET = 2,
    END_X       = EDGE_X_LEFT + X_PADDING + (9 * CELL_WIDTH_MULTIPLIER * X_PADDING),
    END_Y       = EDGE_Y_TOP + Y_PADDING + (9 * CELL_HEIGHT_MULTIPLIER * Y_PADDING),
    cells = {}
}

local function newCell()
    return {
        x_left    = nil,
        x_right   = nil,
        y_top     = nil,
        y_bottom  = nil,
        value     = nil,
        guess     = nil,
        notes     = { false, false, false, false, false, false, false, false, false },
        mouseover = false,
        clicked   = false,
    }
end

local function printTable(t, indent)
    indent = indent or 0
    for k, v in pairs(t) do
        local formatting = string.rep("  ", indent) .. k .. ": "
        if type(v) == "table" then
            print(formatting)
            printTable(v, indent + 1)
        else
            print(formatting .. tostring(v))
        end
    end
end

for i = 1, 9 do
    sudoku.cells[i] = {}
    for j = 1, 9 do
        local cell         = newCell()

        cell.x_left        = math.floor(sudoku.START_X + (j - 1) * sudoku.CELL_WIDTH)
        cell.y_top         = math.floor(sudoku.START_Y + (i - 1) * sudoku.CELL_HEIGHT)
        cell.x_right       = math.floor(cell.x_left + sudoku.CELL_WIDTH)
        cell.y_bottom      = math.floor(cell.y_top + sudoku.CELL_HEIGHT)

        sudoku.cells[i][j] = cell
    end
end

-- for i = 1, 9 do
--     sudoku.cells[i] = {}
--     for j = 1, 9 do
--         sudoku.cells[i][j] = sudoku_cell_properties

--         if i == 1 and j == 1 then
--             sudoku.cells[i][j].x_left = sudoku.START_X
--             sudoku.cells[i][j].y_top = sudoku.START_Y
--             sudoku.cells[i][j].x_right = sudoku.START_X + sudoku.CELL_WIDTH
--             sudoku.cells[i][j].y_bottom = sudoku.START_Y + sudoku.CELL_HEIGHT
--         else
--             sudoku.cells[i][j].x_left = sudoku.cells[i-1][j-1].x_right
--             sudoku.cells[i][j].y_top = sudoku.cells[i-1][j-1].y_bottom
--             sudoku.cells[i][j].x_right = sudoku.START_X + sudoku.CELL_WIDTH - 1
--             sudoku.cells[i][j].y_bottom = sudoku.START_Y + sudoku.CELL_HEIGHT -1
--         end
--         if (j > 0) and ((j % 3) == 0) then
--             sudoku.cells[i][j].x_right = sudoku.cells[i][j].x_left + sudoku.CELL_WIDTH
--         end
--         if (i > 0) and ((i % 3) == 0) then
--             sudoku.cells[i][j].y_bottom = sudoku.cells[i][j].y_top + sudoku.CELL_HEIGHT
--         end
--     end
-- end

printTable(sudoku)