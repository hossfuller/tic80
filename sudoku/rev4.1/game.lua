--
-- Bundle file
-- Code changes will be overwritten
--

-- title:   Sudoku for TIC-80
-- author:  Adam Fuller <the.adam.fuller@gmail.com>
-- version: rev3
-- script:  lua
-- input: mouse

-- ==========================================
-- INCLUDES
-- ==========================================

-- [TQ-Bundler: src.constants]

-- ==========================================
-- CONSTANTS
-- ==========================================

-- Colors
local BLACK                  = 0
local PURPLE                 = 1
local RED                    = 2
local ORANGE                 = 3
local YELLOW                 = 4
local GREEN_LITE             = 5
local GREEN_MED              = 6
local GREEN_DARK             = 7
local BLUE_DARK              = 8
local BLUE_MED               = 9
local BLUE_LITE              = 10
local CYAN                   = 11
local WHITE                  = 12
local GRAY_LITE              = 13
local GRAY_MED               = 14
local GRAY_DARK              = 15

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
local CELL_WIDTH_MULTIPLIER  = 1.75
local CELL_HEIGHT_MULTIPLIER = 1.75
local GAP_CELL               = -1 -- between cells inside a house
local GAP_HOUSE              = 0  -- between houses (after col/row 3 and 6)

-- Game settings
local DIFFICULTY             = {
    easy       = { givens_min = 40, givens_max = 45, max_attempts = 1500, symmetric = true },
    medium     = { givens_min = 32, givens_max = 39, max_attempts = 2500, symmetric = true },
    hard       = { givens_min = 24, givens_max = 31, max_attempts = 6000, symmetric = true },
}
local SELECTED_DIFFICULTY = "medium"

-- [/TQ-Bundler: src.constants]

-- ==========================================
-- MAIN GAME LOOP
-- ==========================================


function TIC()
    cls(BLACK)
end
-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304000000000
-- </SFX>

-- <TRACKS>
-- 000:100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </TRACKS>

-- <PALETTE>
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

