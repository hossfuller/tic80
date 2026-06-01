-- ==========================================
-- MOON OBJECT
-- ==========================================

Moon = setmetatable({}, { __index = Planet })
Moon.__index = Moon

function Moon:new(params)
    params = params or {}

    local self = Planet.new(params)
    setmetatable(self, Moon)

    return self
end

-- ==========================================
-- MOON GETTERS
-- ==========================================

-- ==========================================
-- MOON MATH
-- ==========================================

-- ==========================================
-- MOON PHYSICS
-- ==========================================

-- ==========================================
-- MOON COLLISION DETECTION
-- ==========================================

-- Treat everything like a circle

-- Deflection only works on objects below a certain mass, with the object of the
-- lesser mass being deflected harder than the more massive object.

-- When there's a collision, calculate the energy of the collision and destroy
-- one or both objects depending on how massive the collision is.

-- ==========================================
-- MOON INPUT
-- ==========================================

-- ==========================================
-- MOON UPDATE
-- ==========================================


-- ==========================================
-- MOON DRAW
-- ==========================================

function Moon:drawBody()

end

function Moon:draw()
    self:drawBody()
end
