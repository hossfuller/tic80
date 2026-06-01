-- ==========================================
-- MOON OBJECT
-- ==========================================

Moon = setmetatable({}, { __index = Planet })
Moon.__index = Moon

function Moon:new(params)
    params = params or {}

    params.has_atmosphere = false
    params.has_ring = false
    params.num_rings = 0

    params.mass = params.mass or randomFloat(MOON_MIN_MASS, MOON_MASS)

    params.radius_real = params.radius_real or randomFloat(100, 900)
    params.radius = params.radius or Moon:getDrawRadiusFromRealRadius(params.radius_real)

    params.colors = params.colors or randomMoonColorSet()

    -- Important:
    -- Planet:new is defined with colon syntax, so call it using colon syntax.
    local self = Planet:new(params)
    setmetatable(self, Moon)

    self.name = params.name or "Moon"
    self.host = params.host

    self.has_atmosphere = false
    self.has_ring = false
    self.num_rings = 0

    local orbit = params.orbit or {}

    self.orbit = {
        semi_major   = orbit.semi_major or 100,
        eccentricity = orbit.eccentricity or randomFloat(0.05, 0.55),
        angle        = orbit.angle or randomFloat(0, math.pi * 2),
        phase        = orbit.phase or randomFloat(0, math.pi * 2),
        period       = orbit.period or math.random(900, 3600),
    }

    self.orbit.semi_minor =
        self.orbit.semi_major *
        math.sqrt(1 - self.orbit.eccentricity * self.orbit.eccentricity)

    return self
end

-- ==========================================
-- MOON GETTERS
-- ==========================================

-- ==========================================
-- MOON UPDATE
-- ==========================================

function Moon:updateOrbitPosition(focus)
    if not focus then
        return
    end

    local orbit = self.orbit

    local a = orbit.semi_major
    local b = orbit.semi_minor
    local e = orbit.eccentricity

    -- Treat phase as eccentric anomaly.
    local E = orbit.phase

    -- Ellipse relative to one focus.
    -- Center-relative ellipse:
    --   x = a * cos(E)
    --   y = b * sin(E)
    --
    -- Focus-relative version shifts x by -a*e.
    local local_x = a * math.cos(E) - a * e
    local local_y = b * math.sin(E)

    -- Used only for draw order.
    -- Negative means "behind" the planet, positive means "in front".
    self.orbit_depth = local_y

    -- Rotate ellipse.
    local cos_a = math.cos(orbit.angle)
    local sin_a = math.sin(orbit.angle)

    local rotated_x = local_x * cos_a - local_y * sin_a
    local rotated_y = local_x * sin_a + local_y * cos_a

    self.position.x = focus.x + rotated_x
    self.position.y = focus.y + rotated_y
end

function Moon:update()
    self:updateTimer()

    if not self.host then
        return
    end

    local focus = self.host.barycenter or self.host.position

    self.orbit.phase = self.orbit.phase + ((math.pi * 2) / self.orbit.period)

    if self.orbit.phase > math.pi * 2 then
        self.orbit.phase = self.orbit.phase - math.pi * 2
    end

    self:updateOrbitPosition(focus)
end

-- ==========================================
-- MOON DRAW
-- ==========================================

function Moon:getDrawRadiusFromRealRadius(radius_real)
    -- Moon real radius range: 100..900.
    -- Draw radius range: 4..12 pixels.
    local min_real_radius = 100
    local max_real_radius = 900

    local min_draw_radius = 4
    local max_draw_radius = 12

    radius_real = radius_real or min_real_radius

    local t = (radius_real - min_real_radius) / (max_real_radius - min_real_radius)
    t = clamp(t, 0, 1)

    return math.floor(min_draw_radius + t * (max_draw_radius - min_draw_radius))
end

function Moon:drawBody()
    local zoom = game.camera.zoom or 1

    local screen_x, screen_y = worldToScreen(self.position.x, self.position.y)

    screen_x = math.floor(screen_x)
    screen_y = math.floor(screen_y)

    -- Keep moons visible at low zoom.
    local r = math.max(1, math.floor(self.radius * zoom))

    -- Skip if comfortably off-screen.
    if screen_x < -r - 4 or screen_x > SCREEN_W + r + 4 or
        screen_y < -r - 4 or screen_y > SCREEN_H + r + 4 then
        return
    end

    circ(screen_x, screen_y, r, self.colors.primary)

    -- Only draw crater detail when the moon is large enough to show it.
    if r >= 4 then
        self:drawCraters(screen_x, screen_y, r, zoom)
    end
end

function Moon:drawLabel()
    -- No labels for moons for now.
end

function Moon:draw()
    self:drawBody()
end
