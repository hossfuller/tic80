-- ==========================================
-- ASTEROID OBJECT
-- ==========================================

Asteroid = setmetatable({}, { __index = KeplerObj })
Asteroid.__index = Asteroid

function Asteroid:new(params)
    params = params or {}

    params.mass   = params.mass or randomFloat(ASTEROID_MIN_MASS, ASTEROID_MAX_MASS)
    params.radius = params.radius or randomFloat(ASTEROID_RADIUS_MIN, ASTEROID_RADIUS_MAX)
    params.color  = params.color or randomChoice(ASTEROID_COLORS)

    local direction     = params.direction or randomFloat(0, math.pi * 2)
    local speed         = params.speed or randomFloat(ASTEROID_SPEED_MIN, ASTEROID_SPEED_MAX)
    params.direction    = direction
    params.speed        = speed
    params.acceleration = params.acceleration or 0
    params.deceleration = params.deceleration or 0

    local self = KeplerObj:new(params)
    setmetatable(self, Asteroid)

    self.name = params.name or "Asteroid"

    -- Asteroid-specific properties, adapted from your old class.
    -- self.base_points    = params.base_points or 50
    self.clumpiness   = params.clumpiness or 0.35
    self.scale        = params.scale or 1
    self.num_vertices = params.num_vertices or math.random(ASTEROID_VERTICES_MIN, ASTEROID_VERTICES_MAX)

    self.radius       = params.radius or self.radius or 15
    self.radius_minus = params.radius_minus or ASTEROID_RADIUS_MINUS
    self.radius_plus  = params.radius_plus or ASTEROID_RADIUS_PLUS

    self.rotation       = params.rotation or randomFloat(0, math.pi * 2)
    self.rotation_max   = params.rotation_max or ASTEROID_ROTATION_MAX
    self.rotation_speed = params.rotation_speed or randomFloat(
        -self.rotation_max,
        self.rotation_max
    )

    self.velocity_min = params.velocity_min or ASTEROID_SPEED_MIN
    self.velocity_max = params.velocity_max or ASTEROID_SPEED_MAX

    -- Stable polygon shape.
    self.shape = params.shape or self:spawn()

    self.destroyed = false

    return self
end

-- ==========================================
-- ASTEROID GETTERS
-- ==========================================

function Asteroid:getInducedDamage()
    return self.radius * 10
end

function Asteroid:getPoints()
    return self.base_points * self.scale
end

function Asteroid:getRadius()
    return self.radius
end

function Asteroid:getScale()
    return self.scale
end

function Asteroid:getRadiusPlusMinus()
    return {
        plus  = self.radius_plus,
        minus = self.radius_minus,
    }
end

function Asteroid:isFinished()
    return self.destroyed
end

function Asteroid:isOffMap()
    local padding = self.radius + 80

    return
        self.position.x < -padding or
        self.position.x > MAP_PIXELS_W + padding or
        self.position.y < -padding or
        self.position.y > MAP_PIXELS_H + padding
end

-- ==========================================
-- ASTEROID SHAPE
-- ==========================================

function Asteroid:spawn()
    local vertices = {}

    local baseR    = self.radius

    -- Scale the "clumpiness" with size.
    local minus    = math.min(self.radius_minus, baseR * self.clumpiness)
    local plus     = math.min(self.radius_plus, baseR * self.clumpiness)

    table.insert(vertices, { x = baseR, y = 0 })

    for vertex = 1, self.num_vertices - 1 do
        local minr = math.max(1, baseR - minus)
        local maxr = math.max(minr + 0.01, baseR + plus)

        local r = randomFloat(minr, maxr)
        local a = (math.pi * 2 / self.num_vertices) * vertex

        table.insert(vertices, {
            x = r * math.cos(a),
            y = r * math.sin(a),
        })
    end

    table.insert(vertices, { x = baseR, y = 0 })

    return vertices
end

-- ==========================================
-- ASTEROID UPDATE
-- ==========================================

function Asteroid:destroy()
    self.destroyed = true
end

function Asteroid:move()
    local components = self:getVectorComponents(self.velocity)

    self.position.x = self.position.x + components.xComp
    self.position.y = self.position.y + components.yComp

    self.rotation = self.rotation + self.rotation_speed
end

function Asteroid:update()
    self:updateTimer()

    if not self.destroyed then
        self:move()
    end
end

-- ==========================================
-- ASTEROID EXPLOSION
-- ==========================================

function Asteroid:explode()
    local asteroid_fragments = {}

    local orig_scale = self.scale or 1

    if orig_scale < ASTEROID_MAX_FRAGMENT_SCALE then
        local new_scale = orig_scale * 2

        for count = 1, 2 do
            local fragment_radius = math.max(2, self.radius / new_scale)

            local asteroid = Asteroid:new({
                name           = "Asteroid Fragment",
                color          = self.color,
                x              = self.position.x,
                y              = self.position.y,

                speed          = randomFloat(self.velocity_min, self.velocity_max),
                direction      = randomFloat(0, math.pi * 2),

                acceleration   = self.acceleration,
                deceleration   = self.deceleration,
                elasticity     = self.elasticity,

                scale          = new_scale,

                rotation_speed = randomFloat(
                    -self.rotation_max,
                    self.rotation_max
                ),

                radius         = fragment_radius,
                radius_minus   = self.radius_minus,
                radius_plus    = self.radius_plus,
                num_vertices   = self.num_vertices,

                base_points    = self.base_points,
                clumpiness     = self.clumpiness,
            })

            table.insert(asteroid_fragments, asteroid)
        end
    end

    self:destroy()

    return asteroid_fragments
end

-- ==========================================
-- ASTEROID DRAW
-- ==========================================

function Asteroid:getRotatedPoint(point)
    local cos_r = math.cos(self.rotation)
    local sin_r = math.sin(self.rotation)

    return {
        x = point.x * cos_r - point.y * sin_r,
        y = point.x * sin_r + point.y * cos_r,
    }
end

function Asteroid:draw()
    if self.destroyed then
        return
    end

    local zoom = game.camera.zoom or 1

    local screen_x, screen_y = worldToScreen(self.position.x, self.position.y)

    local screen_radius = self.radius * zoom

    if screen_x < -screen_radius - 8 or
        screen_x > SCREEN_W + screen_radius + 8 or
        screen_y < -screen_radius - 8 or
        screen_y > SCREEN_H + screen_radius + 8 then
        return
    end

    local cx = math.floor(screen_x)
    local cy = math.floor(screen_y)

    for i = 1, #self.shape - 1 do
        local p1 = self:getRotatedPoint(self.shape[i])
        local p2 = self:getRotatedPoint(self.shape[i + 1])

        local x1 = math.floor(screen_x + p1.x * zoom)
        local y1 = math.floor(screen_y + p1.y * zoom)
        local x2 = math.floor(screen_x + p2.x * zoom)
        local y2 = math.floor(screen_y + p2.y * zoom)

        tri(cx, cy, x1, y1, x2, y2, self.color)
        line(x1, y1, x2, y2, GRAY_LITE)
    end
end
