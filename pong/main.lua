-- title:   Pong
-- author:  Adam Fuller <the.adam.fuller@gmail.com>
-- version: 0.1
-- script:  lua

--[[ CONSTANTS ]]--

BLACK  = 0
YELLOW = 1
GREEN  = 2
WHITE  = 3

EDGE_X_LEFT   = 0
EDGE_X_RIGHT  = 239
EDGE_Y_TOP    = 0
EDGE_Y_BOTTOM = 135

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
        vx    = params.vx or 0,
        vy    = params.vy or 0,
        vmax  = params.vmax or 2,
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
    obj.width  = params.width or PADDLE_WIDTH
    obj.height = params.height or PADDLE_HEIGHT
    return obj
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
    self.vx = math.random(2) == 1 and 2 or -2
    self.vy = math.random(-2, 2)
end

--[[ FUNCTIONS ]]--



--[[ INITIALIZATION ]]--



--[[ GAME LOOP ]]--
function TIC()
    -- Create objects
    local paddle1 = PaddleObj:new({x = EDGE_X_LEFT, y = EDGE_Y_TOP})
    local paddle2 = PaddleObj:new({x = EDGE_X_RIGHT - PADDLE_WIDTH, y = EDGE_Y_BOTTOM - PADDLE_HEIGHT})
    local ball    = BallObj:new({x = EDGE_X_RIGHT/2, y = EDGE_Y_BOTTOM/2})

    --[[ CHECK FOR USER INPUT ]]--
    INPUT()

    --[[ UPDATE GAME DATA ]]--
    UPDATE(paddle1, paddle2, ball)

    --[[ DRAW GAME GRAPHICS ]]--
    DRAW(paddle1, paddle2, ball)

    --[[ CHECK FOR GAME OVER ]]--

end --TIC


--[[ INPUT FUNCTIONS ]]--
function INPUT()
end -- INPUT()


--[[ UPDATE FUNCTIONS ]]--
function UPDATE(paddle1, paddle2, ball)
    -- paddle1:update()
    -- paddle2:update()
    -- ball:update()
end -- UPDATE()


--[[ DRAW FUNCTIONS ]]--
function DRAW(paddle1, paddle2, ball)
    cls(BLACK)

    -- Draw the court, which is stationary.
    -- Net
    for _i=EDGE_Y_TOP+2,EDGE_Y_BOTTOM,8 do
        rect(EDGE_X_RIGHT/2, _i, BOUNDARY_WIDTH, 4, GREEN)
    end
    -- Court boundaries
    line(EDGE_X_LEFT, EDGE_Y_TOP, EDGE_X_RIGHT, EDGE_Y_TOP, YELLOW)
    line(EDGE_X_LEFT, EDGE_Y_BOTTOM, EDGE_X_RIGHT, EDGE_Y_BOTTOM, YELLOW)
    

    -- Draw the moving elements.
    paddle1:draw()
    paddle2:draw()
    ball:draw()
end -- DRAW()



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
-- 000:1a1c2cffff0000ae04ffffffffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

