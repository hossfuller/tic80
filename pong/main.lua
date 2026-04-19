-- title:   Pong
-- author:  Adam Fuller <the.adam.fuller@gmail.com>
-- version: 0.1
-- script:  lua

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

-- Screen Edges
EDGE_X_LEFT   = 0
EDGE_X_RIGHT  = 239
EDGE_Y_TOP    = 0
EDGE_Y_BOTTOM = 135

-- Controls
P1_UP    = 0
P1_DOWN  = 1
P1_LEFT  = 2
P1_RIGHT = 3
P2_UP    = 8
P2_DOWN  = 9
P2_LEFT  = 10
P2_RIGHT = 11

-- Moving Parts Contraints
PADDLE_WIDTH   = 4
PADDLE_HEIGHT  = 24
BALL_RADIUS    = 3
BOUNDARY_WIDTH = 2


--[[ Base Class: PongObject ]]--
PongObject = {}
PongObject.__index = PongObject
function PongObject:new(params)
    params = params or {}
    local obj = {
        x     = params.x or 0,
        y     = params.y or 0,
        vx    = params.vx or 2,
        vy    = params.vy or 2,
        -- vmax  = params.vmax or 2,
        color = params.color or WHITE,
    }
    setmetatable(obj, self)
    return obj
end
function PongObject:draw()
    rect(self.x, self.y, self.width, self.height, self.color)
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
        self.y = self.y - self.vy
    end
    if btn(self.downButton) then
        self.y = self.y + self.vy
    end
    if btn(self.leftButton) then
        self.x = self.x - self.vx
    end
    if btn(self.rightButton) then
        self.x = self.x + self.vx
    end
end
function PongObject:update()
    if self.x < EDGE_X_LEFT then
        self.x = EDGE_X_LEFT
    elseif self.x > (EDGE_X_RIGHT - self.width) then
        self.x = EDGE_X_RIGHT - self.width + 1
    end
    if self.y < EDGE_Y_TOP then
        self.y = EDGE_Y_TOP
    elseif self.y > (EDGE_Y_BOTTOM - self.height) then
        self.y = EDGE_Y_BOTTOM - self.height + 1
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
    return obj
end
function BallObj:draw()
    circ(self.x, self.y, self.radius, self.color)
end
function BallObj:reset(x, y)
    self.x = x or EDGE_X_RIGHT/2
    self.y = y or EDGE_Y_BOTTOM/2
    -- self.vx = math.random(2) == 1 and 2 or -2
    -- self.vy = math.random(-2, 2)
end

--[[ FUNCTIONS ]]--



--[[ INITIALIZATION ]]--
-- Create objects
local paddle1 = PaddleObj:new({
    x = EDGE_X_LEFT, 
    y = EDGE_Y_TOP, 
    player = 1
})
local paddle2 = PaddleObj:new({
    x = EDGE_X_RIGHT - PADDLE_WIDTH, 
    y = EDGE_Y_BOTTOM - PADDLE_HEIGHT,
    player = 2
})
local ball    = BallObj:new({
    x = EDGE_X_RIGHT/2, 
    y = EDGE_Y_BOTTOM/2
})


--[[ GAME LOOP ]]--
function TIC()
    --[[ CHECK FOR USER INPUT ]]--
    INPUT(paddle1, paddle2)

    --[[ UPDATE GAME DATA ]]--
    UPDATE(paddle1, paddle2, ball)

    --[[ DRAW GAME GRAPHICS ]]--
    DRAW(paddle1, paddle2, ball)

    --[[ CHECK FOR GAME OVER ]]--

end --TIC


--[[ INPUT FUNCTIONS ]]--
function INPUT(paddle1, paddle2)
    paddle1:input()
    paddle2:input()
end -- INPUT()


--[[ UPDATE FUNCTIONS ]]--
function UPDATE(paddle1, paddle2, ball)
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
    line(EDGE_X_LEFT, EDGE_Y_TOP, EDGE_X_RIGHT, EDGE_Y_TOP, YELLOW)
    line(EDGE_X_LEFT, EDGE_Y_BOTTOM, EDGE_X_RIGHT, EDGE_Y_BOTTOM, YELLOW)
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

