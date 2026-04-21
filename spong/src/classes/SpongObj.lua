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
