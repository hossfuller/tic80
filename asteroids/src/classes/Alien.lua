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

    -- Alien doesn't use lasers (for now)
    self.laser_blasts = {}
    self.laser_params = {
        lifetime  = 0,
        max_shots = 0,
        speed     = 0,
        offset    = { x = 0, y = 0 }
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

function Alien:draw()
    if not self.dead then
        self:drawBody()
    end

    self:drawParticles(self.TYPES.EXPLOSION)
    self:drawParticles(self.TYPES.SPARK)
end