-- ==========================================
-- SPACESTATION OBJECT
-- ==========================================

SpaceStation = setmetatable({}, { __index = Planet })
SpaceStation.__index = SpaceStation

function SpaceStation:new(params)
    params = params or {}

    params.name        = params.name or "Station 9999X"
    params.mass        = params.mass or STATION_MASS
    params.radius_real = params.radius_real or STATION_RADIUS
    params.radius      = params.radius or self:getDrawRadiusFromRealRadius(params.radius_real)

    params.has_atmosphere = false
    params.has_ring = false
    params.num_rings = 0

    params.colors = params.colors or {
        primary   = WHITE,
        secondary = BLUE_MED,
        tertiary  = RED,
    }

    params.velocity = {
        speed = 0,
        direction = 0,
    }
    params.acceleration = 0
    params.deceleration = 0

    params.exerts_gravity = true
    params.affected_by_gravity = false

    local self = Planet:new(params)
    setmetatable(self, SpaceStation)

    self.name        = params.name
    self.mass        = params.mass
    self.radius_real = params.radius_real
    self.radius      = params.radius

    self.exerts_gravity      = true
    self.affected_by_gravity = false

    self.velocity.speed     = 0
    self.velocity.direction = 0
    self.acceleration       = 0
    self.deceleration       = 0

    self.has_atmosphere = false
    self.has_ring       = false
    self.num_rings      = 0

    self.colors = params.colors
    self.color  = self.colors.primary

    return self
end

-- ==========================================
-- SPACESTATION GETTERS
-- ==========================================

-- Override the normal getDrawRadiusFromRealRadius(radius_real) to get something
-- more to scale with the player's ship.
function SpaceStation:getDrawRadiusFromRealRadius(radius_real)
    return STATION_REAL_RADIUS
end

-- ==========================================
-- SPACESTATION UPDATE
-- ==========================================

function SpaceStation:update()
    self:updateTimer()

    if self.docks then
        for _, dock in ipairs(self.docks) do
            dock:update()
        end
    end
end

-- ==========================================
-- SPACESTATION DRAW
-- ==========================================

function SpaceStation:drawBody()
    local screen_x, screen_y = worldToScreen(self.position.x, self.position.y)
    local zoom = game.camera.zoom or 1

    screen_x = math.floor(screen_x)
    screen_y = math.floor(screen_y)

    local r = math.max(1, math.floor(self.radius * zoom))

    -- Skip if comfortably off-screen.
    if screen_x < -r - 4 or screen_x > SCREEN_W + r + 4 or
        screen_y < -r - 4 or screen_y > SCREEN_H + r + 4 then
        return
    end

    -- SpaceStation body.
    circ(screen_x, screen_y, r, self.colors.primary)
    -- Add other decorations
end

function SpaceStation:drawLabel()
    local zoom = game.camera.zoom or 1

    -- Labels are only visible when zoomed out.
    if zoom >= 1 then
        return
    end

    local screen_x, screen_y = worldToScreen(self.position.x, self.position.y)
    screen_x                 = math.floor(screen_x)
    screen_y                 = math.floor(screen_y)

    local r       = math.max(1, math.floor(self.radius * zoom))
    local text    = self.name or "SpaceStation"
    local text_w  = print(text, 0, -100, WHITE, true, 1, true)
    local label_x = math.floor(screen_x - text_w / 2)
    local label_y = screen_y + r + 4

    -- Skip labels that are clearly off-screen.
    if label_x > SCREEN_W or label_x + text_w < 0 or
        label_y > SCREEN_H or label_y + FIXED_CHAR_HEIGHT < 0 then
        return
    end

    -- Shadow.
    print(text, label_x + 1, label_y + 1, BLACK, true, 1, true)

    -- Label.
    print(text, label_x, label_y, WHITE, true, 1, true)
end

function SpaceStation:draw()
    self:drawBody()
    self:drawLabel()
end
