-- title:   Mouse Test
-- author:  Adam Fuller <the.adam.fuller@gmail.com>
-- desc:    short description
-- license: MIT License (change this to your license of choice)
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

-- Character dimensions (these scale linearly)
local FIXED_CHAR_WIDTH      = 6
local FIXED_CHAR_HEIGHT     = 6

-- Screen dimensions
local EDGE_X_LEFT           = 0
local EDGE_X_RIGHT          = 240
local EDGE_Y_TOP            = 0
local EDGE_Y_BOTTOM         = 136
local X_PADDING             = FIXED_CHAR_WIDTH
local Y_PADDING             = FIXED_CHAR_HEIGHT


-- ==========================================
-- MAIN GAME LOOP
-- ==========================================

local barx, bary = 10, 10

function TIC()
    -- INPUT
    local x, y, left, middle, right, scrollx, scrolly = mouse()

    -- UPDATE
    barx = barx + scrollx
    bary = bary + scrolly
    if barx < 1 then barx = 1 end
    if bary < 1 then bary = 1 end

    -- DRAW
    cls(BLACK)
    print('Move Mouse:', 10, 10, YELLOW)
    print('Position ' .. string.format('x=%03i y=%03i', x, y), 100, 10, WHITE)

    print('Press Buttons:', 10, 20, YELLOW)
    print('Left ' .. tostring(left), 100, 20, WHITE)
    print('Middle ' .. tostring(middle), 100, 30, WHITE)
    print('Right ' .. tostring(right), 100, 40, WHITE)

    print('Scroll White:', 10, 80, YELLOW)
    print('Scroll X', 100, 80, WHITE)
    print('Scroll Y', 160, 80, WHITE)
    rect(100, 136 / 2 - barx, 8, barx, GREEN_MED)
    rect(160, 136 / 2 - bary, 8, bary, GREEN_MED)
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
