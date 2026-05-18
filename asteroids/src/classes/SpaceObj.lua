-- ==========================================
-- SPACEOBJ OBJECT
-- ==========================================

SpaceObj = {}
SpaceObj.__index = SpaceObj

function SpaceObj.new(params)
    params       = params or {}
    local self   = setmetatable({}, SpaceObj)

    self.color         = params.color or WHITE
    self.position      = {
        x = params.x or math.floor(EDGE_X_RIGHT / 2),
        y = params.y or math.floor(EDGE_Y_BOTTOM / 2)

    }
    self.velocity = {
        speed     = params.speed     or 0,
        direction = params.direction or 0,
    }
    self.acceleration  = params.acceleration  or 0.05
    self.deceleration  = params.deceleration  or 0.01
    self.rotation      = params.rotation      or 5
    self.rotationSpeed = params.rotationSpeed or 0.07
    self.shape         = params.shape         or {
        { x = 10,  y = 10  },
        { x = -10, y = 10  },
        { x = -10, y = -10 },
        { x = 10,  y = -10 },
    }
    self.timer = params.timer or 0

    return self
end

-- ==========================================
-- SPACEOBJ MATH
-- ==========================================

function SpaceObj:keepAngleInRange(angle)
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
function SpaceObj:rotatePoint(point, rotation)
    local rotated_x = (point.x * math.cos(rotation)) - (point.y * math.sin(rotation))
    local rotated_y = (point.y * math.cos(rotation)) + (point.x * math.sin(rotation))
    return { x = rotated_x, y = rotated_y }
end

function SpaceObj:getVectorComponents(vector)
    local xComp = vector.speed * math.cos(vector.direction)
    local yComp = vector.speed * math.sin(vector.direction)

    local components = {
        xComp = xComp,
        yComp = yComp
    }

    return components
end

function SpaceObj:addVectors(vector1, vector2)
    v1Comp = self:getVectorComponents(vector1)
    v2Comp = self:getVectorComponents(vector2)
    resultantX = v1Comp.xComp + v2Comp.xComp
    resultantY = v1Comp.yComp + v2Comp.yComp

    local resVector = self:compToVector(resultantX, resultantY)

    return resVector
end

function SpaceObj:compToVector(x, y)
    local magnitude = math.sqrt((x * x) + (y * y))
    local direction = math.atan(y, x)

    direction = self:keepAngleInRange(direction)

    local vector = {
        speed = magnitude,
        direction = direction
    }

    return vector
end

function SpaceObj:movePointByVelocity(obj)
    if obj == nil then
        obj = self
    end

    components = self:getVectorComponents(obj.velocity)

    local newPosition = {
        x = obj.position.x + components.xComp,
        y = obj.position.y + components.yComp
    }

    return newPosition
end


-- ==========================================
-- SPACEOBJ COLLISION DETECTION
-- ==========================================

function SpaceObj:checkSeparation(point1, point2, separation)
    -- leaving as squares removes need to do a sqrt
    local separationSq = separation * separation
    local distanceSq =
        ((point1.x - point2.x) * (point1.x - point2.x))
        + ((point1.y - point2.y) * (point1.y - point2.y))
    return (distanceSq <= separationSq)
end

function SpaceObj:pointInPolygon(point, shape)
    local first_point   = true
    local last_point    = 0
    local rotated_point = 0
    local on_right      = 0
    local on_left       = 0
    local x_crossing    = 0

    for index, shape_point in ipairs(shape.shape) do
        rotated_point = self:rotatePoint(shape_point, shape.rotation)

        if first_point then
            last_point  = rotated_point
            first_point = false
        else
            start_point = {
                x = last_point.x + shape.position.x,
                y = last_point.y + shape.position.y
            }
            end_point = {
                x = rotated_point.x + shape.position.x,
                y = rotated_point.y + shape.position.y
            }
            if (
                ((start_point.y >= point.y) and (end_point.y < point.y)) or
                ((start_point.y < point.y) and (end_point.y >= point.y))
            ) then
                -- line crosses ray
                if (start_point.x <= point.x) and (end_point.x <= point.x) then
                    -- line is to left
                    on_left = on_left + 1
                elseif (start_point.x >= point.x) and (end_point.x >= point.x) then
                    -- line is to right
                    on_right = on_right + 1
                else
                    -- need to calculate crossing x coordinate
                    if (start_point.y ~= end_point.y) then
                        -- filter out horizontal line
                        x_crossing = start_point.x + (
                            (point.y - start_point.y) * (end_point.x - start_point.x) / (end_point.y - start_point.y)
                        )
                        if (x_crossing >= point.x) then
                            on_right = on_right + 1
                        else
                            on_left = on_left + 1
                        end
                    end
                end
            end

            last_point = rotated_point
        end
    end

    -- only need to check on side
    if (on_right % 2) == 1 then
        -- odd = inside
        return true
    else
        return false
    end
end

-- ==========================================
-- SPACEOBJ GETTERS
-- ==========================================

function SpaceObj:getPosition()
    return self.position
end

function SpaceObj:getRotation()
    return {
        rotation = self.rotation,
        speed    = self.rotationSpeed
    }
end

function SpaceObj:getTimer()
    return self.timer
end

function SpaceObj:getVelocity()
    return self.velocity
end

-- Returns true every N ticks
function SpaceObj:everyNTicks(n)
    return (self.timer % n) == 0
end

-- ==========================================
-- SPACEOBJ INPUT
-- ==========================================

-- ==========================================
-- SPACEOBJ UPDATE
-- ==========================================

function SpaceObj:updateTimer()
    self.timer = (self.timer + 1) % 60
end

function SpaceObj:wrapPosition(obj)
    if obj == nil then
        obj = self
    end
    if (obj.position.x >= EDGE_X_RIGHT) then
        obj.position.x = 0
    elseif (obj.position.x < 0) then
        obj.position.x = EDGE_X_RIGHT - 1
    end

    if (obj.position.y >= EDGE_Y_BOTTOM) then
        obj.position.y = 0
    elseif (obj.position.y < 0) then
        obj.position.y = EDGE_Y_BOTTOM - 1
    end
    return obj.position
end

function SpaceObj:move()
    self.position = self:movePointByVelocity()
    self:wrapPosition() -- don't assign if wrapPosition returns nil
    self:updateTimer()
end

-- ==========================================
-- SPACEOBJ DRAW
-- ==========================================

-- Draw the SpaceObj.
function SpaceObj:draw()
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
