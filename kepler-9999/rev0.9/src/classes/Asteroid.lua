-- ==========================================
-- ASTEROID OBJECT
-- ==========================================

--[[
    Adapted from the Asteroids clone.
--]]

Asteroid = setmetatable({}, { __index = KeplerObj })
Asteroid.__index = Asteroid

function Asteroid:new(params)
    params = params or {}

    params.mass   = params.mass or randomFloat(ASTEROID_MIN_MASS, ASTEROID_MAX_MASS)
    params.radius = params.radius or randomFloat(ASTEROID_RADIUS_MIN, ASTEROID_RADIUS_MAX)
    params.colors = params.colors or shuffledAsteroidColors()
    params.color  = params.color or params.colors.primary

    local direction     = params.direction or randomFloat(0, math.pi * 2)
    local speed         = params.speed or randomFloat(ASTEROID_SPEED_MIN, ASTEROID_SPEED_MAX)
    params.direction    = direction
    params.speed        = speed
    params.acceleration = params.acceleration or 0
    params.deceleration = params.deceleration or 0

    local self = KeplerObj:new(params)
    setmetatable(self, Asteroid)

    self.name = params.name or "Asteroid"

    -- Asteroid-specific properties, adapted from your old class.
    -- self.base_points    = params.base_points or 50
    self.clumpiness   = params.clumpiness or 0.35
    self.scale        = params.scale or 1
    self.num_vertices = params.num_vertices or math.random(ASTEROID_VERTICES_MIN, ASTEROID_VERTICES_MAX)

    self.radius       = params.radius or self.radius or 15
    self.radius_minus = params.radius_minus or ASTEROID_RADIUS_MINUS
    self.radius_plus  = params.radius_plus or ASTEROID_RADIUS_PLUS

    self.rotation       = params.rotation or randomFloat(0, math.pi * 2)
    self.rotation_max   = params.rotation_max or ASTEROID_ROTATION_MAX
    self.rotation_speed = params.rotation_speed or randomFloat(-self.rotation_max, self.rotation_max)

    self.velocity_min = params.velocity_min or ASTEROID_SPEED_MIN
    self.velocity_max = params.velocity_max or ASTEROID_SPEED_MAX

    -- Stable polygon shape.
    self.shape = params.shape or self:spawn()

    self.mineable = true

    self.particle_systems = {
        explosion = {
            colors = params.explosion_colors or {
                WHITE,
                YELLOW,
                ORANGE,
                RED,
                GRAY_LITE,
                GRAY_MED,
            },
            params = {
                count_min    = 12,
                count_max    = 24,
                speed_min    = 0.25,
                speed_max    = 1.7,
                life_min     = 15,
                life_max     = 38,
                size_min     = 1,
                size_max     = 2,
                drag         = 0.965,
                spawn_radius = self.radius or 8,
            },
            particles = {},
        },
    }

    return self
end

-- ==========================================
-- ASTEROID GETTERS
-- ==========================================

function Asteroid:getRadius()
    return self.radius
end

function Asteroid:getScale()
    return self.scale
end

function Asteroid:getRadiusPlusMinus()
    return {
        plus  = self.radius_plus,
        minus = self.radius_minus,
    }
end

function Asteroid:isOffMap()
    local padding = self.radius + 80

    return
        self.position.x < -padding or
        self.position.x > MAP_PIXELS_W + padding or
        self.position.y < -padding or
        self.position.y > MAP_PIXELS_H + padding
end

-- ==========================================
-- ASTEROID SHAPE
-- ==========================================

function Asteroid:spawn()
    local vertices = {}

    local baseR    = self.radius

    -- Scale the "clumpiness" with size.
    local minus    = math.min(self.radius_minus, baseR * self.clumpiness)
    local plus     = math.min(self.radius_plus, baseR * self.clumpiness)

    table.insert(vertices, { x = baseR, y = 0 })

    for vertex = 1, self.num_vertices - 1 do
        local minr = math.max(1, baseR - minus)
        local maxr = math.max(minr + 0.01, baseR + plus)

        local r = randomFloat(minr, maxr)
        local a = (math.pi * 2 / self.num_vertices) * vertex

        table.insert(vertices, {
            x = r * math.cos(a),
            y = r * math.sin(a),
        })
    end

    table.insert(vertices, { x = baseR, y = 0 })

    return vertices
end


-- ==========================================
-- ASTEROID PARTICLE EFFECTS
-- ==========================================

function Asteroid:getParticleSystem(type)
    if not self.particle_systems then
        return nil
    end

    return self.particle_systems[type]
end

function Asteroid:hasLiveParticles()
    for _, system in pairs(self.particle_systems or {}) do
        if system.particles and #system.particles > 0 then
            return true
        end
    end

    return false
end

function Asteroid:spawnParticleBurst(type, x, y, direction, spread, count)
    local system = self:getParticleSystem(type)

    if not system then
        return
    end

    local p = system.params
    local particles = system.particles

    direction = direction or 0
    spread    = spread or math.pi * 2

    for i = 1, count do
        local particle_direction = direction - spread / 2 + math.random() * spread
        local spawn_radius       = p.spawn_radius or 0
        local spawn_angle        = math.random() * math.pi * 2
        local spawn_distance     = math.random() * spawn_radius

        local px = x + math.cos(spawn_angle) * spawn_distance
        local py = y + math.sin(spawn_angle) * spawn_distance

        table.insert(particles, {
            position = {
                x = px,
                y = py,
            },
            velocity = {
                speed     = randomFloat(p.speed_min or 0.1, p.speed_max or 1),
                direction = particle_direction,
            },
            life     = math.random(p.life_min or 10, p.life_max or 30),
            max_life = p.life_max or 30,
            size     = math.random(p.size_min or 1, p.size_max or 2),
            color    = system.colors[math.random(1, #system.colors)],
            drag     = p.drag or 1,
        })
    end
end

function Asteroid:updateParticleList(type)
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
            particle.velocity.direction = self:keepAngleInRange(particle.velocity.direction or 0)

            local components = self:getVectorComponents(particle.velocity)

            particle.position.x = particle.position.x + components.xComp
            particle.position.y = particle.position.y + components.yComp
        end
    end
end

function Asteroid:drawParticles(type)
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

        local size = math.max(1, particle.size * zoom)
        local alpha = particle.life / particle.max_life
        alpha = math.max(0, math.min(1, alpha))

        local color = particle.color or WHITE
        circ(math.floor(screen_x), math.floor(screen_y), size, color)
    end
end

function Asteroid:explosionEffect()
    local system = self:getParticleSystem("explosion")

    if not system then
        return
    end

    local p          = system.params
    local base_count = math.random(
        p.count_min or 12,
        p.count_max or 24
    )

    local radius_scale = math.max(0.75, (self.radius or 10) / 10)
    local count        = math.floor(base_count * radius_scale)
    self:spawnParticleBurst(
        "explosion",
        self.position.x,
        self.position.y,
        nil,
        math.pi * 2,
        count
    )
end


-- ==========================================
-- ASTEROID UPDATE
-- ==========================================

function Asteroid:move()
    if self.dead then
        return
    end

    local components = self:getVectorComponents(self.velocity)
    self.position.x = self.position.x + components.xComp
    self.position.y = self.position.y + components.yComp
    self.rotation   = self.rotation + self.rotation_speed
end

function Asteroid:update()
    self:updateTimer()

    -- Particles should keep updating even after the asteroid body is dead.
    self:updateParticleList("explosion")

    if self.dead then
        return
    end

    self:move()
end

-- ==========================================
-- ASTEROID COLLISION DAMAGE
-- ==========================================

function Asteroid:takeDamage(damage, other)
    damage = damage or 0

    if self.dead then
        return false
    end

    if damage <= 0 then
        return false
    end

    self.mass = (self.mass or 0) - damage

    if self.mass > 0 then
        return false
    end

    self.mass = 0

    -- Store collision info for Asteroid:explode().
    if other and other.position and self.position then
        local nx, ny = getCollisionNormal(self, other)

        self.break_normal = {
            x = nx,
            y = ny,
        }

        self.break_other = other
    else
        local direction = self.velocity and self.velocity.direction or randomFloat(0, math.pi * 2)

        self.break_normal = {
            x = math.cos(direction),
            y = math.sin(direction),
        }

        self.break_other = other
    end

    local fragments = self:kill()

    for _, fragment in ipairs(fragments or {}) do
        table.insert(game.play.asteroids, fragment)
    end

    return true
end

-- ==========================================
-- ASTEROID EXPLOSION
-- ==========================================

function Asteroid:explode()
    if self.exploded then
        return {}
    end

    self.exploded = true

    local asteroid_fragments = {}

    local orig_scale = self.scale or 1

    if orig_scale < ASTEROID_MAX_FRAGMENT_SCALE then
        local new_scale = orig_scale * 2

        -- Default break direction if no collision normal was supplied.
        local break_nx = 0
        local break_ny = 0

        if self.break_normal then
            break_nx = self.break_normal.x or 0
            break_ny = self.break_normal.y or 0
        end

        if break_nx == 0 and break_ny == 0 then
            break_nx = math.cos(self.velocity.direction or 0)
            break_ny = math.sin(self.velocity.direction or 0)
        end

        local break_angle = math.atan(break_ny, break_nx)

        -- Perpendicular direction for splitting the two fragments apart.
        local side_angle = break_angle + math.pi / 2

        for count = 1, 2 do
            local side_sign = -1

            if count == 2 then
                side_sign = 1
            end

            local fragment_radius = math.max(2, self.radius / new_scale)

            -- Send both fragments mostly away from the collision,
            -- but split them left/right so they visibly separate.
            local fragment_direction =
                break_angle +
                side_sign * randomFloat(0.35, 0.85)

            -- Move the spawned fragments slightly outside the impact area.
            local spawn_push = self.radius + fragment_radius + 2

            local spawn_x =
                self.position.x +
                math.cos(break_angle) * spawn_push +
                math.cos(side_angle) * side_sign * fragment_radius

            local spawn_y =
                self.position.y +
                math.sin(break_angle) * spawn_push +
                math.sin(side_angle) * side_sign * fragment_radius

            -- If the asteroid hit a large body, push fragments outside that body.
            -- This prevents fragments from spawning inside a planet/star/moon and
            -- instantly dying on the next frame.
            local other = self.break_other

            if other and other.position then
                local other_radius = getCollisionRadius(other)
                local dx = spawn_x - other.position.x
                local dy = spawn_y - other.position.y
                local dist_sq = dx * dx + dy * dy

                if dist_sq > 0 then
                    local dist = math.sqrt(dist_sq)
                    local min_dist = other_radius + fragment_radius + 2

                    if dist < min_dist then
                        local nx = dx / dist
                        local ny = dy / dist

                        spawn_x = other.position.x + nx * min_dist
                        spawn_y = other.position.y + ny * min_dist
                    end
                else
                    spawn_x = other.position.x + math.cos(break_angle) * (other_radius + fragment_radius + 2)
                    spawn_y = other.position.y + math.sin(break_angle) * (other_radius + fragment_radius + 2)
                end
            end

            local asteroid = Asteroid:new({
                name           = "Asteroid Fragment",
                colors         = self.colors,
                color          = self.color,
                x              = spawn_x,
                y              = spawn_y,
                speed          = randomFloat(self.velocity_min, self.velocity_max) + 0.15,
                direction      = fragment_direction,
                acceleration   = self.acceleration,
                deceleration   = self.deceleration,
                elasticity     = self.elasticity,
                scale          = new_scale,
                rotation_speed = randomFloat(-self.rotation_max, self.rotation_max),
                radius         = fragment_radius,
                radius_minus   = self.radius_minus,
                radius_plus    = self.radius_plus,
                num_vertices   = self.num_vertices,
                clumpiness     = self.clumpiness,
            })
            table.insert(asteroid_fragments, asteroid)
        end
    end

    self:explosionEffect()

    return asteroid_fragments
end

-- ==========================================
-- ASTEROID DRAW
-- ==========================================

function Asteroid:getRotatedPoint(point)
    local cos_r = math.cos(self.rotation)
    local sin_r = math.sin(self.rotation)

    return {
        x = point.x * cos_r - point.y * sin_r,
        y = point.x * sin_r + point.y * cos_r,
    }
end

function Asteroid:draw()
    local zoom               = game.camera.zoom or 1
    local screen_x, screen_y = worldToScreen(self.position.x, self.position.y)
    local screen_radius      = self.radius * zoom

    -- If the asteroid body and its particles are offscreen, skip drawing.
    -- The extra padding helps avoid clipping explosion particles.
    local padding = screen_radius + 64

    if screen_x < -padding or
        screen_x > SCREEN_W + padding or
        screen_y < -padding or
        screen_y > SCREEN_H + padding then
        return
    end

    -- Draw the asteroid body only while alive.
    if not self.dead then
        local cx = math.floor(screen_x)
        local cy = math.floor(screen_y)

        for i = 1, #self.shape - 1 do
            local p1 = self:getRotatedPoint(self.shape[i])
            local p2 = self:getRotatedPoint(self.shape[i + 1])

            local x1 = math.floor(screen_x + p1.x * zoom)
            local y1 = math.floor(screen_y + p1.y * zoom)
            local x2 = math.floor(screen_x + p2.x * zoom)
            local y2 = math.floor(screen_y + p2.y * zoom)

            tri(cx, cy, x1, y1, x2, y2, self.colors.secondary)
            line(x1, y1, x2, y2, self.colors.primary)
        end
    end

    -- Draw explosion particles even after the asteroid body is gone.
    self:drawParticles("explosion")
end
