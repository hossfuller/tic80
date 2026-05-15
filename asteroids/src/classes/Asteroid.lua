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
    self.radius       = params.radius       or 15
    self.radius_minus = params.radius_minus or 6
    self.radius_plus  = params.radius_plus  or 4
    self.num_vertices = params.num_vertices or 10
    self.shape        = params.shape or self:spawn()

    return self
end

-- ==========================================
-- ASTEROID MATH
-- ==========================================

-- ==========================================
-- ASTEROID GETTERS
-- ==========================================

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

    -- Insert first vertex using default radius.
    table.insert(vertices, { x = self.radius, y = 0 })

    -- Now do the vertices in between the first and last ones.
    for vertex = 1, (self.num_vertices - 1) do
        local radius = math.random(
            self.radius - self.radius_minus,
            self.radius + self.radius_plus
        )
        local angle = ((math.pi * 2) / self.num_vertices) * vertex
        local vector = {
            speed     = radius,
            direction = angle
        }
        local components = self:getVectorComponents(vector)
        table.insert(vertices, {
            x = components.xComp,
            y = components.yComp
        })
    end

    -- Last vertex is the same as the first vertex
    table.insert(vertices, { x = self.radius, y = 0 })

    return vertices
end

function Asteroid:move()
    self.rotation = self.rotation + self.rotationSpeed

    SpaceObj.move(self)
end

-- ==========================================
-- ASTEROID DRAW
-- ==========================================
