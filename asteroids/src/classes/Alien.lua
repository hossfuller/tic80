-- ==========================================
-- ALIEN OBJECT
-- ==========================================

Alien = setmetatable({}, { __index = Ship })
Alien.__index = Alien

function Alien:new(params)
    params = params or {}

    -- Set alien-specific defaults before calling Ship:new
    params.color      = params.color or RED
    params.max_health = params.max_health or 1  -- Default to 1 if not specified
    params.max_lives  = params.max_lives or 1

    -- Spawn on left edge at random Y position
    params.x = params.x or 0
    params.y = params.y or math.random(20, EDGE_Y_BOTTOM - 20)

    -- Set initial velocity (moving right)
    params.speed     = params.speed or 0.5
    params.direction = params.direction or 0  -- 0 radians = right

    local self = Ship.new(self, params)
    setmetatable(self, Alien)

    -- Ensure cur_health matches max_health (Ship:new sets this, but be explicit)
    self.cur_health = self.max_health

    -- Alien-specific properties
    self.base_points = params.base_points or 500
    self.active      = true

    -- Alien ship shape (different from player ship)
    self.shape = params.shape or {
        { x = 6,  y = 0  },
        { x = 3,  y = -4 },
        { x = -3, y = -4 },
        { x = -6, y = 0  },
        { x = -3, y = 4  },
        { x = 3,  y = 4  },
        { x = 6,  y = 0  }
    }

    -- Alien laser settings
    self.fire_timer   = 0
    self.laser_blasts = {}
    self.laser_params = {
        lifetime = params.laser_lifetime or 90,
        speed    = params.laser_speed    or 1.5,
        damage   = params.laser_damage   or 35,
        offset   = { x = 6, y = 0 },
    }

    -- Point rotation in direction of travel
    self.rotation = self.velocity.direction

    return self
end

-- ==========================================
-- ALIEN GETTERS
-- ==========================================

function Alien:getHealth()
    if self.cur_health < 0 then
        self.cur_health = 0
    end
    return self.cur_health
end

function Alien:getHealthFraction()
    return self:getHealth() / self.max_health
end

function Alien:getPoints()
    return self.base_points
end

function Alien:isActive()
    return self.active and not self.dead
end

-- ==========================================
-- ALIEN INPUT
-- ==========================================

-- Alien doesn't respond to player input
function Alien:input()
    -- No-op: alien moves autonomously
end

-- ==========================================
-- ALIEN UPDATE
-- ==========================================

function Alien:getFireInterval(level)
    local params             = game.play.params.alien
    local levels_after_spawn = math.max(0, level - params.min_level)
    local interval           = params.fire_interval_start - (levels_after_spawn * params.fire_interval_step)
    return math.max(params.fire_interval_min, interval)
end

function Alien:getDirectionToTarget(target)
    local dx        = target.position.x - self.position.x
    local dy        = target.position.y - self.position.y
    local direction = math.atan(dy, dx)
    return self:keepAngleInRange(direction)
end

function Alien:fireAtPlayer(player)
    if not player or player.dead then
        return
    end

    local direction     = self:getDirectionToTarget(player)
    local rel_spawn_pos = self:rotatePoint(self.laser_params.offset, direction)
    local laser         = {
        position = {
            x = self.position.x + rel_spawn_pos.x,
            y = self.position.y + rel_spawn_pos.y,
        },
        velocity = {
            speed     = self.laser_params.speed,
            direction = direction,
        },
        lifetime = self.laser_params.lifetime,
        damage   = self.laser_params.damage,
    }
    table.insert(self.laser_blasts, laser)

    sfx(0, 30, 15, 0, 8, 1)
end

function Alien:updateShooting(player, level)
    if not self:isActive() then
        return
    end
    self.fire_timer = self.fire_timer + 1
    local interval = self:getFireInterval(level)
    if self.fire_timer >= interval then
        self.fire_timer = 0
        self:fireAtPlayer(player)
    end
end

function Alien:moveLaserBlasts()
    for index = #self.laser_blasts, 1, -1 do
        local laser    = self.laser_blasts[index]
        laser.lifetime = laser.lifetime - 1
        if laser.lifetime < 0 then
            table.remove(self.laser_blasts, index)
        else
            laser.position = self:movePointByVelocity(laser)
            laser.position = self:wrapPosition(laser)
        end
    end
end

function Alien:checkLaserHitAsteroids(asteroids)
    for laser_index = #self.laser_blasts, 1, -1 do
        local laser = self.laser_blasts[laser_index]

        for asteroid_index = #asteroids, 1, -1 do
            local asteroid         = asteroids[asteroid_index]
            local ast_r            = asteroid:getRadius()
            local ast_r_var        = asteroid:getRadiusPlusMinus()
            local separation_value = self:checkSeparation(
                laser.position,
                asteroid.position,
                ast_r + ast_r_var.plus
            )

            if separation_value and self:pointInPolygon(laser.position, asteroid) then
                local hit_position = {
                    x = laser.position.x,
                    y = laser.position.y,
                }

                table.remove(self.laser_blasts, laser_index)
                self:laserHitEffect(hit_position)

                local fragments = asteroid:explode()
                table.remove(asteroids, asteroid_index)
                if fragments then
                    for _, fragment in ipairs(fragments) do
                        table.insert(asteroids, fragment)
                    end
                end

                return true
            end
        end
    end

    return false
end

function Alien:checkLaserHitPlayer(player)
    if not player or player.dead then
        return false
    end

    if player.invulnerable and player.invulnerable > 0 then
        return false
    end

    for laser_index = #self.laser_blasts, 1, -1 do
        local laser            = self.laser_blasts[laser_index]
        local player_r         = player:getBoundingRadius()
        local separation_value = self:checkSeparation(
            laser.position,
            player.position,
            player_r
        )

        if separation_value and self:pointInPolygon(laser.position, player) then
            local hit_position = {
                x = laser.position.x,
                y = laser.position.y,
            }
            table.remove(self.laser_blasts, laser_index)
            self:laserHitEffect(hit_position)
            player:takesDamage(laser.damage)
            if player:getHealth() <= 0 then
                player:kill()
            end

            return true
        end
    end

    return false
end

function Alien:move()
    if self.dead then
        -- Still animate particles when dead
        self:moveParticles(self.TYPES.EXPLOSION)
        self:moveParticles(self.TYPES.SPARK)
        self:updateTimer()
        return
    end

    -- Alien moves at constant velocity (no thrust needed)
    -- Just update position and wrap
    self.position = self:movePointByVelocity()
    self:wrapPosition()
    self:updateTimer()

    -- Move any particles
    self:moveParticles(self.TYPES.EXPLOSION)
    self:moveParticles(self.TYPES.SPARK)
end

function Alien:takesDamage(damage)
    if damage == nil then
        damage = 1
    end
    self.cur_health = self.cur_health - damage
    self:sparkEffect()
    sfx(1, 60, 50, 1, 25)

    if self:getHealth() <= 0 then
        self:kill()
    end

    return self:getHealth()
end

function Alien:kill()
    if self.dead then
        return
    end
    self.dead = true
    self.active = false
    self:explode()
end

-- Alien doesn't respawn - it gets regenerated at level start
function Alien:respawn()
    -- No-op for alien
end

-- ==========================================
-- ALIEN DRAW
-- ==========================================

function Alien:drawLaserBlasts()
    for _, laser in ipairs(self.laser_blasts) do
        -- Use a simple red/yellow pixel or small circle.
        circ(laser.position.x, laser.position.y, 1, RED)
        pix(laser.position.x, laser.position.y, YELLOW)
    end
end

function Alien:draw()
    if not self.dead then
        self:drawBody()
    end
    self:drawLaserBlasts()
    self:drawParticles(self.TYPES.EXPLOSION)
    self:drawParticles(self.TYPES.SPARK)
end
