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
        primary   = GRAY_LITE,
        secondary = GRAY_MED,
        tertiary  = BLUE_LITE,
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

    self.colors              = {
        primary   = params.colors and params.colors.primary or GRAY_LITE,
        secondary = params.colors and params.colors.secondary or GRAY_MED,
        tertiary  = params.colors and params.colors.tertiary or BLUE_LITE,
    }

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

    -- You can't mine a SpaceDock! But the NPC freighter can gather it up for
    -- transport to the station.
    self.mineable = false

    self.ore_bank = {
        cur = 0,
        max = DOCK_ORE_BANK_MAX,
    }

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

function SpaceDock:getHostSpaceStation()
    if not self.host then
        return nil
    end

    if SpaceStation ~= nil and getmetatable(self.host) == SpaceStation then
        return self.host
    end

    return nil
end

function SpaceDock:transferOreToHostStation()
    local station = self:getHostSpaceStation()

    if not station then
        return false
    end

    if not self.ore_bank or not station.ore_bank then
        return false
    end

    if self.ore_bank.cur <= 0 then
        return false
    end

    local station_free_space = math.max(
        0,
        station.ore_bank.max - station.ore_bank.cur
    )

    if station_free_space <= 0 then
        return false
    end

    local transfer_amount = math.min(
        self.ore_bank.cur,
        station_free_space
    )

    station.ore_bank.cur = station.ore_bank.cur + transfer_amount
    self.ore_bank.cur = self.ore_bank.cur - transfer_amount

    if self.ore_bank.cur <= 0 then
        self.ore_bank.cur = 0
    end

    return transfer_amount > 0
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

    -- Dead docks no longer orbit or transfer ore.
    if self.dead then
        return
    end

    -- If this dock is attached to a SpaceStation, instantly transfer any stored
    -- ore into the station, up to the station's capacity.
    self:transferOreToHostStation()

    -- Docks without hosts cannot orbit.
    if not self.host then
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
    if screen_x < -r - 8 or screen_x > SCREEN_W + r + 8 or
        screen_y < -r - 8 or screen_y > SCREEN_H + r + 8 then
        return
    end

    -- Very low zoom: keep it readable as a bright marker.
    if r <= 2 then
        pix(screen_x, screen_y, self.colors.primary or WHITE)
        pix(screen_x - 1, screen_y, GRAY_LITE)
        pix(screen_x + 1, screen_y, GRAY_LITE)
        pix(screen_x, screen_y - 1, WHITE)
        pix(screen_x, screen_y + 1, WHITE)
        return
    end

    local primary      = self.colors.primary or GRAY_LITE
    local secondary    = self.colors.secondary or WHITE
    local tertiary     = self.colors.tertiary or BLUE_LITE

    local outer_r      = r
    local mid_r        = math.max(1, math.floor(r * 0.72))
    local inner_r      = math.max(1, math.floor(r * 0.38))

    -- Slight animation for beacon/lights.
    local timer        = self.timer or 0
    local beacon_angle = (timer * 0.06) % (math.pi * 2)

    -- ==========================================
    -- Main body ring
    -- ==========================================

    -- Outer hull.
    circ(screen_x, screen_y, outer_r, primary)

    -- Slight inner band.
    circ(screen_x, screen_y, mid_r, secondary)

    -- Dark interior/core.
    circ(screen_x, screen_y, inner_r, BLACK)

    -- Inner hatch.
    local hatch_r = math.max(1, math.floor(inner_r * 0.45))
    circ(screen_x, screen_y, hatch_r, tertiary)

    -- Cross / docking guide lines.
    line(screen_x - inner_r, screen_y, screen_x + inner_r, screen_y, GRAY_DARK)
    line(screen_x, screen_y - inner_r, screen_x, screen_y + inner_r, GRAY_DARK)

    -- Small bright center.
    pix(screen_x, screen_y, WHITE)

    -- ==========================================
    -- Ring panel details
    -- ==========================================

    if r >= 5 then
        local panel_count = 8
        local panel_r = math.max(1, math.floor(r * 0.10))
        local panel_dist = math.floor(r * 0.82)

        for i = 1, panel_count do
            local a = ((i - 1) / panel_count) * math.pi * 2
            local px = screen_x + math.floor(math.cos(a) * panel_dist)
            local py = screen_y + math.floor(math.sin(a) * panel_dist)

            local color = GRAY_DARK

            -- Alternating hull panels.
            if i % 2 == 0 then
                color = GRAY_MED
            end

            circ(px, py, panel_r, color)
        end
    end

    -- ==========================================
    -- Lights
    -- ==========================================

    if r >= 4 then
        local light_dist = math.floor(r * 1.18)

        -- Blinking lights.
        local blink_on = (math.floor(timer / 20) % 2) == 0
        local blink_color = blink_on and YELLOW or ORANGE

        local lx1 = screen_x + math.floor(math.cos(math.pi * 0.25) * light_dist)
        local ly1 = screen_y + math.floor(math.sin(math.pi * 0.25) * light_dist)

        local lx2 = screen_x + math.floor(math.cos(math.pi * 1.25) * light_dist)
        local ly2 = screen_y + math.floor(math.sin(math.pi * 1.25) * light_dist)

        pix(lx1, ly1, blink_color)
        pix(lx2, ly2, blink_color)

        -- Fixed navigation lights.
        local lx3 = screen_x + math.floor(math.cos(math.pi * 0.75) * light_dist)
        local ly3 = screen_y + math.floor(math.sin(math.pi * 0.75) * light_dist)

        local lx4 = screen_x + math.floor(math.cos(math.pi * 1.75) * light_dist)
        local ly4 = screen_y + math.floor(math.sin(math.pi * 1.75) * light_dist)

        pix(lx3, ly3, RED)
        pix(lx4, ly4, GREEN_LITE)
    end

    -- ==========================================
    -- Rotating beacon arm
    -- ==========================================

    if r >= 5 then
        local beacon_inner = math.floor(r * 0.45)
        local beacon_outer = math.floor(r * 1.25)

        local bx1 = screen_x + math.floor(math.cos(beacon_angle) * beacon_inner)
        local by1 = screen_y + math.floor(math.sin(beacon_angle) * beacon_inner)

        local bx2 = screen_x + math.floor(math.cos(beacon_angle) * beacon_outer)
        local by2 = screen_y + math.floor(math.sin(beacon_angle) * beacon_outer)

        line(bx1, by1, bx2, by2, CYAN)
        circ(bx2, by2, 1, WHITE)
    end
end

function SpaceDock:draw()
    if not self.dead then
        self:drawBody()
    end

    self:drawParticles("explosion")
end
