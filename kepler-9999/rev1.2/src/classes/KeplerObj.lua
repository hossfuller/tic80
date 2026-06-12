-- ==========================================
-- KEPLEROBJ OBJECT
-- ==========================================

KeplerObj = {}
KeplerObj.__index = KeplerObj

function KeplerObj:new(params)
    params = params or {}
    local self = setmetatable({}, KeplerObj)

    self.name = params.name or "Kepler System Object"

    local colors = params.colors or {}
    self.colors  = {
        primary   = colors.primary   or BLUE_MED,
        secondary = colors.secondary or WHITE,
        tertiary  = colors.tertiary  or YELLOW,
    }
    self.color = self.colors.primary    -- In case it's a one-color object.

    self.mass     = params.mass or 100                 -- (kg)
    self.max_mass = params.max_mass or self.mass or 1  -- (kg)
    self.radius   = params.radius or 10                -- (m)

    self.position = {
        x = params.x or math.floor(EDGE_X_RIGHT / 2),
        y = params.y or math.floor(EDGE_Y_BOTTOM / 2)
    }
    self.velocity = {
        speed     = params.speed     or 0,
        direction = params.direction or 0,
    }
    self.acceleration   = params.acceleration   or 0.05
    self.deceleration   = params.deceleration   or 0.01
    self.rotation       = params.rotation       or 5
    self.rotation_speed = params.rotation_speed or 0.07

    -- Gravity behavior.
    -- Objects with gravity_mass/exerts_gravity pull on other objects.
    -- Objects with affected_by_gravity get their velocity changed by gravity.
    self.exerts_gravity      = getOrDefault(params.exerts_gravity, true)
    self.affected_by_gravity = getOrDefault(params.affected_by_gravity, true)

    self.max_mass  = params.max_mass  or 1    -- (kg)
    self.max_speed = params.max_speed or 1.0

    -- By default all KeplerObj objects are not mineable. We'll change this on a
    -- object-by-object basis later.
    self.mineable = false

    -- For deflections: 1.0 = perfectly elastic, <1.0 loses speed
    -- More massive bodies have a higher elasticity. Smaller things like ships
    -- have tiny elasticity.
    self.elasticity = params.elasticity or 1.0

    -- Lifecycle state.
    -- dead:     The object should no longer update position/velocity.
    -- exploded: The object's explosion has already been triggered.
    self.dead     = params.dead or false
    self.exploded = params.exploded or false

    self.timer = params.timer or 0

    return self
end

-- ==========================================
-- KEPLEROBJ GETTERS
-- ==========================================

function KeplerObj:getTimer()
    return self.timer
end

-- Returns true every N ticks
function KeplerObj:everyNTicks(n)
    return (self.timer % n) == 0
end

function KeplerObj:getVelocity()
    return self.velocity.speed
end

function KeplerObj:getVelocityFraction()
    return self:getVelocity() / self.max_speed
end

function KeplerObj:isFinished()
    return self.dead
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
    local v1Comp = self:getVectorComponents(vector1)
    local v2Comp = self:getVectorComponents(vector2)

    local resultantX = v1Comp.xComp + v2Comp.xComp
    local resultantY = v1Comp.yComp + v2Comp.yComp

    local resVector = self:compToVector(resultantX, resultantY)

    return resVector
end

function KeplerObj:compToVector(x, y)
    local magnitude = math.sqrt((x * x) + (y * y))
    local direction = math.atan(y, x)

    direction = self:keepAngleInRange(direction)

    local vector = {
        speed     = magnitude,
        direction = direction
    }

    return vector
end

function KeplerObj:movePointByVelocity(obj)
    if obj == nil then
        obj = self
    end

    -- Dead objects do not update position.
    if obj.dead then
        return {
            x = obj.position.x,
            y = obj.position.y,
        }
    end

    local components  = self:getVectorComponents(obj.velocity)
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
-- KEPLEROBJ COLLISION DAMAGE
-- ==========================================

function KeplerObj:induceDamage(obj)
    if not obj then
        return 0
    end

    if self.dead or obj.dead then
        return 0
    end

    if not self.position or not obj.position then
        return 0
    end

    if not self.velocity then
        return 0
    end

    local self_comp = self:getVectorComponents(
        self.velocity or { speed = 0, direction = 0 }
    )

    local self_vx = self_comp.xComp
    local self_vy = self_comp.yComp

    local obj_vx = 0
    local obj_vy = 0

    if obj.getVectorComponents then
        local obj_comp = obj:getVectorComponents(
            obj.velocity or { speed = 0, direction = 0 }
        )

        obj_vx = obj_comp.xComp
        obj_vy = obj_comp.yComp
    elseif obj.velocity then
        obj_vx = math.cos(obj.velocity.direction or 0) * (obj.velocity.speed or 0)
        obj_vy = math.sin(obj.velocity.direction or 0) * (obj.velocity.speed or 0)
    end

    local rel_vx = self_vx - obj_vx
    local rel_vy = self_vy - obj_vy

    -- getCollisionNormal(obj, self) points from self toward obj.
    local nx, ny = getCollisionNormal(obj, self)

    -- Only the velocity component going into the collision counts.
    local inbound_speed = rel_vx * nx + rel_vy * ny

    if inbound_speed <= 0 then
        return 0
    end

    local mass = self.mass or 0

    return 0.5 * mass * inbound_speed * inbound_speed * COLLISION_DAMAGE_SCALE
end

function KeplerObj:takeDamage(damage, other)
    damage = damage or 0

    if self.dead then
        return false
    end

    if damage <= 0 then
        return false
    end

    self.mass = (self.mass or 0) - damage

    if self.mass <= 0 then
        self.mass = 0
        self:kill()
        return true
    end

    return false
end


-- ==========================================
-- KEPLEROBJ INPUT
-- ==========================================

-- ==========================================
-- KEPLEROBJ UPDATE
-- ==========================================

function KeplerObj:updateTimer()
    self.timer = (self.timer + 1) % 36000
end

function KeplerObj:move()
    if self.dead then
        return
    end
end

-- ==========================================
-- KEPLEROBJ LIFECYCLE
-- ==========================================

function KeplerObj:kill()
    if self.dead then
        return
    end
    self.dead = true
    return self:explode()
end

function KeplerObj:explode()
    if self.exploded then
        return
    end
    self.exploded = true
    self:explosionEffect()
    return self.dead and self.exploded
end

function KeplerObj:explosionEffect()
    -- Empty stub.
    -- Child objects can override this to spawn particles, fragments, sounds, etc.
end

-- ==========================================
-- KEPLEROBJ DRAW
-- ==========================================

function KeplerObj:drawBody()

end

function KeplerObj:draw()
    self:drawBody()

    -- Anything else to draw, like particle effects?
end