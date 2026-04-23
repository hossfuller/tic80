-- title:   Menu Test
-- author:  Adam Fuller <the.adam.fuller@gmail.com>
-- desc:    Scratch code to figure out how to do title and menu screens.
-- version: 0.1
-- script:  lua

-- -------------------------------------------------------------------------- --
--[[ WHAT WE'RE TRYING TO ACHIEVE ]] --
--
-- [ ] Make a title screen with "Start Game" and "Menu" options.
-- [ ] Reset keymappings on boot, and then configuring them automagically.
-- [ ] Offer a menu screen that allows the constants below to be changed.
-- [ ] Launch into the game from the "Start Game" start screen option.


--[[ CONSTANTS ]] --

-- Colors
BLACK              = 0
PURPLE             = 1
RED                = 2
ORANGE             = 3
YELLOW             = 4
GREEN_LITE         = 5
GREEN_MED          = 6
GREEN_DARK         = 7
BLUE_DARK          = 8
BLUE_MED           = 9
BLUE_LITE          = 10
CYAN               = 11
WHITE              = 12
GRAY_LITE          = 13
GRAY_MED           = 14
GRAY_DARK          = 15

-- Controls
P1_UP              = 0
P1_DOWN            = 1
P1_LEFT            = 2
P1_RIGHT           = 3
P2_UP              = 8
P2_DOWN            = 9
P2_LEFT            = 10
P2_RIGHT           = 11

-- Screen Edges
BOUNDARY_WIDTH     = 2
HUD_WIDTH          = 12
EDGE_X_LEFT        = 0 + HUD_WIDTH
EDGE_X_RIGHT       = 239 - HUD_WIDTH
EDGE_Y_TOP         = 0
EDGE_Y_BOTTOM      = 135

-- Moving Parts Contraints
PADDLE_WIDTH       = 4
PADDLE_HEIGHT      = 24
BALL_RADIUS        = 3
GAME_SPEED         = 1
SPEED_BOOSTER      = 0.25
RETURN_THRESHOLD   = 5

-- Game Configuration
WINNING_SCORE      = 10
SHOW_NUM_RETURNS   = true
ENABLE_SPEED_BOOST = true

GAME_MODES = {'start', 'menu', 'game'}

-- -------------------------------------------------------------------------- --
--[[ NOW THE CODE-CODE ]]--

CURRENT_GAME_MODE = 'start'

function BOOT()
end

function INIT()
end

function INPUT(mode)
    if mode == 'start' then
    elseif mode == 'menu' then
    elseif mode == 'game' then
    end
end

function UPDATE(mode)
    if mode == 'start' then
    elseif mode == 'menu' then
    elseif mode == 'game' then
    end
end

function DRAW(mode)
    if mode == 'start' then
        print_centered_text("SPONG", math.floor(EDGE_Y_BOTTOM * 0.25), ORANGE, true, true, 4)

    elseif mode == 'menu' then
    elseif mode == 'game' then
    end
end

INIT()

function TIC()
    cls(0)

    INPUT(CURRENT_GAME_MODE)

    UPDATE(CURRENT_GAME_MODE)

    DRAW(CURRENT_GAME_MODE)

end

function print_centered_text(message, height, color, shadow, fixed, scale)
    if height == nil then
        height = math.floor(EDGE_Y_BOTTOM / 2)
    end
    if color == nil then
        color = WHITE
    end
    if shadow == nil then
        shadow = false
    end
    if fixed == nil then
        fixed = true
    end
    if scale == nil then
        scale = 1
    end
    local message_width = print(message, 0, -40, color, fixed, scale)
    local x_pos = ((EDGE_X_RIGHT - message_width) / 2) + 2
    if shadow then
        print(message, x_pos + 1, height + 1, color + 1, fixed, scale)
    end
    print(message, x_pos, height, color, fixed, scale)
end

-- <SPRITES>
-- 001:00ffffff0feeeeeefeeefffefeef222ffef22222fef22222fef22222feef222f
-- 002:f0000000ef000000eef00000eef00000fef00000fef00000fef00000eef00000
-- 003:00ffffff0feeeeeefeeefffefeefdddffefdddddfefdddddfefdddddfeefdddf
-- 004:f0000000ef000000eef00000eef00000fef00000fef00000fef00000eef00000
-- 005:00ffffff0feeeeeefeeefffefeefdddffefdddddfefdddddfefdddddfeefdddf
-- 006:f0000000ef000000eef00000eef00000fef00000fef00000fef00000eef00000
-- 007:000d000000ddd0000ddddd00ddddddd000000000000000000000000000000000
-- 017:feeefffefeeeeeeefeeefffefeefdddffefdddddfefdddddfefdddddfeefdddf
-- 018:eef00000eef00000eef00000eef00000fef00000fef00000fef00000eef00000
-- 019:feeefffefeeeeeeefeeefffefeef444ffef44444fef44444fef44444feef444f
-- 020:eef00000eef00000eef00000eef00000fef00000fef00000fef00000eef00000
-- 021:feeefffefeeeeeeefeeefffefeefdddffefdddddfefdddddfefdddddfeefdddf
-- 022:eef00000eef00000eef00000eef00000fef00000fef00000fef00000eef00000
-- 033:feeefffefeeeeeeefeeefffefeefdddffefdddddfefdddddfefdddddfeefdddf
-- 034:eef00000eef00000eef00000eef00000fef00000fef00000fef00000eef00000
-- 035:feeefffefeeeeeeefeeefffefeefdddffefdddddfefdddddfefdddddfeefdddf
-- 036:eef00000eef00000eef00000eef00000fef00000fef00000fef00000eef00000
-- 037:feeefffefeeeeeeefeeefffefeef666ffef66666fef66666fef66666feef666f
-- 038:eef00000eef00000eef00000eef00000fef00000fef00000fef00000eef00000
-- 049:feeefffe0feeeeee00ffffff0000000000000000000000000000000000000000
-- 050:eef00000ef000000f00000000000000000000000000000000000000000000000
-- 051:feeefffe0feeeeee00ffffff0000000000000000000000000000000000000000
-- 052:eef00000ef000000f00000000000000000000000000000000000000000000000
-- 053:feeefffe0feeeeee00ffffff0000000000000000000000000000000000000000
-- 054:eef00000ef000000f00000000000000000000000000000000000000000000000
-- </SPRITES>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:00000000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000404000000000
-- 001:00000000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f00020a000000000
-- 002:04f004c0049004600430f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400100000000000
-- 003:000000000000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f00070b000000000
-- 004:000000000000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000705000000000
-- 005:00f00030003000f0f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000302000000000
-- </SFX>

-- <TRACKS>
-- 000:100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </TRACKS>

-- <PALETTE>
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>
