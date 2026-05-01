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
