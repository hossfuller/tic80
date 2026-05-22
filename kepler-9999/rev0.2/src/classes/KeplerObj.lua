-- ==========================================
-- KEPLEROBJ OBJECT
-- ==========================================

KeplerObj = {}
KeplerObj.__index = KeplerObj

function KeplerObj.new(params)
    params = params or {}
    local self = setmetatable({}, KeplerObj)

    self.mass   = params.mass or 100   -- (kg)
    self.radius = params.radius or 10  -- (m)

    self.position = {
        x = params.x or math.floor(EDGE_X_RIGHT / 2),
        y = params.y or math.floor(EDGE_Y_BOTTOM / 2)
    }
    self.velocity = {
        speed     = params.speed     or 0,
        direction = params.direction or 0,
    }
    self.acceleration   = params.acceleration or 0.05
    self.deceleration   = params.deceleration or 0.01
    self.rotation       = params.rotation or 5
    self.rotation_speed = params.rotation_speed or 0.07

    -- For deflections: 1.0 = perfectly elastic, <1.0 loses speed
    -- More massive bodies have a higher elasticity. Smaller things like ships
    -- have tiny elasticity.
    self.elasticity = params.elasticity or 1.0

    return self
end

-- ==========================================
-- KEPLEROBJ MATH
-- ==========================================

function KeplerObj:keepAngleInRange(angle)
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
function KeplerObj:rotatePoint(point, rotation)
    local rotated_x = (point.x * math.cos(rotation)) - (point.y * math.sin(rotation))
    local rotated_y = (point.y * math.cos(rotation)) + (point.x * math.sin(rotation))
    return { x = rotated_x, y = rotated_y }
end

function KeplerObj:getVectorComponents(vector)
    local xComp = vector.speed * math.cos(vector.direction)
    local yComp = vector.speed * math.sin(vector.direction)

    local components = {
        xComp = xComp,
        yComp = yComp
    }

    return components
end

function KeplerObj:addVectors(vector1, vector2)
    v1Comp = self:getVectorComponents(vector1)
    v2Comp = self:getVectorComponents(vector2)
    resultantX = v1Comp.xComp + v2Comp.xComp
    resultantY = v1Comp.yComp + v2Comp.yComp

    local resVector = self:compToVector(resultantX, resultantY)

    return resVector
end

function KeplerObj:compToVector(x, y)
    local magnitude = math.sqrt((x * x) + (y * y))
    local direction = math.atan(y, x)

    direction = self:keepAngleInRange(direction)

    local vector = {
        speed = magnitude,
        direction = direction
    }

    return vector
end

function KeplerObj:movePointByVelocity(obj)
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
-- KEPLEROBJ PHYSICS
-- ==========================================

-- ==========================================
-- KEPLEROBJ COLLISION DETECTION
-- ==========================================

-- Treat everything like a circle

-- Deflection only works on objects below a certain mass, with the object of the
-- lesser mass being deflected harder than the more massive object.

-- When there's a collision, calculate the energy of the collision and destroy
-- one or both objects depending on how massive the collision is.


-- ==========================================
-- KEPLEROBJ GETTERS
-- ==========================================

-- ==========================================
-- KEPLEROBJ INPUT
-- ==========================================

-- ==========================================
-- KEPLEROBJ UPDATE
-- ==========================================

function KeplerObj:move()
end

-- ==========================================
-- KEPLEROBJ DRAW
-- ==========================================

function KeplerObj:draw()
end

