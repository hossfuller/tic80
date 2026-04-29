-- ==========================================
-- DRAW FUNCTIONS
-- ==========================================

function drawPuzzle()
    for i = 1, 9 do
        for j = 1, 9 do
            local cell_bgcolor = GRAY_DARK
            local grid_x       = sudoku.cells[i][j].x_left
            local grid_y       = sudoku.cells[i][j].y_top
            local grid_width   = sudoku.cells[i][j].x_right - sudoku.cells[i][j].x_left + 1
            local grid_height  = sudoku.cells[i][j].y_bottom - sudoku.cells[i][j].y_top + 1

            -- Check cell status and change the cell's background color.
            if sudoku.cells[i][j].locked == true then
                cell_bgcolor = BLACK
            elseif sudoku.cells[i][j].clicked == true then
                cell_bgcolor = YELLOW
            elseif sudoku.cells[i][j].mouseover == true then
                cell_bgcolor = PURPLE
            end
            rect(grid_x, grid_y, grid_width, grid_height, cell_bgcolor)

            -- If there isn't a guess, print the notes.
            if sudoku.cells[i][j].guess == nil then
                local cell = sudoku.cells[i][j]

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
                print(sudoku.cells[i][j].guess, grid_x + 2, grid_y + 2, WHITE, true, 2)
            end

            -- Finally, draw the grid.
            rectb(grid_x, grid_y, grid_width, grid_height, WHITE)
        end
    end
end

local function drawNotesGrid()
    local grid_x = sudoku.END_X + 10
    local grid_y = sudoku.START_Y

    local cell_w = math.floor(sudoku.CELL_WIDTH)
    local cell_h = math.floor(sudoku.CELL_HEIGHT)







    local n = 1
    for i = 1, 3 do
        for j = 1, 3 do
            local x = grid_x + (j - 1) * cell_w
            local y = grid_y + (i - 1) * cell_h

            rectb(x, y, cell_w, cell_h, WHITE)     -- cell border
            print(n, x + 2, y + 2, WHITE, true, 2) -- number

            n = n + 1
        end
    end
end

function DRAW()
    cls(BLACK)

    -- Screen border
    rectb(
        EDGE_X_LEFT,
        EDGE_Y_TOP,
        EDGE_X_RIGHT,
        EDGE_Y_BOTTOM,
        WHITE
    )

    drawPuzzle()
    drawNotesGrid()
end
