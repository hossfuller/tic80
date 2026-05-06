-- ==========================================
-- SUDOKU LOGIC
-- ==========================================

-- God, I wish I'd paid more attention in linear algebra class....

--[[
## Generate a Valid Complete Grid
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

-- Copies a grid instead of creating references to a pre-exisitng grid.
local function copy_grid(g)
    local out = {}
    for i = 1, 9 do
        out[i] = {}
        for j = 1, 9 do
            out[i][j] = g[i][j]
        end
    end
    return out
end

-- Shuffles a table with values 1..9
local function shuffled_1_to_9()
    local t = { 1, 2, 3, 4, 5, 6, 7, 8, 9 }
    for i = 9, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end

-- Kinda does the same thing as shuffled_1_to_9(), but instead of filling in an
-- empty grid, this lets us shift around a pre-exisitng grid.
local function shuffled_positions()
    local pos = {}
    for k = 1, 81 do
        pos[k] = k
    end
    for i = 81, 2, -1 do
        local j = math.random(i)
        pos[i], pos[j] = pos[j], pos[i]
    end
    return pos
end

-- Checks if a number can safely go into a specific cell of the grid.
local function isSafe(grid_cells, r, c, n)
    -- Checks the row
    for j = 1, 9 do
        if grid_cells[r][j] == n then
            return false
        end
    end

    -- Checks the col
    for i = 1, 9 do
        if grid_cells[i][c] == n then
            return false
        end
    end

    local r0 = math.floor((r - 1) / 3) * 3 + 1
    local c0 = math.floor((c - 1) / 3) * 3 + 1
    for i = r0, r0 + 2 do
        for j = c0, c0 + 2 do
            if grid_cells[i][j] == n then
                return false
            end
        end
    end
    return true
end

-- Finds an empty cell in the grid worth inserting a solution. Returns the
-- coordinates of an empty cell. When the grid is full, it returns nil.
local function findEmpty(grid_cells)
    for i = 1, 9 do
        for j = 1, 9 do
            if grid_cells[i][j] == 0 then
                return i, j
            end
        end
    end
    return nil
end

-- Recursively fill in the grid until we have a valid sudoku board.
local function fillGrid(grid_cells)
    local r, c = findEmpty(grid_cells)
    if not r then
        return true
    end -- solved

    local nums = shuffled_1_to_9()
    for k = 1, 9 do
        local n = nums[k]
        if isSafe(grid_cells, r, c, n) then
            grid_cells[r][c] = n
            if fillGrid(grid_cells) then
                return true
            end
            grid_cells[r][c] = 0
        end
    end

    return false
end

local function generateSolution()

    local init_grid = {
        { 0, 0, 0,  0, 0, 0,  0, 0, 0 },
        { 0, 0, 0,  0, 0, 0,  0, 0, 0 },
        { 0, 0, 0,  0, 0, 0,  0, 0, 0 },

        { 0, 0, 0,  0, 0, 0,  0, 0, 0 },
        { 0, 0, 0,  0, 0, 0,  0, 0, 0 },
        { 0, 0, 0,  0, 0, 0,  0, 0, 0 },

        { 0, 0, 0,  0, 0, 0,  0, 0, 0 },
        { 0, 0, 0,  0, 0, 0,  0, 0, 0 },
        { 0, 0, 0,  0, 0, 0,  0, 0, 0 },
    }

    -- This tracks whether or not each of the 3x3 diagonal houses have been
    -- filled.
    local filled = { [0] = false, [1] = false, [2] = false }

    for i = 1, 9 do
        for j = 1, 9 do
            -- We only want rows 1..3 with cols 1..3, rows 4..6 with cols 4..6,
            -- and rows 7..9 with col 7..9. As we iterate over i and j, we can
            -- calculate a "block index" of the row and column.
            local bi = math.floor((i-1)/3)
            local bj = math.floor((j-1)/3)
            -- These block indices will come out to either 0 (row/col 1..3),
            -- 1 (row/col 4..6), or 2 (row/col 7..9). If the block indices are
            -- the same, then we're working in one of the diagonal houses.
            if (
                bi == bj             -- block indices match, so we're on a diag.
                and not filled[bi]   -- we haven't filled this diag house.
                and (i - 1) % 3 == 0 -- we're on the left-most i of the house.
                and (j - 1) % 3 == 0 -- we're on the top-most j of the house.
            ) then
                filled[bi] = true

                local nums = shuffled_1_to_9()
                local k = 1

                -- This is the magic diagonal part.
                for r = i, i+2 do
                    for c = j, j+2 do
                        init_grid[r][c] = nums[k]
                        k = k + 1
                    end
                end
            end
        end
    end

    -- Fill in the rest of the grid now:
    assert(fillGrid(init_grid), "failed to generate a full grid")

    -- Now copy our unique, valid sudoku puzzle into the main sudoku structure.
    for i = 1, sudoku.DIM_X do
        for j = 1, sudoku.DIM_Y do
            sudoku.cells[i][j].solution = init_grid[i][j]
        end
    end
end

--[[
## Create the Puzzle by Removing Numbers
Simply removing X random numbers might result in a board that is unsolvable or
has multiple solutions. So we aim for strategic removal.
    1. Create a list of all 81 cell positions and shuffle it.
    2. Pick a cell and remove its value.
    3. Uniqueness Check: Use a Sudoku solver (often the same backtracking
       algorithm used in Step 1) to check if the board still has exactly one
       unique solution.
    4. If there is more than one solution, put the number back.
    5. Repeat until you have reached the desired difficulty or tested all cells.
--]]

-- As we hide cells, we want to count up the number of potential solutions. This
-- will work recursively to make sure there's only 1 solution. The moment it
-- hits 2, it reverses back and punts out.

local function countSolutions(g, limit)
    local r, c = findEmpty(g)
    if not r then
        return 1
    end -- found a complete solution

    local total = 0
    local nums = shuffled_1_to_9() -- random order; helps vary puzzles
    for k = 1, 9 do
        local n = nums[k]
        if isSafe(g, r, c, n) then
            g[r][c] = n
            total = total + countSolutions(g, limit - total)
            g[r][c] = 0
            if total >= limit then
                return total
            end -- early stop
        end
    end
    return total
end

-- Allows for symmetric clue removal.
local function symPos(r, c)
    return 10 - r, 10 - c
end

-- Remove clues while also keeping the puzzle's solution unique.
-- Parameters:
--   sol: fully solved puzzle
--   target_givens: how many filled cells we want left (e.g. 30-40)
--   max_attempts: cap on removal tries (prevents long runs)
--   symmetric: enables/disables symmetric clue removal.
local function makePuzzleUnique(sol, target_givens, max_attempts, symmetric)
    local puz = copy_grid(sol)
    local givens = 81
    local attempts = 0

    local order = shuffled_positions()
    local idx = 1

    while givens > target_givens and attempts < max_attempts do
        if idx > 81 then
            order = shuffled_positions()
            idx = 1
        end

        local k = order[idx]; idx = idx + 1
        local r = math.floor((k - 1) / 9) + 1
        local c = ((k - 1) % 9) + 1

        if puz[r][c] ~= 0 then
            local r2, c2 = symPos(r, c)

            -- If doing symmetry, we try to remove a pair.
            -- If the symmetric cell is already empty, we can either:
            --   * treat it as a single removal, or
            --   * skip to preserve "paired" removals.
            -- Here we allow single removal when the pair is already empty.
            local backup1 = puz[r][c]
            local backup2 = puz[r2][c2]

            local removing_two = symmetric and not (r == r2 and c == c2) and (backup2 ~= 0)

            puz[r][c] = 0
            if removing_two then puz[r2][c2] = 0 end

            local test = copy_grid(puz)
            local nsol = countSolutions(test, 2)

            if nsol ~= 1 then
                -- revert
                puz[r][c] = backup1
                if removing_two then puz[r2][c2] = backup2 end
            else
                -- keep
                givens = givens - 1
                if removing_two then givens = givens - 1 end
            end

            attempts = attempts + 1
        end
    end

    return puz
end

local function solutionCellsToGrid()
    local sol = {}
    for i = 1, 9 do
        sol[i] = {}
        for j = 1, 9 do
            sol[i][j] = sudoku.cells[i][j].solution
        end
    end
    return sol
end

local function applyPuzzleGridToCells(puzzle_grid)
    for i = 1, 9 do
        for j = 1, 9 do
            local cell = sudoku.cells[i][j]
            local clue = puzzle_grid[i][j] -- 0 means empty

            if clue ~= 0 then
                cell.guess  = clue
                cell.locked = true
                -- Clear notes for locked cells
                cell.notes  = { { false, false, false }, { false, false, false }, { false, false, false } }
            else
                cell.guess  = nil
                cell.locked = false
                cell.notes  = { { false, false, false }, { false, false, false }, { false, false, false } }
            end
        end
    end

    sudoku.clicked.i, sudoku.clicked.j = nil, nil
    sudoku.solved = false
end

-- Sets the difficulty target.
local function pickTargetGivens(tier)
    local a, b = tier.givens_min, tier.givens_max
    return a + math.random(b - a)
end

local function generatePuzzleByTier(name)
    local tier = DIFFICULTY[name] or DIFFICULTY.medium
    local target = pickTargetGivens(tier)

    local sol_grid = solutionCellsToGrid()
    local puzzle_grid = makePuzzleUnique(sol_grid, target, tier.max_attempts, tier.symmetric)

    applyPuzzleGridToCells(puzzle_grid)
    sudoku.difficulty = name
end
