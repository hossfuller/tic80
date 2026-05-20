-- ==========================================
-- SHIP OBJECT
-- ==========================================

Ship = setmetatable({}, { __index = SpaceObj })
Ship.__index = Ship

function Ship:new(params)
    params = params or {}
    local self = SpaceObj.new(params) -- build base fields
    setmetatable(self, Ship)          -- make it a Ship instance

    -- Ship-specific properties
    self.max_health    = params.max_health or 1000
    self.cur_health    = self.max_health
    self.max_lives     = params.max_lives or 3
    self.cur_lives     = self.max_lives
    self.invulnerable  = 0
    self.dead          = false
    self.exploded      = false
    self.respawn_timer = 0

    self.deadstop = {
        brake = params.brake or 0.35, -- 0..1, higher = faster stop per frame
        snap  = params.snap  or 0.02  -- below this speed, just snap to 0
    }
    self.radius = params.radius or 10
    self.shape  = params.shape or {
        { x = 8,  y = 0  },
        { x = -8, y = 6  },
        { x = -4, y = 0  },
        { x = -8, y = -6 },
        { x = 8,  y = 0  }
    }

    -- laser blast stuff
    self.laser_blasts = {}
    self.laser_params = {
        lifetime  = params.lifetime or 60,
        max_shots = params.shots    or 4,
        speed     = 2,
        offset    = {
            x = 8,
            y = 0,
        }
    }

    return self
end

-- ==========================================
-- SHIP MATH
-- ==========================================

-- ==========================================
-- SHIP GETTERS
-- ==========================================

function Ship:getHealth()
    if self.cur_health < 0 then
        self.cur_health = 0
    end
    return self.cur_health
end

function Ship:getHealthFraction()
    return self:getHealth() / self.max_health
end

function Ship:getNumLaserBlasts()
    return #self.laser_blasts
end

function Ship:getNumLives()
    return self.cur_lives
end

-- ==========================================
-- SHIP INPUT
-- ==========================================

function Ship:input()
    if btn(BTN_P1_LEFT) then
        self.rotation = self.rotation - self.rotation_speed
    end
    if btn(BTN_P1_RIGHT) then
        self.rotation = self.rotation + self.rotation_speed
    end
    if btnp(BTN_P1_A) then
        self:fireLaserBlast()
    end

    self.rotation = self:keepAngleInRange(self.rotation)
end


-- ==========================================
-- SHIP UPDATE
-- ==========================================

function Ship:deadStop(brake, snap)
    if brake == nil then
        brake = self.deadstop.brake
    end
    if snap == nil then
        snap = self.deadstop.snap
    end
    local s = self.velocity.speed
    if s <= 0 then
        self.velocity.speed = 0
        self.velocity.direction = 0
        return
    end

    -- Smoothly reduce speed; never goes negative
    s = s * (1 - brake)
    if s < snap then
        s = 0
        self.velocity.direction = 0
    end
    self.velocity.speed = s
end

function Ship:thrust()
    local acceleration = {
        speed     = self.acceleration,
        direction = self.rotation
    }
    self.velocity = self:addVectors(self.velocity, acceleration)

    self:thrustEffect()
    sfx(3, 10, 10, 3, -8, 1)
end

function Ship:move()
    if not self.dead and btn(BTN_P1_UP) then
        self:thrust()
    end

    if not self.dead then
        self.velocity.speed = self.velocity.speed - self.deceleration
        if self.velocity.speed < 0 then
            self.velocity.speed = 0
        end

        -- Leak smoke when damaged
        local health_frac = self:getHealthFraction()
        if health_frac < 0.5 then
            self:leakingSmoke(health_frac)
        end

        SpaceObj.move(self)
    else
        -- Dead ship body does not move, but particles still animate.
        self:moveParticles(self.TYPES.EXPLOSION)
        self:moveParticles(self.TYPES.LASER_HIT)
        self:moveParticles(self.TYPES.SMOKE)
        self:moveParticles(self.TYPES.THRUST)
        self:updateTimer()
    end
end

function Ship:spawnLaserBlast()
    local rel_spawn_pos = self:rotatePoint(self.laser_params.offset, self.rotation)
    return {
        position = {
            x = rel_spawn_pos.x + self.position.x,
            y = rel_spawn_pos.y + self.position.y,
        },
        velocity = {
            speed = self.laser_params.speed,
            direction = self.rotation,
        },
        lifetime = self.laser_params.lifetime,
    }
end

function Ship:fireLaserBlast()
    if #self.laser_blasts < self.laser_params.max_shots then
        -- Okay to fire
        table.insert(self.laser_blasts, self:spawnLaserBlast())
        sfx(0, 40, 20, 0, 15, 1)
    end
end

function Ship:moveLaserBlasts()
    for index, laser in ipairs(self.laser_blasts) do
        laser.lifetime = laser.lifetime - 1
        if laser.lifetime < 0 then
            table.remove(self.laser_blasts, index)
        else
            laser.position = self:movePointByVelocity(laser)
            laser.position = self:wrapPosition(laser)
        end
    end
end

function Ship:checkLaserHit(asteroids)
    asteroid_was_hit = -1
    for laser_index, laser in ipairs(self.laser_blasts) do
        for asteroid_index, asteroid in ipairs(asteroids) do
            ast_r = asteroid:getRadius()
            ast_r_var = asteroid:getRadiusPlusMinus()
            separation_value = self:checkSeparation(
                laser.position,
                asteroid.position,
                ast_r + ast_r_var.plus
            )
            if separation_value then
                if self:pointInPolygon(laser.position, asteroid) then
                    local hit_position = {
                        x = laser.position.x,
                        y = laser.position.y
                    }
                    -- Remove laser blast and mark the asteroid hit.
                    table.remove(self.laser_blasts, laser_index)
                    asteroid_was_hit = asteroid_index
                    self:laserHitEffect(hit_position)
                    return asteroid_was_hit
                end
            end
        end
    end
    return asteroid_was_hit
end

function Ship:checkLaserHitAlien(alien)
    if not alien or not alien:isActive() then
        return false
    end
    
    for laser_index, laser in ipairs(self.laser_blasts) do
        local alien_r = alien:getBoundingRadius()
        local separation_value = self:checkSeparation(
            laser.position,
            alien.position,
            alien_r
        )
        if separation_value then
            if self:pointInPolygon(laser.position, alien) then
                local hit_position = {
                    x = laser.position.x,
                    y = laser.position.y
                }
                -- Remove laser blast and damage the alien
                table.remove(self.laser_blasts, laser_index)
                self:laserHitEffect(hit_position)
                alien:takesDamage(1)
                return true
            end
        end
    end
    return false
end


function Ship:regenerateHealth()
    if self.cur_health < self.max_health then
        self.cur_health = self.cur_health + 1
    end
    return self.cur_health
end

function Ship:takesDamage(damage)
    if damage == nil then
        damage = 0
    end
    self.cur_health = self.cur_health - damage
    self:sparkEffect()
    sfx(1, 60, 50, 1, 25)

    return self:getHealth()
end

function Ship:kill()
    if self.dead then
        return
    end
    self.dead = true
    self.cur_lives = self.cur_lives - 1
    self.respawn_timer = 90
    self:explode()
end

function Ship:respawn()
    self.dead               = false
    self.exploded           = false
    self.cur_health         = self.max_health
    self.position.x         = EDGE_X_RIGHT / 2
    self.position.y         = EDGE_Y_BOTTOM / 2
    self.velocity.speed     = 0
    self.velocity.direction = 0
    self.rotation           = -math.pi / 2
    self.invulnerable       = 120 -- 2 seconds invulnerable
    self.smoke_cooldown     = 0
end


-- ==========================================
-- SHIP DRAW
-- ==========================================

function Ship:drawLaserBlasts()
    for index, laser in ipairs(self.laser_blasts) do
        spr(1, laser.position.x, laser.position.y, 0)
    end
end

-- This is for when the ship first starts out and is invulnerable.
function Ship:shouldDraw()
    if self.invulnerable <= 0 then
        return true
    end
    -- blink: visible 6 frames, invisible 6 frames
    return (math.floor(self.invulnerable / 6) % 2) == 0
end

function Ship:explode()
    if self.exploded then
        return
    end
    self.exploded = true
    self:explosionEffect()
    sfx(2, 10, 30, 3, 15)
end
