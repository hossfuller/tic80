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

    self.dust_particles = {}

    self.dust = {
        colors = params.dust_colors or {
            GRAY_DARK,
            GRAY_MED,
            GRAY_LITE,
            self.colors.primary,
            self.colors.secondary,
        },
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

    return self
end

-- ==========================================
-- MOON GETTERS
-- ==========================================

function Moon:isFinished()
    return self.dead and self.dust_particles and #self.dust_particles <= 0
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

    -- Dust continues after death.
    self:updateDustParticles()

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
    if not self.dust then
        return
    end

    local dust = self.dust
    local count = math.random(dust.count_min, dust.count_max)

    for i = 1, count do
        local angle = randomFloat(0, math.pi * 2)
        local spawn_dist = randomFloat(0, dust.spawn_radius or self.radius or 8)

        local x = self.position.x + math.cos(angle) * spawn_dist
        local y = self.position.y + math.sin(angle) * spawn_dist

        local direction = randomFloat(0, math.pi * 2)
        local speed = randomFloat(dust.speed_min, dust.speed_max)
        local life = math.random(dust.life_min, dust.life_max)

        table.insert(self.dust_particles, {
            position = {
                x = x,
                y = y,
            },
            velocity = {
                speed = speed,
                direction = direction,
            },
            life = life,
            max_life = life,
            size = math.random(dust.size_min, dust.size_max),
            color = randomChoice(dust.colors),
            drag = dust.drag or 0.965,
        })
    end
end

function Moon:updateDustParticles()
    if not self.dust_particles then
        return
    end

    for i = #self.dust_particles, 1, -1 do
        local particle = self.dust_particles[i]

        particle.life = particle.life - 1

        if particle.life <= 0 then
            table.remove(self.dust_particles, i)
        else
            particle.velocity.speed = particle.velocity.speed * (particle.drag or 1)
            particle.velocity.direction = self:keepAngleInRange(
                particle.velocity.direction or 0
            )

            local components = self:getVectorComponents(particle.velocity)

            particle.position.x = particle.position.x + components.xComp
            particle.position.y = particle.position.y + components.yComp
        end
    end
end

function Moon:drawDustParticles()
    if not self.dust_particles then
        return
    end

    local zoom = game.camera.zoom or 1

    for _, particle in ipairs(self.dust_particles) do
        local screen_x, screen_y = worldToScreen(
            particle.position.x,
            particle.position.y
        )

        screen_x = math.floor(screen_x)
        screen_y = math.floor(screen_y)

        if screen_x >= -4 and screen_x <= SCREEN_W + 4 and
            screen_y >= -4 and screen_y <= SCREEN_H + 4 then
            local life_fraction = particle.life / particle.max_life
            local size = math.max(1, math.floor((particle.size or 1) * zoom))

            -- As the dust fades, make it visually smaller.
            if life_fraction < 0.35 then
                size = 1
            end

            if size <= 1 then
                pix(screen_x, screen_y, particle.color)
            else
                circ(screen_x, screen_y, size, particle.color)
            end
        end
    end
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
