-- title:   Sudoku for TIC-80
-- author:  Adam Fuller <the.adam.fuller@gmail.com>
-- version: 0.1
-- script:  lua
-- input: mouse

-- ==========================================
-- CONSTANTS
-- ==========================================

-- Colors
local BLACK                 = 0
local PURPLE                = 1
local RED                   = 2
local ORANGE                = 3
local YELLOW                = 4
local GREEN_LITE            = 5
local GREEN_MED             = 6
local GREEN_DARK            = 7
local BLUE_DARK             = 8
local BLUE_MED              = 9
local BLUE_LITE             = 10
local CYAN                  = 11
local WHITE                 = 12
local GRAY_LITE             = 13
local GRAY_MED              = 14
local GRAY_DARK             = 15

-- Button mappings
local BTN_P1_UP             = 0
local BTN_P1_DOWN           = 1
local BTN_P1_LEFT           = 2
local BTN_P1_RIGHT          = 3
local BTN_P1_A              = 4 -- Primary action / Select
local BTN_P1_B              = 5 -- Secondary action / Back / Pause
local BTN_P1_X              = 6
local BTN_P1_Y              = 7
local BTN_P2_UP             = 8
local BTN_P2_DOWN           = 9
local BTN_P2_LEFT           = 10
local BTN_P2_RIGHT          = 11
local BTN_P2_A              = 12
local BTN_P2_B              = 13
local BTN_P2_X              = 14
local BTN_P2_Y              = 15

-- Screen dimensions
local EDGE_X_LEFT           = 0
local EDGE_X_RIGHT          = 240
local EDGE_Y_TOP            = 0
local EDGE_Y_BOTTOM         = 136

-- Character dimensions (these scale linearly)
local FIXED_CHAR_WIDTH  = 6
local FIXED_CHAR_HEIGHT = 6

local X_PADDING              = FIXED_CHAR_WIDTH + 2
local Y_PADDING              = FIXED_CHAR_HEIGHT + 2
local CELL_WIDTH_MULTIPLIER  = 1.75
local CELL_HEIGHT_MULTIPLIER = 1.75

local sudoku_matrix = {
    START_X       = EDGE_X_LEFT + X_PADDING,
    START_Y       = EDGE_Y_TOP + Y_PADDING,
    CELL_WIDTH    = CELL_WIDTH_MULTIPLIER * X_PADDING,
    CELL_HEIGHT   = CELL_HEIGHT_MULTIPLIER * Y_PADDING,
    CELL_OFFSET   = 2,
    END_X         = EDGE_X_LEFT + X_PADDING + (9 * CELL_WIDTH_MULTIPLIER * X_PADDING),
    END_Y         = EDGE_Y_TOP + Y_PADDING + (9 * CELL_HEIGHT_MULTIPLIER * Y_PADDING),
    coordinates   = {},
    solution      = {},
    locked        = {},
    visible       = {},
    visible_notes = {},
    user_guesses  = {},
    user_notes    = {},
    mouseover     = { x = -1, y = -1 },
    clicked       = { x = -1, y = -1 },
}


-- ==========================================
-- FUNCTIONS
-- ==========================================

local function initialize_matrix_coordinates()
    local x_pos = sudoku_matrix.START_X
    local y_pos = sudoku_matrix.START_Y
    for i = 1, 9 do
        sudoku_matrix.coordinates[i] = {}
        for j = 1, 9 do
            sudoku_matrix.coordinates[i][j] = {
                x = x_pos,
                y = y_pos
            }
            if (j > 0) and ((j % 3) == 0) then
                x_pos = x_pos + sudoku_matrix.CELL_WIDTH
            else
                x_pos = x_pos + sudoku_matrix.CELL_WIDTH - 1 -- makes the cell borders overlap
            end
        end
        x_pos = sudoku_matrix.START_X
        if (i > 0) and ((i % 3) == 0) then
            y_pos = y_pos + sudoku_matrix.CELL_HEIGHT
        else
            y_pos = y_pos + sudoku_matrix.CELL_HEIGHT - 1 -- makes the cell borders overlap
        end
    end
end

local function initialize_matrix_everything_else()
    for i = 1, 9 do
        sudoku_matrix.locked[i]        = {}
        sudoku_matrix.visible[i]       = {}
        sudoku_matrix.visible_notes[i] = {}
        sudoku_matrix.user_guesses[i]  = {}
        sudoku_matrix.user_notes[i]    = {}

        for j = 1, 9 do
            sudoku_matrix.locked[i][j]        = true
            sudoku_matrix.visible[i][j]       = math.random() < 0.5
            sudoku_matrix.visible_notes[i][j] = {}
            sudoku_matrix.user_guesses[i][j]  = {}
            sudoku_matrix.user_notes[i][j]    = {}
        end
    end
end

local function initialize_matrix_solution()
    for i = 1, 9 do
        sudoku_matrix.solution[i] = {}
        for j = 1, 9 do
            sudoku_matrix.solution[i][j] = i
            if sudoku_matrix.visible[i][j] == true then
                sudoku_matrix.user_guesses[i][j] = sudoku_matrix.solution[i][j]
            end
        end
    end
end


local function lock_matrix()
    for i = 1, 9 do
        for j = 1, 9 do
            sudoku_matrix.locked[i][j] = true
        end
    end
end


function matrix_grid_draw()
    local cell_bgcolor = BLACK

    for i = 1, 9 do
        for j = 1, 9 do

            local grid_x = sudoku_matrix.coordinates[i][j].x
            local grid_y = sudoku_matrix.coordinates[i][j].y
            rectb(grid_x, grid_y, sudoku_matrix.CELL_WIDTH, sudoku_matrix.CELL_HEIGHT, WHITE)

            if (grid_x < sudoku_matrix.mouseover.x) and (sudoku_matrix.mouseover.x < grid_x + sudoku_matrix.CELL_WIDTH) then
                if (grid_y < sudoku_matrix.mouseover.y) and (sudoku_matrix.mouseover.y < grid_y + sudoku_matrix.CELL_HEIGHT) then
                    cell_bgcolor = PURPLE
                end
            end

--             -- We need to check what the mouse is doing as that will change how
--             -- we display the cell. First check if the mouse is over a cell.
--             -- Then, while in that cell, check to see if the user has toggled
--             -- the cell.
--             if (grid_x < x) and (x < grid_x + sudoku_matrix.CELL_WIDTH) then
--                 if (grid_y < y) and (y < grid_y + sudoku_matrix.CELL_HEIGHT) then
--                     cell_bgcolor = PURPLE

--                     if left == true then
--                         sudoku_matrix.highlighted[i][j] = not sudoku_matrix.highlighted[i][j]
--                     end
--                 end
--             end

--             -- Check if this cell has been clicked.
--             if sudoku_matrix.highlighted[i][j] == true then
--                 clear_matrix_highlighting()
--                 sudoku_matrix.highlighted[i][j] = true
--                 cell_bgcolor = YELLOW
--             end

            -- Now draw the cell.
            rect(
                grid_x + 1,
                grid_y + 1,
                sudoku_matrix.CELL_WIDTH - 2,
                sudoku_matrix.CELL_HEIGHT - 2,
                cell_bgcolor
            )

            if sudoku_matrix.visible[i][j] == true then
                local x_pos = sudoku_matrix.coordinates[i][j].x + sudoku_matrix.CELL_OFFSET
                local y_pos = sudoku_matrix.coordinates[i][j].y + sudoku_matrix.CELL_OFFSET
                print(sudoku_matrix.solution[i][j], x_pos, y_pos, GRAY_LITE, true, 2)
            end

            cell_bgcolor = BLACK
        end
    end
end


-- function matrix_grid_fill()
--     for i = 1, 9 do
--         for j = 1, 9 do
--             if sudoku_matrix.visible[i][j] == true then
--                 x_pos = sudoku_matrix.coordinates[i][j].x + MATRIX_CELL_OFFSET
--                 y_pos = sudoku_matrix.coordinates[i][j].y + MATRIX_CELL_OFFSET
--                 print(sudoku_matrix.solution[i][j], x_pos, y_pos, GRAY_LITE, true, 2)
--             end
--         end
--     end
-- end





function INIT()
    initialize_matrix_coordinates()
    initialize_matrix_everything_else()
    initialize_matrix_solution()
end -- INIT()

function INPUT()
    local mouse_x, mouse_y, left_click, middle_click, right_click, scroll_x, scroll_y = mouse()

    if (sudoku_matrix.START_X < mouse_x) and (mouse_x < sudoku_matrix.END_X) then
        if (sudoku_matrix.START_Y < mouse_y) and (mouse_y < sudoku_matrix.END_Y) then
            sudoku_matrix.mouseover.x = mouse_x
            sudoku_matrix.mouseover.y = mouse_y

            if left_click == true then
                sudoku_matrix.clicked.x = mouse_x
                sudoku_matrix.clicked.y = mouse_y
            end

            -- also check for wheel spin so we know whether or not to change number.
        end
    end
end

function UPDATE()
    for i = 1, 9 do
        for j = 1, 9 do
            local grid_x = sudoku_matrix.coordinates[i][j].x
            local grid_y = sudoku_matrix.coordinates[i][j].y

            if (grid_x < sudoku_matrix.mouseover.x) and (sudoku_matrix.mouseover.x < grid_x + sudoku_matrix.CELL_WIDTH) then
                if (grid_x < sudoku_matrix.mouseover.x) and (sudoku_matrix.mouseover.x < grid_x + sudoku_matrix.CELL_WIDTH) then

                end
            end

            --             if (grid_x < x) and (x < grid_x + sudoku_matrix.CELL_WIDTH) then
            --                 if (grid_y < y) and (y < grid_y + sudoku_matrix.CELL_HEIGHT) then
            --                     cell_bgcolor = PURPLE

            --                     if left == true then
            --                         sudoku_matrix.highlighted[i][j] = not sudoku_matrix.highlighted[i][j]
            --                     end
            --                 end
            --             end


        end
    end
end

-- local sudoku_matrix = {
--     START_X       = EDGE_X_LEFT + X_PADDING,
--     START_Y       = EDGE_Y_TOP + Y_PADDING,
--     CELL_WIDTH    = CELL_WIDTH_MULTIPLIER * X_PADDING,
--     CELL_HEIGHT   = CELL_HEIGHT_MULTIPLIER * Y_PADDING,
--     END_X         = EDGE_X_LEFT + X_PADDING + (9 * CELL_WIDTH_MULTIPLIER * X_PADDING),
--     END_Y         = EDGE_Y_TOP + Y_PADDING + (9 * CELL_HEIGHT_MULTIPLIER * Y_PADDING),
--     coordinates   = {},
--     solution      = {},
--     highlighted   = {},
--     visible       = {},
--     visible_notes = {},
--     user_guesses  = {},
--     user_notes    = {},
--     mouseover     = { x = -1, y = -1 },
--     clicked       = { x = -1, y = -1 },
-- }






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

    matrix_grid_draw()
    -- matrix_grid_fill()
end

-- ==========================================
-- MAIN GAME LOOP
-- ==========================================

INIT()

function TIC()
    INPUT()
    UPDATE()
    DRAW()

    local what_is_next = {
        "Need to work out a ",
        "better data ",
        "structure. Instead ",
        "of a bunch of ",
        "duplicate matrices, ",
        "there should be ",
        "one matrix with ",
        "each cell ",
        "containing the ",
        "solution, user ",
        "guess, and a bunch ",
        "of flags that ",
        "dictate what is ",
        "actually printed.",
        "The tough part ",
        "being how do we ",
        "handle auto and ",
        "user notes."
    }

    for i, msg in ipairs(what_is_next) do
        print(
            msg,
            sudoku_matrix.END_X,
            sudoku_matrix.START_Y + (i * Y_PADDING),
            WHITE
        )
        -- -- print left column
        -- print(header, column_one_x, EDGE_Y_TOP + (num * Y_PADDING), WHITE, true, 1)

        -- -- print right column
        -- local y_pos = EDGE_Y_TOP + (num * Y_PADDING)
        -- local value_width = print(tostring(datetime_data[num]), 0, -100, WHITE, true, 1)
        -- local x_pos = EDGE_X_RIGHT - X_PADDING - value_width
        -- print(tostring(datetime_data[num]), x_pos, y_pos, WHITE, true, 1)
    end

end
-- local sudoku_matrix = {
--     START_X       = EDGE_X_LEFT + X_PADDING,
--     START_Y       = EDGE_Y_TOP + Y_PADDING,
--     CELL_WIDTH    = CELL_WIDTH_MULTIPLIER * X_PADDING,
--     CELL_HEIGHT   = CELL_HEIGHT_MULTIPLIER * Y_PADDING,
--     CELL_OFFSET   = 2,
--     END_X         = EDGE_X_LEFT + X_PADDING + (9 * CELL_WIDTH_MULTIPLIER * X_PADDING),
--     END_Y         = EDGE_Y_TOP + Y_PADDING + (9 * CELL_HEIGHT_MULTIPLIER * Y_PADDING),
