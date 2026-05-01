-- ==========================================
-- UPDATE FUNCTIONS
-- ==========================================

local function setSingleCellNotes(i, j)
    local starting_notes = {
        { true, true, true },
        { true, true, true },
        { true, true, true }
    }

    -- Check this row's values
    for y = 1, 9 do
        if sudoku.cells[i][y].guess == 1 then
            starting_notes[1][1] = false
        elseif sudoku.cells[i][y].guess == 2 then
            starting_notes[1][2] = false
        elseif sudoku.cells[i][y].guess == 3 then
            starting_notes[1][3] = false
        elseif sudoku.cells[i][y].guess == 4 then
            starting_notes[2][1] = false
        elseif sudoku.cells[i][y].guess == 5 then
            starting_notes[2][2] = false
        elseif sudoku.cells[i][y].guess == 6 then
            starting_notes[2][3] = false
        elseif sudoku.cells[i][y].guess == 7 then
            starting_notes[3][1] = false
        elseif sudoku.cells[i][y].guess == 8 then
            starting_notes[3][2] = false
        elseif sudoku.cells[i][y].guess == 9 then
            starting_notes[3][3] = false
        end
    end

    -- -- Check this column's values
    for x = 1, 9 do
        if sudoku.cells[x][j].guess == 1 then
            starting_notes[1][1] = false
        elseif sudoku.cells[x][j].guess == 2 then
            starting_notes[1][2] = false
        elseif sudoku.cells[x][j].guess == 3 then
            starting_notes[1][3] = false
        elseif sudoku.cells[x][j].guess == 4 then
            starting_notes[2][1] = false
        elseif sudoku.cells[x][j].guess == 5 then
            starting_notes[2][2] = false
        elseif sudoku.cells[x][j].guess == 6 then
            starting_notes[2][3] = false
        elseif sudoku.cells[x][j].guess == 7 then
            starting_notes[3][1] = false
        elseif sudoku.cells[x][j].guess == 8 then
            starting_notes[3][2] = false
        elseif sudoku.cells[x][j].guess == 9 then
            starting_notes[3][3] = false
        end
    end

    -- Check this house's values
    local house_start_x = 1
    local house_start_y = 1

    if 4 <= i and i <= 6 then
        house_start_x = 4
    elseif 7 <= i then
        house_start_x = 7
    end
    if 4 <= j and j <= 6 then
        house_start_y = 4
    elseif 7 <= j then
        house_start_y = 7
    end
    for x = house_start_x, house_start_x + 2 do
        for y = house_start_y, house_start_y + 2 do
            if sudoku.cells[x][y].guess == 1 then
                starting_notes[1][1] = false
            elseif sudoku.cells[x][y].guess == 2 then
                starting_notes[1][2] = false
            elseif sudoku.cells[x][y].guess == 3 then
                starting_notes[1][3] = false
            elseif sudoku.cells[x][y].guess == 4 then
                starting_notes[2][1] = false
            elseif sudoku.cells[x][y].guess == 5 then
                starting_notes[2][2] = false
            elseif sudoku.cells[x][y].guess == 6 then
                starting_notes[2][3] = false
            elseif sudoku.cells[x][y].guess == 7 then
                starting_notes[3][1] = false
            elseif sudoku.cells[x][y].guess == 8 then
                starting_notes[3][2] = false
            elseif sudoku.cells[x][y].guess == 9 then
                starting_notes[3][3] = false
            end
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
