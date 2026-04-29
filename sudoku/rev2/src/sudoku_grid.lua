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
