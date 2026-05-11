-- title:   PMEM-TEST
-- author:  Hoss Fuller <hossfuller@proton.me>
-- desc:    Test code reading and writing to the persistent memory. This is a test script for the sudoku app.
-- version: 0.1
-- script:  lua

-- Colors
local BLACK             = 0
local PURPLE            = 1
local RED               = 2
local ORANGE            = 3
local YELLOW            = 4
local GREEN_LITE        = 5
local GREEN_MED         = 6
local GREEN_DARK        = 7
local BLUE_DARK         = 8
local BLUE_MED          = 9
local BLUE_LITE         = 10
local CYAN              = 11
local WHITE             = 12
local GRAY_LITE         = 13
local GRAY_MED          = 14
local GRAY_DARK         = 15

-- Controls
local P1_UP             = 0
local P1_DOWN           = 1
local P1_LEFT           = 2
local P1_RIGHT          = 3
local P1_A              = 4
local P2_UP             = 8
local P2_DOWN           = 9
local P2_LEFT           = 10
local P2_RIGHT          = 11
local P2_A              = 12

-- Screen dimensions
local EDGE_X_LEFT       = 0
local EDGE_X_RIGHT      = 240
local EDGE_Y_TOP        = 0
local EDGE_Y_BOTTOM     = 136

-- Character dimensions (these scale linearly)
local FIXED_CHAR_WIDTH  = 6
local FIXED_CHAR_HEIGHT = 6

local X_PADDING         = FIXED_CHAR_WIDTH + 2
local Y_PADDING         = FIXED_CHAR_HEIGHT + 2


-- ==========================================
-- MAIN GAME LOOP
-- ==========================================

local test_data = {}

local function generate_test_data()
    for i = 0, 63 do
        local starting_index = i * 4
        test_data[starting_index] = {
            date = math.tointeger(tstamp()),
            difficulty = math.random(0, 2),
            timer = math.random(1, 100),
            autonotes = math.random(0, 20)
        }
        starting_index = starting_index + 1
    end
end

function BOOT()
    generate_test_data
end

function TIC()
    cls(BLACK)

    -- input
    local mouse_x, mouse_y, left_click, middle_click, right_click, scroll_x, scroll_y = mouse()

    -- update


    -- draw


end
