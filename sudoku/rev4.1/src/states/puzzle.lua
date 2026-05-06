-- ==========================================
-- STATE: PUZZLE
-- ==========================================


local function updatePuzzle()


end


function drawPuzzleGrid()
    for i = 1, sudoku.DIM_X do
        for j = 1, sudoku.DIM_Y do
            local cell = sudoku.cells[i][j]

            local cell_bgcolor = GRAY_DARK
            local grid_x       = cell.x_left
            local grid_y       = cell.y_top
            local grid_width   = cell.x_right - cell.x_left + 1
            local grid_height  = cell.y_bottom - cell.y_top + 1

            -- Check cell status and change the cell's background color.
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
                print(cell.guess, grid_x + 2, grid_y + 2, WHITE, true, 2)
            end

            -- Finally, draw the grid.
            rectb(grid_x, grid_y, grid_width, grid_height, WHITE)
        end
    end
end


local function drawNotesGrid()
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
            local num_color = GRAY_LITE

            local x = grid_x + (j - 1) * cell_w
            local y = grid_y + (i - 1) * cell_h

            if (active_cell_notes ~= nil) and (active_cell_notes[i][j] == true) then
                num_color = YELLOW
            end

            rectb(x, y, cell_w, cell_h, WHITE)     -- cell border
            print(n, x + 2, y + 2, num_color, true, 2) -- number

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

    -- Print active clock and difficulty level.
    local start_x = box_start_x + math.floor(X_PADDING / 2)
    local start_y = box_start_y + Y_PADDING

    print("CLOCK", start_x, start_y, WHITE, false, 2, false)
    print("UNDO = " .. tostring(undo_btn.CLICKED) , start_x, start_y + 2*Y_PADDING, WHITE, false, 1, false)

    local difficultyItem = game.options.items[1]  -- First item is Difficulty
    local difficultyName = difficultyItem.values[difficultyItem.current]  -- "Easy", "Medium", or "Hard"

    print(
        difficultyName .. " difficulty", 
        start_x, 
        box_start_y + box_height - Y_PADDING, 
        WHITE
    )
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
end
