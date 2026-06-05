-- ==========================================
-- SPACEDOCK OBJECT
-- ==========================================

SpaceDock = setmetatable({}, { __index = Moon })
SpaceDock.__index = SpaceDock

function SpaceDock:new(params)
    params                = params or {}

    params.name        = params.name or "SpaceDock"
    params.mass        = params.mass        or DOCK_MASS
    params.radius_real = params.radius_real or DOCK_REAL_RADIUS
    params.radius      = params.radius      or SpaceDock:getDrawRadiusFromRealRadius(params.radius_real)
    params.colors      = params.colors or {
        primary = WHITE,
        secondary = BLUE_LITE,
        tertiary  = GRAY_LITE,
    }

    params.has_atmosphere      = false
    params.has_ring            = false
    params.num_rings           = 0
    params.exerts_gravity      = true
    params.affected_by_gravity = false

    -- SpaceDocks are moon-like orbital bodies.
    local self            = Moon:new(params)
    setmetatable(self, SpaceDock)

    self.name = params.name or "SpaceDock"
    self.mass = DOCK_MASS
    self.host = params.host

    self.has_atmosphere      = false
    self.has_ring            = false
    self.num_rings           = 0
    self.exerts_gravity      = false
    self.affected_by_gravity = false

    local orbit = params.orbit or {}
    self.orbit  = {
        semi_major   = orbit.semi_major or 100,
        eccentricity = orbit.eccentricity or 0,
        angle        = orbit.angle or 0,
        phase        = orbit.phase or 0,
        period       = orbit.period or 1800,
    }

    self.orbit.semi_minor =
        self.orbit.semi_major *
        math.sqrt(1 - self.orbit.eccentricity * self.orbit.eccentricity)

    -- You can't mine a SpaceDock!
    self.mineable = false

    -- SpaceDocks do not use Moon dust effects. Instead they have SpaceShip-like
    -- explosion effects.
    self.dust_particles = {}
    self.dust           = nil
    self.particles           = {
        explosion = {
            colors = params.explosion_colors or {
                WHITE,
                YELLOW,
                ORANGE,
                RED,
                GRAY_LITE,
                GRAY_MED,
                GRAY_DARK,
            },
            params = {
                count_min    = 130,
                count_max    = 190,
                speed_min    = 1.0,
                speed_max    = 5.2,
                life_min     = 45,
                life_max     = 120,
                size_min     = 1,
                size_max     = 4,
                drag         = 0.97,
                spawn_radius = (self.radius or DOCK_RADIUS or 10) * 2.4,
            },
            particles = {},
        },
    }

    -- Initialize dock position immediately if it has a host.
    if self.host then
        local focus = self.host.barycenter or self.host.position
        self:updateOrbitPosition(focus)
    end

    return self
end

-- ==========================================
-- SPACEDOCK GETTERS
-- ==========================================

function SpaceDock:isFinished()
    local explosion = self.particles and self.particles.explosion
    if not explosion then
        return self.dead
    end
    return self.dead and #explosion.particles <= 0
end

function SpaceDock:getDrawRadiusFromRealRadius(radius_real)
    return DOCK_REAL_RADIUS
end

-- ==========================================
-- SPACEDOCK PARTICLE EFFECTS
-- ==========================================

function SpaceDock:getParticleSystem(type)
    if not self.particles then
        return nil
    end

    return self.particles[type]
end

function SpaceDock:addParticle(type, particle)
    local system = self:getParticleSystem(type)

    if not system then
        return
    end

    table.insert(system.particles, particle)
end

function SpaceDock:updateParticleList(type)
    local system = self:getParticleSystem(type)

    if not system then
        return
    end

    local particles = system.particles

    for i = #particles, 1, -1 do
        local particle = particles[i]

        particle.life = particle.life - 1

        if particle.life <= 0 then
            table.remove(particles, i)
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

function SpaceDock:updateParticles()
    if not self.particles then
        return
    end

    self:updateParticleList("explosion")
end

function SpaceDock:drawParticles(type)
    local system = self:getParticleSystem(type)

    if not system then
        return
    end

    local zoom = game.camera.zoom or 1

    for _, particle in ipairs(system.particles) do
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

function SpaceDock:spawnParticleBurst(type, origin_x, origin_y, count)
    local system = self:getParticleSystem(type)

    if not system then
        return
    end

    local p      = system.params
    local colors = system.colors

    count        = count or math.random(p.count_min or 1, p.count_max or 1)

    for i = 1, count do
        local direction    = randomFloat(0, math.pi * 2)
        local speed        = randomFloat(p.speed_min or 0.1, p.speed_max or 1)
        local life         = math.random(p.life_min or 10, p.life_max or 30)
        local size         = math.random(p.size_min or 1, p.size_max or 1)

        local spawn_radius = p.spawn_radius or 0
        local spawn_angle  = randomFloat(0, math.pi * 2)
        local spawn_dist   = randomFloat(0, spawn_radius)

        local sx           = origin_x + math.cos(spawn_angle) * spawn_dist
        local sy           = origin_y + math.sin(spawn_angle) * spawn_dist

        self:addParticle(type, {
            position = {
                x = sx,
                y = sy,
            },
            velocity = {
                speed     = speed,
                direction = direction,
            },
            life     = life,
            max_life = life,
            color    = randomChoice(colors),
            size     = size,
            drag     = p.drag or 1,
        })
    end
end

function SpaceDock:explosionEffect()
    local system = self:getParticleSystem("explosion")

    if not system then
        return
    end

    local p = system.params
    local count = math.random(p.count_min or 120, p.count_max or 180)

    self:spawnParticleBurst(
        "explosion",
        self.position.x,
        self.position.y,
        count
    )
end

-- ==========================================
-- SPACEDOCK UPDATE
-- ==========================================

function SpaceDock:update()
    self:updateTimer()

    -- Explosion particles continue after death.
    self:updateParticles()

    -- Dead docks no longer orbit.
    if self.dead or not self.host then
        return
    end

    local focus      = self.host.barycenter or self.host.position
    self.orbit.phase = self.orbit.phase + ((math.pi * 2) / self.orbit.period)
    if self.orbit.phase > math.pi * 2 then
        self.orbit.phase = self.orbit.phase - math.pi * 2
    end

    self:updateOrbitPosition(focus)
end

-- ==========================================
-- SPACEDOCK DRAW
-- ==========================================

function SpaceDock:drawBody()
    if self.dead then
        return
    end

    local zoom = game.camera.zoom or 1

    local screen_x, screen_y = worldToScreen(self.position.x, self.position.y)

    screen_x = math.floor(screen_x)
    screen_y = math.floor(screen_y)

    local r = math.max(1, math.floor(self.radius * zoom))

    -- Skip if comfortably off-screen.
    if screen_x < -r - 4 or screen_x > SCREEN_W + r + 4 or
        screen_y < -r - 4 or screen_y > SCREEN_H + r + 4 then
        return
    end

    -- Simple dock body.
    circ(screen_x, screen_y, r, self.colors.primary)
end

function SpaceDock:draw()
    if not self.dead then
        self:drawBody()
    end

    self:drawParticles("explosion")
end
