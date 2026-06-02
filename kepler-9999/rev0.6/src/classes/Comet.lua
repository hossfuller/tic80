-- ==========================================
-- COMET OBJECT
-- ==========================================

Comet = setmetatable({}, { __index = KeplerObj })
Comet.__index = Comet

function Comet:new(params)
    params = params or {}

    params.mass = params.mass or randomFloat(COMET_MIN_MASS, COMET_MAX_MASS)

    params.radius_real = params.radius_real or randomFloat(
        COMET_RADIUS_REAL_MIN,
        COMET_RADIUS_REAL_MAX
    )
    params.radius = params.radius or Comet:getDrawRadiusFromRealRadius(params.radius_real)

    params.colors = params.colors or randomCometColorSet()

    local direction     = params.direction or randomFloat(0, math.pi * 2)
    local speed         = params.speed or randomFloat(COMET_SPEED_MIN, COMET_SPEED_MAX)
    params.direction    = direction
    params.speed        = speed
    params.acceleration = 0
    params.deceleration = 0

    local self = KeplerObj:new(params)
    setmetatable(self, Comet)

    self.name = params.name or "Comet"

    self.radius_real    = params.radius_real
    self.destroyed      = false
    self.mass_initial   = self.mass
    self.radius_initial = self.radius
    self.draw_scale     = 1

    self.color_list = randomCometColorList(self.colors)

    -- Lump circles are generated once so the comet has a stable shape.
    self.lumps = {}
    local lump_count = params.lump_count or math.random(4, 8)

    for i = 1, lump_count do
        local angle = randomFloat(0, math.pi * 2)
        local dist = randomFloat(0, self.radius * 0.55)

        table.insert(self.lumps, {
            x = math.cos(angle) * dist,
            y = math.sin(angle) * dist,
            r = randomFloat(self.radius * 0.35, self.radius * 0.75),
            color = randomChoice(self.color_list),
        })
    end

    -- Guarantee one central lump.
    table.insert(self.lumps, {
        x = 0,
        y = 0,
        r = self.radius,
        color = self.colors.primary,
    })

    self.tail_particles = {}
    self.tail_spawn_carry = 0

    return self
end

-- ==========================================
-- COMET GETTERS
-- ==========================================

function Comet:isFinished()
    return self.destroyed and #self.tail_particles <= 0
end

function Comet:getDrawRadiusFromRealRadius(radius_real)
    -- Comet real radius range: 100..900.
    -- Draw radius range: 3..9 pixels.
    local min_draw_radius = 3
    local max_draw_radius = 9

    radius_real = radius_real or COMET_RADIUS_REAL_MIN

    local t = (radius_real - COMET_RADIUS_REAL_MIN) /
        (COMET_RADIUS_REAL_MAX - COMET_RADIUS_REAL_MIN)

    t = clamp(t, 0, 1)

    return math.floor(min_draw_radius + t * (max_draw_radius - min_draw_radius))
end

function Comet:getDistanceToStar()
    if not game.play.star then
        return nil
    end

    local star = game.play.star
    local dx = self.position.x - star.position.x
    local dy = self.position.y - star.position.y

    return math.sqrt(dx * dx + dy * dy)
end

function Comet:getTailStrength()
    if not game.play.star then
        return 0
    end

    local distance_to_star = self:getDistanceToStar()

    if not distance_to_star then
        return 0
    end

    -- Approx max possible map distance from the star to any map corner.
    local star = game.play.star

    local d1 = math.sqrt((star.position.x - 0) ^ 2 + (star.position.y - 0) ^ 2)
    local d2 = math.sqrt((star.position.x - MAP_PIXELS_W) ^ 2 + (star.position.y - 0) ^ 2)
    local d3 = math.sqrt((star.position.x - 0) ^ 2 + (star.position.y - MAP_PIXELS_H) ^ 2)
    local d4 = math.sqrt((star.position.x - MAP_PIXELS_W) ^ 2 + (star.position.y - MAP_PIXELS_H) ^ 2)

    local max_distance = math.max(d1, d2, d3, d4)

    if max_distance <= 0 then
        return 0
    end

    -- Farthest from star => 0 tail.
    -- Closest to star => near 1 tail.
    local strength = 1 - (distance_to_star / max_distance)

    return clamp(strength, 0, 1)
end

function Comet:isOffMap()
    local padding = self.radius + 80

    return
        self.position.x < -padding or
        self.position.x > MAP_PIXELS_W + padding or
        self.position.y < -padding or
        self.position.y > MAP_PIXELS_H + padding
end

-- ==========================================
-- COMET UPDATE
-- ==========================================

function Comet:destroy()
    self.destroyed = true
end

function Comet:move()
    local components = self:getVectorComponents(self.velocity)

    self.position.x = self.position.x + components.xComp
    self.position.y = self.position.y + components.yComp
end

function Comet:getTailDirection()
    -- Comet tails usually point away from the star.
    if game.play.star then
        local star = game.play.star
        local dx = self.position.x - star.position.x
        local dy = self.position.y - star.position.y

        if dx ~= 0 or dy ~= 0 then
            return math.atan(dy, dx)
        end
    end

    -- Fallback: trail opposite movement direction.
    return self.velocity.direction + math.pi
end

function Comet:spawnTailParticles()
    local strength = self:getTailStrength()
    local mass_fraction = 1

    if self.mass_initial and self.mass_initial > 0 then
        mass_fraction = clamp(self.mass / self.mass_initial, 0, 1)
    end

    local shedding_bonus = 1 + (1 - mass_fraction) * 2

    -- No tail when very far away.
    if strength <= 0.05 then
        return
    end

    local tail_direction = self:getTailDirection()

    -- Spawn rate increases near the star.
    local spawn_amount = (
        COMET_TAIL_SPAWN_MIN +
        strength * (COMET_TAIL_SPAWN_MAX - COMET_TAIL_SPAWN_MIN)
    ) * shedding_bonus

    self.tail_spawn_carry = self.tail_spawn_carry + spawn_amount

    local spawn_count = math.floor(self.tail_spawn_carry)
    self.tail_spawn_carry = self.tail_spawn_carry - spawn_count

    -- Tail length increases near the star.
    local max_tail_life = math.floor(
        COMET_TAIL_LIFE_MIN +
        strength * (COMET_TAIL_LIFE_MAX - COMET_TAIL_LIFE_MIN)
    )

    local max_tail_speed =
        COMET_TAIL_SPEED_MIN +
        strength * (COMET_TAIL_SPEED_MAX - COMET_TAIL_SPEED_MIN)

    for i = 1, spawn_count do
        local spread = randomFloat(-0.08, 0.08)
        local direction = tail_direction + spread

        local spawn_back = randomFloat(0, self.radius)
        local spawn_side = randomFloat(-self.radius * 0.5, self.radius * 0.5)

        local side_angle = direction + math.pi / 2

        local px =
            self.position.x +
            math.cos(direction) * spawn_back +
            math.cos(side_angle) * spawn_side

        local py =
            self.position.y +
            math.sin(direction) * spawn_back +
            math.sin(side_angle) * spawn_side

        table.insert(self.tail_particles, {
            x = px,
            y = py,
            direction = direction,
            speed = randomFloat(0.05, max_tail_speed),
            life = max_tail_life,
            max_life = max_tail_life,
            size = math.random(1, 2),
            color = randomChoice(self.color_list),
        })
    end
end

function Comet:updateTailParticles()
    for i = #self.tail_particles, 1, -1 do
        local particle = self.tail_particles[i]

        particle.life = particle.life - 1

        if particle.life <= 0 then
            table.remove(self.tail_particles, i)
        else
            particle.x = particle.x + math.cos(particle.direction) * particle.speed
            particle.y = particle.y + math.sin(particle.direction) * particle.speed

            -- Slight slowdown/drift.
            particle.speed = particle.speed * 0.985
        end
    end
end

function Comet:evaporate()
    if self.destroyed then
        return
    end

    local strength = self:getTailStrength()

    if strength <= 0.05 then
        return
    end

    local curved_strength = strength ^ 3
    local evaporation_rate =
        COMET_EVAPORATION_MIN +
        curved_strength * (COMET_EVAPORATION_MAX - COMET_EVAPORATION_MIN)

    self.mass = self.mass - evaporation_rate

    if self.mass <= 0 then
        self.mass = 0
        self:destroy()
        return
    end

    local mass_fraction = clamp(self.mass / self.mass_initial, 0, 1)

    -- Square root gives a nicer radius-vs-mass feel than linear shrink.
    self.draw_scale = math.sqrt(mass_fraction)

    self.radius = math.max(1, self.radius_initial * self.draw_scale)
end

function Comet:update()
    self:updateTimer()

    if not self.destroyed then
        self:move()
        self:evaporate()

        -- Only living comets spawn new tail particles.
        if not self.destroyed then
            self:spawnTailParticles()
        end
    end

    -- Existing tail particles continue after the comet evaporates.
    self:updateTailParticles()
end

-- ==========================================
-- COMET DRAW
-- ==========================================

function Comet:drawTailParticles()
    for _, particle in ipairs(self.tail_particles) do
        local screen_x, screen_y = worldToScreen(particle.x, particle.y)

        screen_x = math.floor(screen_x)
        screen_y = math.floor(screen_y)

        -- Skip if off-screen.
        if screen_x >= 0 and screen_x < SCREEN_W and
            screen_y >= 0 and screen_y < SCREEN_H then
            pix(screen_x, screen_y, particle.color)
        end
    end
end

function Comet:drawBody()
    local zoom = game.camera.zoom or 1

    local screen_x, screen_y = worldToScreen(self.position.x, self.position.y)

    screen_x = math.floor(screen_x)
    screen_y = math.floor(screen_y)

    local scale = self.draw_scale or 1
    local r     = math.max(1, math.floor(self.radius_initial * scale * zoom))

    -- Skip if comfortably off-screen.
    if screen_x < -r - 8 or screen_x > SCREEN_W + r + 8 or
        screen_y < -r - 8 or screen_y > SCREEN_H + r + 8 then
        return
    end

    -- Draw lump composed of squished-together colored circles.
    for _, lump in ipairs(self.lumps) do
        local lx = screen_x + math.floor(lump.x * scale * zoom)
        local ly = screen_y + math.floor(lump.y * scale * zoom)
        local lr = math.max(1, math.floor(lump.r * scale * zoom))

        circ(lx, ly, lr, lump.color)
    end
end

function Comet:draw()
    -- Tail can remain after body is gone.
    self:drawTailParticles()

    if not self.destroyed then
        self:drawBody()
    end
end
