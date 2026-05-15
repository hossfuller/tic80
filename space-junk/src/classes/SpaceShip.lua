-- ==========================================
-- SPACESHIP OBJECT
-- ==========================================

SpaceShip = {}
SpaceShip.__index = SpaceShip

-- Creates a new SpaceShip instance
function SpaceShip.new(params)
    params             = params or {}
    local self         = setmetatable({}, SpaceShip)

    self.color    = params.color or BLUE_MED
    self.position = {
        x = params.x or math.floor(EDGE_X_RIGHT / 2),
        y = params.y or math.floor(EDGE_Y_BOTTOM / 2)

    }
    self.velocity = {
        speed     = 0,
        direction = 0,
    }
    self.acceleration  = 0.05
    self.deceleration  = 0.01
    self.rotation      = params.rotation or 5
    self.rotationSpeed = params.rotationSpeed or 0.07
    self.shape         = params.shape or {
        {x=8, y=0},
        {x=-8, y=6},
        {x=-4, y=0},
        {x=-8, y=-6},
        {x=8, y=0}
	}
    return self
end

-- ==========================================
-- SPACESHIP MATH
-- ==========================================

function SpaceShip:keepAngleInRange(angle)
    if angle < 0 then
        while angle < 0 do
            angle = angle + (2 * math.pi)
        end
    end
    if angle > (2 * math.pi) then
        while angle > (2 * math.pi) do
            angle = angle - (2 * math.pi)
        end
    end
    return angle
end

-- 'rotation' parameter is in radians.
function SpaceShip:rotatePoint(point, rotation)
    local rotated_x = (point.x * math.cos(rotation)) - (point.y * math.sin(rotation))
    local rotated_y = (point.y * math.cos(rotation)) + (point.x * math.sin(rotation))
    return { x = rotated_x, y = rotated_y }
end

function SpaceShip:getVectorComponents(vector)
    local xComp = vector.speed * math.cos(vector.direction)
    local yComp = vector.speed * math.sin(vector.direction)

    local components = {
        xComp = xComp,
        yComp = yComp
    }

    return components
end

function SpaceShip:addVectors(vector1, vector2)
    v1Comp = self:getVectorComponents(vector1)
    v2Comp = self:getVectorComponents(vector2)
    resultantX = v1Comp.xComp + v2Comp.xComp
    resultantY = v1Comp.yComp + v2Comp.yComp

    local resVector = self:compToVector(resultantX, resultantY)

    return resVector
end

function SpaceShip:compToVector(x, y)
    local magnitude = math.sqrt((x * x) + (y * y))
    local direction = math.atan(y, x)

    direction = self:keepAngleInRange(direction)

    local vector = {
        speed = magnitude,
        direction = direction
    }

    return vector
end

function SpaceShip:movePointByVelocity()
    components = self:getVectorComponents(self.velocity)

    local newPosition = {
        x = self.position.x + components.xComp,
        y = self.position.y + components.yComp
    }

    return newPosition
end


-- ==========================================
-- SPACESHIP GETTERS
-- ==========================================

function SpaceShip:getPosition()
    return self.position
end

function SpaceShip:getVelocity()
    return self.velocity
end

function SpaceShip:getRotation()
    return {
        rotation = self.rotation,
        speed    = self.rotationSpeed
    }
end


-- ==========================================
-- SPACESHIP INPUT
-- ==========================================

function SpaceShip:input()
    if btn(BTN_P1_LEFT) then
        self.rotation = self.rotation - self.rotationSpeed
    end
    if btn(BTN_P1_RIGHT) then
        self.rotation = self.rotation + self.rotationSpeed
    end
    self.rotation = self:keepAngleInRange(self.rotation)
end


-- ==========================================
-- SPACESHIP UPDATE
-- ==========================================

function SpaceShip:wrapPosition()
    if (self.position.x >= EDGE_X_RIGHT) then
        self.position.x = 0
    elseif (self.position.x < 0) then
        self.position.x = EDGE_X_RIGHT - 1
    end

    if (self.position.y >= EDGE_Y_BOTTOM) then
        self.position.y = 0
    elseif (self.position.y < 0) then
        self.position.y = EDGE_Y_BOTTOM - 1
    end
    return self.position
end

function SpaceShip:thrust()
    local acceleration = {
        speed     = self.acceleration,
        direction = self.rotation
    }
    self.velocity = self:addVectors(self.velocity, acceleration)
end

function SpaceShip:move()
    if btn(BTN_P1_UP) then
        self:thrust()
    end

    self.velocity.speed = self.velocity.speed - self.deceleration
    if self.velocity.speed < 0 then
        self.velocity.speed = 0
    end

    self.position = self:movePointByVelocity()
    self.position = self:wrapPosition()
end


-- ==========================================
-- SPACESHIP DRAW
-- ==========================================

-- Draw the spaceship.
function SpaceShip:draw()
    local first_point = true
    local last_point = 0
    local rotated_point = 0
    for index, point in ipairs(self.shape) do
        rotated_point = self:rotatePoint(point, self.rotation)

        if first_point then
            last_point = rotated_point
            first_point = false
        else
            line(
                last_point.x + self.position.x,
                last_point.y + self.position.y,
                rotated_point.x + self.position.x,
                rotated_point.y + self.position.y,
                self.color
            )
            last_point = rotated_point
        end
    end
end
