-- ==========================================
-- LASERBLAST OBJECT
-- ==========================================

LaserBlast = setmetatable({}, { __index = SpaceObj })
LaserBlast.__index = LaserBlast

function LaserBlast:new(params)
    params = params or {}
    local self = SpaceObj.new(params) -- build base fields
    setmetatable(self, LaserBlast)    -- make it a LaserBlast instance

    -- LASERBLAST-specific properties
    self.lifetime = params.lifetime or 60

    return self
end

-- ==========================================
-- LASERBLAST MATH
-- ==========================================

-- ==========================================
-- LASERBLAST GETTERS
-- ==========================================

-- ==========================================
-- LASERBLAST INPUT
-- ==========================================

-- ==========================================
-- LASERBLAST UPDATE
-- ==========================================

-- ==========================================
-- LASERBLAST DRAW
-- ==========================================
