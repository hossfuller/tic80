--[[ Base Class: SballObj ]]--

SballObj = setmetatable({}, {__index = SpongObj})
SballObj.__index = SballObj

function SballObj:new(params)
    params = params or {}
    local obj = SpongObj.new(self, params)
    setmetatable(obj, self)

    -- SballObj-specific properties
    obj.radius = params.radius or BALL_RADIUS

    return obj
end

function SballObj:draw()
    circ(self.x, self.y, self.radius, self.color)
end

function SballObj:getCollisionBox()
    return {
        top    = self.y - self.radius,
        bottom = self.y + self.radius,
        left   = self.x - self.radius,
        right  = self.x + self.radius,
    }
end

function SballObj:reset(x, y)
    self.x      = x or math.floor(EDGE_X_RIGHT/2)
    self.y      = y or math.floor(EDGE_Y_BOTTOM/2)

    -- Get the ball moving in a random direction.
    local ball_direction_x = (math.random() < 0.5) and 1 or -1
    local ball_direction_y = (math.random() < 0.5) and 1 or -1
    self.vx = ball_direction_x * GAME_SPEED
    self.vy = ball_direction_y * GAME_SPEED

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
