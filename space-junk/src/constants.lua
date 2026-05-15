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
local BTN_P1_UP     = 0
local BTN_P1_DOWN   = 1
local BTN_P1_LEFT   = 2
local BTN_P1_RIGHT  = 3
local BTN_P1_A      = 4         -- Primary action / Select
local BTN_P1_B      = 5         -- Secondary action / Back / Pause
local BTN_P1_X      = 6
local BTN_P1_Y      = 7
local BTN_P1_SELECT = BTN_P1_X
local BTN_P1_START  = BTN_P1_Y

-- Screen dimensions
local EDGE_X_LEFT   = 0
local EDGE_X_RIGHT  = 240
local EDGE_Y_TOP    = 0
local EDGE_Y_BOTTOM = 136

-- Character dimensions (these scale linearly)
local FIXED_CHAR_WIDTH  = 6
local FIXED_CHAR_HEIGHT = 6
local X_PADDING         = FIXED_CHAR_WIDTH + 2
local Y_PADDING         = FIXED_CHAR_HEIGHT + 2

local DEBUG = true