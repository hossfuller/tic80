--
-- Bundle file
-- Code changes will be overwritten
--

-- title:   SPong (Son of Pong)
-- author:  Hoss Fuller
-- version: 0.3
-- script:  lua


--[[ INCLUDES ]]--
-- [TQ-Bundler: src.constants]

--[[ CONSTANTS ]]--

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
P2_A     = 12

-- Screen Edges
BOUNDARY_WIDTH = 2
EDGE_X_LEFT    = 0
EDGE_X_RIGHT   = 239
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
WINNING_SCORE        = 11
SHOW_NUM_RETURNS     = true
ENABLE_SPEED_BOOST   = true
WIN_BY_TWO           = true

-- State Machine Parts
local STATE = {
    START    = "START",
    OPTIONS  = "OPTIONS",
    READY    = "READY",
    PLAY     = "PLAY",
    GAMEOVER = "GAMEOVER",
}

local current_state = STATE.START
local winner_paddle = nil

local function set_state(s)
    current_state = s
end

--[[ TODO LIST ]]--

-- TODO: Add a way to pause the game.
-- TODO: Do power ups!



-- [/TQ-Bundler: src.constants]

-- [TQ-Bundler: src.helpers]

--[[ HELPERS ]]--

local function begin_round()
    -- after a point, nobody is ready
    paddle1:reset()
    paddle2:reset()
    ball:reset()
    winner_paddle = nil
    set_state(STATE.READY)
end

local function award_point_if_ball_out()
    if ball:isInPlay() then return false end

    if (ball.x + ball.radius) < EDGE_X_LEFT then
        paddle2:incrementScore()
    elseif ball.x >= EDGE_X_RIGHT then
        paddle1:incrementScore()
    else
        -- ball is "out of play" for some other reason; don't score
        return false
    end

    return true
end

local function check_for_winner()
    local score_one  = paddle1:getScore()
    local score_two  = paddle2:getScore()
    local max_score  = math.max(score_one, score_two)
    local diff_score = math.abs(score_one - score_two)

    if WIN_BY_TWO then
        if max_score >= WINNING_SCORE and diff_score >= 2 then
            return (score_one > score_two) and paddle1 or paddle2
        end
    else
        if score_one >= WINNING_SCORE then return paddle1 end
        if score_two >= WINNING_SCORE then return paddle2 end
    end

    return nil
end

local function update_paddle_colors()
    local p1 = paddle1:isInPlay()
    local p2 = paddle2:isInPlay()

    if p1 == false and p2 == false then
        paddle1:changeColor(RED)
        paddle2:changeColor(RED)
    elseif p1 == true and p2 == false then
        paddle1:changeColor(YELLOW)
    elseif p1 == false and p2 == true then
        paddle2:changeColor(YELLOW)
    else
        paddle1:changeColor(WHITE)
        paddle2:changeColor(WHITE)
    end

end


-- [/TQ-Bundler: src.helpers]

-- [TQ-Bundler: src.classes.SpongObj]

--[[ Base Class: SpongObj ]]--

SpongObj = {}
SpongObj.__index = SpongObj

function SpongObj:new(params)
    params = params or {}
    local obj = {
        x       = params.x or 0,
        y       = params.y or 0,
        vx      = params.vx or GAME_SPEED,
        vy      = params.vy or GAME_SPEED,
        width   = params.width or PADDLE_WIDTH,
        height  = params.height or PADDLE_HEIGHT,
        color   = params.color or WHITE,
        play_on = false,

        enable_speed_up = params.enable_speed_up or ENABLE_SPEED_BOOST,
        speed_booster   = params.speed_booster or SPEED_BOOSTER,
    }
    setmetatable(obj, self)

    return obj
end

function SpongObj:draw()
    rect(self.x, self.y, self.width, self.height, self.color)
end

function SpongObj:changeColor(color)
    self.color = color
end

function SpongObj:getCollisionBox()
    return {
        top    = self.y,
        bottom = self.y + self.height,
        left   = self.x,
        right  = self.x + self.width
    }
end


function SpongObj:speedUp()
    if self.enable_speed_up then
        if self.vx < 0 then
            self.vx = self.vx - self.speed_booster
        else
            self.vx = self.vx + self.speed_booster
        end
        if self.vy < 0 then
            self.vy = self.vy - self.speed_booster
        else
            self.vy = self.vy + self.speed_booster
        end
    end
end

function SpongObj:reset(x, y)
    print("This method hasn't been implemented", EDGE_X_LEFT, EDGE_Y_BOTTOM / 2, RED)
end

function SpongObj:inPlay()
    self.play_on = true
end

function SpongObj:outOfPlay()
    self.play_on = false
end

function SpongObj:isInPlay()
    return self.play_on
end


-- [/TQ-Bundler: src.classes.SpongObj]

-- [TQ-Bundler: src.classes.SpaddleObj]

--[[ Base Class: SpaddleObj ]]--

SpaddleObj = setmetatable({}, { __index = SpongObj })
SpaddleObj.__index = SpaddleObj

function SpaddleObj:new(params)
    params = params or {}
    local obj = SpongObj.new(self, params)
    setmetatable(obj, self)
    -- SpaddleObj-specific properties
    obj.player = params.player or 1

    -- controls
    obj.upButton    = P1_UP
    obj.downButton  = P1_DOWN
    obj.leftButton  = P1_LEFT
    obj.rightButton = P1_RIGHT
    obj.aButton     = P1_A
    if obj.player == 2 then
        obj.upButton    = P2_UP
        obj.downButton  = P2_DOWN
        obj.leftButton  = P2_LEFT
        obj.rightButton = P2_RIGHT
        obj.aButton     = P2_A
    end

    obj.score   = 0
    obj.returns = 0

    return obj
end

function SpaddleObj:input()
    if btn(self.upButton) then
        self.y = math.floor(self.y - self.vy)
    end
    if btn(self.downButton) then
        self.y = math.ceil(self.y + self.vy)
    end
    -- Pressing left indicates that we're ready to play!
    if btn(self.leftButton) and self:isInPlay() == false then
        self:inPlay()
    end
end

function SpaddleObj:update()
    if self.x < EDGE_X_LEFT then
        self.x = EDGE_X_LEFT
    elseif self.x > (EDGE_X_RIGHT - self.width) then
        self.x = math.floor(EDGE_X_RIGHT - self.width)
    end
    if self.y < (EDGE_Y_TOP + 1) then
        self.y = EDGE_Y_TOP + 1
    elseif self.y > (EDGE_Y_BOTTOM - self.height) then
        self.y = math.floor(EDGE_Y_BOTTOM - self.height)
    end
end

function SpaddleObj:reset(x, y)
    self.x = x or EDGE_X_LEFT
    self.y = y or math.floor((EDGE_Y_BOTTOM - self.height) / 2)
    if self.player == 2 then
        self.x = x or EDGE_X_RIGHT - self.width
    end

    -- Reset speeds, too!
    self.vx = GAME_SPEED
    self.vy = GAME_SPEED

    self:resetReturns()
    self:outOfPlay()
end

function SpaddleObj:getReturns()
    return self.returns
end

function SpaddleObj:incrementReturns()
    self.returns = self.returns + 1
end

function SpaddleObj:resetReturns()
    self.returns = 0
end

function SpaddleObj:getScore()
    return self.score
end

function SpaddleObj:incrementScore()
    self.score = self.score + 1
    CURRENT_SERVE_PLAYER = self.player
end

function SpaddleObj:resetScore()
    self.score = 0
end


-- [/TQ-Bundler: src.classes.SpaddleObj]

-- [TQ-Bundler: src.classes.SballObj]

--[[ Base Class: SballObj ]]--

SballObj = setmetatable({}, { __index = SpongObj })
SballObj.__index = SballObj

function SballObj:new(params)
    params = params or {}
    local obj = SpongObj.new(self, params)
    setmetatable(obj, self)

    -- SballObj-specific properties
    obj.radius            = params.radius or BALL_RADIUS
    obj.touching_paddle   = false
    obj.serve_direction_x = 1 -- serve the ball right
    obj.serve_direction_y = 1 -- serve the ball down

    return obj
end

function SballObj:draw()
    circ(self.x, self.y, self.radius, self.color)

    -- Draw the serve direction if the ball is out of play.
    if self:isInPlay() == false then
        local serve_dir_arrow_spr_id = 263
        local serve_dir_arrow_x = self.x - self.radius - 1
        local serve_dir_arrow_y = self.y + 1
        local serve_dir_arrow_flip = 0
        local serve_dir_arrow_rotate = 0

        -- Use the intended serve direction (not vx/vy) as the source of truth.
        local dx = self.serve_direction_x
        local dy = self.serve_direction_y

        -- Sprite 263 is the serve direction arrow, and it's drawn to be
        -- "right+up" by default.
        -- For "down" rotate 180 degrees (rotate=2).
        -- For "left" rely on the art/positioning being symmetric here.
        if dy < 0 then
            -- up
            serve_dir_arrow_x = serve_dir_arrow_x + 1
            serve_dir_arrow_y = serve_dir_arrow_y - 2 * self.radius - 3
            serve_dir_arrow_rotate = 0
        else
            -- down
            serve_dir_arrow_rotate = 2
        end

        spr(
            serve_dir_arrow_spr_id,
            serve_dir_arrow_x,
            serve_dir_arrow_y,
            0, -- colorkey
            1, -- scale
            serve_dir_arrow_flip,
            serve_dir_arrow_rotate,
            1, 1 -- width and height
        )
    end
end

function SballObj:getCollisionBox()
    return {
        top    = self.y - self.radius,
        bottom = self.y + self.radius,
        left   = self.x - self.radius,
        right  = self.x + self.radius,
    }
end

function SballObj:input()
    if (
        (CURRENT_SERVE_PLAYER == 1 and btnp(P1_RIGHT))
        or (CURRENT_SERVE_PLAYER == 2 and btnp(P2_RIGHT))
    ) then
        if self.serve_direction_y > 0 then
            self.serve_direction_y = -1 -- serve the ball up
            sfx(4)
        else
            self.serve_direction_y = 1 -- serve the ball down
            sfx(3)
        end
    end
end

function SballObj:preServe(paddle)
    local serving_x = EDGE_X_LEFT + PADDLE_WIDTH + self.radius + 2
    local serving_y = paddle.y + math.floor(paddle.height / 2)

    if paddle.player == 2 then
        serving_x = EDGE_X_RIGHT - PADDLE_WIDTH - self.radius - 3
    end

    self:reset(serving_x, serving_y)
end

function SballObj:reset(x, y)
    self.x = x or EDGE_X_LEFT + PADDLE_WIDTH + self.radius + 2
    self.y = y or math.floor(EDGE_Y_BOTTOM / 2)
    if CURRENT_SERVE_PLAYER == 2 then
        self.x = x or EDGE_X_RIGHT - PADDLE_WIDTH - self.radius - 3
    end

    if CURRENT_SERVE_PLAYER == 1 then
        self.serve_direction_x = 1
    else
        self.serve_direction_x = -1
    end

    self.vx = self.serve_direction_x * GAME_SPEED
    self.vy = self.serve_direction_y * GAME_SPEED

    self:outOfPlay()
end

function SballObj:update()
    if self:isInPlay() then
        self.x = self.x + self.vx
        self.y = self.y + self.vy
    end

    if (
        ((self.x + (3 * self.radius)) < EDGE_X_LEFT)
        or ((self.x - (3 * self.radius)) > EDGE_X_RIGHT)
    ) then
        sfx(2)
        self:outOfPlay()
    end

    if self.y < (EDGE_Y_TOP + self.radius + 1) then
        sfx(0)
        self.y  = EDGE_Y_TOP + self.radius + 1
        self.vy = -self.vy
    elseif self.y > (EDGE_Y_BOTTOM - (self.radius)) then
        sfx(0)
        self.y  = math.floor(EDGE_Y_BOTTOM - self.radius)
        self.vy = -self.vy
    end
end

function SballObj:collision(paddle)
    local ball_box   = self:getCollisionBox()
    local paddle_box = paddle:getCollisionBox()

    local is_colliding = ball_box['left'] < paddle_box['right']
        and ball_box['right'] > paddle_box['left']
        and ball_box['top'] < paddle_box['bottom']
        and ball_box['bottom'] > paddle_box['top']

    if is_colliding then
        if self:isTouchingPaddle() == false then
            sfx(1)
            self.vx = -self.vx

            -- Push the ball out of the paddle to prevent re-collision
            if paddle.player == 1 then
                self.x = paddle_box['right'] + self.radius + 1
            else
                self.x = paddle_box['left'] - self.radius - 1
            end

            self:touchingPaddle()
            paddle:incrementReturns()

            -- Speed up if that's where we're at.
            if (paddle:getReturns() > 0) and (paddle:getReturns() % RETURN_THRESHOLD) == 0 then
                ball:speedUp()
                paddle:speedUp()
            end
        end
    else
        self:clearOfPaddle()
    end
end

function SballObj:clearOfPaddle()
    self.touching_paddle = false
end

function SballObj:touchingPaddle()
    self.touching_paddle = true
end

function SballObj:isTouchingPaddle()
    return self.touching_paddle
end

-- [/TQ-Bundler: src.classes.SballObj]

-- [TQ-Bundler: src.state_machine]

--[[ STATE MACHINE ]]--

local function state_ready_update()
    -- allow moving paddles and toggling serve direction
    paddle1:input()
    paddle2:input()
    ball:input()

    update_paddle_colors()

    paddle1:update()
    paddle2:update()

    -- keep ball attached to serving paddle
    if CURRENT_SERVE_PLAYER == 1 then
        ball:preServe(paddle1)
    else
        ball:preServe(paddle2)
    end

    -- transition when both are ready
    if paddle1:isInPlay() and paddle2:isInPlay() then
        sfx(5)
        ball:inPlay()
        set_state(STATE.PLAY)
    end
end

local function state_ready_draw()
    DRAW()

    local ready_msg_height = math.floor(EDGE_Y_BOTTOM / 2) - 20
    print_centered_text("READY?", ready_msg_height, ORANGE, true, true, 3)
    print_centered_text("PRESS LEFT TO BEGIN", ready_msg_height + 30, BLUE_LITE, false, false, 1)
    print_centered_text("PRESS RIGHT TO CHANGE", ready_msg_height + 40, BLUE_LITE, false, false, 1)
    print_centered_text("SERVE DIRECTION", ready_msg_height + 47, BLUE_LITE, false, false, 1)
end

local function state_play_update()
    INPUT()
    UPDATE()

    -- scoring / round end
    if award_point_if_ball_out() then
        local w = check_for_winner()
        if w then
            winner_paddle = w
            set_state(STATE.GAMEOVER)
        else
            begin_round()
        end
    end
end

local function state_play_draw()
    DRAW()
end

local function state_gameover_update()
    -- no INPUT/UPDATE; only wait for A
    if winner_paddle and btnp(winner_paddle.aButton) then
        set_state(STATE.START)
        INIT()
    end
end

local function state_gameover_draw()
    DRAW()

    local winning_message = string.format("PLAYER %d WINS!", winner_paddle.player)
    print_centered_text(winning_message, EDGE_Y_BOTTOM / 2, ORANGE, true, false, 2)
    print_centered_text("PRESS A TO RETURN", EDGE_Y_BOTTOM / 2 + 20, BLUE_LITE)
    print_centered_text("TO START SCREEN", EDGE_Y_BOTTOM / 2 + 27, BLUE_LITE)
end


-- [/TQ-Bundler: src.state_machine]

-- [TQ-Bundler: src.screen_start]

--[[ GAME START SCREEN FUNCTIONS ]]--


local start_title_y    = math.floor(EDGE_Y_BOTTOM * 0.25)
local start_subtitle_y = start_title_y + 35

local start_menu_option_x = math.floor(EDGE_X_RIGHT * 0.41)
local start_menu_option_y = start_subtitle_y + 20
local start_menu_space_y  = 10

local start_menu_options = {
    "New Game",
    "Options"
}
local start_menu_options_num = #start_menu_options

local start_menu_ball = {
    x = start_menu_option_x - 7,
    y = start_menu_option_y + 2,
    r = 2,
    cur = 1,
    sel = 0,
}

local function state_start_update()
    start_screen() -- your start screen already does input/update/draw
    -- your start_screen_update() currently sets CURRENT_GAME_MODE.
    -- Change that to:
    --   set_state(STATE.READY) for New Game
    --   set_state(STATE.OPTIONS) for Options
end

function start_screen()
    start_screen_input()
    start_screen_update()
    start_screen_draw()
end

function start_screen_input()
    if btnp(P1_UP) or btnp(P1_DOWN) then
        if start_menu_ball.cur == start_menu_options_num then
            start_menu_ball.cur = 1
            start_menu_ball.y   = start_menu_option_y + 2
        else
            start_menu_ball.cur = start_menu_ball.cur + 1
            start_menu_ball.y = start_menu_ball.y + start_menu_space_y
        end
    end
    if btnp(P1_LEFT) or btnp(P1_RIGHT) then
        start_menu_ball.sel = start_menu_ball.cur
    end
end

function start_screen_update()
    if start_menu_ball.sel == 1 then
        -- New Game
        INIT()
        begin_round() -- goes to READY
    elseif start_menu_ball.sel == 2 then
        set_state(STATE.OPTIONS)
    end
    start_menu_ball.sel = 0
end

function start_screen_draw()
    print_centered_text("SPONG", start_title_y, ORANGE, true, true, 6)
    print_centered_text("Son of PONG", start_subtitle_y, BLUE_DARK, true, true, 2)

    local current_start_menu_option_y = start_menu_option_y
    for index, start_option_text in ipairs(start_menu_options) do
        if index == start_menu_ball.cur then
            circ(start_menu_ball.x, start_menu_ball.y, start_menu_ball.r, WHITE)
        end
        print(start_option_text, start_menu_option_x, current_start_menu_option_y, GRAY_LITE)
        current_start_menu_option_y = current_start_menu_option_y + start_menu_space_y
    end
end


-- [/TQ-Bundler: src.screen_start]

-- [TQ-Bundler: src.screen_menu]

--[[ GAME MENU SCREEN FUNCTIONS ]]--


local menu_title_y       = 0
local menu_menu_option_x = 20
local menu_menu_option_y = menu_title_y + 20
local menu_menu_space_y  = 8

local menu_menu_options = {
    "< Back to Main Menu",
    "Player who serves first",
    "Winning Score",
    "Win by at least 2 points",
    "Starting game speed",
    "Enable speed boost",
    "Speed boost multiplier",
    "Returns before speed boost",
    "Display number of returns",
}
local menu_menu_options_num = #menu_menu_options

local menu_menu_ball = {
    x = menu_menu_option_x - 7,
    y = menu_menu_option_y + 2,
    r = 2,
    cur = 1,
    sel = 0,
    inc = false,
    dec = false,
}

local function state_options_update()
    menu_screen() -- your menu screen already does input/update/draw
    -- In menu_screen_update(), where you currently do:
    --   CURRENT_GAME_MODE = 'start'
    -- change it to:
    --   set_state(STATE.START)
end

function menu_screen()
    menu_screen_input()
    menu_screen_update()
    menu_screen_draw()
end

function menu_screen_input()
    if btnp(P1_UP) then
        if menu_menu_ball.cur == 1 then
            menu_menu_ball.cur = menu_menu_options_num
        else
            menu_menu_ball.cur = menu_menu_ball.cur - 1
        end
        menu_menu_ball.y = (menu_menu_option_y + 2) + ((menu_menu_ball.cur - 1) * menu_menu_space_y)
    end
    if btnp(P1_DOWN) then
        if menu_menu_ball.cur == menu_menu_options_num then
            menu_menu_ball.cur = 1
        else
            menu_menu_ball.cur = menu_menu_ball.cur + 1
        end
        menu_menu_ball.y = (menu_menu_option_y + 2) + ((menu_menu_ball.cur - 1) * menu_menu_space_y)
    end
    if btnp(P1_LEFT) then
        menu_menu_ball.sel = menu_menu_ball.cur
        menu_menu_ball.inc = false
        menu_menu_ball.dec = true
    end
    if btnp(P1_RIGHT) then
        menu_menu_ball.sel = menu_menu_ball.cur
        menu_menu_ball.inc = true
        menu_menu_ball.dec = false
    end
end

function menu_screen_update()
    local winning_score_limit    = 100
    local game_speed_limit       = 10
    local return_threshold_limit = 100

    local multiplier = 1
    if menu_menu_ball.dec == true and menu_menu_ball.inc == false then
        multiplier = -1
    end

    if menu_menu_ball.sel == 1 then
        -- < Back to Main Menu
        set_state(STATE.START)
    elseif menu_menu_ball.sel == 2 then
        CURRENT_SERVE_PLAYER = 1
        if multiplier > 0 then
            CURRENT_SERVE_PLAYER = 2
        end
    elseif menu_menu_ball.sel == 3 then
        WINNING_SCORE = WINNING_SCORE + (1 * multiplier)
        if WIN_BY_TWO == true and WINNING_SCORE < 2 then
            WINNING_SCORE = 2
        elseif WIN_BY_TWO == false and WINNING_SCORE < 1 then
            WINNING_SCORE = 1
        elseif WINNING_SCORE > winning_score_limit then
            WINNING_SCORE = winning_score_limit
        end
    elseif menu_menu_ball.sel == 4 then
        if WIN_BY_TWO == true then
            WIN_BY_TWO = false
        else
            WIN_BY_TWO = true
            if WINNING_SCORE < 2 then
                WINNING_SCORE = 2
            end
        end
    elseif menu_menu_ball.sel == 5 then
        GAME_SPEED = GAME_SPEED + (1 * multiplier)
        if GAME_SPEED > game_speed_limit then
            GAME_SPEED = game_speed_limit
        elseif GAME_SPEED < 1 then
            GAME_SPEED = 1
        end
    elseif menu_menu_ball.sel == 6 then
        if ENABLE_SPEED_BOOST == true then
            ENABLE_SPEED_BOOST = false
        else
            ENABLE_SPEED_BOOST = true
        end
    elseif menu_menu_ball.sel == 7 then
        SPEED_BOOSTER = SPEED_BOOSTER + (0.05 * multiplier)
        if SPEED_BOOSTER > 1.01 then
            SPEED_BOOSTER = 1.0
        elseif SPEED_BOOSTER < 0.05 then
            SPEED_BOOSTER = 0.05
        end
    elseif menu_menu_ball.sel == 8 then
        RETURN_THRESHOLD = RETURN_THRESHOLD + (1 * multiplier)
        if RETURN_THRESHOLD > return_threshold_limit then
            RETURN_THRESHOLD = return_threshold_limit
        elseif RETURN_THRESHOLD < 1 then
            RETURN_THRESHOLD = 1
        end
    elseif menu_menu_ball.sel == 9 then
        if SHOW_NUM_RETURNS == true then
            SHOW_NUM_RETURNS = false
        else
            SHOW_NUM_RETURNS = true
        end
    end

    menu_menu_ball.sel = 0
    menu_menu_ball.inc = false
    menu_menu_ball.dec = false
end

function menu_screen_draw()
    print_centered_text("OPTIONS", menu_title_y, ORANGE, true, true, 2)

    -- Get longest option length first.
    local longest_option_width = 0
    for index, menu_option_text in ipairs(menu_menu_options) do
        longest_option_width = print(menu_option_text, 0, -10)
    end
    longest_option_width = longest_option_width + 30

    local current_menu_menu_option_y = menu_menu_option_y
    for index, menu_option_text in ipairs(menu_menu_options) do
        if index == menu_menu_ball.cur then
            circ(menu_menu_ball.x, menu_menu_ball.y, menu_menu_ball.r, WHITE)
        end
        print(menu_option_text, menu_menu_option_x, current_menu_menu_option_y, GRAY_LITE)
        print(
            menu_screen_get_option_value(index),
            longest_option_width + (2 * menu_menu_space_y),
            current_menu_menu_option_y,
            GRAY_LITE,
            true
        )
        current_menu_menu_option_y = current_menu_menu_option_y + menu_menu_space_y
    end
end

function menu_screen_get_option_value(index)
    local return_string = " "
    local true_string   = string.format("%5s", "TRUE")
    local false_string  = string.format("%5s", "FALSE")

    if index == 2 then
        return_string = string.format("%5d", tostring(CURRENT_SERVE_PLAYER))
    elseif index == 3 then
        return_string = string.format("%5d", tostring(WINNING_SCORE))
    elseif index == 4 then
        if WIN_BY_TWO == true then
            return_string = true_string
        else
            return_string = false_string
        end
    elseif index == 5 then
        return_string = string.format("%5d", tostring(GAME_SPEED))
    elseif index == 6 then
        if ENABLE_SPEED_BOOST == true then
            return_string = true_string
        else
            return_string = false_string
        end
    elseif index == 7 then
        return_string = string.format(" %0.2f", tostring(SPEED_BOOSTER))
    elseif index == 8 then
        return_string = string.format("%5d", tostring(RETURN_THRESHOLD))
    elseif index == 9 then
        if SHOW_NUM_RETURNS == true then
            return_string = true_string
        else
            return_string = false_string
        end
    end
    return return_string
end


-- [/TQ-Bundler: src.screen_menu]

-- [TQ-Bundler: src.input]

--[[ INPUT FUNCTIONS ]]--

function INPUT()
    paddle1:input()
    paddle2:input()
    ball:input()
end -- INPUT()


-- [/TQ-Bundler: src.input]

-- [TQ-Bundler: src.update]

--[[ UPDATE FUNCTIONS ]]--

function UPDATE()
    -- Get the ball moving after being out of play.
    if
        paddle1:isInPlay()
        and paddle2:isInPlay()
        and ball:isInPlay() == false
    then
        sfx(5)
        ball:inPlay()
    end

    -- Keep the paddles on the screen
    paddle1:update()
    paddle2:update()

    -- Check for paddle/ball collision.
    ball:collision(paddle1)
    ball:collision(paddle2)
    ball:update()
end -- UPDATE()


-- [/TQ-Bundler: src.update]

-- [TQ-Bundler: src.draw]

--[[ DRAW FUNCTIONS ]]--

function DRAW()
    drawCourt()

    drawScores()

    if SHOW_NUM_RETURNS then
        drawReturns()
    end

    -- Draw the moving elements.
    paddle1:draw()
    paddle2:draw()
    ball:draw()
end -- DRAW()


function drawCourt()
    -- Net
    for i = EDGE_Y_TOP + 2, EDGE_Y_BOTTOM, 8 do
        rect(EDGE_X_RIGHT / 2, i, BOUNDARY_WIDTH, 4, GREEN_LITE)
    end
    -- Court boundaries
    line(EDGE_X_LEFT, EDGE_Y_TOP, EDGE_X_RIGHT - 1, EDGE_Y_TOP, YELLOW)
    line(EDGE_X_LEFT, EDGE_Y_BOTTOM, EDGE_X_RIGHT - 1, EDGE_Y_BOTTOM, YELLOW)
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

function drawScores()
    local score_scale = 2
    local score_color = ORANGE
    local y_pos       = EDGE_Y_BOTTOM - 15

    local p1_score_str   = string.format("%2d", paddle1:getScore())
    local p1_score_width = print(p1_score_str, 0, -100, WHITE, true, score_scale, false)
    local p1_x_pos       = math.floor((EDGE_X_RIGHT - BOUNDARY_WIDTH) / 2) - p1_score_width - 4
    print(p1_score_str, p1_x_pos + 1, y_pos + 1, score_color + 1, true, score_scale, false)
    print(p1_score_str, p1_x_pos, y_pos, score_color, true, score_scale, false)

    local p2_score_str = string.format("%-2d", paddle2:getScore())
    local p2_x_pos     = math.floor((EDGE_X_RIGHT - BOUNDARY_WIDTH) / 2) + 10
    print(p2_score_str, p2_x_pos + 1, y_pos + 1, score_color + 1, true, score_scale, false)
    print(p2_score_str, p2_x_pos, y_pos, score_color, true, score_scale, false)
end

function drawReturns()
    local return_scale = 2
    local return_color = GRAY_LITE
    local y_pos        = EDGE_Y_TOP + BOUNDARY_WIDTH + 3

    local p1_return_str   = string.format("%2d", paddle1:getReturns())
    local p1_return_width = print(p1_return_str, 0, -100, WHITE, true, return_scale, false)
    local p1_x_pos       = math.floor((EDGE_X_RIGHT - BOUNDARY_WIDTH) / 2) - p1_return_width - 4
    print(p1_return_str, p1_x_pos + 1, y_pos + 1, return_color + 1, true, return_scale, false)
    print(p1_return_str, p1_x_pos, y_pos, return_color, true, return_scale, false)

    local p2_return_str = string.format("%-2d", paddle2:getReturns())
    local p2_x_pos     = math.floor((EDGE_X_RIGHT - BOUNDARY_WIDTH) / 2) + 10
    print(p2_return_str, p2_x_pos + 1, y_pos + 1, return_color + 1, true, return_scale, false)
    print(p2_return_str, p2_x_pos, y_pos, return_color, true, return_scale, false)
end


-- [/TQ-Bundler: src.draw]

--[[ INITIALIZATION ]]--

-- Create objects
paddle1 = SpaddleObj:new({ player = 1 })
paddle2 = SpaddleObj:new({ player = 2 })
ball    = SballObj:new()


function BOOT()
end

function INIT()
    paddle1:reset()
    paddle2:reset()
    ball:reset()

    paddle1:resetScore()
    paddle2:resetScore()
end

INIT()


--[[ GAME LOOP ]]--

function TIC()
    cls(BLACK)

    if current_state == STATE.START then
        --[[ START SCREEN ]] --
        state_start_update()

    elseif current_state == STATE.OPTIONS then
        --[[ USER CAN CONFIGURE CONSTANTS ]] --
        state_options_update()

    elseif current_state == STATE.READY then
        state_ready_update()
        state_ready_draw()

    elseif current_state == STATE.PLAY then
        state_play_update()
        state_play_draw()

    elseif current_state == STATE.GAMEOVER then
        state_gameover_update()
        state_gameover_draw()
    end
end

-- <SPRITES>
-- 001:00ffffff0feeeeeefeeefffefeef222ffef22222fef22222fef22222feef222f
-- 002:f0000000ef000000eef00000eef00000fef00000fef00000fef00000eef00000
-- 003:00ffffff0feeeeeefeeefffefeefdddffefdddddfefdddddfefdddddfeefdddf
-- 004:f0000000ef000000eef00000eef00000fef00000fef00000fef00000eef00000
-- 005:00ffffff0feeeeeefeeefffefeefdddffefdddddfefdddddfefdddddfeefdddf
-- 006:f0000000ef000000eef00000eef00000fef00000fef00000fef00000eef00000
-- 007:000d000000ddd0000ddddd00ddddddd000000000000000000000000000000000
-- 008:00dddd000d0000d0d00dd00dd0d0000dd0d0000dd00dd00d0d0000d000dddd00
-- 017:feeefffefeeeeeeefeeefffefeefdddffefdddddfefdddddfefdddddfeefdddf
-- 018:eef00000eef00000eef00000eef00000fef00000fef00000fef00000eef00000
-- 019:feeefffefeeeeeeefeeefffefeef444ffef44444fef44444fef44444feef444f
-- 020:eef00000eef00000eef00000eef00000fef00000fef00000fef00000eef00000
-- 021:feeefffefeeeeeeefeeefffefeefdddffefdddddfefdddddfefdddddfeefdddf
-- 022:eef00000eef00000eef00000eef00000fef00000fef00000fef00000eef00000
-- 023:00ffff000f2222f0f222222ff222222ff222222ff222222f0f2222f000ffff00
-- 024:00ffff000f6666f0f666666ff666666ff666666ff666666f0f6666f000ffff00
-- 033:feeefffefeeeeeeefeeefffefeefdddffefdddddfefdddddfefdddddfeefdddf
-- 034:eef00000eef00000eef00000eef00000fef00000fef00000fef00000eef00000
-- 035:feeefffefeeeeeeefeeefffefeefdddffefdddddfefdddddfefdddddfeefdddf
-- 036:eef00000eef00000eef00000eef00000fef00000fef00000fef00000eef00000
-- 037:feeefffefeeeeeeefeeefffefeef666ffef66666fef66666fef66666feef666f
-- 038:eef00000eef00000eef00000eef00000fef00000fef00000fef00000eef00000
-- 039:00ffff000f4444f0f444444ff444444ff444444ff444444f0f4444f000ffff00
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

-- <SCREEN>
-- 033:000000000000000000000000000000000000033333333333333333333333300000033333333333333333333333300000000000000000033333333333333333300000000000033333333333300000000000033333300000000000033333333333333333333333300000000000000000000000000000000000
-- 034:000000000000000000000000000000000000033333333333333333333333340000033333333333333333333333340000000000000000033333333333333333340000000000033333333333340000000000033333340000000000033333333333333333333333340000000000000000000000000000000000
-- 035:000000000000000000000000000000000000033333333333333333333333340000033333333333333333333333340000000000000000033333333333333333340000000000033333333333340000000000033333340000000000033333333333333333333333340000000000000000000000000000000000
-- 036:000000000000000000000000000000000000033333333333333333333333340000033333333333333333333333340000000000000000033333333333333333340000000000033333333333340000000000033333340000000000033333333333333333333333340000000000000000000000000000000000
-- 037:000000000000000000000000000000000000033333333333333333333333340000033333333333333333333333340000000000000000033333333333333333340000000000033333333333340000000000033333340000000000033333333333333333333333340000000000000000000000000000000000
-- 038:000000000000000000000000000000000000033333333333333333333333340000033333333333333333333333340000000000000000033333333333333333340000000000033333333333340000000000033333340000000000033333333333333333333333340000000000000000000000000000000000
-- 039:000000000000000000000000000000033333333333333333344444444444440000033333333333344444444444433333300000033333333333344444444444433333300000033333333333333333300000033333340000033333333333344444444444444444440000000000000000000000000000000000
-- 040:000000000000000000000000000000033333333333333333340000000000000000033333333333340000000000033333340000033333333333340000000000033333340000033333333333333333340000033333340000033333333333340000000000000000000000000000000000000000000000000000
-- 041:000000000000000000000000000000033333333333333333340000000000000000033333333333340000000000033333340000033333333333340000000000033333340000033333333333333333340000033333340000033333333333340000000000000000000000000000000000000000000000000000
-- 042:000000000000000000000000000000033333333333333333340000000000000000033333333333340000000000033333340000033333333333340000000000033333340000033333333333333333340000033333340000033333333333340000000000000000000000000000000000000000000000000000
-- 043:000000000000000000000000000000033333333333333333340000000000000000033333333333340000000000033333340000033333333333340000000000033333340000033333333333333333340000033333340000033333333333340000000000000000000000000000000000000000000000000000
-- 044:000000000000000000000000000000033333333333333333340000000000000000033333333333340000000000033333340000033333333333340000000000033333340000033333333333333333340000033333340000033333333333340000000000000000000000000000000000000000000000000000
-- 045:000000000000000000000000000000004444433333333333333333300000000000033333333333340000000000033333340000033333333333340000000000033333340000033333333333333333333333333333340000033333333333340000033333333333300000000000000000000000000000000000
-- 046:000000000000000000000000000000000000033333333333333333340000000000033333333333340000000000033333340000033333333333340000000000033333340000033333333333333333333333333333340000033333333333340000033333333333340000000000000000000000000000000000
-- 047:000000000000000000000000000000000000033333333333333333340000000000033333333333340000000000033333340000033333333333340000000000033333340000033333333333333333333333333333340000033333333333340000033333333333340000000000000000000000000000000000
-- 048:000000000000000000000000000000000000033333333333333333340000000000033333333333340000000000033333340000033333333333340000000000033333340000033333333333333333333333333333340000033333333333340000033333333333340000000000000000000000000000000000
-- 049:000000000000000000000000000000000000033333333333333333340000000000033333333333340000000000033333340000033333333333340000000000033333340000033333333333333333333333333333340000033333333333340000033333333333340000000000000000000000000000000000
-- 050:000000000000000000000000000000000000033333333333333333340000000000033333333333340000000000033333340000033333333333340000000000033333340000033333333333333333333333333333340000033333333333340000033333333333340000000000000000000000000000000000
-- 051:000000000000000000000000000000000000004444433333333333333333300000033333333333333333333333304444440000033333333333340000000000033333340000033333333333344444433333333333340000033333333333340000004444433333340000000000000000000000000000000000
-- 052:000000000000000000000000000000000000000000033333333333333333340000033333333333333333333333340000000000033333333333340000000000033333340000033333333333340000033333333333340000033333333333340000000000033333340000000000000000000000000000000000
-- 053:000000000000000000000000000000000000000000033333333333333333340000033333333333333333333333340000000000033333333333340000000000033333340000033333333333340000033333333333340000033333333333340000000000033333340000000000000000000000000000000000
-- 054:000000000000000000000000000000000000000000033333333333333333340000033333333333333333333333340000000000033333333333340000000000033333340000033333333333340000033333333333340000033333333333340000000000033333340000000000000000000000000000000000
-- 055:000000000000000000000000000000000000000000033333333333333333340000033333333333333333333333340000000000033333333333340000000000033333340000033333333333340000033333333333340000033333333333340000000000033333340000000000000000000000000000000000
-- 056:000000000000000000000000000000000000000000033333333333333333340000033333333333333333333333340000000000033333333333340000000000033333340000033333333333340000033333333333340000033333333333340000000000033333340000000000000000000000000000000000
-- 057:000000000000000000000000000000033333333333333333333333344444440000033333333333344444444444440000000000004444433333333333333333304444440000033333333333340000004444433333340000004444433333333333333333333333340000000000000000000000000000000000
-- 058:000000000000000000000000000000033333333333333333333333340000000000033333333333340000000000000000000000000000033333333333333333340000000000033333333333340000000000033333340000000000033333333333333333333333340000000000000000000000000000000000
-- 059:000000000000000000000000000000033333333333333333333333340000000000033333333333340000000000000000000000000000033333333333333333340000000000033333333333340000000000033333340000000000033333333333333333333333340000000000000000000000000000000000
-- 060:000000000000000000000000000000033333333333333333333333340000000000033333333333340000000000000000000000000000033333333333333333340000000000033333333333340000000000033333340000000000033333333333333333333333340000000000000000000000000000000000
-- 061:000000000000000000000000000000033333333333333333333333340000000000033333333333340000000000000000000000000000033333333333333333340000000000033333333333340000000000033333340000000000033333333333333333333333340000000000000000000000000000000000
-- 062:000000000000000000000000000000033333333333333333333333340000000000033333333333340000000000000000000000000000033333333333333333340000000000033333333333340000000000033333340000000000033333333333333333333333340000000000000000000000000000000000
-- 063:000000000000000000000000000000004444444444444444444444440000000000004444444444440000000000000000000000000000004444444444444444440000000000004444444444440000000000004444440000000000004444444444444444444444440000000000000000000000000000000000
-- 068:000000000000000000000000000000000000000000000000000000000888888880000000000000000000000000000000000000000000000000000008888880000000000000088888888000000888888000088880000880000888888880000000000000000000000000000000000000000000000000000000
-- 069:000000000000000000000000000000000000000000000000000000000888888889000000000000000000000000000000000000000000000000000008888889000000000000088888888900000888888900088889000889000888888889000000000000000000000000000000000000000000000000000000
-- 070:000000000000000000000000000000000000000000000000000000088888899999000888888000088888888000000000000000000888888000000888899999000000000000088889999880088889999880088888800889088889999999000000000000000000000000000000000000000000000000000000
-- 071:000000000000000000000000000000000000000000000000000000088888890000000888888900088888888900000000000000000888888900000888890000000000000000088889000889088889000889088888890889088889000000000000000000000000000000000000000000000000000000000000
-- 072:000000000000000000000000000000000000000000000000000000009888888000088889999880088889999880000000000000088889999880088888888880000000000000088889000889088889000889088888888889088889088880000000000000000000000000000000000000000000000000000000
-- 073:000000000000000000000000000000000000000000000000000000000888888900088889000889088889000889000000000000088889000889088888888889000000000000088889000889088889000889088888888889088889088889000000000000000000000000000000000000000000000000000000
-- 074:000000000000000000000000000000000000000000000000000000000098888880088889000889088889000889000000000000088889000889009888899999000000000000088888888099088889000889088889988889088889009889000000000000000000000000000000000000000000000000000000
-- 075:000000000000000000000000000000000000000000000000000000000008888889088889000889088889000889000000000000088889000889000888890000000000000000088888888900088889000889088889088889088889000889000000000000000000000000000000000000000000000000000000
-- 076:000000000000000000000000000000000000000000000000000000088888888999009888888099088889000889000000000000009888888099000888890000000000000000088889999900009888888099088889009889009888888889000000000000000000000000000000000000000000000000000000
-- 077:000000000000000000000000000000000000000000000000000000088888888900000888888900088889000889000000000000000888888900000888890000000000000000088889000000000888888900088889000889000888888889000000000000000000000000000000000000000000000000000000
-- 078:000000000000000000000000000000000000000000000000000000009999999900000099999900009999000099000000000000000099999900000099990000000000000000009999000000000099999900009999000099000099999999000000000000000000000000000000000000000000000000000000
-- 088:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccc00000dd00d000000000000000000dddd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 089:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccc0000ddd0d00ddd00d000d00000dd00000dddd0dd0d000ddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 090:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccc0000ddddd0dd0dd0d0d0d00000dd0dd0d00dd0ddddd0dd0dd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 091:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccc0000dd0dd0ddd000ddddd00000dd00d0d00dd0d0d0d0ddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 092:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccc00000dd00d00ddd00dd0dd000000dddd00dddd0d0d0d00ddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 098:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ddd000000000dd000dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 099:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd00d0dddd00ddddd00000ddd00dddd000dddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 100:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd00d0dd00d00dd000dd0dd00d0dd00d0ddd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 101:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd00d0dd00d00dd000dd0dd00d0dd00d000ddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 102:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ddd00dddd0000ddd0dd00ddd00dd00d0dddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 103:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </SCREEN>

-- <PALETTE>
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

