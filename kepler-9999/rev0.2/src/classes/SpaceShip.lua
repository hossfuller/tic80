-- ==========================================
-- SPACESHIP OBJECT
-- ==========================================

SpaceShip = setmetatable({}, { __index = KeplerObj })
SpaceShip.__index = SpaceShip

function SpaceShip:new(params)
    params = params or {}
    local self = KeplerObj.new(params) -- build base fields
    setmetatable(self, SpaceShip)     -- make it a SpaceShip instance

    return self
end

-- ==========================================
-- SPACESHIP GETTERS
-- ==========================================

-- ==========================================
-- SPACESHIP INPUT
-- ==========================================

function SpaceShip:input()

end

-- ==========================================
-- SPACESHIP UPDATE
-- ==========================================

function SpaceShip:move()

end

-- ==========================================
-- SPACESHIP DRAW
-- ==========================================

function SpaceShip:draw()

end