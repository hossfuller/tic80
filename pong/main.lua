-- title:   Pong
-- author:  Adam Fuller <the.adam.fuller@gmail.com>
-- version: 0.1
-- script:  lua

-- TODO: Figure out how to split this up into multiple files and then compile together before running.
-- TODO: Fix scoring.
-- TODO: Fix collision detection.
-- TODO: Need a way to signal that each player is ready to play.
-- TODO: Hold the ball until both players are ready to play.
-- TODO: Make the score go away during play (between the time the ball first hits a paddle and when it goes out of bounds).
-- TODO: Add a way to pause the game.
-- TODO: Rewrite the boot section once we know how to create start and menu screens.
-- TODO: Menu screen lets user configure Moving Parts Contraints and Game Configuration settings.
-- TODO: Add a way to preserve the score?
-- TODO: Add an option to do one or two players.
-- TODO: Add computer player 2 logic.


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
P2_UP    = 8
P2_DOWN  = 9
P2_LEFT  = 10
P2_RIGHT = 11

-- Screen Edges
EDGE_X_LEFT   = 0
EDGE_X_RIGHT  = 240
EDGE_Y_TOP    = 0
EDGE_Y_BOTTOM = 135

-- Moving Parts Contraints
PADDLE_WIDTH     = 4
PADDLE_HEIGHT    = 24
BALL_RADIUS      = 30
BOUNDARY_WIDTH   = 5

-- Game Configuration
GAME_SPEED        = 1
WINNING_SCORE     = 2
SHOW_NUM_RETURNS  = true
ALWAYS_SHOW_SCORE = true


--[[ Base Class: PongObject ]]--
PongObject = {}
PongObject.__index = PongObject
function PongObject:new(params)
    params = params or {}
    local obj = {
        x      = params.x or 0,
        y      = params.y or 0,
        vx     = params.vx or GAME_SPEED,
        vy     = params.vy or GAME_SPEED,
        width  = params.width or PADDLE_WIDTH,
        height = params.height or PADDLE_HEIGHT,
        color  = params.color or WHITE,
        inPlay = false,
    }
    setmetatable(obj, self)
    return obj
end
function PongObject:getCollisionBox()
    return {
        top    = self.y,
        bottom = self.y + self.height,
        left   = self.x,
        right  = self.x + self.width
    }
end
function PongObject:draw()
    rect(self.x, self.y, self.width, self.height, self.color)
end
function PongObject:reset(x, y)
    print("This method hasn't been implemented", EDGE_X_LEFT, EDGE_Y_BOTTOM/2, RED)
end
function PongObject:play()
    self.inPlay = true
end
function PongObject:outOfPlay()
    self.inPlay = false
end
function PongObject:isInPlay()
    return self.inPlay
end


--[[ Base Class: PaddleObj ]]--
PaddleObj = setmetatable({}, {__index = PongObject})
PaddleObj.__index = PaddleObj
function PaddleObj:new(params)
    params = params or {}
    local obj = PongObject.new(self, params)
    setmetatable(obj, self)
    -- PaddleObj-specific properties
    obj.player      = params.player or 1
    obj.score       = 0
    obj.returns     = 0
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
    return obj
end
function PaddleObj:input()
    if btn(self.upButton) then
        self.y = math.floor(self.y - self.vy)
    end
    if btn(self.downButton) then
        self.y = math.ceil(self.y + self.vy)
    end
    -- Need a way to signal that each player is ready to play.
    -- if btn(self.leftButton) and self:outOfPlay() then
    --     self:play()
    -- end
end
function PaddleObj:update()
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
function PaddleObj:reset(x, y)
    self.x = x or EDGE_X_LEFT
    self.y = y or math.floor(EDGE_Y_BOTTOM / 2 - self.height / 2)
    if self.player == 2 then
        self.x = EDGE_X_RIGHT
    end
    self:resetReturns()
    -- self:outOfPlay()
end
function PaddleObj:getReturns()
    return self.returns
end
function PaddleObj:incrementReturns()
    self.returns = self.returns + 1
end
function PaddleObj:resetReturns()
    self.returns = 0
    end
function PaddleObj:getScore()
    return self.score
end
function PaddleObj:incrementScore()
    self.score = self.score + 1
end
function PaddleObj:resetScore()
    self.score = 0
end


--[[ Base Class: BallObj ]]--
BallObj = setmetatable({}, {__index = PongObject})
BallObj.__index = BallObj
function BallObj:new(params)
    params = params or {}
    local obj = PongObject.new(self, params)
    setmetatable(obj, self)
    -- BallObj-specific properties
    obj.radius = params.radius or BALL_RADIUS
    return obj
end
function BallObj:getCollisionBox()
    return {
        top    = self.y - self.radius,
        bottom = self.y + self.radius,
        left   = self.x - self.radius,
        right  = self.x + self.radius,
    }
end
function BallObj:draw()
    circ(self.x, self.y, self.radius, self.color)
end
function BallObj:reset(x, y)
    self.x      = x or math.floor(EDGE_X_RIGHT/2)
    self.y      = y or math.floor(EDGE_Y_BOTTOM/2)

    -- Get the ball moving in a random direction.
    local ball_direction_x = (math.random() < 0.5) and 1 or -1
    local ball_direction_y = (math.random() < 0.5) and 1 or -1
    self.vx = ball_direction_x * GAME_SPEED
    self.vy = ball_direction_y * GAME_SPEED

    self:outOfPlay()
end
function BallObj:update()
    -- if self:isInPlay() then
    --     self.x = self.x + self.vx
    --     self.y = self.y + self.vy
    -- end
    self.x = self.x + self.vx
    self.y = self.y + self.vy

    if self.x < (EDGE_X_LEFT - 2*self.radius) or self.x > EDGE_X_RIGHT then
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
function BallObj:collision(paddle)
    ball_box   = self:getCollisionBox()
    paddle_box = paddle:getCollisionBox()
    if
        ball_box['left'] < paddle_box['right']
        and ball_box['right'] > paddle_box['left']
        and ball_box['top'] < paddle_box['bottom']
        and ball_box['bottom'] > paddle_box['top']
    then
        sfx(1)
        self.vx = -self.vx
        paddle:incrementReturns()
    end
end


--[[ INITIALIZATION ]]--
-- Create objects
local paddle1 = PaddleObj:new({player = 1})
local paddle2 = PaddleObj:new({player = 2})
local ball    = BallObj:new()

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
    CHECK_RESET()
end --TIC

--[[ FUNCTIONS ]]--

--[[ INPUT FUNCTIONS ]]--
function INPUT()
    paddle1:input()
    paddle2:input()
end -- INPUT()


--[[ UPDATE FUNCTIONS ]]--
function UPDATE()
    -- -- Get the ball moving after being out of play.
    -- if
    --     paddle1:isInPlay() and paddle1:isInPlay()
    --     and ball:isInPlay() == false
    -- then
    --     ball:play()
    -- end

    -- Keep the paddles on the screen
    paddle1:update()
    paddle2:update()

    -- Check for paddle/ball collision.
    ball:collision(paddle1)
    ball:collision(paddle2)
    ball:update()
end -- UPDATE()


--[[ DRAW FUNCTIONS ]]--
function DRAW()
    cls(BLACK)

    -- Draw the court, which is stationary.
    drawCourt()

    -- Draw score and other situational information
    -- if ALWAYS_SHOW_SCORE or (
    --     paddle1:isInPlay() == false
    --     or paddle1:isInPlay() == false
    --     or ball:isInPlay() == false
    -- ) then
    --     drawScoreBug()
    -- end
    drawScoreBug()

    -- Draw the moving elements.
    paddle1:draw()
    paddle2:draw()
    ball:draw()
end -- DRAW()

function drawCourt()
    -- Net
    for _i=EDGE_Y_TOP+2,EDGE_Y_BOTTOM,8 do
        rect(EDGE_X_RIGHT/2, _i, BOUNDARY_WIDTH, 4, GREEN_LITE)
    end
    -- Court boundaries
    line(EDGE_X_LEFT, EDGE_Y_TOP, EDGE_X_RIGHT - 1, EDGE_Y_TOP, YELLOW)
    line(EDGE_X_LEFT, EDGE_Y_BOTTOM, EDGE_X_RIGHT - 1, EDGE_Y_BOTTOM, YELLOW)
end

function drawScoreBug()
    local score_line = string.format("%d - %d", paddle1:getScore(), paddle2:getScore())
    print_centered_text(score_line, BOUNDARY_WIDTH + 2, BLUE_LITE, true, 2)

    if SHOW_NUM_RETURNS then
        local returns_line = string.format("%d   %d", paddle1:getReturns(), paddle2:getReturns())
        print_centered_text(returns_line, EDGE_Y_BOTTOM - 9, GRAY_LITE, true, 1)
    end
end


function print_centered_text(message, height, color, shadow, scale)
    if shadow == nil then
        shadow = false
    end
    if scale == nil then
        scale = 1
    end
    local message_width = print(message, 0, -10, color, true, scale)
    local x_pos = ((EDGE_X_RIGHT - message_width) / 2) + 2
    if shadow then
        print(message, x_pos + 1, height + 1, color + 1, true, scale)
    end
    print(message, x_pos, height, color, true, scale)
end


--[[ CHECK FOR GAME STOPPAGES ]]--
function CHECK_RESET()

    -- -- There's some sort of game stoppage (someone scored or the game is paused.)
    -- if paddle1:isInPlay() == false and paddle1:isInPlay() == false then
    --     print_centered_text("READY?", math.floor(EDGE_Y_BOTTOM/2), ORANGE, true, 3)

    -- elseif paddle1:isInPlay() == true and paddle1:isInPlay() == false then
    --     print_centered_text("READY?", math.floor(EDGE_Y_BOTTOM / 2), ORANGE, true, 3)
    --     print("YES!", EDGE_X_LEFT + 2, BOUNDARY_WIDTH + 2, ORANGE, true, 2)

    -- elseif paddle1:isInPlay() == false and paddle1:isInPlay() == true then
    --     print_centered_text("READY?", math.floor(EDGE_Y_BOTTOM / 2), ORANGE, true, 3)
    --     local p2_ready_width = print("YES!", EDGE_X_LEFT + 2, -20, ORANGE, true, 2)
    --     print("YES!", EDGE_X_RIGHT - p2_ready_width, BOUNDARY_WIDTH + 2, ORANGE, true, 2)

    --     -- The ball has gone out of play....
    -- elseif

    if
        paddle1:isInPlay() and paddle1:isInPlay()
        and ball:isInPlay() == false
    then
        -- Indicate ball is out of play
        sfx(2)

        -- Increment score
        if (ball.x + ball.radius) < EDGE_X_LEFT then
            paddle2:incrementScore()
            -- paddle2:outOfPlay()

        elseif ball.x >= EDGE_X_RIGHT then
            paddle1:incrementScore()
            -- paddle1:outOfPlay()
        end

        -- Check if somebody's score == the WINNING_SCORE
        if paddle1:getScore() == WINNING_SCORE then
            GAME_OVER(paddle1)
        elseif paddle2:getScore() == WINNING_SCORE then
            GAME_OVER(paddle2)
        else
            paddle1:reset()
            paddle2:reset()
            ball:reset()
        end
    end
end -- CHECK_RESET()

function GAME_OVER(winning_paddle)
    local winning_message = string.format("PLAYER [%d] WINS!", winning_paddle.player)
    print_centered_text(winning_message, EDGE_Y_BOTTOM/2, ORANGE, true, 3)
end


-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:00000000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000404000000000
-- 001:00000000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f00020a000000000
-- 002:04f004c0049004600430f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400100000000000
-- </SFX>

-- <TRACKS>
-- 000:100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </TRACKS>

-- <PALETTE>
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

