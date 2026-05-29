-- ==========================================
-- MOON OBJECT
-- ==========================================

Moon = setmetatable({}, { __index = KeplerObj })
Moon.__index = Moon

function Moon:new(params)
    params = params or {}

    -- -- Pick a stellar type if one was not supplied.
    -- params.stellar_type      = params.stellar_type or randomChoice(STELLAR_TYPES)

    -- -- Apply stellar-profile values before calling KeplerObj.new().
    -- local profile            = STELLAR_PROFILES[params.stellar_type] or STELLAR_PROFILES.G

    -- local mass_solar_units   = randomFloat(profile.mass_min, profile.mass_max)
    -- local radius_solar_units = randomFloat(profile.radius_min, profile.radius_max)

    -- params.mass              = params.mass or mass_solar_units * SOLAR_MASS
    -- params.radius_real       = params.radius_real or radius_solar_units * SOLAR_RADIUS
    -- params.temperature       = params.temperature or math.floor(randomFloat(profile.temp_min, profile.temp_max))

    -- -- Important:
    -- -- `radius` is currently used by drawBody() as a pixel radius.
    -- -- A real stellar radius would be enormous, so keep drawing radius separate.
    -- params.radius            = params.radius or Star:getDrawRadiusForType(params.stellar_type)

    -- params.colors            = params.colors or {
    --     primary   = profile.colors.primary,
    --     secondary = profile.colors.secondary,
    --     tertiary  = profile.colors.tertiary,
    -- }

    -- params.velocity          = {
    --     speed     = 0,
    --     direction = 0,
    -- }

    -- params.acceleration      = 0
    -- params.deceleration      = 0

    local self = KeplerObj.new(params)
    setmetatable(self, Moon)

    -- self.name               = params.name or "Kepler-9999"
    -- self.stellar_type       = params.stellar_type
    -- self.temperature        = params.temperature
    -- self.radius_real        = params.radius_real

    -- self.mass_solar         = mass_solar_units
    -- self.radius_solar       = radius_solar_units

    -- self.velocity.speed     = 0
    -- self.velocity.direction = 0
    -- self.acceleration       = 0
    -- self.deceleration       = 0

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
