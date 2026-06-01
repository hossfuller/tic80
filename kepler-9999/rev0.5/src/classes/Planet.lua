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

    self.name           = params.name or "Planet"
    self.radius_real    = params.radius_real
    self.has_atmosphere = params.has_atmosphere

    if self.has_atmosphere then
        self.colors.cloud = params.colors.cloud or PLANET_CLOUD_COLORS[math.random(1, #PLANET_CLOUD_COLORS)]
    else
        self.craters           = {}
        self.colors.crater     = params.colors.crater or DARK_GREY or GREY or BLACK
        self.colors.crater_rim = params.colors.crater_rim or self.colors.secondary

        local crater_count = params.crater_count or math.random(
            math.floor(params.radius * 0.2),
            math.floor(params.radius * 0.45)
        )

        for i = 1, crater_count do
            -- Generate random point inside unit circle.
            local angle = randomFloat(0, math.pi * 2)
            local dist = math.sqrt(randomFloat(0, 1))

            -- Store normalized coordinates.
            -- These are relative to the planet radius, so they scale with zoom.
            local crater = {
                x = math.cos(angle) * dist,
                y = math.sin(angle) * dist,
                r = randomFloat(0.04, 0.16),
            }

            table.insert(self.craters, crater)
        end
    end

    self.velocity.speed     = 0
    self.velocity.direction = 0
    self.acceleration       = 0
    self.deceleration       = 0

    -- Visual details.
    self.surface_band_offset = math.random(0, 100)

    self.has_ring  = params.has_ring
    self.num_rings = params.num_rings or 0
    if self.has_ring == nil then
        self.has_ring = math.random(1, 100) <= 12
    end
    if self.has_ring then
        self.num_rings = math.random(1,15)
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

function Planet:drawCraters(screen_x, screen_y, r, zoom)
    if self.has_atmosphere then
        return
    end

    if not self.craters then
        return
    end

    -- Too small to show useful crater detail.
    if r < 5 then
        return
    end

    local crater_color = self.colors.crater
    local rim_color = self.colors.crater_rim

    for i = 1, #self.craters do
        local crater = self.craters[i]

        local crater_x = math.floor(screen_x + crater.x * r)
        local crater_y = math.floor(screen_y + crater.y * r)
        local crater_r = math.max(1, math.floor(crater.r * r))

        -- Keep the whole crater inside the planet disk.
        local dx = crater_x - screen_x
        local dy = crater_y - screen_y
        local dist_from_center = math.sqrt(dx * dx + dy * dy)

        if dist_from_center + crater_r <= r then
            -- Rim/highlight.
            circ(crater_x - 1, crater_y - 1, crater_r, self.colors.crater_rim)
            circ(crater_x, crater_y, crater_r, crater_color)
            circ(crater_x, crater_y, math.max(1, crater_r - 1), crater_color)
        end
    end
end

function Planet:drawAtmosphere(screen_x, screen_y, r, zoom)
    if not self.has_atmosphere then
        return
    end
    local atmosphere_extra = math.max(1, math.floor(4 * zoom))
    circ(screen_x, screen_y, r + atmosphere_extra, self.colors.tertiary)
end

function Planet:drawRing(screen_x, screen_y, r, zoom)
    if not self.has_ring then
        return
    end

    -- Simple flattened ring.
    local ring_w = math.max(2, math.floor(r * 2.8))
    local ring_h = math.max(1, math.floor(r * 0.7))

    for ring_num = 0, self.num_rings, 1 do
        ellib(screen_x, screen_y, ring_w + ring_num, ring_h + ring_num, self.colors.tertiary)
    end
end

function Planet:drawClouds(screen_x, screen_y, r, zoom)
    if not self.has_atmosphere then
        return
    end

    -- Too small to show useful cloud detail.
    if r < 6 then
        return
    end

    -- Cloud bands should cover almost the whole planet,
    -- from near the north pole to near the south pole.
    local band_spacing = math.max(4, math.floor(r * 0.18))
    local band_count = math.max(3, math.floor((r * 2) / band_spacing))

    -- Used to make each planet's clouds look different.
    local seed = self.surface_band_offset or 0

    for band = 1, band_count do
        -- Place bands from near top pole to near bottom pole.
        local t = 0

        if band_count > 1 then
            t = (band - 1) / (band_count - 1)
        end

        -- t = 0 gives top pole, t = 1 gives bottom pole.
        -- Use 0.92 instead of 1.0 so the bands do not collapse to zero width.
        local y_offset = math.floor(-r * 0.80 + t * (r * 1.84))

        -- Slight per-band wobble so they are not perfectly parallel.
        y_offset = y_offset + math.floor(math.sin(seed + band * 2.1) * r * 0.05)

        -- Clamp y_offset so it stays inside the planet.
        y_offset = clamp(y_offset, -r + 1, r - 1)

        -- Width of the planet at this y coordinate.
        local half_width = math.floor(
            math.sqrt(math.max(0, r * r - y_offset * y_offset))
        )

        -- Near the poles the width gets very small.
        -- Skip if there is basically no room to draw.
        if half_width > 1 then
            local band_height = math.max(2, math.floor(r * 0.08))
            local puff_step = math.max(3, math.floor(r * 0.16))

            -- Offset the start position per planet/band.
            local x_start = -half_width + ((seed + band * 7) % puff_step)

            -- Make sure tiny polar bands still get at least one puff.
            if half_width < puff_step then
                x_start = 0
            end

            for x_offset = x_start, half_width, puff_step do
                -- Deterministic pseudo-random value based on band/position.
                local n = math.sin((x_offset + seed * 13 + band * 31) * 12.9898) * 43758.5453
                n = n - math.floor(n)

                -- Leave some gaps.
                if n > 0.25 then
                    local puff_r = math.floor(band_height * (0.7 + n * 1.2))

                    -- Keep puffs mostly inside the planet disk.
                    local max_puff_r = half_width - math.abs(x_offset)
                    puff_r = math.floor(math.min(puff_r, max_puff_r))

                    if puff_r > 0 then
                        local puff_y = y_offset + math.floor((n - 0.5) * band_height)

                        -- Final safety check: keep puff center inside planet.
                        local dx = x_offset
                        local dy = puff_y

                        if dx * dx + dy * dy <= r * r then
                            circ(
                                screen_x + math.floor(x_offset),
                                screen_y + math.floor(puff_y),
                                puff_r,
                                self.colors.cloud
                            )
                        end
                    end
                end
            end
        end
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

    -- Craters for planets without atmospheres.
    self:drawCraters(screen_x, screen_y, r, zoom)

    -- Puffy cloud bands for planets with atmospheres.
    self:drawClouds(screen_x, screen_y, r, zoom)
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
