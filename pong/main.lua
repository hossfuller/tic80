-- title:   Pong
-- author:  Adam Fuller <the.adam.fuller@gmail.com>
-- version: 0.1
-- script:  lua

--[[ TODOs ]]--

-- Add a menu screen to configure paddle size, ball size, and game speed.
-- Add collision detection for the ball and paddles.
-- Add scoring.
-- Add a way to preserve the score?
-- Add an option to do one or two players.
-- Add computer player 2 logic.


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
EDGE_X_RIGHT  = 239
EDGE_Y_TOP    = 0
EDGE_Y_BOTTOM = 135

-- Moving Parts Contraints
PADDLE_WIDTH   = 4
PADDLE_HEIGHT  = 24
BALL_RADIUS    = 3
BOUNDARY_WIDTH = 2
GAME_SPEED     = 0.25


--[[ Base Class: PongObject ]]--
PongObject = {}
PongObject.__index = PongObject
function PongObject:new(params)
    params = params or {}
    local obj = {
        x     = params.x or 0,
        y     = params.y or 0,
        vx    = params.vx or GAME_SPEED,
        vy    = params.vy or GAME_SPEED,
        -- vmax  = params.vmax or 2,
        color = params.color or WHITE,
    }
    setmetatable(obj, self)
    return obj
end
function PongObject:draw()
    rect(self.x, self.y, self.width, self.height, self.color)
end
function PongObject:reset(x, y)
    print("This method hasn't been implemented", EDGE_X_LEFT, EDGE_Y_BOTTOM/2, RED)
end

--[[ Base Class: PaddleObj ]]--
PaddleObj = setmetatable({}, {__index = PongObject})
PaddleObj.__index = PaddleObj
function PaddleObj:new(params)
    params = params or {}
    local obj = PongObject.new(self, params)
    setmetatable(obj, self)
    -- PaddleObj-specific properties
    obj.width      = params.width or PADDLE_WIDTH
    obj.height     = params.height or PADDLE_HEIGHT
    obj.player     = params.player or 1
    obj.upButton   = P1_UP
    obj.downButton = P1_DOWN
    obj.leftButton   = P1_LEFT
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
    self.y = y or math.floor(EDGE_Y_BOTTOM/2 - self.height/2)
    if self.player == 2 then
       self.x = EDGE_X_RIGHT
    end
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
    obj.inPlay = true
    return obj
end
function BallObj:draw()
    circ(self.x, self.y, self.radius, self.color)
end
function BallObj:reset(x, y)
    self.x      = x or math.floor(EDGE_X_RIGHT/2)
    self.y      = y or math.floor(EDGE_Y_BOTTOM/2)

    local ball_direction_x = (math.random() < 0.5) and 1 or -1
    local ball_direction_y = (math.random() < 0.5) and 1 or -1
    self.vx = ball_direction_x * GAME_SPEED
    self.vy = ball_direction_y * GAME_SPEED

    self.inPlay = true
end
function BallObj:update()
    self.x = self.x + self.vx
    self.y = self.y + self.vy

    if self.x < (EDGE_X_LEFT - 2*self.radius) or self.x > EDGE_X_RIGHT then
        self.inPlay = false
    end
    if self.y < (EDGE_Y_TOP + self.radius + 1) then
        self.y = EDGE_Y_TOP + self.radius + 1
        self.vy = - self.vy
    elseif self.y > (EDGE_Y_BOTTOM - (self.radius)) then
        self.y = math.floor(EDGE_Y_BOTTOM - (2*self.radius))
        self.vy = - self.vy
    end
end
function BallObj:isInPlay()
    return self.inPlay
end
-- function BallObj:collision(paddle)
--     if self.x < (EDGE_X_LEFT + paddle.width) then
--         if self.y > paddle.y and self.y < paddle.y + paddle.height then
--             self.vx = - self.vx
--         end
--     end
--     if self.x > (EDGE_X_RIGHT - paddle.width) then
--         if self.y > paddle.y and self.y < paddle.y + paddle.height then
--             self.vx = - self.vx
--         end
--     end
-- end


--[[ FUNCTIONS ]]--


--[[ INITIALIZATION ]]--
-- Create objects
local paddle1 = PaddleObj:new({player = 1})
local paddle2 = PaddleObj:new({player = 2})
local ball    = BallObj:new()

function INIT()
    paddle1:reset()
    paddle2:reset()
    ball:reset()
end

INIT()

--[[ GAME LOOP ]]--
function TIC()
    --[[ CHECK FOR USER INPUT ]]--
    INPUT(paddle1, paddle2)

    --[[ UPDATE GAME DATA ]]--
    UPDATE(paddle1, paddle2, ball)

    --[[ DRAW GAME GRAPHICS ]]--
    DRAW(paddle1, paddle2, ball)

    print(string.format("paddle1: [%3d,%3d]", paddle1.x, paddle1.y), EDGE_X_LEFT+10, EDGE_Y_BOTTOM-21, YELLOW)
    print(string.format("paddle2: [%3d,%3d]", paddle2.x, paddle2.y), EDGE_X_LEFT+10, EDGE_Y_BOTTOM-14, YELLOW)
    print(string.format("ball: [%3.0f,%3.0f]", ball.x, ball.y), EDGE_X_LEFT+10, EDGE_Y_BOTTOM-7, YELLOW)

    --[[ CHECK FOR GAME OVER ]]--
    if ball:isInPlay() == false then
        paddle1:reset()
        paddle2:reset()
        ball:reset()
    end
end --TIC


--[[ INPUT FUNCTIONS ]]--
function INPUT(paddle1, paddle2)
    paddle1:input()
    paddle2:input()
end -- INPUT()


--[[ UPDATE FUNCTIONS ]]--
function UPDATE(paddle1, paddle2, ball)

    -- -- Check for paddle/ball collision.
    -- ball:collision(paddle1)
    -- ball:collision(paddle2)

    -- Check if anything has left the screen.
    paddle1:update()
    paddle2:update()
    ball:update()
end -- UPDATE()


--[[ DRAW FUNCTIONS ]]--
function DRAW(paddle1, paddle2, ball)
    cls(BLACK)

    -- Draw the court, which is stationary.
    drawCourt()

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

