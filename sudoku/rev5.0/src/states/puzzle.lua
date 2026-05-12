-- ==========================================
-- STATE: PUZZLE
-- ==========================================

local function markNoteFalse(starting_notes, guess)
    if guess ~= nil and guess >= 1 and guess <= 9 then
        local row = math.ceil(guess / 3)
        local col = (guess - 1) % 3 + 1
        starting_notes[row][col] = false
    end
end

local function setSingleCellNotes(i, j)
    local starting_notes = {
        { true, true, true },
        { true, true, true },
        { true, true, true }
    }

    -- Check row
    for y = 1, 9 do
        markNoteFalse(starting_notes, sudoku.cells[i][y].guess)
    end

    -- Check column
    for x = 1, 9 do
        markNoteFalse(starting_notes, sudoku.cells[x][j].guess)
    end

    -- Check house
    local house_start_x = math.floor((i - 1) / 3) * 3 + 1
    local house_start_y = math.floor((j - 1) / 3) * 3 + 1

    for x = house_start_x, house_start_x + 2 do
        for y = house_start_y, house_start_y + 2 do
            markNoteFalse(starting_notes, sudoku.cells[x][y].guess)
        end
    end

    sudoku.cells[i][j].notes = starting_notes
end

function checkAutoNote()
    for i = 1, sudoku.DIM_X do
        for j = 1, sudoku.DIM_Y do
            setSingleCellNotes(i, j)
        end
    end
end

local function checkPuzzle()
    local all_guesses_are_correct = false
    local all_cells_are_filled_in = true

    for i = 1, sudoku.DIM_X do
        for j = 1, sudoku.DIM_Y do
            local cell = sudoku.cells[i][j]
            if cell.guess == nil then
                all_cells_are_filled_in = false
            end
        end
    end

    -- Only if all cells are filled in do we check if solution is complete.
    if all_cells_are_filled_in then
        all_guesses_are_correct = true
        for i = 1, sudoku.DIM_X do
            for j = 1, sudoku.DIM_Y do
                local cell = sudoku.cells[i][j]
                if cell.guess ~= cell.solution then
                    all_cells_are_filled_in = false
                end
            end
        end
    end
    game.play.solved = all_guesses_are_correct

    -- Stop the clock and register "score" in high scores
    if all_guesses_are_correct then
        game.play.timer:stop()
        saveCurrentScore()
    end
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

local function undoLastNumber()
    undo_last_action()
end

local function setNewPuzzle()
    changeState(STATE.NEWPUZZLE)
end

local function exitToMainMenu()
    changeState(STATE.TITLE)
end

local function updatePuzzle()
    if game.play.timer:isRunning() then
        game.play.timer:update()
    end

    if auto_note_btn.PREV_CLICK == true then
        checkAutoNote()
    end

    if undo_btn.PREV_CLICK == true then
        undoLastNumber()
    end

    if clear_btn.PREV_CLICK == true then
        clearGuessesAndNotes()
    end

    if check_solution_btn.PREV_CLICK == true then
        checkPuzzle()
    end

    if new_puzzle_btn.PREV_CLICK == true then
        setNewPuzzle()
    end

    if exit_btn.PREV_CLICK == true then
        exitToMainMenu()
    end
end

local function getCompletedDigitsInAllHouses()
    local present = {}
    for d = 1, 9 do present[d] = {} end

    for i = 1, 9 do
        for j = 1, 9 do
            local guess = sudoku.cells[i][j].guess -- FIXED
            if guess then
                local hi          = math.floor((i - 1) / 3)
                local hj          = math.floor((j - 1) / 3)
                local h           = hi * 3 + hj -- 0..8
                present[guess][h] = true
            end
        end
    end

    local doneDigit = {}
    for d = 1, 9 do
        local ok = true
        for h = 0, 8 do
            if not present[d][h] then
                ok = false; break
            end
        end
        doneDigit[d] = ok
    end

    local doneCell = {}
    for r = 1, 9 do
        doneCell[r] = {}
        for c = 1, 9 do
            local v = sudoku.cells[r][c].guess
            doneCell[r][c] = (v ~= nil) and doneDigit[v] or false
        end
    end

    return doneDigit, doneCell
end

local function inSameRowColOrHouse(sel_i, sel_j, i, j)
    if sel_i == nil or sel_j == nil then
        return false
    end

    -- same row or same column
    if i == sel_i or j == sel_j then
        return true
    end

    -- same 3x3 house
    local sel_hi = math.floor((sel_i - 1) / 3)
    local sel_hj = math.floor((sel_j - 1) / 3)
    local hi     = math.floor((i - 1) / 3)
    local hj     = math.floor((j - 1) / 3)

    return (hi == sel_hi) and (hj == sel_hj)
end

function drawPuzzleGrid()
    local _, doneCell = getCompletedDigitsInAllHouses()

    -- We want to highlight all the cells in the same house, row, and column
    -- when a user clicks on an editable cell. This code starts the highlighting
    -- process.
    local sel_i, sel_j = sudoku.clicked.i, sudoku.clicked.j
    local highlight_ok = false
    if sel_i and sel_j then
        local sel_cell = sudoku.cells[sel_i][sel_j]
        highlight_ok = (sel_cell ~= nil) and (sel_cell.locked == false)
    end

    for i = 1, sudoku.DIM_X do
        for j = 1, sudoku.DIM_Y do
            local cell = sudoku.cells[i][j]

            local cell_bgcolor = GRAY_DARK
            local border_color = WHITE
            local number_color = WHITE

            local grid_x      = cell.x_left
            local grid_y      = cell.y_top
            local grid_width  = cell.x_right - cell.x_left + 1
            local grid_height = cell.y_bottom - cell.y_top + 1

            -- Background coloring.
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
                -- If the digit is complete in all houses, make it blue.
                number_color = doneCell[i][j] and BLUE_LITE or WHITE
                print(cell.guess, grid_x + 2, grid_y + 2, number_color, true, 2)
            end

            -- Change border color when selecting an unlocked cell.
            if highlight_ok and inSameRowColOrHouse(sel_i, sel_j, i, j) then
                border_color = ORANGE
            end

            -- Finally, draw the grid.
            rectb(grid_x, grid_y, grid_width, grid_height, border_color)
        end
    end
end


local function drawNotesGrid()
    local doneDigit = select(1, getCompletedDigitsInAllHouses())

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
            local number_color = GRAY_LITE

            -- if the digit is complete in all houses, make it blue.
            if doneDigit[n] then
                number_color = BLUE_LITE
            end

            local x = grid_x + (j - 1) * cell_w
            local y = grid_y + (i - 1) * cell_h

            if (active_cell_notes ~= nil) and (active_cell_notes[i][j] == true) then
                number_color = YELLOW
            end

            rectb(x, y, cell_w, cell_h, WHITE)     -- cell border
            print(n, x + 2, y + 2, number_color, true, 2) -- number

            n = n + 1
        end
    end
end

local function drawPuzzleButtons()
    for i, butt in ipairs(puzzle_buttons) do
        local text_color = WHITE
        local bg_color   = GRAY_DARK
        if butt.CLICKED then
            text_color = GRAY_DARK
            bg_color = butt.BG_COLOR
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
    local sudoku_end_y = check_solution_btn.START_Y - Y_PADDING
    local box_height = sudoku_end_y - box_start_y + 1

    rect(box_start_x, box_start_y, box_width, box_height, BLACK)
    rectb(box_start_x, box_start_y, box_width, box_height, WHITE)

    -- Print active clock, num of auto-nots, and difficulty level.
    local start_x = box_start_x + math.floor(X_PADDING / 2)
    local start_y = box_start_y + Y_PADDING

    -- Add clock here.
    print(game.play.timer:getFormatted(), start_x, start_y, WHITE, true, 3)
    print(
        "Auto-Note: " .. tostring(game.play.autonotes),
        start_x,
        start_y + 3*Y_PADDING,
        WHITE
    )

    print(
        -- "Level: " .. difficultyName,
        "Level: " .. game.play.difficulty,
        start_x,
        box_start_y + box_height - Y_PADDING,
        WHITE
    )
end

local function drawSuccess()
    if game.play.solved then
        drawOverlayBox({ "SUCCESS!", "Click 'NEW' or", "'EXIT' to continue." })
        game.play.timer:stop()
    end
end


function drawPuzzle()
    cls(BLACK)

    -- Screen border
    rectb(
        EDGE_X_LEFT,
        EDGE_Y_TOP,
        EDGE_X_RIGHT,
        EDGE_Y_BOTTOM,
        WHITE
    )

    -- Puzzle elements
    drawPuzzleGrid()
    drawNotesGrid()
    drawPuzzleButtons()
    drawStatBox()
    drawSuccess()
end
