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
