-- ==========================================
-- STAR OBJECT
-- ==========================================

Star = setmetatable({}, { __index = KeplerObj })
Star.__index = Star

function Star:new(params)
    params = params or {}

    -- Pick a stellar type if one was not supplied.
    params.stellar_type = params.stellar_type or randomChoice(STELLAR_TYPES)

    -- Apply stellar-profile values before calling KeplerObj.new().
    local profile = STELLAR_PROFILES[params.stellar_type] or STELLAR_PROFILES.G

    local mass_solar_units   = randomFloat(profile.mass_min, profile.mass_max)
    local radius_solar_units = randomFloat(profile.radius_min, profile.radius_max)

    params.mass        = params.mass or mass_solar_units * SOLAR_MASS
    params.radius_real = params.radius_real or radius_solar_units * SOLAR_RADIUS
    params.temperature = params.temperature or math.floor(randomFloat(profile.temp_min, profile.temp_max))

    -- Important:
    -- `radius` is currently used by drawBody() as a pixel radius.
    -- A real stellar radius would be enormous, so keep drawing radius separate.
    params.radius = params.radius or Star:getDrawRadiusForType(params.stellar_type)

    params.colors = params.colors or {
        primary   = profile.colors.primary,
        secondary = profile.colors.secondary,
        tertiary  = profile.colors.tertiary,
    }

    params.velocity = {
        speed     = 0,
        direction = 0,
    }

    params.acceleration = 0
    params.deceleration = 0

    local self = KeplerObj.new(params)
    setmetatable(self, Star)

    self.name               = params.name or "Kepler-9999"
    self.stellar_type       = params.stellar_type
    self.temperature        = params.temperature
    self.radius_real        = params.radius_real

    self.mass_solar         = mass_solar_units
    self.radius_solar       = radius_solar_units

    self.velocity.speed     = 0
    self.velocity.direction = 0
    self.acceleration       = 0
    self.deceleration       = 0

    self.particles          = {
        wind = {
            particles = {},
            spawn_chance = 0.45, -- Chance per update frame.
            speed_min = 0.15,
            speed_max = 0.45,
            max_distance_multiplier = 2,
            colors = {
                self.colors.secondary,
                self.colors.tertiary,
            },
        },

        flare = {
            particles = {},
            spawn_chance = 0.015, -- Much rarer than wind.
            particles_per_flare_min = 8,
            particles_per_flare_max = 18,
            speed_min = 0.55,
            speed_max = 1.25,
            angle_spread = math.pi / 7,
            max_distance_multiplier = 4,
            colors = {
                self.colors.primary,
                self.colors.secondary,
                self.colors.tertiary,
                WHITE,
            },
        },
    }

    return self
end


-- ==========================================
-- STAR GETTERS
-- ==========================================

-- ==========================================
-- STAR MATH
-- ==========================================

-- ==========================================
-- STAR PHYSICS
-- ==========================================

-- ==========================================
-- STAR COLLISION DETECTION
-- ==========================================

-- Treat everything like a circle

-- Deflection only works on objects below a certain mass, with the object of the
-- lesser mass being deflected harder than the more massive object.

-- When there's a collision, calculate the energy of the collision and destroy
-- one or both objects depending on how massive the collision is.

-- ==========================================
-- STAR INPUT
-- ==========================================

-- ==========================================
-- STAR UPDATE
-- ==========================================

function Star:spawnWindParticle()
    local system = self.particles.wind

    local angle = randomFloat(0, math.pi * 2)

    -- Start exactly on the star surface.
    local start_x = self.position.x + math.cos(angle) * self.radius
    local start_y = self.position.y + math.sin(angle) * self.radius

    local speed = randomFloat(system.speed_min, system.speed_max)
    local max_distance = self.radius * system.max_distance_multiplier

    local particle = {
        x            = start_x,
        y            = start_y,
        origin_x     = start_x,
        origin_y     = start_y,
        direction    = angle,
        speed        = speed,
        max_distance = max_distance,
        color        = randomChoice(system.colors),
        size         = 1,
    }

    table.insert(system.particles, particle)
end

function Star:spawnFlare()
    local system = self.particles.flare

    -- One surface location for the whole flare clump.
    local base_angle = randomFloat(0, math.pi * 2)

    local start_x = self.position.x + math.cos(base_angle) * self.radius
    local start_y = self.position.y + math.sin(base_angle) * self.radius

    local count = math.random(
        system.particles_per_flare_min,
        system.particles_per_flare_max
    )

    for i = 1, count do
        local angle_offset = randomFloat(-system.angle_spread, system.angle_spread)
        local direction = base_angle + angle_offset

        local speed = randomFloat(system.speed_min, system.speed_max)

        -- Each particle can die at a different range up to 4x radius.
        local max_distance = randomFloat(
            self.radius * 1.1,
            self.radius * system.max_distance_multiplier
        )

        local particle = {
            x = start_x,
            y = start_y,
            origin_x = start_x,
            origin_y = start_y,
            direction = direction,
            speed = speed,
            max_distance = max_distance,
            color = randomChoice(system.colors),
            size = math.random(1, 2), -- Some flare particles are slightly larger.
            evaporate_chance = randomFloat(0.005, 0.025), -- Random evaporation chance per frame.
        }
        table.insert(system.particles, particle)
    end
end

function Star:updateParticleList(particles, evaporates)
    for i = #particles, 1, -1 do
        local particle = particles[i]

        particle.x = particle.x + math.cos(particle.direction) * particle.speed
        particle.y = particle.y + math.sin(particle.direction) * particle.speed

        local dx = particle.x - particle.origin_x
        local dy = particle.y - particle.origin_y
        local distance = math.sqrt(dx * dx + dy * dy)

        local remove_particle = false

        if distance >= particle.max_distance then
            remove_particle = true
        end

        -- Flares can randomly evaporate before reaching max distance.
        if evaporates and particle.evaporate_chance then
            if math.random() < particle.evaporate_chance then
                remove_particle = true
            end
        end

        if remove_particle then
            table.remove(particles, i)
        end
    end
end

function Star:update()
    self:updateTimer()

    -- Lazy stellar wind.
    if math.random() < self.particles.wind.spawn_chance then
        self:spawnWindParticle()
    end

    -- Occasional flare clump.
    if math.random() < self.particles.flare.spawn_chance then
        self:spawnFlare()
    end

    self:updateParticleList(self.particles.wind.particles, false)
    self:updateParticleList(self.particles.flare.particles, true)
end

-- ==========================================
-- STAR DRAW
-- ==========================================

function Star:getDrawRadiusForType(stellar_type)
    local multiplier = 20
    if stellar_type == "O" then
        return 8 * multiplier
    elseif stellar_type == "B" then
        return 7 * multiplier
    elseif stellar_type == "A" then
        return 6 * multiplier
    elseif stellar_type == "F" then
        return 5 * multiplier
    elseif stellar_type == "G" then
        return 5 * multiplier
    elseif stellar_type == "K" then
        return 4 * multiplier
    elseif stellar_type == "M" then
        return 3 * multiplier
    end

    return 5 * multiplier
end

function Star:drawBody()
    local screen_x, screen_y = worldToScreen(self.position.x, self.position.y)
    local zoom = game.camera.zoom or 1

    screen_x = math.floor(screen_x)
    screen_y = math.floor(screen_y)

    local r = math.max(1, math.floor(self.radius * zoom))
    local outer_extra = math.max(1, math.floor(2 * zoom))
    local middle_extra = math.max(1, math.floor(1 * zoom))

    circ(screen_x, screen_y, r + outer_extra, self.colors.tertiary)
    circ(screen_x, screen_y, r + middle_extra, self.colors.secondary)
    circ(screen_x, screen_y, r, self.colors.primary)
end


function Star:drawParticleList(particles)
    local zoom = game.camera.zoom or 1

    for _, particle in ipairs(particles) do
        local screen_x, screen_y = worldToScreen(particle.x, particle.y)

        screen_x = math.floor(screen_x)
        screen_y = math.floor(screen_y)

        local size = math.max(1, math.floor(particle.size * zoom))

        if size <= 1 then
            pix(screen_x, screen_y, particle.color)
        else
            circ(screen_x, screen_y, size, particle.color)
        end
    end
end

function Star:draw()
    self:drawParticleList(self.particles.wind.particles)
    self:drawBody()
    self:drawParticleList(self.particles.flare.particles)
end

function Star:explode()
    -- All space objects explode. How is another matter.
end
