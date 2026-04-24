-- ==========================================
-- CONSTANTS
-- ==========================================

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

-- Button mappings
local P1_UP    = 0
local P1_DOWN  = 1
local P1_LEFT  = 2
local P1_RIGHT = 3
local P1_A     = 4
local P1_B     = 5
local P1_X     = 6
local P1_Y     = 7
local P2_UP    = 8
local P2_DOWN  = 9
local P2_LEFT  = 10
local P2_RIGHT = 11
local P2_A     = 12
local P2_B     = 13
local P2_X     = 14
local P2_Y     = 15
-- local BTN_UP     = P1_UP
-- local BTN_DOWN   = P1_DOWN
-- local BTN_LEFT   = P1_LEFT
-- local BTN_RIGHT  = P1_RIGHT
-- local BTN_Z      = P1_A  -- Primary action / Select
-- local BTN_X      = P1_B  -- Secondary action / Back / Pause


-- Screen dimensions
local EDGE_X_LEFT    = 0
local EDGE_X_RIGHT   = 240
local EDGE_Y_TOP     = 0
local EDGE_Y_BOTTOM  = 136
local SCREEN_W = EDGE_X_RIGHT
local SCREEN_H = EDGE_Y_BOTTOM


local STATE = {
    START    = "START",
    OPTIONS  = "OPTIONS",
    HISCORES = "HISCORES",
    READY    = "READY",
    PLAY     = "PLAY",
    PAUSE    = "PAUSE",
    GAMEOVER = "GAMEOVER",
}


--[[ TODO LIST ]]--

-- TODO: Add a way to pause the game.
-- TODO: Do power ups!

