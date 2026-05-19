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
    return self.cur_health
end

function Ship:getHealthFraction()
    return self.cur_health / self.max_health
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
end

function Ship:move()
    if btn(BTN_P1_UP) then
        self:thrust()
    end

    self.velocity.speed = self.velocity.speed - self.deceleration
    if self.velocity.speed < 0 then
        self.velocity.speed = 0
    end

    SpaceObj.move(self)
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
                    -- Remove laser blast and mark the asteroid hit.
                    table.remove(self.laser_blasts, laser_index)
                    asteroid_was_hit = asteroid_index
                    return asteroid_was_hit -- immediately break out of loop
                end
            end
        end
    end
    return asteroid_was_hit
end

function Ship:takesDamage(damage)
    if damage == nil then
        damage = 0
    end
    self.cur_health = self.cur_health - damage
    return self:getHealth()
end

function Ship:kill()
    if self.dead then
        return
    end
    self.dead = true
    self.respawn_timer = 60 -- 1 second delay (60 fps)
end

function Ship:respawn()
    self.dead               = false
    self.cur_health         = self.max_health
    self.position.x         = EDGE_X_RIGHT / 2
    self.position.y         = EDGE_Y_BOTTOM / 2
    self.velocity.speed     = 0
    self.velocity.direction = 0
    self.rotation           = -math.pi / 2
    self.invulnerable       = 120       -- 2 seconds invulnerable
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

    sfx(2, 10, 30, 3, 15)

    drawCenteredText("EXPLODED", EDGE_Y_BOTTOM / 2, RED, true, 3, false, YELLOW)
end