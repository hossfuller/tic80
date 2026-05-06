-- ==========================================
-- UPDATE FUNCTIONS
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

local function checkAutoNote()
    for i = 1, sudoku.DIM_X do
        for j = 1, sudoku.DIM_Y do
            setSingleCellNotes(i, j)
        end
    end
end

local function checkPuzzle()
    local all_guesses_are_correct = true
    for i = 1, sudoku.DIM_X do
        for j = 1, sudoku.DIM_Y do
            local cell = sudoku.cells[i][j]
            if cell.guess ~= nil and cell.guess ~= cell.solution then
                all_guesses_are_correct = false
            end
        end
    end
    sudoku.solved = all_guesses_are_correct
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

function UPDATE()
    if auto_note_btn.CLICKED == true then
        checkAutoNote()
    end

    if check_solution_btn.CLICKED == true then
        checkPuzzle()
    end

    if clear_btn.CLICKED == true then
        clearGuessesAndNotes()
    end
end
