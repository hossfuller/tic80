-- title:   Big Clock
-- author:  Adam Fuller <the.adam.fuller@gmail.com>
-- desc:    Test code for a big digital clock.
-- version: 0.2
-- script:  lua
-- input:   mouse

-- Colors
local BLACK      = 0
local PURPLE     = 1
local RED        = 2
local ORANGE     = 3
local YELLOW     = 4
local GREEN_LITE = 5
local GREEN_MED  = 6
local GREEN_DARK = 7
local BLUE_DARK  = 8
local BLUE_MED   = 9
local BLUE_LITE  = 10
local CYAN       = 11
local WHITE      = 12
local GRAY_LITE  = 13
local GRAY_MED   = 14
local GRAY_DARK  = 15

-- Screen dimensions
local EDGE_X_LEFT            = 0
local EDGE_X_RIGHT           = 240
local EDGE_Y_TOP             = 0
local EDGE_Y_BOTTOM          = 136

-- Character dimensions (these scale linearly)
local FIXED_CHAR_WIDTH       = 6
local FIXED_CHAR_HEIGHT      = 6

local X_PADDING              = FIXED_CHAR_WIDTH + 2
local Y_PADDING              = FIXED_CHAR_HEIGHT + 2


-- ==========================================
-- INCLUDES
-- ==========================================

include "TimerObj"


-- ==========================================
-- MAIN GAME LOOP
-- ==========================================

newTimer = TimerObj.new()

function TIC()
    cls(BLACK)

    -- input
    local mouse_x, mouse_y, left_click, middle_click, right_click, scroll_x, scroll_y = mouse()

    -- update
    if left_click then newTimer:start() end
    if right_click then newTimer:stop() end
    if middle_click then newTimer:reset() end

    newTimer:update()


    -- draw
    print("Left click:   Start", EDGE_X_LEFT, EDGE_Y_TOP, ORANGE)
    print("Middle click: Reset", EDGE_X_LEFT, EDGE_Y_TOP + 2 * Y_PADDING, ORANGE)
    print("Right click:  Stop", EDGE_X_LEFT, EDGE_Y_TOP + Y_PADDING, ORANGE)

    print(
        newTimer:getFormatted(),
        EDGE_X_LEFT, 
        EDGE_Y_TOP + 4 * Y_PADDING, 
        WHITE, 
        true, 
        3, 
        false
    )

    -- Show running status
    local status = newTimer:isRunning() and "Running" or "Stopped"
    print("Status: "..status, EDGE_X_LEFT, EDGE_Y_BOTTOM - Y_PADDING, CYAN)
end