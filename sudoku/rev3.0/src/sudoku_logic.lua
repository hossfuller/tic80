-- ==========================================
-- SUDOKU LOGIC
-- ==========================================

local function generateSolution()
    local init_grid = {
        { 1, 2, 3,  4, 5, 6,  7, 8, 9 },
        { 4, 5, 6,  7, 8, 9,  1, 2, 3 },
        { 7, 8, 9,  1, 2, 3,  4, 5, 6 },

        { 3, 1, 2,  6, 4, 5,  9, 7, 8 },
        { 6, 4, 5,  9, 7, 8,  3, 1, 2 },
        { 9, 7, 8,  3, 1, 2,  6, 4, 5 },

        { 2, 3, 1,  5, 6, 4,  8, 9, 7 },
        { 5, 6, 4,  8, 9, 7,  2, 3, 1 },
        { 8, 9, 7,  2, 3, 1,  5, 6, 4 },
    }
    for i = 1, sudoku.DIM_X do
        for j = 1, sudoku.DIM_Y do
            sudoku.cells[i][j].solution = init_grid[i][j]
        end
    end

--[[
Generate a Valid Complete Grid
Starting with an empty 9x9 board, use a backtracking algorithm to fill it.
    1. Diagonal Fill (Optional for Speed): Fill the three diagonal 3x3 sub-grids
       first. Since they don't share rows or columns with each other, you can
       fill them with a random shuffle of numbers 1–9 without needing complex
       checks.
    2. Backtracking Search:
        1. Find the next empty cell.
        2. Pick a random number from 1 to 9.
        3. Check if it is "safe" (not present in the current row, column, or
           3x3 sub-grid).
        4. If safe, place it and move to the next cell.
        5. If you hit a dead end (no numbers are valid), backtrack to the
           previous cell and try a different number.
    3. Shuffle for Variety: You can also take a pre-existing valid board and
       apply transformations like swapping rows within a block, rotating the
       grid, or permuting the numbers (e.g., swapping all 1s with 5s).
--]]

    -- local init_grid = {
    --     { nil, nil, nil,  nil, nil, nil,  nil, nil, nil },
    --     { nil, nil, nil,  nil, nil, nil,  nil, nil, nil },
    --     { nil, nil, nil,  nil, nil, nil,  nil, nil, nil },

    --     { nil, nil, nil,  nil, nil, nil,  nil, nil, nil },
    --     { nil, nil, nil,  nil, nil, nil,  nil, nil, nil },
    --     { nil, nil, nil,  nil, nil, nil,  nil, nil, nil },

    --     { nil, nil, nil,  nil, nil, nil,  nil, nil, nil },
    --     { nil, nil, nil,  nil, nil, nil,  nil, nil, nil },
    --     { nil, nil, nil,  nil, nil, nil,  nil, nil, nil },
    -- }

    -- for i = 1, 9 do
    --     for j = 1, 9 do



    --     end
    -- end







end


local function setPuzzleDifficulty(difficulty)
    if difficulty == nil then
        difficulty = 'random'
    end
    for i = 1, sudoku.DIM_X do
        for j = 1, sudoku.DIM_Y do
            if difficulty == 'random' and math.random() < 0.5 then
                sudoku.cells[i][j].guess = sudoku.cells[i][j].solution
                sudoku.cells[i][j].locked = true
            end
        end
    end
end
