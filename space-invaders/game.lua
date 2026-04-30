--
-- Bundle file
-- Code changes will be overwritten
--

-- title:   Space Invaders
-- author:  Adam Fuller <the.adam.fuller@gmail.com>
-- version: 0.1
-- script:  lua


-- ==========================================
-- INCLUDES
-- ==========================================

-- [TQ-Bundler: src.constants]

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
local BTN_P1_UP    = 0
local BTN_P1_DOWN  = 1
local BTN_P1_LEFT  = 2
local BTN_P1_RIGHT = 3
local BTN_P1_A     = 4  -- Primary action / Select
local BTN_P1_B     = 5  -- Secondary action / Back / Pause
local BTN_P1_X     = 6
local BTN_P1_Y     = 7
local BTN_P2_UP    = 8
local BTN_P2_DOWN  = 9
local BTN_P2_LEFT  = 10
local BTN_P2_RIGHT = 11
local BTN_P2_A     = 12
local BTN_P2_B     = 13
local BTN_P2_X     = 14
local BTN_P2_Y     = 15

-- Screen dimensions
local EDGE_X_LEFT    = 0
local EDGE_X_RIGHT   = 240
local EDGE_Y_TOP     = 0
local EDGE_Y_BOTTOM  = 136

-- [/TQ-Bundler: src.constants]

-- ==========================================
-- CONSTANTS
-- ==========================================




function BOOT()
end

function INIT()
end

INIT()

--[[ GAME LOOP ]]--

function TIC()
    cls(BLACK)

end

-- <TILES>
-- 001:eccccccccc888888caaaaaaaca888888cacccccccacc0ccccacc0ccccacc0ccc
-- 002:ccccceee8888cceeaaaa0cee888a0ceeccca0ccc0cca0c0c0cca0c0c0cca0c0c
-- 003:eccccccccc888888caaaaaaaca888888cacccccccacccccccacc0ccccacc0ccc
-- 004:ccccceee8888cceeaaaa0cee888a0ceeccca0cccccca0c0c0cca0c0c0cca0c0c
-- 017:cacccccccaaaaaaacaaacaaacaaaaccccaaaaaaac8888888cc000cccecccccec
-- 018:ccca00ccaaaa0ccecaaa0ceeaaaa0ceeaaaa0cee8888ccee000cceeecccceeee
-- 019:cacccccccaaaaaaacaaacaaacaaaaccccaaaaaaac8888888cc000cccecccccec
-- 020:ccca00ccaaaa0ccecaaa0ceeaaaa0ceeaaaa0cee8888ccee000cceeecccceeee
-- </TILES>

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

