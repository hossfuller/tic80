--
-- Bundle file
-- Code changes will be overwritten
--

-- title:   SPong (Son of Pong)
-- author:  Adam Fuller <the.adam.fuller@gmail.com>
-- version: 0.2
-- script:  lua


--[[ INCLUDES ]]--
-- [TQ-Bundler: src.constants]

--[[ CONSTANTS ]] --

-- Colors
BLACK             = 0
PURPLE            = 1
RED               = 2
ORANGE            = 3
YELLOW            = 4
GREEN_LITE        = 5
GREEN_MED         = 6
GREEN_DARK        = 7
BLUE_DARK         = 8
BLUE_MED          = 9
BLUE_LITE         = 10
CYAN              = 11
WHITE             = 12
GRAY_LITE         = 13
GRAY_MED          = 14
GRAY_DARK         = 15

-- Controls
P1_UP             = 0
P1_DOWN           = 1
P1_LEFT           = 2
P1_RIGHT          = 3
P2_UP             = 8
P2_DOWN           = 9
P2_LEFT           = 10
P2_RIGHT          = 11

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
WINNING_SCORE        = 10
SHOW_NUM_RETURNS     = true
ENABLE_SPEED_BOOST   = true


--[[ TODO LIST ]]--

-- TODO: How do I automatically change the keymapping upon loading?
-- TODO: Rewrite the boot section once we know how to create start and menu screens.
-- TODO: Menu screen lets user configure Moving Parts Contraints and Game Configuration settings.
-- TODO: Figure out how to do game over stuff. Send back to start screen?

-- TODO: Add a way to pause the game.
-- TODO: Do power ups!
-- TODO: Should we be able to move the paddles along the x-axis?
-- TODO: Win by 2?

-- TODO: Add a way to preserve the score?
-- TODO: Add an option to do one or two players.
-- TODO: Add computer player 2 logic.



-- [/TQ-Bundler: src.constants]

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
    print("This method hasn't been implemented", EDGE_X_LEFT, EDGE_Y_BOTTOM/2, RED)
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

SpaddleObj = setmetatable({}, {__index = SpongObj})
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
    if obj.player == 2 then
        obj.upButton    = P2_UP
        obj.downButton  = P2_DOWN
        obj.leftButton  = P2_LEFT
        obj.rightButton = P2_RIGHT
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

SballObj = setmetatable({}, {__index = SpongObj})
SballObj.__index = SballObj

function SballObj:new(params)
    params = params or {}
    local obj = SpongObj.new(self, params)
    setmetatable(obj, self)

    -- SballObj-specific properties
    obj.radius = params.radius or BALL_RADIUS
    obj.touching_paddle = false
    obj.serve_direction_x = 1  -- serve the ball right
    obj.serve_direction_y = 1  -- serve the ball down

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

        if self.vx > 0 and self.vy < 0 then -- pointing right and up
            serve_dir_arrow_x = serve_dir_arrow_x + 1 
            serve_dir_arrow_y = serve_dir_arrow_y - 2*self.radius - 3
        elseif self.vx > 0 and self.vy > 0 then -- pointing right and down
            serve_dir_arrow_rotate = 2
        elseif self.vx < 0 and self.vy > 0 then -- pointing left and up
            serve_dir_arrow_x = serve_dir_arrow_x + 1 
            serve_dir_arrow_y = serve_dir_arrow_y - 2*self.radius - 3
        elseif self.vx < 0 and self.vy < 0 then -- pointing left and down
            -- serve_dir_arrow_x = serve_dir_arrow_x - self.radius
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
            sfx(3)
        else
            self.serve_direction_y = 1 -- serve the ball down
            sfx(4)
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

    if (self.x + 3*self.radius) < EDGE_X_LEFT or (self.x - 3*self.radius) > EDGE_X_RIGHT then
        sfx(2)
        self:outOfPlay()
    end

    if self.y < (EDGE_Y_TOP + self.radius + 1) then
        sfx(0)
        self.y = EDGE_Y_TOP + self.radius + 1
        self.vy = - self.vy
    elseif self.y > (EDGE_Y_BOTTOM - (self.radius)) then
        sfx(0)
        self.y = math.floor(EDGE_Y_BOTTOM - self.radius)
        self.vy = - self.vy
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
            if (paddle:getReturns() > 0) and (paddle1:getReturns() % RETURN_THRESHOLD) == 0 then
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
    cls(BLACK)

    --- Draw the court, which is stationary.
    drawCourt()

    -- Draw the HUD for each user.
    drawHud(paddle1, ball:isInPlay())
    drawHud(paddle2, ball:isInPlay())

    -- Draw the moving elements.
    paddle1:draw()
    paddle2:draw()
    ball:draw()

    -- print_centered_text("P1.x = " .. paddle1.x, 20)
    -- print_centered_text("P1.y = " .. paddle1.y, 30)
    -- print_centered_text("P1.player = " .. paddle1.player, 40)
    -- print_centered_text("P1.isInPlay() = " .. tostring(paddle1:isInPlay()), 50)

    -- print_centered_text("P2.x = " .. paddle2.x, 70)
    -- print_centered_text("P2.y = " .. paddle2.y, 80)
    -- print_centered_text("P2.player = " .. paddle2.player, 90)
    -- print_centered_text("P2.isInPlay() = " .. tostring(paddle2:isInPlay()), 100)

    -- print_centered_text("Ball.isInPlay() = " .. tostring(ball:isInPlay()), 110)
    -- print_centered_text("Ball.isTouchingPaddle() = " .. tostring(ball:isTouchingPaddle()), 120)
end -- DRAW()

function drawHud(paddle, ball_status)
    local x_pos = EDGE_X_LEFT - HUD_WIDTH
    local y_pos = EDGE_Y_TOP + BOUNDARY_WIDTH

    local red_light_spr_id    = 257
    local yellow_light_spr_id = 259
    local green_light_spr_id  = 261
    local status_light_spr_id = 0

    local score_scale  = 2
    local return_scale = 2
    local score_color  = ORANGE
    local return_color = BLUE_LITE

    if paddle.player == 2 then
        x_pos = EDGE_X_RIGHT + 1
    end

    if paddle:isInPlay() == false then
        status_light_spr_id = red_light_spr_id
    elseif paddle:isInPlay() == true and ball_status == false then
        status_light_spr_id = yellow_light_spr_id
    elseif paddle:isInPlay() == true and ball_status == true then
        status_light_spr_id = green_light_spr_id
    end
    spr(status_light_spr_id, x_pos, y_pos, 0, 1, 0, 0, 2, 4)

    if paddle:getScore() > 9 then
        score_scale = 1
    end
    print(paddle:getScore(), x_pos + 1, y_pos + 36, score_color + 1, true, score_scale, false)
    print(paddle:getScore(), x_pos, y_pos + 35, score_color, true, score_scale, false)

    if SHOW_NUM_RETURNS then
        if paddle:getReturns() > 9 then
            return_scale = 1
        end
        print(paddle:getReturns(), x_pos + 1, y_pos + 51, return_color - 1, true, return_scale, false)
        print(paddle:getReturns(), x_pos, y_pos + 50, return_color, true, return_scale, false)
    end
end

function drawCourt()
    -- Net
    for _i=EDGE_Y_TOP+2,EDGE_Y_BOTTOM,8 do
        rect(EDGE_X_RIGHT/2, _i, BOUNDARY_WIDTH, 4, GREEN_LITE)
    end
    -- Court boundaries
    line(EDGE_X_LEFT, EDGE_Y_TOP, EDGE_X_RIGHT - 1, EDGE_Y_TOP, YELLOW)
    line(EDGE_X_LEFT, EDGE_Y_BOTTOM, EDGE_X_RIGHT - 1, EDGE_Y_BOTTOM, YELLOW)
end

function print_centered_text(message, height, color, shadow, fixed, scale)
    if height == nil then
        height = math.floor(EDGE_Y_BOTTOM/2)
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


-- [/TQ-Bundler: src.draw]

-- [TQ-Bundler: src.check]

--[[ CHECK FOR GAME STOPPAGES ]]--

function CHECK()
    
    -- Check if somebody's score == the WINNING_SCORE
    if paddle1:getScore() == WINNING_SCORE then
        GAME_OVER(paddle1)
    elseif paddle2:getScore() == WINNING_SCORE then
        GAME_OVER(paddle2)

    -- There's some sort of game stoppage (someone scored or the game is paused.)
    elseif
        paddle1:isInPlay() == false
        or paddle2:isInPlay() == false
    then
        print_centered_text("READY?", math.floor(EDGE_Y_BOTTOM/2), ORANGE, true, true, 3)
        print_centered_text("PRESS LEFT TO BEGIN", math.floor(EDGE_Y_BOTTOM/2 + 28), BLUE_LITE, false, false, 1)

        -- Serving player can move up and down with the ball with this wrapper
        -- method for ball:reset().
        if CURRENT_SERVE_PLAYER == 1 then
            ball:preServe(paddle1)
        else
            ball:preServe(paddle2)
        end
    -- Both players are ready but the ball has gone out of bounds.
    elseif
        paddle1:isInPlay() == true
        and paddle2:isInPlay() == true
    then
        
        if ball:isInPlay() == true then
            -- Ball is in play!
        else
            -- Ball is out of play! Increment score
            if (ball.x + ball.radius) < EDGE_X_LEFT then
                paddle2:incrementScore()
            elseif ball.x >= EDGE_X_RIGHT then
                paddle1:incrementScore()
            end

            paddle1:reset()
            paddle2:reset()
            ball:reset()
        end

    -- Everybody is playing, nothing new has happened.
    elseif
        paddle1:isInPlay() == true
        and paddle2:isInPlay() == true
        and ball:isInPlay() == true
    then
        -- Do nothing...for now.
    end
end -- CHECK()


function GAME_OVER(winning_paddle)
    local winning_message = string.format("PLAYER %d WINS!", winning_paddle.player)
    print_centered_text(winning_message, EDGE_Y_BOTTOM/2, ORANGE, true, false, 2)

    INIT()
end


-- [/TQ-Bundler: src.check]

--[[ INITIALIZATION ]]--

-- Create objects
paddle1 = SpaddleObj:new({player = 1})
paddle2 = SpaddleObj:new({player = 2})
ball    = SballObj:new()

-- TODO: How do I automatically change the keymapping upon loading?
function BOOT()
end

function INIT()
    paddle1:reset()
    paddle2:reset()
    ball:reset()
end

INIT()


--[[ GAME LOOP ]]--

function TIC()
    --[[ CHECK FOR USER INPUT ]]--
    INPUT()

    --[[ UPDATE GAME DATA ]]--
    UPDATE()

    --[[ DRAW GAME GRAPHICS ]]--
    DRAW()

    --[[ CHECK FOR GAME STOPPAGES ]]--
    CHECK()
end --TIC
