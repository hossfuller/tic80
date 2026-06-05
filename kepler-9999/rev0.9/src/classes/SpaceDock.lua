-- ==========================================
-- SPACEDOCK OBJECT
-- ==========================================

SpaceDock = setmetatable({}, { __index = Moon })
SpaceDock.__index = SpaceDock

function SpaceDock:new(params)
    params                = params or {}

    params.name        = params.name or "SpaceDock"
    params.mass        = params.mass        or DOCK_MASS
    params.radius_real = params.radius_real or DOCK_REAL_RADIUS
    params.radius      = params.radius      or SpaceDock:getDrawRadiusFromRealRadius(params.radius_real)
    params.colors      = params.colors or {
        primary = WHITE,
        secondary = BLUE_LITE,
        tertiary  = GRAY_LITE,
    }

    params.has_atmosphere      = false
    params.has_ring            = false
    params.num_rings           = 0
    params.exerts_gravity      = true
    params.affected_by_gravity = false

    -- SpaceDocks are moon-like orbital bodies.
    local self            = Moon:new(params)
    setmetatable(self, SpaceDock)

    self.name = params.name or "SpaceDock"
    self.mass = DOCK_MASS
    self.host = params.host

    self.has_atmosphere      = false
    self.has_ring            = false
    self.num_rings           = 0
    self.exerts_gravity      = false
    self.affected_by_gravity = false

    local orbit = params.orbit or {}
    self.orbit  = {
        semi_major   = orbit.semi_major or 100,
        eccentricity = orbit.eccentricity or 0,
        angle        = orbit.angle or 0,
        phase        = orbit.phase or 0,
        period       = orbit.period or 1800,
    }

    self.orbit.semi_minor =
        self.orbit.semi_major *
        math.sqrt(1 - self.orbit.eccentricity * self.orbit.eccentricity)

    -- SpaceDocks do not use Moon dust effects.
    self.dust_particles   = {}
    self.dust             = nil

    -- Initialize dock position immediately if it has a host.
    if self.host then
        local focus = self.host.barycenter or self.host.position
        self:updateOrbitPosition(focus)
    end

    return self
end

-- ==========================================
-- SPACEDOCK GETTERS
-- ==========================================

function SpaceDock:isFinished()
    return self.dead
end

function SpaceDock:getDrawRadiusFromRealRadius(radius_real)
    return DOCK_REAL_RADIUS
end

-- ==========================================
-- SPACEDOCK PARTICLE EFFECTS
-- ==========================================

-- function SpaceDock:explosionEffect()
--     -- Do nothing, no explosions here...
-- end

-- function SpaceDock:updateDustParticles()
--     -- Do nothing, no dust particles to update here...
-- end

-- function SpaceDock:drawDustParticles()
--     -- Do nothing, no dust particles to draw here...
-- end

-- ==========================================
-- SPACEDOCK UPDATE
-- ==========================================

-- function SpaceDock:takeDamage(damage, other)
--     -- Docks are solid/harpoonable but not destructible.
--     return false
-- end

-- ==========================================
-- SPACEDOCK DRAW
-- ==========================================

function SpaceDock:drawBody()
    if self.dead then
        return
    end

    local zoom = game.camera.zoom or 1

    local screen_x, screen_y = worldToScreen(self.position.x, self.position.y)

    screen_x = math.floor(screen_x)
    screen_y = math.floor(screen_y)

    local r = math.max(1, math.floor(self.radius * zoom))

    -- Skip if comfortably off-screen.
    if screen_x < -r - 4 or screen_x > SCREEN_W + r + 4 or
        screen_y < -r - 4 or screen_y > SCREEN_H + r + 4 then
        return
    end

    -- Simple dock body.
    circ(screen_x, screen_y, r, self.colors.primary)

    -- Small inner detail.
    if r >= 3 then
        circ(screen_x, screen_y, math.max(1, r - 2), self.colors.secondary)
    end
end

function SpaceDock:drawLabel()
    local zoom = game.camera.zoom or 1

    -- Labels are only visible when zoomed out.
    if zoom >= 1 then
        return
    end

    local screen_x, screen_y = worldToScreen(self.position.x, self.position.y)
    screen_x                 = math.floor(screen_x)
    screen_y                 = math.floor(screen_y)

    local r       = math.max(1, math.floor(self.radius * zoom))
    local text    = self.name or "SpaceDock"
    local text_w  = print(text, 0, -100, WHITE, true, 1, true)
    local label_x = math.floor(screen_x - text_w / 2)
    local label_y = screen_y + r + 4
    if label_x > SCREEN_W or label_x + text_w < 0 or
        label_y > SCREEN_H or label_y + FIXED_CHAR_HEIGHT < 0 then
        return
    end

    print(text, label_x + 1, label_y + 1, BLACK, true, 1, true)
    print(text, label_x, label_y, WHITE, true, 1, true)
end

function SpaceDock:draw()
    if self.dead then
        return
    end

    self:drawBody()
    self:drawLabel()
end
