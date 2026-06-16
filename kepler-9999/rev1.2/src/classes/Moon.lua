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

    params.mass        = params.mass or randomFloat(MOON_MIN_MASS, MOON_MASS)
    params.max_mass    = params.max_mass or params.mass
    params.radius_real = params.radius_real or randomFloat(100, 900)
    params.radius      = params.radius or Moon:getDrawRadiusFromRealRadius(params.radius_real)
    params.colors      = params.colors or randomMoonColorSet()

    -- Important:
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

    self.mineable = true

    self.fx = Particle:new({
        dust = makeParticleSystem(
            params.dust_colors or {
                GRAY_DARK,
                GRAY_MED,
                GRAY_LITE,
                self.colors.primary,
                self.colors.secondary,
            },
            {
                count_min    = params.dust_count_min or 35,
                count_max    = params.dust_count_max or 70,
                speed_min    = params.dust_speed_min or 0.15,
                speed_max    = params.dust_speed_max or 1.25,
                life_min     = params.dust_life_min or 35,
                life_max     = params.dust_life_max or 90,
                size_min     = params.dust_size_min or 1,
                size_max     = params.dust_size_max or 3,
                drag         = params.dust_drag or 0.965,
                spread       = math.pi * 2,
                spawn_radius = self.radius or 8,
            }
        ),
    })
    return self
end

-- ==========================================
-- MOON GETTERS
-- ==========================================

function Moon:isFinished()
    return self.dead and self.fx and not self.fx:hasLive("dust")
end

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

    -- Dust continues after death.
    self.fx:update("dust")

    -- Dead moons no longer orbit or update body position.
    if self.dead then
        return
    end

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
-- MOON PARTICLE EFFECTS
-- ==========================================

function Moon:explosionEffect()
    if not self.fx then
        return
    end

    self.fx:burst(
        "dust",
        self.position.x,
        self.position.y,
        {
            spread = math.pi * 2,
        }
    )
end

function Moon:drawDustParticles()
    if not self.fx then
        return
    end

    self.fx:draw("dust", {
        offscreen_pad = 4,
        shrink_when_fading = true,
    })
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
    -- Draw the moon body only while alive.
    if not self.dead then
        self:drawBody()
    end

    -- Dust can remain after the moon is dead.
    self:drawDustParticles()
end
