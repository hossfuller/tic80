-- ==========================================
-- SPACESHIP OBJECT
-- ==========================================

SpaceShip = setmetatable({}, { __index = KeplerObj })
SpaceShip.__index = SpaceShip

function SpaceShip:new(params)
    params = params or {}
    local self = KeplerObj:new(params) -- build base fields
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
    self.mission_manifest = {
        cargo      = {},
        passengers = {},
        smuggled   = {},
    }
    self.cargo_has_ore = params.cargo_has_ore or false

    self.mass       = params.mass       or 100   -- (kg)
    self.radius     = params.radius     or 10    -- (pixels)
    self.elasticity = params.elasticity or 0.5
    self.max_mass   = params.max_mass   or 1300  -- (kg)
    self.max_speed  = params.max_speed  or 2.5

    self.base_max_speed = self.max_speed
    self.base_max_mass  = self.max_mass

    self.mass_delivered = 0  -- (kg) this is basically the score

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
        brake = deadstop.brake or 0.05, -- 0..1, higher = faster stop per frame
        snap  = deadstop.snap  or 0.02  -- below this speed, just snap to 0
    }

    self.mortality = {
        num_lives     = params.num_lives or 3,
        invulnerable  = 0,
        dead          = false,
        exploded      = false,
        respawn_timer = 0,
    }
    self.spawn = {
        x        = self.position.x,
        y        = self.position.y,
        rotation = self.rotation,
    }

    self.harpoon    = {
        attached     = false,
        target       = nil,
        offset_x     = 0,
        offset_y     = 0,
        range        = params.harpoon_range        or HARPOON_RANGE,
        lock_offset  = params.harpoon_lock_offset  or HARPOON_LOCK_OFFSET,
        reel_speed   = params.harpoon_reel_speed   or HARPOON_REEL_SPEED,
        reel_padding = params.harpoon_reel_padding or HARPOON_REEL_PADDING,
        release_push = params.harpoon_release_push or HARPOON_RELEASE_PUSH,
        line_color   = params.harpoon_line_color   or GRAY_LITE,
        anchor_color = params.harpoon_anchor_color or YELLOW,
    }

    -- Particle Effects: all particles use the same simple particle tuning vars.
    self.particles  = {
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
                count_min    = 70,
                count_max    = 110,
                speed_min    = 0.8,
                speed_max    = 4.2,
                life_min     = 35,
                life_max     = 95,
                size_min     = 1,
                size_max     = 3,
                drag         = 0.975,
                spawn_radius = (self.radius or 10) * 1.6,
            },
            particles = {},
        },
        smoke = {
            colors = params.smoke_colors or {
                GRAY_DARK,
                GRAY_MED,
                GRAY_LITE,
            },
            params = {
                -- Spawn chance is calculated from life support fraction.
                spawn_chance_min = 0.04,
                spawn_chance_max = 0.65,
                count_min        = 1,
                count_max        = 2,
                speed_min        = 0.05,
                speed_max        = 0.45,
                life_min         = 32,
                life_max         = 90,
                size_min         = 1,
                size_max         = 3,
                drag             = 0.985,
                diffuse_speed    = 0.35,                -- Random outward diffusion.
                trail_strength   = 0.65,                -- smoke trails opposite current ship movement
                spawn_radius     = self.radius or 10,
            },
            particles = {},
        },
        spark = {
            colors = params.spark_colors or {
                YELLOW,
                ORANGE,
                RED,
                WHITE,
            },
            params = {
                count_min    = 6,
                count_max    = 14,
                speed_min    = 0.5,
                speed_max    = 2.2,
                life_min     = 8,
                life_max     = 22,
                size_min     = 1,
                size_max     = 1,
                drag         = 0.92,
                spawn_radius = self.radius or 10,
            },
            particles = {},
        },

        thrust = {
            colors = params.thrust_colors or {
                BLUE_LITE,
                CYAN,
                WHITE,
                ORANGE,
            },
            params = {
                count_min      = 1,
                count_max      = 3,
                speed_min      = 0.4,
                speed_max      = 1.4,
                life_min       = 8,
                life_max       = 18,
                size_min       = 1,
                size_max       = 2,
                drag           = 0.94,
                spread         = math.pi / 7,         -- Exhaust cone behind the ship.
                backend_offset = self.radius or 10,   -- Spawn just behind ship center.
                side_jitter    = 3,                   -- Slight side jitter so exhaust is not a single line.
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

function SpaceShip:getMassDelivered()
    -- this is basically the user's score.
    return self.mass_delivered
end

function SpaceShip:isFinished()
    -- If the ship still has lives, it is not truly finished.
    if self.mortality and self.mortality.num_lives > 0 then
        return false
    end

    -- No lives left. Optionally wait for particles to finish before considering
    -- the ship fully finished.
    if self.particles then
        for _, system in pairs(self.particles) do
            if system.particles and #system.particles > 0 then
                return false
            end
        end
    end

    return self.dead
end

-- ==========================================
-- SPACESHIP ENGINE MANAGEMENT
-- ==========================================

function SpaceShip:getAddedMass()
    return self:getCargoMass() + self:getPassengerMass() + self:getSmuggledMass()
end

function SpaceShip:getAddedMassMax()
    return self.max_mass - self.mass
end

function SpaceShip:getAddedMassFraction()
    local added_mass_max = self:getAddedMassMax()

    if added_mass_max <= 0 then
        return 0
    end

    return clamp(self:getAddedMass() / added_mass_max, 0, 1)
end

function SpaceShip:getEnergyDrainMultiplier()
    local load_fraction = self:getAddedMassFraction()

    -- At full added mass, energy drains 3x faster.
    local max_multiplier = 3

    return 1 + load_fraction * (max_multiplier - 1)
end

function SpaceShip:getEnergyDrainAmount()
    return math.ceil(self:getEnergyDrainMultiplier())
end

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

function SpaceShip:drainEnergy(amount)
    amount = amount or self:getEnergyDrainAmount()
    return self:modifyEngineCurrentValue("energy", -amount)
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

function SpaceShip:drainLifeSupportForPassengers()
    if not self.holds or not self.holds.passengers then
        return
    end

    -- Once per second.
    if not self:everyNTicks(60) then
        return
    end

    local passenger_count = math.floor(self.holds.passengers.cur / PASSENGER_TOTAL_MASS)
    if passenger_count <= 0 then
        return
    end

    -- Drain 1 life support per passenger.
    for i = 1, passenger_count do
        self:drainLifeSupport()
    end
end

-- ==========================================
-- SPACESHIP LEVEL-COMPLETE UPGRADE MANAGEMENT
-- ==========================================

function SpaceShip:canUpgradeEngine(type)
    if not self.engines or not self.engines[type] then
        return false
    end

    return (self.engines[type].mul or 1) < 9
end

function SpaceShip:upgradeEngine(type)
    if not self:canUpgradeEngine(type) then
        return false
    end

    self.engines[type].mul = self.engines[type].mul + 1

    local max_chunk = math.floor(self.engines[type].max / (self.engines[type].mul - 1))
    self.engines[type].max = max_chunk * self.engines[type].mul

    return true
end

function SpaceShip:canUpgradeMaxSpeed()
    if not self.base_max_speed then
        return false
    end

    return self.max_speed < (self.base_max_speed * 1.2)
end

function SpaceShip:upgradeMaxSpeed()
    if not self:canUpgradeMaxSpeed() then
        return false
    end

    local multiplier = randomFloat(1.02, 1.1)
    self.max_speed = math.min(self.max_speed * multiplier, self.base_max_speed * 1.2)

    return true
end

function SpaceShip:canUpgradeHold(hold_type)
    if not self.holds or not self.holds[hold_type] then
        return false
    end

    if not self.base_max_mass then
        return false
    end

    return self.max_mass < (self.base_max_mass * 1.4)
end

function SpaceShip:upgradeHold(hold_type)
    if not self:canUpgradeHold(hold_type) then
        return false
    end

    local hold = self.holds[hold_type]
    hold.max = hold.max + 100
    self.max_mass = math.min(self.max_mass + 100, math.floor(self.base_max_mass * 1.4))

    return true
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
    cargo_mass = cargo_mass or 0

    local before = self:getCargoMass()
    local amount = math.min(cargo_mass, before)
    if amount <= 0 then
        return false
    end

    local delivered = self:updateHoldMass("cargo", -amount)
    if delivered then
        self:updateMassDelivered(amount)

        if self:getCargoMass() <= 0 then
            self.cargo_has_ore = false
        end
    end

    return delivered
end

function SpaceShip:pickupPassengers(num_passengers)
    return self:updateHoldMass("passengers", num_passengers * PASSENGER_TOTAL_MASS)
end

function SpaceShip:deliverPassengers(num_passengers)
    num_passengers = num_passengers or 0

    local requested_mass = num_passengers * PASSENGER_TOTAL_MASS
    local before = self:getPassengerMass()
    local amount = math.min(requested_mass, before)
    if amount <= 0 then
        return false
    end

    local delivered = self:updateHoldMass("passengers", -amount)
    if delivered then
        self:updateMassDelivered(amount)
    end

    return delivered
end

function SpaceShip:pickupSmuggledGoods(smuggled_mass)
    return self:updateHoldMass("smuggled", smuggled_mass)
end

function SpaceShip:deliverSmuggledGoods(smuggled_mass)
    smuggled_mass = smuggled_mass or 0

    local before = self:getSmuggledMass()
    local amount = math.min(smuggled_mass, before)
    if amount <= 0 then
        return false
    end

    local delivered = self:updateHoldMass("smuggled", -amount)
    if delivered then
        self:updateMassDelivered(amount)
    end

    return delivered
end

-- ==========================================
-- SPACESHIP MINING
-- ==========================================

function SpaceShip:getCargoFreeMass()
    return math.max(0, self:getCargoMassMax() - self:getCargoMass())
end

function SpaceShip:getMiningTarget()
    if not self.harpoon then
        return nil
    end

    if not self.harpoon.attached then
        return nil
    end

    local target = self.harpoon.target
    if not target or target.dead or target.mineable == false then
        return nil
    end
    if not target.mass or target.mass <= 0 then
        return nil
    end

    return target
end

function SpaceShip:canMineHarpoonTarget()
    local target = self:getMiningTarget()

    if not target then
        return false
    end

    -- No cargo space.
    if self:getCargoFreeMass() <= 0 then
        return false
    end

    -- Empty cargo hold can start ore cargo.
    if self:getCargoMass() <= 0 then
        return true
    end

    -- Non-empty hold can continue mining only if current cargo is ore.
    return self.cargo_has_ore == true
end

function SpaceShip:mineHarpoonTarget()
    local target = self:getMiningTarget()

    if not target then
        return false
    end

    if not self:canMineHarpoonTarget() then
        return false
    end

    local free_mass = self:getCargoFreeMass()
    if free_mass <= 0 then
        return false
    end

    local mine_mass = math.min(target.mass, free_mass, HARPOON_MINE_RATE)
    if mine_mass <= 0 then
        return false
    end

    -- If the cargo hold was empty, this establishes that the current cargo is ore.
    if self:getCargoMass() <= 0 then
        self.cargo_has_ore = true
    end

    -- Reuse existing cargo setter logic.
    local picked_up = self:pickupCargo(mine_mass)

    if not picked_up then
        return false
    end

    target.mass = target.mass - mine_mass

    if target.mass <= 0 then
        target.mass = 0
        target:kill()

        -- The harpoon should not remain attached to a mined-out object.
        if self.harpoon and self.harpoon.target == target then
            self:clearHarpoon()
        end
    end

    return true
end

-- ==========================================
-- SPACESHIP PARTICLE EFFECTS
-- ==========================================

function SpaceShip:getParticleSystem(type)
    if not self.particles then
        return nil
    end

    return self.particles[type]
end

function SpaceShip:addParticle(type, particle)
    local system = self:getParticleSystem(type)

    if not system then
        return
    end

    table.insert(system.particles, particle)
end

function SpaceShip:spawnParticleBurst(type, origin_x, origin_y, base_direction, spread, count)
    local system = self:getParticleSystem(type)

    if not system then
        return
    end

    local p = system.params
    local colors = system.colors

    count = count or math.random(p.count_min or 1, p.count_max or 1)
    spread = spread or math.pi * 2

    for i = 1, count do
        local direction

        if base_direction then
            direction = base_direction + randomFloat(-spread, spread)
        else
            direction = randomFloat(0, math.pi * 2)
        end

        direction = self:keepAngleInRange(direction)

        local speed = randomFloat(p.speed_min or 0.1, p.speed_max or 1)
        local life = math.random(p.life_min or 10, p.life_max or 30)
        local size = math.random(p.size_min or 1, p.size_max or 1)

        local spawn_radius = p.spawn_radius or 0
        local spawn_angle = self:keepAngleInRange(randomFloat(0, math.pi * 2))
        local spawn_dist = randomFloat(0, spawn_radius)

        local offset = self:rotatePoint({
            x = spawn_dist,
            y = 0
        }, spawn_angle)

        local sx = origin_x + offset.x
        local sy = origin_y + offset.y

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
            gravity  = {
                speed     = p.gravity_speed or 0,
                direction = p.gravity_direction or 0,
            },
        })
    end
end

function SpaceShip:updateParticleList(type)
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
            if particle.gravity and particle.gravity.speed and particle.gravity.speed ~= 0 then
                particle.velocity = self:addVectors(particle.velocity, particle.gravity)
            end

            particle.velocity.speed = particle.velocity.speed * (particle.drag or 1)
            particle.velocity.direction = self:keepAngleInRange(particle.velocity.direction or 0)

            local components = self:getVectorComponents(particle.velocity)

            particle.position.x = particle.position.x + components.xComp
            particle.position.y = particle.position.y + components.yComp
        end
    end
end

function SpaceShip:updateParticles()
    if not self.particles then
        return
    end

    self:updateParticleList("explosion")
    self:updateParticleList("smoke")
    self:updateParticleList("spark")
    self:updateParticleList("thrust")
end

function SpaceShip:drawParticles(type)
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

function SpaceShip:drawAllParticles()
    if not self.particles then
        return
    end

    -- Draw smoke/explosion behind hotter particles.
    self:drawParticles("smoke")
    self:drawParticles("explosion")
    self:drawParticles("thrust")
    self:drawParticles("spark")
end


function SpaceShip:explosionEffect()
    local system = self:getParticleSystem("explosion")

    if not system then
        return
    end

    local p = system.params
    local count = math.random(p.count_min or 20, p.count_max or 40)
    self:spawnParticleBurst(
        "explosion",
        self.position.x,
        self.position.y,
        nil,
        math.pi * 2,
        count
    )
end

function SpaceShip:smokeEffect()
    local system = self:getParticleSystem("smoke")
    if not system then
        return
    end

    local life_fraction = self:getLifeSupportFraction()
    if life_fraction > 0.5 then
        return
    end

    local p               = system.params
    local damage_fraction = clamp((0.5 - life_fraction) / 0.5, 0, 1)
    local spawn_chance    =
        (p.spawn_chance_min or 0.04) +
        damage_fraction * ((p.spawn_chance_max or 0.65) - (p.spawn_chance_min or 0.04))

    if math.random() > spawn_chance then
        return
    end

    local count = math.random(p.count_min or 1, p.count_max or 2)
    local ship_speed = self.velocity and self.velocity.speed or 0

    for i = 1, count do
        local spawn_radius = p.spawn_radius or self.radius or 10
        local spawn_angle  = self:keepAngleInRange(randomFloat(0, math.pi * 2))
        local spawn_dist   = randomFloat(0, spawn_radius * 0.7)
        local spawn_offset = self:rotatePoint({
            x = spawn_dist,
            y = 0,
        }, spawn_angle)
        local x              = self.position.x + spawn_offset.x
        local y              = self.position.y + spawn_offset.y
        local diffuse_angle  = self:keepAngleInRange(randomFloat(0, math.pi * 2))
        local diffuse_speed  = randomFloat(0.02, p.diffuse_speed or 0.35)
        local smoke_velocity = {
            speed = diffuse_speed,
            direction = diffuse_angle,
        }

        -- If the ship is moving, smoke trails behind it.
        if ship_speed > 0.05 then
            local trail_strength = p.trail_strength or 0.65
            local trail_velocity = {
                speed = ship_speed * trail_strength,
                direction = self:keepAngleInRange(self.velocity.direction + math.pi),
            }
            smoke_velocity = self:addVectors(smoke_velocity, trail_velocity)
        end

        smoke_velocity.direction = self:keepAngleInRange(
            smoke_velocity.direction or 0
        )

        local life = math.random(p.life_min or 30, p.life_max or 80)
        local size = math.random(p.size_min or 1, p.size_max or 3)
        self:addParticle("smoke", {
            position = {
                x = x,
                y = y,
            },
            velocity = smoke_velocity,
            life     = life,
            max_life = life,
            color    = randomChoice(system.colors),
            size     = size,
            drag     = p.drag or 0.985,
            gravity  = {
                speed     = p.gravity_speed or 0,
                direction = p.gravity_direction or 0,
            },
        })
    end
end

function SpaceShip:sparkEffect()
    local system = self:getParticleSystem("spark")

    if not system then
        return
    end

    local p         = system.params
    local count     = math.random(p.count_min or 4, p.count_max or 10)
    local direction = nil
    if self.velocity and self.velocity.speed and self.velocity.speed > 0.05 then
        direction = self:keepAngleInRange(self.velocity.direction + math.pi)
    end

    self:spawnParticleBurst(
        "spark",
        self.position.x,
        self.position.y,
        direction,
        math.pi / 1.5,
        count
    )
end

function SpaceShip:thrustEffect()
    local system = self:getParticleSystem("thrust")

    if not system then
        return
    end

    local p                 = system.params
    local exhaust_direction = self:keepAngleInRange(self.rotation + math.pi)
    local backend_distance  = p.backend_offset or self.radius or 10
    local side_jitter       = p.side_jitter or 0
    local count             = math.random(p.count_min or 1, p.count_max or 1)

    for i = 1, count do
        local jitter = randomFloat(-side_jitter, side_jitter)

        -- Local-space rear exhaust point.
        -- x is behind the ship, y is side jitter.
        local offset = self:rotatePoint({
            x = -backend_distance,
            y = jitter,
        }, self.rotation)
        local x = self.position.x + offset.x
        local y = self.position.y + offset.y
        local direction = self:keepAngleInRange(
            exhaust_direction + randomFloat(-(p.spread or 0.2), p.spread or 0.2)
        )
        local speed = randomFloat(p.speed_min or 0.2, p.speed_max or 1)
        local exhaust_velocity = {
            speed = speed,
            direction = direction,
        }
        -- Include a little of the ship velocity so exhaust feels attached.
        local ship_velocity = {
            speed = (self.velocity and self.velocity.speed or 0) * 0.25,
            direction = self.velocity and self.velocity.direction or 0,
        }
        local particle_velocity = self:addVectors(exhaust_velocity, ship_velocity)
        particle_velocity.direction = self:keepAngleInRange(
            particle_velocity.direction or 0
        )

        local life = math.random(p.life_min or 8, p.life_max or 18)
        local size = math.random(p.size_min or 1, p.size_max or 2)
        self:addParticle("thrust", {
            position = {
                x = x,
                y = y,
            },
            velocity = particle_velocity,
            life     = life,
            max_life = life,
            color    = randomChoice(system.colors),
            size     = size,
            drag     = p.drag or 0.94,
            gravity  = {
                speed = p.gravity_speed or 0,
                direction = p.gravity_direction or 0,
            },
        })
    end
end

-- ==========================================
-- SPACESHIP COLLISION DAMAGE
-- ==========================================

function SpaceShip:takeDamage(damage, other)
    damage = damage or 0

    if self.dead then
        return false
    end

    if damage <= 0 then
        return false
    end

    -- Docked/harpooned ships are protected while attached to SpaceDock.
    if self:isHarpoonedToSpaceDock() then
        return false
    end

    -- Optional: ignore damage while invulnerable.
    if self.mortality and self.mortality.invulnerable > 0 then
        return false
    end

    local remaining_damage = damage

    -- 1. Shields absorb damage first.
    local shield = self.engines.shield

    if shield.cur > 0 then
        local absorbed = math.min(shield.cur, remaining_damage)

        shield.cur = shield.cur - absorbed
        remaining_damage = remaining_damage - absorbed

        if shield.cur < 0 then
            shield.cur = 0
        end
    end

    -- 2. Remaining damage hits life support.
    local life_support = self.engines.life_support

    if remaining_damage > 0 and life_support.cur > 0 then
        local absorbed = math.min(life_support.cur, remaining_damage)

        life_support.cur = life_support.cur - absorbed
        remaining_damage = remaining_damage - absorbed

        if life_support.cur < 0 then
            life_support.cur = 0
        end
    end

    -- 3. If life support is depleted, the ship dies.
    if life_support.cur <= 0 then
        life_support.cur = 0
        self:kill()
        return true
    end

    -- Damaged but survived.
    self:sparkEffect()

    return false
end
-- ==========================================
-- SPACESHIP HARPOON
-- ==========================================

function SpaceShip:getHarpoonTipPosition()
    return {
        x = self.position.x + math.cos(self.rotation) * self.radius,
        y = self.position.y + math.sin(self.rotation) * self.radius,
    }
end

function SpaceShip:getHarpoonEndPosition()
    local tip = self:getHarpoonTipPosition()

    return {
        x = tip.x + math.cos(self.rotation) * self.harpoon.range,
        y = tip.y + math.sin(self.rotation) * self.harpoon.range,
    }
end

function SpaceShip:isHarpoonAttachedTo(obj)
    if not self.harpoon then
        return false
    end

    return self.harpoon.attached and self.harpoon.target == obj
end

function SpaceShip:isHarpoonedToSpaceDock()
    if not self.harpoon or not self.harpoon.attached then
        return false
    end

    local target = self.harpoon.target
    if not target or target.dead then
        return false
    end

    return SpaceDock ~= nil and getmetatable(target) == SpaceDock
end

function SpaceShip:clearHarpoon()
    if not self.harpoon then
        return
    end

    local target = self.harpoon.target

    if self.harpoon.attached and target and target.position then
        local dx = self.position.x - target.position.x
        local dy = self.position.y - target.position.y

        local dist_sq = dx * dx + dy * dy

        if dist_sq > 0 then
            local dist = math.sqrt(dist_sq)

            local safe_distance =
                getCollisionRadius(self) +
                getCollisionRadius(target) +
                self.harpoon.reel_padding

            local nx = dx / dist
            local ny = dy / dist

            -- If the ship is too close, move it just outside the safe radius.
            if dist < safe_distance then
                self.position.x = target.position.x + nx * safe_distance
                self.position.y = target.position.y + ny * safe_distance

                self.position.x = clamp(self.position.x, 0, MAP_PIXELS_W - 1)
                self.position.y = clamp(self.position.y, 0, MAP_PIXELS_H - 1)
            end

            -- Give the ship a small push away from the released object.
            if self.velocity then
                self.velocity.direction = math.atan(ny, nx)
                self.velocity.speed = math.max(
                    self.velocity.speed or 0,
                    self.harpoon.release_push
                )
            end
        end
    end

    self.harpoon.attached = false
    self.harpoon.target   = nil
    self.harpoon.offset_x = 0
    self.harpoon.offset_y = 0
end

function SpaceShip:canHarpoonTarget(obj)
    if not obj then
        return false
    end

    if obj.dead then
        return false
    end

    if not obj.position then
        return false
    end

    -- Do not harpoon yourself.
    if obj == self then
        return false
    end

    -- First round feature: moons and smaller objects.
    -- Exclude planets and stars.
    if getmetatable(obj) == Star then
        return false
    end

    if getmetatable(obj) == Planet then
        return false
    end

    return true
end

function SpaceShip:getHarpoonTargets()
    local targets = {}

    -- Moons.
    for _, planet in ipairs(game.play.planets or {}) do
        for _, moon in ipairs(planet.moons or {}) do
            if self:canHarpoonTarget(moon) then
                table.insert(targets, moon)
            end
        end
    end

    -- Comets.
    for _, comet in ipairs(game.play.comets or {}) do
        if self:canHarpoonTarget(comet) then
            table.insert(targets, comet)
        end
    end

    -- Asteroids.
    for _, asteroid in ipairs(game.play.asteroids or {}) do
        if self:canHarpoonTarget(asteroid) then
            table.insert(targets, asteroid)
        end
    end

    -- Space Docks orbiting planets and attached to the space station.
    for _, planet in ipairs(game.play.planets or {}) do
        for _, dock in ipairs(planet.docks or {}) do
            if self:canHarpoonTarget(dock) then
                table.insert(targets, dock)
            end
        end
    end
    for _, station in ipairs(game.play.space_stations or {}) do
        for _, dock in ipairs(station.docks or {}) do
            if self:canHarpoonTarget(dock) then
                table.insert(targets, dock)
            end
        end
    end

    return targets
end

function SpaceShip:findHarpoonTarget()
    local tip = self:getHarpoonTipPosition()
    local end_pos = self:getHarpoonEndPosition()

    local best_target = nil
    local best_distance_sq = nil

    for _, target in ipairs(self:getHarpoonTargets()) do
        local radius = getCollisionRadius(target)

        -- Give tiny objects a little aiming forgiveness.
        radius = math.max(radius, 6)

        if segmentIntersectsCircle(
                tip.x,
                tip.y,
                end_pos.x,
                end_pos.y,
                target.position.x,
                target.position.y,
                radius
            ) then
            local d_sq = distanceSquared(
                self.position.x,
                self.position.y,
                target.position.x,
                target.position.y
            )

            if best_distance_sq == nil or d_sq < best_distance_sq then
                best_distance_sq = d_sq
                best_target = target
            end
        end
    end

    return best_target
end

function SpaceShip:attachHarpoon(target)
    if not target then
        return false
    end

    if not self.harpoon then
        return false
    end

    self.harpoon.attached = true
    self.harpoon.target   = target

    -- Preserve the current relative offset so the ship moves with the target.
    self.harpoon.offset_x = self.position.x - target.position.x
    self.harpoon.offset_y = self.position.y - target.position.y

    -- If we somehow attached while almost centered on the target, push the ship
    -- slightly outside the target so it does not sit inside the collision body.
    local offset_len_sq   =
        self.harpoon.offset_x * self.harpoon.offset_x +
        self.harpoon.offset_y * self.harpoon.offset_y

    if offset_len_sq <= 0.01 then
        local angle = self.rotation + math.pi
        local lock_distance =
            getCollisionRadius(target) +
            getCollisionRadius(self) +
            self.harpoon.lock_offset

        self.harpoon.offset_x = math.cos(angle) * lock_distance
        self.harpoon.offset_y = math.sin(angle) * lock_distance
    end

    return true
end

function SpaceShip:fireHarpoon()
    if self.dead then
        return false
    end

    local target = self:findHarpoonTarget()

    if target then
        return self:attachHarpoon(target)
    end

    return false
end

function SpaceShip:toggleHarpoon()
    if not self.harpoon then
        return
    end

    if self.harpoon.attached then
        self:clearHarpoon()
    else
        self:fireHarpoon()
    end
end

function SpaceShip:updateHarpoonLock()
    if not self.harpoon then
        return
    end

    if not self.harpoon.attached then
        return
    end

    local target = self.harpoon.target

    if not target or target.dead or not target.position then
        self:clearHarpoon()
        return
    end

    -- If the harpooned object leaves the map, disconnect automatically.
    if objectIsOffMap(target) then
        self:clearHarpoon()
        return
    end

    -- Shorten the harpoon distance over time.
    self:reelHarpoon()

    -- Lock the ship to the target's current position using the shortened offset.
    self.position.x = target.position.x + self.harpoon.offset_x
    self.position.y = target.position.y + self.harpoon.offset_y

    self.position.x = clamp(self.position.x, 0, MAP_PIXELS_W - 1)
    self.position.y = clamp(self.position.y, 0, MAP_PIXELS_H - 1)

    -- Face the harpooned target.
    local dx = target.position.x - self.position.x
    local dy = target.position.y - self.position.y

    if dx ~= 0 or dy ~= 0 then
        self.rotation = self:keepAngleInRange(math.atan(dy, dx))
    end
end

function SpaceShip:reelHarpoon()
    if not self.harpoon then
        return
    end

    if not self.harpoon.attached then
        return
    end

    local target = self.harpoon.target

    if not target or not target.position then
        return
    end

    local ox = self.harpoon.offset_x
    local oy = self.harpoon.offset_y

    local distance = math.sqrt(ox * ox + oy * oy)

    if distance <= 0 then
        return
    end

    -- This is the minimum safe center-to-center distance between the ship and
    -- the harpooned object. It prevents instant collision after disengage.
    local desired_distance = getCollisionRadius(self) + getCollisionRadius(target) + self.harpoon.reel_padding

    if distance <= desired_distance then
        return
    end

    local new_distance = math.max(
        desired_distance,
        distance - self.harpoon.reel_speed
    )

    local scale = new_distance / distance

    self.harpoon.offset_x = ox * scale
    self.harpoon.offset_y = oy * scale
end

-- ==========================================
-- SPACESHIP DOCKING
-- ==========================================

function SpaceShip:getDockedSpaceDock()
    if not self.harpoon or not self.harpoon.attached then
        return nil
    end

    local target = self.harpoon.target
    if not target or target.dead then
        return nil
    end
    if SpaceDock ~= nil and getmetatable(target) == SpaceDock then
        return target
    end

    return nil
end

function SpaceShip:replenishEnginesWhileDocked()
    -- 60 points per second at 60 FPS = 1 point per TIC.
    local replenish_amount = 1

    local energy = self.engines.energy
    energy.cur = math.min(energy.max, energy.cur + replenish_amount)

    local life_support = self.engines.life_support
    life_support.cur = math.min(life_support.max, life_support.cur + replenish_amount)

    local shield = self.engines.shield
    shield.cur = math.min(shield.max, shield.cur + replenish_amount)
end

function SpaceShip:depositOreToDock(dock)
    if not dock or not dock.ore_bank then
        return false
    end

    if self.cargo_has_ore ~= true then
        return false
    end

    local cargo = self.holds.cargo
    if cargo.cur <= 0 then
        self.cargo_has_ore = false
        return false
    end

    local free_ore_bank_space = math.max(0, dock.ore_bank.max - dock.ore_bank.cur)
    if free_ore_bank_space <= 0 then
        return false
    end

    -- 60 points per second at 60 FPS = 1 point per TIC.
    local transfer_rate_per_tick = 1
    local transfer_amount = math.min(
        transfer_rate_per_tick,
        cargo.cur,
        free_ore_bank_space
    )

    dock.ore_bank.cur = dock.ore_bank.cur + transfer_amount
    cargo.cur = cargo.cur - transfer_amount

    -- Count ore deposited into a dock/station as delivered mass/score.
    self:updateMassDelivered(transfer_amount)

    -- Show score notification.
    if notifyMassDelivered then
        notifyMassDelivered()
    end

    if cargo.cur <= 0 then
        cargo.cur = 0
        self.cargo_has_ore = false
    end

    return transfer_amount > 0
end

function SpaceShip:updateDocking()
    local dock = self:getDockedSpaceDock()
    if not dock then
        return
    end

    self:replenishEnginesWhileDocked()

    -- Ore unloads to the dock/station ore bank.
    self:depositOreToDock(dock)

    -- Mission cargo/passengers unload automatically when docked at their
    -- destination dock/station.
    deliverMissionManifestAtDock(self, dock)
end

function SpaceShip:drawDockingHud()
    local lines = {}

    local mining_target = self:getMiningTarget()
    if mining_target then
        table.insert(
            lines,
            "Mass: " .. tostring(math.floor(mining_target.mass)) ..
            "/" .. tostring(math.floor(mining_target.max_mass))
        )
    end

    local dock = self:getDockedSpaceDock()
    if dock then
        local station = dock.host
        if (
            station and
            SpaceStation ~= nil and
            getmetatable(station) == SpaceStation and
            station.ore_bank
        ) then
            table.insert(
                lines,
                "Station Ore: " .. tostring(math.floor(station.ore_bank.cur)) ..
                "/" .. tostring(math.floor(station.ore_bank.max))
            )
        elseif dock.ore_bank then
            table.insert(
                lines,
                "Dock Ore: " .. tostring(math.floor(dock.ore_bank.cur)) ..
                "/" .. tostring(math.floor(dock.ore_bank.max))
            )
        end
    end

    if #lines <= 0 then
        return
    end

    local x_padding = 4
    local y = 4
    local line_h = FIXED_CHAR_HEIGHT + 1

    for i, text in ipairs(lines) do
        local line_y = y + (i - 1) * line_h
        local text_w = print(text, 0, -100, WHITE, true, 1, true)
        local line_x = SCREEN_W - text_w - x_padding

        print(text, line_x + 1, line_y + 1, BLACK, true, 1, true)
        print(text, line_x, line_y, WHITE, true, 1, true)
    end
end

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
    local load_fraction = clamp(self:getTotalMassFraction(), 0, 1)

    -- At full mass:
    -- acceleration is 65% of base
    -- max speed is 85% of base
    local acceleration_penalty = 1 - load_fraction * 0.35
    local speed_penalty        = 1 - load_fraction * 0.15

    local acceleration = {
        speed     = self.acceleration * acceleration_penalty,
        direction = self.rotation
    }

    self.velocity = self:addVectors(self.velocity, acceleration)

    local effective_max_speed = self.max_speed * speed_penalty

    if self.velocity.speed > effective_max_speed then
        self.velocity.speed = effective_max_speed
    end

    self:thrustEffect()
    -- sfx(3, 10, 10, 3, -8, 1)
end

function SpaceShip:input()
    if self.dead then
        return
    end

    -- Harpoon toggle does not require energy.
    if btnp(BTN_P1_A) then
        self:toggleHarpoon()
    end

    -- Mining through the harpoon.
    if btn(BTN_P1_B) then
        self:mineHarpoonTarget()
    end

    -- If attached, normal movement controls are disabled for now.
    if self.harpoon and self.harpoon.attached then
        return
    end

    if self:getEnergy() <= 0 then
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

function SpaceShip:updateMassDelivered(delivered_mass)
    self.mass_delivered = self.mass_delivered + delivered_mass
    return self.mass_delivered
end

function SpaceShip:move()
    self:updateTimer()

    self:drainLifeSupportForPassengers()

    -- Particles continue moving even after the ship dies.
    self:updateParticles()

    -- If dead, wait for respawn if lives remain.
    if self.dead then
        self:updateRespawn()
        return
    end

    self:updateInvulnerability()

    if self.harpoon and self.harpoon.attached then
        self:updateHarpoonLock()
    else
        self.position = self:movePointByVelocity()

        self.position.x = clamp(self.position.x, 0, MAP_PIXELS_W - 1)
        self.position.y = clamp(self.position.y, 0, MAP_PIXELS_H - 1)
    end

    self:regenerateEnginesOnTimer()

    -- Docking behavior while harpooned to a SpaceDock.
    self:updateDocking()

    -- Emit smoke if life support is damaged enough.
    self:smokeEffect()
end

function SpaceShip:kill()
    if self.dead then
        return
    end

    self.dead = true
    self.exploded = false

    if self.mortality then
        self.mortality.exploded = false
        self.mortality.num_lives = math.max(0, self.mortality.num_lives - 1)

        if self.mortality.num_lives > 0 then
            self.mortality.respawn_timer = 90
        else
            self.mortality.respawn_timer = 0
        end
    end

    -- Losing a life destroys carried mission cargo/passengers, but missions
    -- remain active and can be re-loaded from their source docks.
    clearCarriedMissionManifestForDestroyedShip(self)

    -- Losing a life destroys all carried cargo/passengers/smuggled goods.
    if self.holds then
        if self.holds.cargo then
            self.holds.cargo.cur = 0
        end

        if self.holds.passengers then
            self.holds.passengers.cur = 0
        end

        if self.holds.smuggled then
            self.holds.smuggled.cur = 0
        end
    end

    -- Cargo is no longer ore after cargo is destroyed.
    self.cargo_has_ore = false

    -- Detach harpoon on death.
    if self.harpoon then
        self.harpoon.attached = false
        self.harpoon.target = nil
        self.harpoon.offset_x = 0
        self.harpoon.offset_y = 0
    end

    self:explode()
end

function SpaceShip:hasLivesRemaining()
    return self.mortality and self.mortality.num_lives > 0
end

function SpaceShip:resetForRespawn()
    -- Restore core lifecycle flags.
    self.dead = false
    self.exploded = false

    if self.mortality then
        self.mortality.exploded = false
        self.mortality.respawn_timer = 0

        -- Short invulnerability after respawn.
        self.mortality.invulnerable = 180
    end

    -- Reset position/velocity.
    self.position.x = self.spawn and self.spawn.x or math.floor(EDGE_X_RIGHT / 2)
    self.position.y = self.spawn and self.spawn.y or math.floor(EDGE_Y_BOTTOM / 2)

    self.velocity.speed = 0
    self.velocity.direction = 0

    self.rotation = self.spawn and self.spawn.rotation or 0

    -- Clear harpoon attachment.
    if self.harpoon then
        self.harpoon.attached = false
        self.harpoon.target = nil
        self.harpoon.offset_x = 0
        self.harpoon.offset_y = 0
    end

    -- Refill engines on respawn.
    self.engines.energy.cur = self.engines.energy.max
    self.engines.life_support.cur = self.engines.life_support.max
    self.engines.shield.cur = self.engines.shield.max
end

function SpaceShip:updateRespawn()
    if not self.dead then
        return
    end

    if not self.mortality then
        return
    end

    if self.mortality.respawn_timer <= 0 then
        return
    end

    self.mortality.respawn_timer = self.mortality.respawn_timer - 1

    if self.mortality.respawn_timer <= 0 and self:hasLivesRemaining() then
        self:resetForRespawn()
    end
end

function SpaceShip:updateInvulnerability()
    if not self.mortality then
        return
    end

    if self.mortality.invulnerable > 0 then
        self.mortality.invulnerable = self.mortality.invulnerable - 1
    end
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

function SpaceShip:drawHarpoon()
    if not self.harpoon then
        return
    end

    local start_x, start_y = worldToScreen(self.position.x, self.position.y)

    start_x = math.floor(start_x)
    start_y = math.floor(start_y)

    if self.harpoon.attached and self.harpoon.target and self.harpoon.target.position then
        local target = self.harpoon.target

        local target_x, target_y = worldToScreen(
            target.position.x,
            target.position.y
        )

        target_x = math.floor(target_x)
        target_y = math.floor(target_y)

        line(start_x, start_y, target_x, target_y, self.harpoon.line_color)
        circ(target_x, target_y, 2, self.harpoon.anchor_color)

        return
    end
end

function SpaceShip:drawBody()
    local zoom = game.camera.zoom or 1

    if zoom <= 0.25 then
        local x, y = worldToScreen(self.position.x, self.position.y)

        x = math.floor(x)
        y = math.floor(y)

        pix(x, y, self.colors.primary)
        pix(x - 1, y, self.colors.primary)
        pix(x + 1, y, self.colors.primary)
        pix(x, y - 1, self.colors.primary)
        pix(x, y + 1, self.colors.primary)

        return
    end

    local points = self:getScreenShapePoints()

    -- Draw a ship-shaped mask first.
    drawFilledPolygon(points, self.colors.secondary)

    -- Draw the ship outline on top.
    drawPolygonOutline(points, self.colors.primary)
end

function SpaceShip:draw()
    -- Draw particles behind/in front of body.
    self:drawParticles("explosion")
    self:drawParticles("thrust")

    if not self.dead then
        self:drawHarpoon()
    end

    if not self.dead and self:shouldDraw() then
        self:drawBody()
    end

    self:drawParticles("smoke")
    self:drawParticles("spark")

    if not self.dead then
        self:drawDockingHud()
    end
end

function SpaceShip:explode()
    if self.exploded then
        return
    end
    self.exploded = true
    self:explosionEffect()
    -- sfx(2, 10, 30, 3, 15)
end
