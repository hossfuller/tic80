-- ==========================================
-- SPACESHIP OBJECT
-- ==========================================

SpaceShip = setmetatable({}, { __index = KeplerObj })
SpaceShip.__index = SpaceShip

function SpaceShip:new(params)
    params = params or {}
    local self = KeplerObj.new(params) -- build base fields
    setmetatable(self, SpaceShip)     -- make it a SpaceShip instance

    -- For regenerating the various attributes. Lower number means slower
    -- regeneration. These also act as a multiplier for the max values.
    self.engines = {
        energy = {
            cur = params.engines.energy.cur or 250,
            max = params.engines.energy.max or 250,
            mul = params.engines.energy.mul or 1,
            tik = params.engines.energy.tik or 20,
        },
        life_support = {
            cur = params.engines.life_support.cur or 100,
            max = params.engines.life_support.max or 100,
            mul = params.engines.life_support.mul or 1,
            tik = params.engines.life_support.tik or 3600,
        },
        shield = {
            cur = params.engines.shield.cur or 100,
            max = params.engines.shield.max or 100,
            mul = params.engines.shield.mul or 1,
            tik = params.engines.shield.tik or 60,
        },
    }

    -- Cargo/passenger holds. Everything is measured in kg and limited by the
    -- max_mass property.
    self.holds = {
        cargo = {
            cur = params.holds.cargo.cur or 0,   -- (kg)
            max = params.holds.cargo.max or 500, -- (kg)
        },
        passengers = {
            cur = params.holds.passengers.cur or 0,      -- (kg)
            max = params.holds.passengers.max or 6 * PASSENGER_TOTAL_MASS, -- (individuals in kg)
        },
        smuggled = {
            cur = params.holds.smuggled.cur or 0,   -- (kg)
            max = params.holds.smuggled.max or 100, -- (kg)
        },
    }

    self.mass       = params.mass       or 100   -- (kg)
    self.radius     = params.radius     or 10    -- (pixels)
    self.elasticity = params.elasticity or 0.5
    self.max_mass   = params.max_mass   or 1300  -- (kg)
    self.max_speed  = params.max_speed  or 2.5

    -- The default SpaceShip shape
    self.shape = params.shape or {
        { x = 8,  y = 0 },
        { x = -8, y = 6 },
        { x = -4, y = 0 },
        { x = -8, y = -6 },
        { x = 8,  y = 0 }
    }

    local deadstop = params.deadstop or {}
    self.deadstop  = {
        brake = deadstop.brake or 0.35,   -- 0..1, higher = faster stop per frame
        snap  = deadstop.snap  or 0.02   -- below this speed, just snap to 0
    }

    self.mortality = {
        num_lives     = params.num_lives or 1,
        invulnerable  = 0,
        dead          = false,
        exploded      = false,
        respawn_timer = 0,
    }

    -- Particle Effects
    self.particles = {
        explosion = {
            colors = { YELLOW, ORANGE, RED },
            params = {
                cooldown      = 0,
                deceleration  = 0.015,
                max_lifetime  = 90,
                max_size      = 3,
                max_speed     = 2,
                num_particles = 100,
                offset        = { x = 0, y = 0 },
                type          = "explosion",
            },
            particles = {},
        },
        smoke = {
            colors = { GRAY_LITE, GRAY_MED, GRAY_DARK },
            params = {
                cooldown      = 0,
                deceleration  = 0.015,
                max_lifetime  = 90,
                max_size      = 3,
                max_speed     = 2,
                num_particles = 100,
                offset        = { x = 0, y = 0 },
                type          = "smoke",
            },
            particles = {},
        },
        spark = {
            colors = { ORANGE },
            params = {
                cooldown      = 0,
                deceleration  = 0.01,
                max_lifetime  = 30,
                max_size      = 1,
                max_speed     = 2,
                num_particles = 30,
                offset        = { x = 0, y = 0 },
                type          = "spark",
            },
            particles = {},
        },
        thrust = {
            colors = { YELLOW, ORANGE, RED, GRAY_LITE, GRAY_MED, GRAY_DARK },
            params = {
                cooldown      = 0,
                deceleration  = 0.01,
                max_lifetime  = 30,
                max_size      = 1,
                max_speed     = 2,
                num_particles = 5,
                offset        = { x = -5, y = 0 },
                type          = "thrust",
            },
            particles = {},
        },
    }

    return self
end

-- ==========================================
-- SPACESHIP STATUS GETTERS
-- ==========================================

function SpaceShip:getEnergy()
    if self.engines.energy.cur < 0 then
        self.engines.energy.cur = 0
    end
    return self.engines.energy.cur
end

function SpaceShip:getEnergyFraction()
    return self:getEnergy() / self.engines.energy.max
end

function SpaceShip:getEnergyMultiplier()
    return self.engines.energy.mul
end

function SpaceShip:getLifeSupport()
    if self.engines.life_support.cur < 0 then
        self.engines.life_support.cur = 0
    end
    return self.engines.life_support.cur
end

function SpaceShip:getLifeSupportFraction()
    return self:getLifeSupport() / self.engines.life_support.max
end

function SpaceShip:getLifeSupportMultiplier()
    return self.engines.life_support.mul
end

function SpaceShip:getShield()
    if self.engines.shield.cur < 0 then
        self.engines.shield.cur = 0
    end
    return self.engines.shield.cur
end

function SpaceShip:getShieldFraction()
    return self:getShield() / self.engines.shield.max
end

function SpaceShip:getShieldMultiplier()
    return self.engines.shield.mul
end


function SpaceShip:getHoldMassMax()
    return self.holds.cargo.max + self.holds.passengers.max + self.holds.smuggled.max
end

function SpaceShip:getCargoMass()
    return self.holds.cargo.cur
end

function SpaceShip:getCargoMassMax()
    return self.holds.cargo.max
end

function SpaceShip:getCargoMassFraction()
    return self:getCargoMass() / self:getHoldMassMax()
end

function SpaceShip:getPassengerMass()
    return self.holds.passengers.cur
end

function SpaceShip:getPassengerMassMax()
    return self.holds.passengers.max
end
function SpaceShip:getPassengerMassFraction()
    return self:getPassengerMass() / self:getHoldMassMax()
end

function SpaceShip:getSmuggledMass()
    return self.holds.smuggled.cur
end

function SpaceShip:getSmuggledMassMax()
    return self.holds.smuggled.max
end

function SpaceShip:getSmuggledMassFraction()
    return self:getSmuggledMass() / self:getHoldMassMax()
end

function SpaceShip:getTotalMass()
    return self.mass + self:getCargoMass() + self:getPassengerMass() + self:getSmuggledMass()
end

function SpaceShip:getTotalMassFraction()
    return self:getTotalMass() / self.max_mass
end


-- ==========================================
-- SPACESHIP ENGINE MANAGEMENT
-- ==========================================

-- TODO:
-- 1. Whenever one of these values regenerates, it pulls from energy. Unless
--    energy regenerates, and that happens on its own.
-- 2. Whenever one of these values gets upgraded, the ship's mass increases.

function SpaceShip:modifyEngineMaxValue(type, upgrade)
    if type == nil then
        type = "energy"
    end
    if upgrade == nil then
        upgrade = false
    end

    local new_engine_max = nil
    if type == "energy" then
        local max_chunk = math.floor(self.engines.energy.max / self.engines.energy.mul)
        if upgrade then
            self.engines.energy.mul = self.engines.energy.mul + 1
        else
            self.engines.energy.mul = self.engines.energy.mul - 1
        end
        if self.engines.energy.mul > 9 then
            self.engines.energy.mul = 9
        elseif self.engines.energy.mul < 1 then
            self.engines.energy.mul = 1
        end
        self.engines.energy.max = max_chunk * self.engines.energy.mul
        new_engine_max = self.engines.energy.mul
    elseif type == "life_support" then
        local max_chunk = math.floor(self.engines.life_support.max / self.engines.life_support.mul)
        if upgrade then
            self.engines.life_support.mul = self.engines.life_support.mul + 1
        else
            self.engines.life_support.mul = self.engines.life_support.mul - 1
        end
        if self.engines.life_support.mul > 9 then
            self.engines.life_support.mul = 9
        elseif self.engines.life_support.mul < 1 then
            self.engines.life_support.mul = 1
        end
        self.engines.life_support.max = max_chunk * self.engines.life_support.mul
        new_engine_max = self.engines.life_support.mul
    elseif type == "shield" then
        local max_chunk = math.floor(self.engines.shield.max / self.engines.shield.mul)
        if upgrade then
            self.engines.shield.mul = self.engines.shield.mul + 1
        else
            self.engines.shield.mul = self.engines.shield.mul - 1
        end
        if self.engines.shield.mul > 9 then
            self.engines.shield.mul = 9
        elseif self.engines.shield.mul < 1 then
            self.engines.shield.mul = 1
        end
        self.engines.shield.max = max_chunk * self.engines.shield.mul
        new_engine_max = self.engines.shield.mul
    end
    return new_engine_max
end

function SpaceShip:upgradeEnergyEngine()
    return self:modifyEngineMaxValue("energy", true)
end

function SpaceShip:degradeEnergyEngine()
    return self:modifyEngineMaxValue("energy", false)
end

function SpaceShip:upgradeLifeSupportEngine()
    return self:modifyEngineMaxValue("life_support", true)
end

function SpaceShip:degradeLifeSupportEngine()
    return self:modifyEngineMaxValue("life_support", false)
end

function SpaceShip:upgradeShieldEngine()
    return self:modifyEngineMaxValue("shield", true)
end

function SpaceShip:degradeShieldEngine()
    return self:modifyEngineMaxValue("shield", false)
end

function SpaceShip:modifyEngineCurrentValue(type, value)
    if type == nil then
        type = "energy"
    end
    if value == nil then
        value = 10
    end

    local new_engine_cur = nil
    if type == "energy" then
        self.engines.energy.cur = self.engines.energy.cur + value
        if self.engines.energy.cur > self.engines.energy.max then
            self.engines.energy.cur = self.engines.energy.max
        elseif self.engines.energy.cur < 0 then
            self.engines.energy.cur = 0
        end
        new_engine_cur = self.engines.energy.cur
    elseif type == "life_support" then
        self.engines.life_support.cur = self.engines.life_support.cur + value
        if self.engines.life_support.cur > self.engines.life_support.max then
            self.engines.life_support.cur = self.engines.life_support.max
        elseif self.engines.life_support.cur < 0 then
            self.engines.life_support.cur = 0
        end
        new_engine_cur = self.engines.life_support.cur
    elseif type == "shield" then
        self.engines.shield.cur = self.engines.shield.cur + value
        if self.engines.shield.cur > self.engines.shield.max then
            self.engines.shield.cur = self.engines.shield.max
        elseif self.engines.shield.cur < 0 then
            self.engines.shield.cur = 0
        end
        new_engine_cur = self.engines.shield.cur
    end
    return new_engine_cur
end

function SpaceShip:drainEnergy()
    return self:modifyEngineCurrentValue("energy", -1)
end

function SpaceShip:regenerateEnergy()
    return self:modifyEngineCurrentValue("energy", 1)
end

function SpaceShip:drainLifeSupport()
    return self:modifyEngineCurrentValue("life_support", -1)
end

function SpaceShip:regenerateLifeSupport()
    return self:modifyEngineCurrentValue("life_support", 1)
end

function SpaceShip:drainShield()
    return self:modifyEngineCurrentValue("shield", -1)
end

function SpaceShip:regenerateShield()
    return self:modifyEngineCurrentValue("shield", 1)
end

function SpaceShip:regenerateEnginesOnTimer()
    if self:everyNTicks(self.engines.energy.tik) then
        self:regenerateEnergy()
    end
    if (
        self:everyNTicks(self.engines.life_support.tik) and
        self:getEnergyFraction() > 0.99 and
        self:getShieldFraction() > 0.99
    ) then
        self:regenerateLifeSupport()
    end
    if self:everyNTicks(self.engines.shield.tik) then
        self:regenerateShield()
    end
end

-- ==========================================
-- SPACESHIP MASS MANAGEMENT
-- ==========================================

function SpaceShip:updateHoldMass(hold_type, mass)
    if hold_type == nil then
        hold_type = "cargo"
    end
    if mass == nil then
        mass = 100
    end

    local hold = self.holds[hold_type]
    if hold == nil then
        return false
    end

    local new_mass = hold.cur + mass
    if new_mass < 0 then
        new_mass = 0
    elseif new_mass > hold.max then
        return false
    end
    hold.cur = new_mass
    return true
end

function SpaceShip:pickupCargo(cargo_mass)
    return self:updateHoldMass("cargo", cargo_mass)
end

function SpaceShip:deliverCargo(cargo_mass)
    return self:updateHoldMass("cargo", -cargo_mass)
end

function SpaceShip:pickupPassengers(num_passengers)
    return self:updateHoldMass("passengers", num_passengers * PASSENGER_TOTAL_MASS)
end

function SpaceShip:deliverPassengers(num_passengers)
    return self:updateHoldMass("passengers", -num_passengers * PASSENGER_TOTAL_MASS)
end

function SpaceShip:pickupSmuggledGoods(smuggled_mass)
    return self:updateHoldMass("smuggled", smuggled_mass)
end

function SpaceShip:deliverSmuggledGoods(smuggled_mass)
    return self:updateHoldMass("smuggled", -smuggled_mass)
end



-- ==========================================
-- SPACESHIP PARTICLE EFFECTS
-- ==========================================

-- function SpaceShip:explosionEffect()
--     self.type               = self.PARTICLE_TYPES.EXPLOSION
--     self.deceleration       = 0.015
--     self.max_lifetime       = 90
--     self.max_size           = 3
--     self.max_speed          = 2
--     self.num_particles      = 100

--     local particle_velocity = {}
--     for particle = 1, self.num_particles do
--         particle_velocity = {
--             speed     = math.random() * self.max_speed,
--             direction = math.random() * math.pi * 2
--         }
--         self:spawnParticle(
--             self.position,
--             particle_velocity,
--             self.max_lifetime,
--             self.EXPLOSION_COLORS,
--             self.max_size,
--             self.deceleration,
--             self.type
--         )
--     end
-- end

-- function SpaceShip:leakingSmoke(health_fraction)
--     -- Check cooldown - don't spawn if still cooling down
--     if self.smoke_cooldown > 0 then
--         self.smoke_cooldown = self.smoke_cooldown - 1
--         return
--     end

--     self.type             = self.PARTICLE_TYPES.SMOKE
--     self.max_lifetime     = 90
--     self.max_size         = 1

--     -- Scale particle count based on damage (more damage = more smoke)
--     local damage_severity = 1 - (health_fraction / 0.5)
--     self.num_particles    = math.floor(1 + damage_severity)

--     -- Set cooldown based on health: more damage = shorter cooldown (more frequent smoke)
--     -- At 50% health: cooldown ~60 frames (1 second)
--     -- At 0% health: cooldown ~15 frames (0.25 seconds)
--     -- Smoke cooldown attributes can be tinkered like this:
--     --  1. Increase `attr_a` to make smoke less frequent at low damage.
--     --  2. Decrease `attr_b` to make the frequency diff between low and high
--     --     damage smaller.
--     --  3. Change self.max_lifetime to control how long each puff lingers.
--     local attr_a          = 30
--     local attr_b          = 75
--     self.smoke_cooldown   = math.floor(attr_a - (damage_severity * attr_b))

--     -- Random offset from ship center for spawn position
--     local spawn_offset    = {
--         x = (math.random() * 8) - 4,
--         y = (math.random() * 8) - 4
--     }
--     local rotated_offset  = self:rotatePoint(spawn_offset, self.rotation)
--     local spawn_position  = {
--         x = rotated_offset.x + self.position.x,
--         y = rotated_offset.y + self.position.y,
--     }

--     for particle = 1, self.num_particles do
--         local particle_velocity = {
--             speed     = 0,
--             direction = 0
--         }
--         self:spawnParticle(
--             spawn_position,
--             particle_velocity,
--             self.max_lifetime,
--             self.SMOKE_LEAK_COLORS,
--             self.max_size,
--             0,
--             self.type
--         )
--     end
-- end

-- function SpaceShip:sparkEffect(position)
--     self.type          = self.PARTICLE_TYPES.SPARK
--     self.deceleration  = 0.01
--     self.max_lifetime  = 30
--     self.max_size      = 1
--     self.max_speed     = 2
--     self.num_particles = 30

--     -- Fallback in case no position is passed
--     position           = position or self.position

--     for particle = 1, self.num_particles do
--         local particle_velocity = {
--             speed     = math.random() * self.max_speed,
--             direction = math.random() * math.pi * 2
--         }

--         self:spawnParticle(
--             position,
--             particle_velocity,
--             self.max_lifetime,
--             self.SPARK_COLORS,
--             self.max_size,
--             self.deceleration,
--             self.type
--         )
--     end
-- end

-- function SpaceShip:thrustEffect()
--     -- Effect-specific overrides
--     self.type                     = self.PARTICLE_TYPES.THRUST
--     self.deceleration             = 0.01
--     self.max_lifetime             = 30
--     self.max_size                 = 1
--     self.max_speed                = 2
--     self.num_particles            = 5

--     local thrust_offset           = { x = -5, y = 0 }
--     local particle_velocity       = {}
--     local direction               = 0
--     local relative_spawn_position = self:rotatePoint(thrust_offset, self.rotation)
--     local spawn_position          = {
--         x = relative_spawn_position.x + self.position.x,
--         y = relative_spawn_position.y + self.position.y,
--     }

--     for particle = 1, self.num_particles do
--         direction = self.rotation + math.pi + (math.random() * math.pi / 6) - (math.pi / 12)
--         direction = self:keepAngleInRange(direction)
--         particle_velocity = {
--             speed     = math.random() * self.max_speed,
--             direction = direction
--         }
--         self:spawnParticle(
--             spawn_position,
--             particle_velocity,
--             self.max_lifetime,
--             self.SMOKE_COLORS,
--             self.max_size,
--             self.deceleration,
--             self.type
--         )
--     end
-- end

-- function SpaceShip:spawnParticle(
--     position,
--     velocity,
--     max_lifetime,
--     colors,
--     max_size,
--     deceleration,
--     particle_type
-- )
--     local particle = {
--         position     = {
--             x = position.x,
--             y = position.y
--         },
--         velocity     = {
--             speed     = velocity.speed,
--             direction = velocity.direction
--         },
--         life_timer   = (max_lifetime / 2) + (math.random() * max_lifetime / 2),
--         colors       = colors,
--         size         = math.random(1, max_size),
--         deceleration = deceleration,
--         type         = particle_type
--     }

--     if particle_type == self.PARTICLE_TYPES.EXPLOSION then
--         table.insert(self.explosionParticles, particle)
--     elseif particle_type == self.PARTICLE_TYPES.LASER_HIT then
--         table.insert(self.laserHitParticles, particle)
--     elseif particle_type == self.PARTICLE_TYPES.SMOKE then
--         table.insert(self.smokeParticles, particle)
--     elseif particle_type == self.PARTICLE_TYPES.SPARK then
--         table.insert(self.sparkParticles, particle)
--     elseif particle_type == self.PARTICLE_TYPES.THRUST then
--         table.insert(self.thrustParticles, particle)
--     end
-- end

-- function SpaceShip:moveParticles(particle_type)
--     local particles = self.explosionParticles

--     if particle_type == self.PARTICLE_TYPES.LASER_HIT then
--         particles = self.laserHitParticles
--     elseif particle_type == self.PARTICLE_TYPES.SMOKE then
--         particles = self.smokeParticles
--     elseif particle_type == self.PARTICLE_TYPES.SPARK then
--         particles = self.sparkParticles
--     elseif particle_type == self.PARTICLE_TYPES.THRUST then
--         particles = self.thrustParticles
--     end

--     for index = #particles, 1, -1 do
--         local particle = particles[index]

--         particle.life_timer = particle.life_timer - 1

--         if particle.life_timer < 0 then
--             table.remove(particles, index)
--         else
--             particle.position = self:movePointByVelocity(particle)

--             particle.velocity.speed = particle.velocity.speed - particle.deceleration
--             if particle.velocity.speed < 0 then
--                 particle.velocity.speed = 0
--             end
--         end
--     end
-- end

-- function SpaceShip:drawParticles(particle_type)
--     local particles = self.particles.explosion

--     if particle_type == self.PARTICLE_TYPES.SMOKE then
--         particles = self.particles.smoke
--     elseif particle_type == self.PARTICLE_TYPES.SPARK then
--         particles = self.particles.spark
--     elseif particle_type == self.PARTICLE_TYPES.THRUST then
--         particles = self.particles.thrust
--     end

--     for index, particle in ipairs(particles) do
--         local particle_color = particle.colors[math.random(1, #particle.colors)]

--         if particle.type == self.PARTICLE_TYPES.EXPLOSION or particle.type == self.PARTICLE_TYPES.LASER_HIT then
--             circ(particle.position.x, particle.position.y, particle.size, particle_color)
--         elseif particle.type == self.PARTICLE_TYPES.THRUST then
--             pix(particle.position.x, particle.position.y, particle_color)
--         elseif particle.type == self.PARTICLE_TYPES.SMOKE then
--             circ(particle.position.x, particle.position.y, particle.size, particle_color)
--         else
--             rect(particle.position.x, particle.position.y, particle.size, particle.size, particle_color)
--         end
--     end
-- end



-- ==========================================
-- SPACESHIP INPUT
-- ==========================================

function SpaceShip:deadStop()
    local s = self.velocity.speed
    if self.velocity.speed <= 0 then
        self.velocity.speed     = 0
        self.velocity.direction = 0
        return
    end

    -- Smoothly reduce speed; never goes negative
    self.velocity.speed = self.velocity.speed * (1 - self.deadstop.brake)
    if self.velocity.speed < self.deadstop.snap then
        self.velocity.speed     = 0
        self.velocity.direction = 0
    end
end

function SpaceShip:thrust()
    local acceleration = {
        speed     = self.acceleration,
        direction = self.rotation
    }
    self.velocity = self:addVectors(self.velocity, acceleration)
    if self.velocity.speed > self.max_speed then
        self.velocity.speed = self.max_speed
    end

    -- self:thrustEffect()
    -- sfx(3, 10, 10, 3, -8, 1)
end

-- Need to do an energy check before doing any of the following.
function SpaceShip:input()
    if self.mortality.dead or self:getEnergy() <= 0 then
        return
    end

    local used_energy = false

    if btn(BTN_P1_UP) then
        self:thrust()
        used_energy = true
    end

    if btn(BTN_P1_DOWN) then
        self:deadStop()
        used_energy = true
    end

    if btn(BTN_P1_LEFT) then
        self.rotation = self.rotation - self.rotation_speed
        used_energy = true
    end

    if btn(BTN_P1_RIGHT) then
        self.rotation = self.rotation + self.rotation_speed
        used_energy = true
    end

    self.rotation = self:keepAngleInRange(self.rotation)

    if used_energy then
        self:drainEnergy()
    end
end

-- ==========================================
-- SPACESHIP UPDATE
-- ==========================================

function SpaceShip:move()
    self:updateTimer()

    if not self.mortality.dead then
        -- We want to be able to coast without any deceleration....
        -- self.velocity.speed = self.velocity.speed - self.deceleration
        -- if self.velocity.speed < 0 then
        --     self.velocity.speed = 0
        -- end

        -- -- Leak smoke when damaged
        -- local health_frac = self:getHealthFraction()
        -- if health_frac < 0.5 then
        --     self:leakingSmoke(health_frac)
        -- end

        self.position   = self:movePointByVelocity()
        self.position.x = clamp(self.position.x, 0, MAP_PIXELS_W - 1)
        self.position.y = clamp(self.position.y, 0, MAP_PIXELS_H - 1)

        self:regenerateEnginesOnTimer()
    else
        -- Dead ship body does not move, but particles still animate.
        -- self:moveParticles(self.TYPES.EXPLOSION)
        -- self:moveParticles(self.TYPES.SMOKE)
        -- self:moveParticles(self.TYPES.THRUST)
    end
end

function SpaceShip:kill()
    if self.mortality.dead then
        return
    end
    self.mortality.dead = true
    self.mortality.num_lives = self.mortality.num_lives - 1
    self.mortality.respawn_timer = 90
    self:explode()
end

-- ==========================================
-- SPACESHIP DRAW
-- ==========================================

-- This is for when the ship first starts out and is invulnerable.
function SpaceShip:shouldDraw()
    if self.mortality.invulnerable <= 0 then
        return true
    end
    -- blink: visible 6 frames, invisible 6 frames
    return (math.floor(self.mortality.invulnerable / 6) % 2) == 0
end

function SpaceShip:getScreenShapePoints()
    local screen_x, screen_y = worldToScreen(self.position.x, self.position.y)
    local zoom = game.camera.zoom or 1

    screen_x = math.floor(screen_x)
    screen_y = math.floor(screen_y)

    local points = {}

    for i, point in ipairs(self.shape) do
        local rotated_point = self:rotatePoint(point, self.rotation)

        points[i] = {
            x = math.floor(screen_x + rotated_point.x * zoom),
            y = math.floor(screen_y + rotated_point.y * zoom),
        }
    end

    return points
end

function SpaceShip:drawBody()
    local zoom = game.camera.zoom or 1

    if zoom <= 0.25 then
        local x, y = worldToScreen(self.position.x, self.position.y)

        x = math.floor(x)
        y = math.floor(y)

        pix(x, y, self.color)
        pix(x - 1, y, self.color)
        pix(x + 1, y, self.color)
        pix(x, y - 1, self.color)
        pix(x, y + 1, self.color)

        return
    end

    local points = self:getScreenShapePoints()

    -- Draw a ship-shaped black mask first.
    drawFilledPolygon(points, BLACK)

    -- Draw the ship outline on top.
    drawPolygonOutline(points, self.color)
end

function SpaceShip:draw()
    if not self.mortality.dead and self:shouldDraw() then
        self:drawBody()
    end

    -- Draw particle effects.
    -- self:drawParticles(self.TYPES.EXPLOSION)
    -- self:drawParticles(self.TYPES.LASER_HIT)
    -- self:drawParticles(self.TYPES.SPARK)
    -- self:drawParticles(self.TYPES.THRUST)
end

function SpaceShip:explode()
    if self.mortality.exploded then
        return
    end
    self.mortality.exploded = true
    -- self:explosionEffect()
    -- sfx(2, 10, 30, 3, 15)
end
