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
