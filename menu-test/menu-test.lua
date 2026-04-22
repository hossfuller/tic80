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


-- -------------------------------------------------------------------------- --
--[[ NOW THE CODE-CODE ]]--

t=0
x=96
y=24

function TIC()

	if btn(0) then y=y-1 end
	if btn(1) then y=y+1 end
	if btn(2) then x=x-1 end
	if btn(3) then x=x+1 end

	cls(13)
	spr(1+t%60//30*2,x,y,14,3,0,0,2,2)
	print("HELLO WORLD!",84,84)
	t=t+1
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

