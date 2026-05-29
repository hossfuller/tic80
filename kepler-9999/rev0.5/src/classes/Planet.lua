-- ==========================================
-- PLANET OBJECT
-- ==========================================

Planet = setmetatable({}, { __index = KeplerObj })
Planet.__index = Planet

function Planet:new(params)
    params = params or {}

    -- Random physical properties.
    params.mass = params.mass or randomFloat(EARTH_MASS, JUPITER_MASS)

    -- Keep real radius separate from draw radius, like Star does.
    params.radius_real = params.radius_real or randomFloat(EARTH_RADIUS, JUPITER_RADIUS)

    -- Atmosphere.
    if params.has_atmosphere == nil then
        params.has_atmosphere = math.random(1, 100) <= 50
    end

    -- Colors depend on whether atmosphere exists.
    params.colors = params.colors or randomPlanetColorSet(params.has_atmosphere)

    -- Important:
    -- `radius` is used as the draw radius in pixels.
    params.radius = params.radius or Planet:getDrawRadiusFromRealRadius(params.radius_real)

    -- For now, planets are static.
    params.velocity = {
        speed = 0,
        direction = 0,
    }

    params.acceleration = 0
    params.deceleration = 0

    local self = KeplerObj.new(params)
    setmetatable(self, Planet)

    self.name                = params.name or "Planet"
    self.radius_real         = params.radius_real
    self.has_atmosphere      = params.has_atmosphere

    self.velocity.speed      = 0
    self.velocity.direction  = 0
    self.acceleration        = 0
    self.deceleration        = 0

    -- Visual details.
    self.surface_band_offset = math.random(0, 100)

    self.has_ring            = params.has_ring

    if self.has_ring == nil then
        self.has_ring = math.random(1, 100) <= 12
    end

    return self
end

-- ==========================================
-- PLANET GETTERS
-- ==========================================

function Planet:getDrawRadiusFromRealRadius(radius_real)
    -- Maps EARTH_RADIUS..JUPITER_RADIUS to about 4..18 pixels.
    local min_draw_radius = 40
    local max_draw_radius = 75

    radius_real = radius_real or EARTH_RADIUS

    local t = (radius_real - EARTH_RADIUS) / (JUPITER_RADIUS - EARTH_RADIUS)
    t = clamp(t, 0, 1)

    return math.floor(min_draw_radius + t * (max_draw_radius - min_draw_radius))
end

-- ==========================================
-- PLANET UPDATE
-- ==========================================

function Planet:update()
    self:updateTimer()
end

-- ==========================================
-- PLANET DRAW
-- ==========================================

function Planet:drawAtmosphere(screen_x, screen_y, r, zoom)
    if not self.has_atmosphere then
        return
    end

    local atmosphere_extra = math.max(1, math.floor(2 * zoom))

    circ(screen_x, screen_y, r + atmosphere_extra, self.colors.tertiary)
end

function Planet:drawRing(screen_x, screen_y, r, zoom)
    if not self.has_ring then
        return
    end

    -- Simple flattened ring.
    local ring_w = math.max(2, math.floor(r * 2.8))
    local ring_h = math.max(1, math.floor(r * 0.7))

    ellib(screen_x, screen_y, ring_w, ring_h, self.colors.tertiary)
end

function Planet:drawSurfaceBands(screen_x, screen_y, r, zoom)
    if r < 4 then
        return
    end

    local band_count = 2

    if r >= 10 then
        band_count = 3
    end

    for i = 1, band_count do
        local y_offset = math.floor(-r / 2 + i * (r / (band_count + 1)))
        local y = screen_y + y_offset

        local half_width = math.floor(
            math.sqrt(math.max(0, r * r - y_offset * y_offset))
        )

        local color = self.colors.secondary

        if i % 2 == 0 then
            color = self.colors.tertiary
        end

        line(
            screen_x - half_width,
            y,
            screen_x + half_width,
            y,
            color
        )
    end
end

function Planet:drawBody()
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

    -- Draw ring behind the planet.
    self:drawRing(screen_x, screen_y, r, zoom)

    -- Atmosphere glow.
    self:drawAtmosphere(screen_x, screen_y, r, zoom)

    -- Planet body.
    circ(screen_x, screen_y, r, self.colors.primary)

    -- Surface variation.
    self:drawSurfaceBands(screen_x, screen_y, r, zoom)

    -- Small highlight for bigger planets.
    if r >= 5 then
        local highlight_r = math.max(1, math.floor(r / 4))

        circ(
            screen_x - math.floor(r / 3),
            screen_y - math.floor(r / 3),
            highlight_r,
            self.colors.secondary
        )
    end
end

function Planet:drawLabel()
    local zoom = game.camera.zoom or 1

    -- Labels are only visible when zoomed out.
    if zoom >= 1 then
        return
    end

    local screen_x, screen_y = worldToScreen(self.position.x, self.position.y)

    screen_x = math.floor(screen_x)
    screen_y = math.floor(screen_y)

    local r = math.max(1, math.floor(self.radius * zoom))
    local text = self.name or "Planet"

    -- TIC-80 print() returns the rendered text width.
    local text_w = print(text, 0, -100, WHITE, true, 1, true)

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

function Planet:draw()
    self:drawBody()
    self:drawLabel()
end
