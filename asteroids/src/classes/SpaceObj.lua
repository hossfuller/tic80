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
    self.acceleration   = params.acceleration   or 0.05
    self.deceleration   = params.deceleration   or 0.01
    self.rotation       = params.rotation       or 5
    self.rotation_speed = params.rotation_speed or 0.07
    self.radius         = params.radius         or 10
    self.shape          = params.shape          or {
        { x = 10,  y = 10  },
        { x = -10, y = 10  },
        { x = -10, y = -10 },
        { x = 10,  y = -10 },
    }
    self.timer = params.timer or 0

    -- For deflections: 1.0 = perfectly elastic, <1.0 loses speed
    self.elasticity = params.elasticity or 0.95

    -- Particle Effects
    self.TYPES = {
        EXPLOSION = "EXPLOSION",
        LASER_HIT = "LASER_HIT",
        THRUST    = "THRUST",
    }
    self.EXPLOSION_COLORS   = { YELLOW, ORANGE, RED }
    self.SMOKE_COLORS       = { YELLOW, ORANGE, RED, GRAY_LITE, GRAY_MED, GRAY_DARK }

    self.explosionParticles = {}
    self.laserHitParticles  = {}
    self.thrustParticles    = {}

    self.max_lifetime  = 30
    self.max_size      = 3
    self.max_speed     = 2
    self.num_particles = 60
    self.type          = nil

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
-- Had to use AI to resolve some bugs, and hooo-boy, it got wild.
-- ==========================================

function SpaceObj:getBoundingRadius()
    local r2 = 0
    for _, p in ipairs(self.shape) do
        local d2 = p.x * p.x + p.y * p.y
        if d2 > r2 then r2 = d2 end
    end
    return math.sqrt(r2) - 2
end

function SpaceObj:collidesCircle(other)
    local ra = self:getBoundingRadius()
    local rb = other:getBoundingRadius()
    return self:checkSeparation(self.position, other.position, ra + rb)
end

function SpaceObj:checkSeparation(point1, point2, separation)
    -- leaving as squares removes need to do a sqrt
    local separationSq = separation * separation
    local distanceSq =
        ((point1.x - point2.x) * (point1.x - point2.x))
        + ((point1.y - point2.y) * (point1.y - point2.y))
    return (distanceSq <= separationSq)
end

function SpaceObj:separateFrom(other)
    local ra = self:getBoundingRadius()
    local rb = other:getBoundingRadius()

    local dx = self.position.x - other.position.x
    local dy = self.position.y - other.position.y
    local d = math.sqrt(dx * dx + dy * dy)

    if d < 1e-6 then
        dx, dy, d = 1, 0, 1
    end

    local overlap = (ra + rb) - d
    if overlap <= 0 then return end

    local nx, ny     = dx / d, dy / d
    local push       = overlap * 0.5 + 0.01 -- +epsilon helps prevent re-penetration

    self.position.x  = self.position.x + nx * push
    self.position.y  = self.position.y + ny * push
    other.position.x = other.position.x - nx * push
    other.position.y = other.position.y - ny * push
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

function SpaceObj:polygonInPolygon(a, b)
    local ra = a:getBoundingRadius()
    local rb = b:getBoundingRadius()

    if not self:checkSeparation(a.position, b.position, ra + rb) then
        return false
    end

    for _, lp in ipairs(a.shape) do
        local rp = self:rotatePoint(lp, a.rotation)
        local wp = { x = rp.x + a.position.x, y = rp.y + a.position.y }
        if self:pointInPolygon(wp, b) then return true end
    end

    for _, lp in ipairs(b.shape) do
        local rp = self:rotatePoint(lp, b.rotation)
        local wp = { x = rp.x + b.position.x, y = rp.y + b.position.y }
        if self:pointInPolygon(wp, a) then return true end
    end

    return false
end

function SpaceObj:checkCollision(colliding_obj)
    return self:polygonInPolygon(self, colliding_obj)
end

function SpaceObj:deflect(other)
    -- self.elasticity: 1.0 = perfectly elastic, <1.0 loses speed
    local vx = self.velocity.speed * math.cos(self.velocity.direction)
    local vy = self.velocity.speed * math.sin(self.velocity.direction)

    -- If we don't know what we hit, just reverse.
    if not other or not other.position then
        vx, vy = -vx, -vy
    else
        -- Collision normal: from other -> self (center-to-center)
        local nx = self.position.x - other.position.x
        local ny = self.position.y - other.position.y
        local nlen = math.sqrt(nx * nx + ny * ny)

        -- If centers coincide, pick any normal
        if nlen < 1e-6 then
            nx, ny, nlen = 1, 0, 1
        end

        nx, ny = nx / nlen, ny / nlen

        -- Reflect v about normal n:
        -- v' = v - 2*(v·n)*n
        local dot = vx * nx + vy * ny
        vx = vx - 2 * dot * nx
        vy = vy - 2 * dot * ny
    end

    -- Apply self.elasticity
    vx = vx * self.elasticity
    vy = vy * self.elasticity

    -- Convert back to your polar velocity representation
    local speed = math.sqrt(vx * vx + vy * vy)
    local dir = math.atan(vy, vx)
    dir = self:keepAngleInRange(dir)

    -- Clamp speed if you want to keep within your configured limits
    if self.velocity_max then speed = math.min(speed, self.velocity_max) end
    if self.velocity_min then speed = math.max(speed, self.velocity_min) end

    self.velocity.speed = speed
    self.velocity.direction = dir

    -- Small positional nudge along the new direction to reduce "sticking"
    self.position.x = self.position.x + math.cos(dir) * 0.5
    self.position.y = self.position.y + math.sin(dir) * 0.5
end

function SpaceObj:resolveCollision(other)
    if not other then return false end

    -- broad-phase (circle)
    if not self:collidesCircle(other) then
        return false
    end

    -- separate first to prevent sticking/spinning
    self:separateFrom(other)

    -- reflect both velocities using your existing deflect()
    self:deflect(other)
    other:deflect(self)

    return true
end

-- ==========================================
-- SPACEOBJ PARTICLE EFFECTS
-- ==========================================

function SpaceObj:explosionEffect()
    self.type          = self.TYPES.EXPLOSION
    self.deceleration  = 0.015
    self.max_lifetime  = 90
    self.max_size      = 3
    self.max_speed     = 2
    self.num_particles = 100

    local particle_velocity = {}
    for particle = 1, self.num_particles do
        particle_velocity = {
            speed     = math.random() * self.max_speed,
            direction = math.random() * math.pi * 2
        }
        self:spawnParticle(
            self.position,
            particle_velocity,
            self.max_lifetime,
            self.EXPLOSION_COLORS,
            self.max_size,
            self.deceleration,
            self.type
        )
    end
end

function SpaceObj:laserHitEffect(position)
    self.type          = self.TYPES.LASER_HIT
    self.deceleration  = 0.01
    self.max_lifetime  = 30
    self.max_size      = 3
    self.max_speed     = 1
    self.num_particles = 60

    -- Fallback in case no position is passed
    position = position or self.position

    for particle = 1, self.num_particles do
        local particle_velocity = {
            speed     = math.random() * self.max_speed,
            direction = math.random() * math.pi * 2
        }

        self:spawnParticle(
            position,
            particle_velocity,
            self.max_lifetime,
            self.EXPLOSION_COLORS,
            self.max_size,
            self.deceleration,
            self.type
        )
    end
end

function SpaceObj:thrustEffect()
    -- Effect-specific overrides
    self.type          = self.TYPES.THRUST
    self.deceleration  = 0.01
    self.max_lifetime  = 30
    self.max_size      = 1
    self.max_speed     = 2
    self.num_particles = 5

    local thrust_offset           = { x = -5, y = 0 }
    local particle_velocity       = {}
    local direction               = 0
    local relative_spawn_position = self:rotatePoint(thrust_offset, self.rotation)
    local spawn_position          = {
        x = relative_spawn_position.x + self.position.x,
        y = relative_spawn_position.y + self.position.y,
    }

    for particle = 1, self.num_particles do
        direction = self.rotation + math.pi + (math.random() * math.pi / 6) - (math.pi / 12)
        direction = self:keepAngleInRange(direction)
        particle_velocity = {
            speed     = math.random() * self.max_speed,
            direction = direction
        }
        self:spawnParticle(
            spawn_position,
            particle_velocity,
            self.max_lifetime,
            self.SMOKE_COLORS,
            self.max_size,
            self.deceleration,
            self.type
        )
    end
end

function SpaceObj:spawnParticle(
    position,
    velocity,
    max_lifetime,
    colors,
    max_size,
    deceleration,
    particle_type
)
    local particle = {
        position     = {
            x = position.x,
            y = position.y
        },
        velocity     = {
            speed     = velocity.speed,
            direction = velocity.direction
        },
        life_timer   = (max_lifetime / 2) + (math.random() * max_lifetime / 2),
        colors       = colors,
        size         = math.random(1, max_size),
        deceleration = deceleration,
        type         = particle_type
    }

    if particle_type == self.TYPES.EXPLOSION then
        table.insert(self.explosionParticles, particle)
    elseif particle_type == self.TYPES.LASER_HIT then
        table.insert(self.laserHitParticles, particle)
    elseif particle_type == self.TYPES.THRUST then
        table.insert(self.thrustParticles, particle)
    end
end

function SpaceObj:moveParticles(particle_type)
    local particles = self.explosionParticles

    if particle_type == self.TYPES.LASER_HIT then
        particles = self.laserHitParticles
    elseif particle_type == self.TYPES.THRUST then
        particles = self.thrustParticles
    end

    for index = #particles, 1, -1 do
        local particle = particles[index]

        particle.life_timer = particle.life_timer - 1

        if particle.life_timer < 0 then
            table.remove(particles, index)
        else
            particle.position = self:movePointByVelocity(particle)

            particle.velocity.speed = particle.velocity.speed - particle.deceleration
            if particle.velocity.speed < 0 then
                particle.velocity.speed = 0
            end
        end
    end
end

function SpaceObj:drawParticles(particle_type)
    local particles = self.explosionParticles

    if particle_type == self.TYPES.LASER_HIT then
        particles = self.laserHitParticles
    elseif particle_type == self.TYPES.THRUST then
        particles = self.thrustParticles
    end

    for index, particle in ipairs(particles) do
        local particle_color = particle.colors[math.random(1, #particle.colors)]

        if particle.type == self.TYPES.EXPLOSION or particle.type == self.TYPES.LASER_HIT then
            circ(particle.position.x, particle.position.y, particle.size, particle_color)
        elseif particle.type == self.TYPES.THRUST then
            pix(particle.position.x, particle.position.y, particle_color)
        else
            rect(particle.position.x, particle.position.y, particle.size, particle.size, particle_color)
        end
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
        speed    = self.rotation_speed
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

    -- Move any particles on the board!
    self:moveParticles(self.TYPES.EXPLOSION)
    self:moveParticles(self.TYPES.LASER_HIT)
    self:moveParticles(self.TYPES.THRUST)
end

-- ==========================================
-- SPACEOBJ DRAW
-- ==========================================

function SpaceObj:drawBody()
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

function SpaceObj:draw()
    self:drawBody()

    self:drawParticles(self.TYPES.EXPLOSION)
    self:drawParticles(self.TYPES.LASER_HIT)
    self:drawParticles(self.TYPES.THRUST)
end

function SpaceObj:explode()
    -- All space objects explode. How is another matter.
end
