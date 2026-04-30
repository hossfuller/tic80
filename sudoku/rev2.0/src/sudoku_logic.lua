-- ==========================================
-- SUDOKU LOGIC
-- ==========================================

local function generateSolution()
    for i = 1, 9 do
        for j = 1, 9 do
            sudoku.cells[i][j].solution = math.random(1, 9)
            if math.random() < 0.5 then
                sudoku.cells[i][j].guess = sudoku.cells[i][j].solution
                sudoku.cells[i][j].locked = true
            end
        end
    end
end

--[[
  Currently we just want to display
--]]
local function finalizePuzzle(difficulty)
    if difficulty == nil then
        difficulty = 'random'
    end
    for i = 1, 9 do
        for j = 1, 9 do
            if difficulty == 'random' and math.random() < 0.5 then
                sudoku.cells[i][j].guess = sudoku.cells[i][j].solution
                sudoku.cells[i][j].locked = true
            end
        end
    end
end
