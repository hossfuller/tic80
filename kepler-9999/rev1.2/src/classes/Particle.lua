-- ==========================================
-- PARTICLE OBJECT
-- ==========================================

Particle = {}
Particle.__index = Particle

function Particle:new(systems)
    local self = setmetatable({}, Particle)
    self.systems = systems or {}
    return self
end

function Particle:get(type)
    if not self.systems then
        return nil
    end

    return self.systems[type]
end

function Particle:add(type, particle)
    local system = self:get(type)

    if not system then
        return false
    end

    system.particles = system.particles or {}
    table.insert(system.particles, particle)

    return true
end

function Particle:clear(type)
    if type then
        local system = self:get(type)
        if system then
            system.particles = {}
        end
        return
    end

    for _, system in pairs(self.systems or {}) do
        system.particles = {}
    end
end

function Particle:hasLive(type)
    if type then
        local system = self:get(type)
        return system and system.particles and #system.particles > 0
    end

    for _, system in pairs(self.systems or {}) do
        if system.particles and #system.particles > 0 then
            return true
        end
    end

    return false
end

function Particle:normalizeAngle(angle)
    angle = angle or 0

    while angle < 0 do
        angle = angle + math.pi * 2
    end

    while angle > math.pi * 2 do
        angle = angle - math.pi * 2
    end

    return angle
end

function Particle:vectorComponents(vector)
    vector = vector or {}

    local speed = vector.speed or 0
    local direction = vector.direction or 0

    return {
        x = speed * math.cos(direction),
        y = speed * math.sin(direction),
    }
end

function Particle:compToVector(x, y)
    local speed = math.sqrt(x * x + y * y)
    local direction = self:normalizeAngle(math.atan(y, x))

    return {
        speed = speed,
        direction = direction,
    }
end

function Particle:addVectors(a, b)
    local ac = self:vectorComponents(a)
    local bc = self:vectorComponents(b)

    return self:compToVector(ac.x + bc.x, ac.y + bc.y)
end

function Particle:randomColor(system)
    if not system.colors or #system.colors <= 0 then
        return WHITE
    end

    return system.colors[math.random(1, #system.colors)]
end

function Particle:randomLife(p)
    local life = math.random(p.life_min or 10, p.life_max or 30)
    return life
end

function Particle:spawnPosition(origin_x, origin_y, spawn_radius)
    spawn_radius = spawn_radius or 0

    if spawn_radius <= 0 then
        return origin_x, origin_y
    end

    local angle = randomFloat(0, math.pi * 2)
    local dist = randomFloat(0, spawn_radius)

    return
        origin_x + math.cos(angle) * dist,
        origin_y + math.sin(angle) * dist
end

function Particle:makeParticle(system, x, y, direction, overrides)
    overrides = overrides or {}

    local p = system.params or {}
    local life = overrides.life or self:randomLife(p)

    local speed = overrides.speed or randomFloat(
        p.speed_min or 0.1,
        p.speed_max or 1
    )

    local size = overrides.size or math.random(
        p.size_min or 1,
        p.size_max or 1
    )

    return {
        position = {
            x = x,
            y = y,
        },
        velocity = {
            speed = speed,
            direction = self:normalizeAngle(direction or 0),
        },
        life = life,
        max_life = overrides.max_life or life,
        size = size,
        color = overrides.color or self:randomColor(system),
        drag = overrides.drag or p.drag or 1,

        -- Optional acceleration/gravity vector.
        gravity = overrides.gravity or {
            speed = p.gravity_speed or 0,
            direction = p.gravity_direction or 0,
        },
    }
end

-- Generic radial/cone burst.
--
-- direction nil: full random radial burst.
-- direction set: burst centered on that direction.
-- spread means total cone width when using centered mode.
function Particle:burst(type, origin_x, origin_y, opts)
    opts = opts or {}

    local system = self:get(type)
    if not system then
        return 0
    end

    local p = system.params or {}

    local count = opts.count or math.random(
        p.count_min or 1,
        p.count_max or 1
    )

    local spread = opts.spread or p.spread or math.pi * 2
    local base_direction = opts.direction

    for i = 1, count do
        local direction

        if base_direction ~= nil then
            direction = base_direction - spread / 2 + math.random() * spread
        else
            direction = randomFloat(0, math.pi * 2)
        end

        direction = self:normalizeAngle(direction)

        local spawn_radius = opts.spawn_radius
        if spawn_radius == nil then
            spawn_radius = p.spawn_radius or 0
        end

        local x, y = self:spawnPosition(origin_x, origin_y, spawn_radius)

        self:add(type, self:makeParticle(system, x, y, direction, opts.particle))
    end

    return count
end

-- For custom emitters like thrust/smoke/tail where you compute x/y/velocity.
function Particle:emit(type, x, y, velocity, opts)
    opts = opts or {}

    local system = self:get(type)
    if not system then
        return false
    end

    local particle = self:makeParticle(
        system,
        x,
        y,
        velocity and velocity.direction or 0,
        opts
    )

    if velocity then
        particle.velocity = {
            speed = velocity.speed or 0,
            direction = self:normalizeAngle(velocity.direction or 0),
        }
    end

    return self:add(type, particle)
end

function Particle:update(type)
    local system = self:get(type)

    if not system then
        return
    end

    local particles = system.particles or {}

    for i = #particles, 1, -1 do
        local particle = particles[i]

        particle.life = particle.life - 1

        if particle.life <= 0 then
            table.remove(particles, i)
        else
            if particle.gravity and
                particle.gravity.speed and
                particle.gravity.speed ~= 0 then
                particle.velocity = self:addVectors(
                    particle.velocity,
                    particle.gravity
                )
            end

            particle.velocity.speed =
                particle.velocity.speed * (particle.drag or 1)

            particle.velocity.direction =
                self:normalizeAngle(particle.velocity.direction or 0)

            local c = self:vectorComponents(particle.velocity)

            particle.position.x = particle.position.x + c.x
            particle.position.y = particle.position.y + c.y
        end
    end
end

function Particle:updateAll(order)
    if order then
        for _, type in ipairs(order) do
            self:update(type)
        end

        return
    end

    for type, _ in pairs(self.systems or {}) do
        self:update(type)
    end
end

function Particle:draw(type, opts)
    opts = opts or {}

    local system = self:get(type)

    if not system then
        return
    end

    local particles = system.particles or {}
    local zoom = game.camera.zoom or 1

    local offscreen_pad = opts.offscreen_pad or 4
    local shrink_when_fading = getOrDefault(opts.shrink_when_fading, true)
    local fade_size_threshold = opts.fade_size_threshold or 0.35
    local always_circ = opts.always_circ or false
    local always_pix = opts.always_pix or false

    for _, particle in ipairs(particles) do
        local screen_x, screen_y = worldToScreen(
            particle.position.x,
            particle.position.y
        )

        screen_x = math.floor(screen_x)
        screen_y = math.floor(screen_y)

        if screen_x >= -offscreen_pad and
            screen_x <= SCREEN_W + offscreen_pad and
            screen_y >= -offscreen_pad and
            screen_y <= SCREEN_H + offscreen_pad then
            local life_fraction = 1

            if particle.max_life and particle.max_life > 0 then
                life_fraction = particle.life / particle.max_life
            end

            local size = math.max(
                1,
                math.floor((particle.size or 1) * zoom)
            )

            if shrink_when_fading and life_fraction < fade_size_threshold then
                size = 1
            end

            local color = particle.color or WHITE

            if always_pix then
                pix(screen_x, screen_y, color)
            elseif always_circ then
                circ(screen_x, screen_y, size, color)
            elseif size <= 1 then
                pix(screen_x, screen_y, color)
            else
                circ(screen_x, screen_y, size, color)
            end
        end
    end
end

function Particle:drawAll(order, opts_by_type)
    opts_by_type = opts_by_type or {}

    if order then
        for _, type in ipairs(order) do
            self:draw(type, opts_by_type[type])
        end

        return
    end

    for type, _ in pairs(self.systems or {}) do
        self:draw(type, opts_by_type[type])
    end
end
