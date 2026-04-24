--[[ CONSTANTS ]] --

-- Colors
BLACK      = 0
PURPLE     = 1
RED        = 2
ORANGE     = 3
YELLOW     = 4
GREEN_LITE = 5
GREEN_MED  = 6
GREEN_DARK = 7
BLUE_DARK  = 8
BLUE_MED   = 9
BLUE_LITE  = 10
CYAN       = 11
WHITE      = 12
GRAY_LITE  = 13
GRAY_MED   = 14
GRAY_DARK  = 15

-- Controls
P1_UP    = 0
P1_DOWN  = 1
P1_LEFT  = 2
P1_RIGHT = 3
P1_A     = 4
P2_UP    = 8
P2_DOWN  = 9
P2_LEFT  = 10
P2_RIGHT = 11

-- Screen Edges
BOUNDARY_WIDTH = 2
HUD_WIDTH      = 12
EDGE_X_LEFT    = 0   + HUD_WIDTH
EDGE_X_RIGHT   = 239 - HUD_WIDTH
EDGE_Y_TOP     = 0
EDGE_Y_BOTTOM  = 135

-- Moving Parts Contraints
PADDLE_WIDTH     = 4
PADDLE_HEIGHT    = 24
BALL_RADIUS      = 3
GAME_SPEED       = 1
SPEED_BOOSTER    = 0.25
RETURN_THRESHOLD = 5

-- Game Configuration
CURRENT_SERVE_PLAYER = 1
WINNING_SCORE        = 1
SHOW_NUM_RETURNS     = true
ENABLE_SPEED_BOOST   = true


GAME_MODES        = {'start', 'menu', 'game', 'over'}
CURRENT_GAME_MODE = 'start'


--[[ TODO LIST ]]--

-- TODO: Add a copyright to the bottom of the start screen.
-- TODO: How do I automatically change the keymapping upon loading?

-- TODO: Add a way to pause the game.
-- TODO: Do power ups!
-- TODO: Should we be able to move the paddles along the x-axis?
-- TODO: Win by 2?

