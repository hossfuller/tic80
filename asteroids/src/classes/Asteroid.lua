-- ==========================================
-- ASTEROID OBJECT
-- ==========================================

Asteroid = setmetatable({}, { __index = SpaceObj })
Asteroid.__index = Asteroid

function Asteroid:new(params)
    params = params or {}
    local self = SpaceObj.new(params) -- build base fields
    setmetatable(self, Asteroid)          -- make it a Asteroid instance

    -- Asteroid-specific properties
    self.base_points  = params.base_points  or 50
    self.clumpiness   = params.clumpiness   or 0.35
    self.scale        = params.scale        or 1  -- set this first!
    self.num_vertices = params.num_vertices or 10
    self.radius       = params.radius       or self.radius or 15
    self.radius_minus = params.radius_minus or 6
    self.radius_plus  = params.radius_plus  or 4
    self.rotation_max = params.rotation_max or 0.03
    self.velocity_max = params.velocity_max or 0.5
    self.velocity_min = params.velocity_min or 0.1
    self.shape        = params.shape        or self:spawn()

    return self
end

-- ==========================================
-- ASTEROID MATH
-- ==========================================

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
        minus = self.radius_minus
    }
end

-- ==========================================
-- ASTEROID INPUT
-- ==========================================

-- ==========================================
-- ASTEROID UPDATE
-- ==========================================

-- Generates Asteroid shape. Called by default when creating an asteroid with
-- default shape settings.
function Asteroid:spawn()
    local vertices = {}

    local baseR    = self.radius
    -- scale the "clumpiness" with size
    local minus    = math.min(self.radius_minus, baseR * self.clumpiness)
    local plus     = math.min(self.radius_plus, baseR * self.clumpiness)

    table.insert(vertices, { x = baseR, y = 0 })

    for vertex = 1, (self.num_vertices - 1) do
        local minr = math.max(1, baseR - minus) -- never <= 0
        local maxr = math.max(minr + 0.01, baseR + plus)

        local r = minr + math.random() * (maxr - minr)
        local a = (math.pi * 2 / self.num_vertices) * vertex

        table.insert(vertices, { x = r * math.cos(a), y = r * math.sin(a) })
    end

    table.insert(vertices, { x = baseR, y = 0 })
    return vertices
end

function Asteroid:move()
    self.rotation = self.rotation + self.rotation_speed

    SpaceObj.move(self)
end

-- ==========================================
-- ASTEROID DRAW
-- ==========================================

function Asteroid:explode()
    local position      = self.position
    local orig_scale    = self.scale

    local asteroid_fragments = {}

    if orig_scale < 4 then
        local new_scale = orig_scale * 2
        for count = 1, 2 do
            local asteroid = Asteroid:new({
                color          = self.color,
                x              = self.position.x,
                y              = self.position.y,
                speed          = (math.random() * (self.velocity_max - self.velocity_min)) + self.velocity_min,
                direction      = math.random() * math.pi * 2,
                acceleration   = self.acceleration,
                deceleration   = self.deceleration,
                elasticity     = self.elasticity,
                scale          = new_scale,
                rotation_speed = (math.random() * (2 * self.rotation_max)) - self.rotation_max,
                radius         = self.radius / new_scale,
                radius_minus   = self.radius_minus,
                radius_plus    = self.radius_plus,
                num_vertices   = self.num_vertices,
            })
            table.insert(asteroid_fragments, asteroid)
        end
    end

    sfx(1, 1, 15, 1, 15)

    return asteroid_fragments
end
