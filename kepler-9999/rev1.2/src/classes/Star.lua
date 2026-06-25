-- ==========================================
-- STAR OBJECT
-- ==========================================

Star = setmetatable({}, { __index = KeplerObj })
Star.__index = Star

function Star:new(params)
    params = params or {}

    -- Pick a stellar type if one was not supplied.
    params.stellar_type = params.stellar_type or randomChoice(STELLAR_TYPES)

    -- Apply stellar-profile values before calling KeplerObj.new().
    local profile = STELLAR_PROFILES[params.stellar_type] or STELLAR_PROFILES.G

    local mass_solar_units   = randomFloat(profile.mass_min, profile.mass_max)
    local radius_solar_units = randomFloat(profile.radius_min, profile.radius_max)

    params.mass        = params.mass or mass_solar_units * SOLAR_MASS
    params.radius_real = params.radius_real or radius_solar_units * SOLAR_RADIUS
    params.temperature = params.temperature or math.floor(randomFloat(profile.temp_min, profile.temp_max))

    -- Important:
    -- `radius` is currently used by drawBody() as a pixel radius.
    -- A real stellar radius would be enormous, so keep drawing radius separate.
    params.radius = params.radius or Star:getDrawRadiusForType(params.stellar_type)

    params.colors = params.colors or {
        primary   = profile.colors.primary,
        secondary = profile.colors.secondary,
        tertiary  = profile.colors.tertiary,
    }

    params.velocity = {
        speed     = 0,
        direction = 0,
    }

    params.acceleration = 0
    params.deceleration = 0

    params.exerts_gravity      = true
    params.affected_by_gravity = false

    local self = KeplerObj:new(params)
    setmetatable(self, Star)

    self.name               = params.name or "Kepler-9999"
    self.stellar_type       = params.stellar_type
    self.temperature        = params.temperature
    self.radius_real        = params.radius_real

    self.mass_solar         = mass_solar_units
    self.radius_solar       = radius_solar_units

    self.velocity.speed     = 0
    self.velocity.direction = 0
    self.acceleration       = 0
    self.deceleration       = 0

    self.fx                 = Particle:new({
        wind = makeParticleSystem(
            params.wind_colors or {
                self.colors.primary,
                self.colors.secondary,
                self.colors.tertiary,
                YELLOW,
                ORANGE,
                WHITE,
            },
            {
                count_min    = params.wind_count_min or 1,
                count_max    = params.wind_count_max or 2,
                speed_min    = params.wind_speed_min or 0.15,
                speed_max    = params.wind_speed_max or 0.85,
                life_min     = params.wind_life_min or 35,
                life_max     = params.wind_life_max or 90,
                size_min     = params.wind_size_min or 1,
                size_max     = params.wind_size_max or 2,
                drag         = params.wind_drag or 0.985,
                spread       = math.pi * 2,
                spawn_radius = self.radius or 32,
            }
        ),

        flare = makeParticleSystem(
            params.flare_colors or {
                WHITE,
                YELLOW,
                ORANGE,
                RED,
                self.colors.primary,
                self.colors.secondary,
            },
            {
                count_min    = params.flare_count_min or 8,
                count_max    = params.flare_count_max or 18,
                speed_min    = params.flare_speed_min or 0.35,
                speed_max    = params.flare_speed_max or 1.8,
                life_min     = params.flare_life_min or 20,
                life_max     = params.flare_life_max or 55,
                size_min     = params.flare_size_min or 1,
                size_max     = params.flare_size_max or 3,
                drag         = params.flare_drag or 0.96,
                spread       = math.pi * 0.45,
                spawn_radius = self.radius or 32,
            }
        ),
    })

    return self
end


-- ==========================================
-- STAR GETTERS
-- ==========================================

-- ==========================================
-- STAR MATH
-- ==========================================

-- ==========================================
-- STAR PHYSICS
-- ==========================================

-- ==========================================
-- STAR COLLISION DETECTION
-- ==========================================

-- ==========================================
-- STAR INPUT
-- ==========================================

-- ==========================================
-- STAR UPDATE
-- ==========================================

function Star:spawnWindParticle()
    if not self.fx then
        return
    end

    local angle        = randomFloat(0, math.pi * 2)
    local spawn_radius = self.radius or 32

    local x = self.position.x + math.cos(angle) * spawn_radius
    local y = self.position.y + math.sin(angle) * spawn_radius

    self.fx:burst(
        "wind",
        x,
        y,
        {
            count = 1,
            direction = angle,
            spread = 0.35,
        }
    )
end

function Star:spawnFlare()
    if not self.fx then
        return
    end

    local angle        = randomFloat(0, math.pi * 2)
    local spawn_radius = self.radius or 32

    local x = self.position.x + math.cos(angle) * spawn_radius
    local y = self.position.y + math.sin(angle) * spawn_radius

    self.fx:burst(
        "flare",
        x,
        y,
        {
            direction = angle,
            spread = math.pi * 0.35,
        }
    )
end

function Star:update()
    self:updateTimer()

    if self.fx then
        self.fx:update("wind")
        self.fx:update("flare")
    end

    -- Constant solar wind.
    if self:everyNTicks(3) then
        self:spawnWindParticle()
    end

    -- Occasional flare.
    if self:everyNTicks(90) and math.random(1, 100) <= 35 then
        self:spawnFlare()
    end
end

-- ==========================================
-- STAR DRAW
-- ==========================================

function Star:getDrawRadiusForType(stellar_type)
    local multiplier = 21
    if stellar_type == "O" then
        return 8 * multiplier
    elseif stellar_type == "B" then
        return 7 * multiplier
    elseif stellar_type == "A" then
        return 6 * multiplier
    elseif stellar_type == "F" then
        return 5 * multiplier
    elseif stellar_type == "G" then
        return 5 * multiplier
    elseif stellar_type == "K" then
        return 4 * multiplier
    elseif stellar_type == "M" then
        return 3 * multiplier
    end

    return 5 * multiplier
end

function Star:drawBody()
    local screen_x, screen_y = worldToScreen(self.position.x, self.position.y)
    local zoom = game.camera.zoom or 1

    screen_x = math.floor(screen_x)
    screen_y = math.floor(screen_y)

    local r = math.max(1, math.floor(self.radius * zoom))
    local outer_extra = math.max(1, math.floor(2 * zoom))
    local middle_extra = math.max(1, math.floor(1 * zoom))

    circ(screen_x, screen_y, r + outer_extra, self.colors.tertiary)
    circ(screen_x, screen_y, r + middle_extra, self.colors.secondary)
    circ(screen_x, screen_y, r, self.colors.primary)
end


function Star:drawParticles()
    if not self.fx then
        return
    end

    self.fx:draw("wind", {
        offscreen_pad = 32,
        shrink_when_fading = true,
    })

    self.fx:draw("flare", {
        offscreen_pad = 48,
        shrink_when_fading = true,
    })
end

function Star:draw()
    self:drawParticles()
    self:drawBody()
end
