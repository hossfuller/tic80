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
