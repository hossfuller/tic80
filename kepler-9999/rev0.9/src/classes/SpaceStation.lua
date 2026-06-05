-- ==========================================
-- SPACESTATION OBJECT
-- ==========================================

SpaceStation = setmetatable({}, { __index = Planet })
SpaceStation.__index = SpaceStation

function SpaceStation:new(params)
    params = params or {}

    params.name        = params.name or "Station 9999X"
    params.mass        = params.mass or STATION_MASS
    params.radius_real = params.radius_real or STATION_REAL_RADIUS
    params.radius      = params.radius or SpaceStation:getDrawRadiusFromRealRadius(params.radius_real)

    params.has_atmosphere = false
    params.has_ring = false
    params.num_rings = 0

    params.colors = params.colors or {
        primary   = WHITE,
        secondary = GRAY_MED,
        tertiary  = BLUE_LITE,
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

    self.colors      = params.colors
    self.color       = self.colors.primary
    self.tube_colors = {
        shadow = params.tube_shadow_color or GRAY_DARK,
        body   = params.tube_body_color   or GRAY_LITE,
        stripe = params.tube_stripe_color or WHITE,
        light  = params.tube_light_color  or CYAN,
    }

    self.ore_bank = {
        cur = 0,
        max = STATION_ORE_BANK_MAX,
    }

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

function SpaceStation:drawDocks()
    if not self.docks then
        return
    end

    for _, dock in ipairs(self.docks) do
        dock:draw()
    end
end

function SpaceStation:drawThickLine(x1, y1, x2, y2, thickness, color)
    thickness = thickness or 1

    if thickness <= 1 then
        line(x1, y1, x2, y2, color)
        return
    end

    local dx = x2 - x1
    local dy = y2 - y1
    local len = math.sqrt(dx * dx + dy * dy)

    if len <= 0 then
        circ(x1, y1, math.floor(thickness / 2), color)
        return
    end

    -- Perpendicular unit vector.
    local nx = -dy / len
    local ny = dx / len

    local half = math.floor(thickness / 2)

    for offset = -half, half do
        local ox = math.floor(nx * offset)
        local oy = math.floor(ny * offset)

        line(x1 + ox, y1 + oy, x2 + ox, y2 + oy, color)
    end
end

function SpaceStation:drawTubeDetailLine(x1, y1, x2, y2, t, size, color)
    local px = math.floor(x1 + (x2 - x1) * t)
    local py = math.floor(y1 + (y2 - y1) * t)

    local dx = x2 - x1
    local dy = y2 - y1
    local len = math.sqrt(dx * dx + dy * dy)

    if len <= 0 then
        return
    end

    local nx = -dy / len
    local ny = dx / len

    local sx = math.floor(nx * size)
    local sy = math.floor(ny * size)

    line(px - sx, py - sy, px + sx, py + sy, color)
end

function SpaceStation:drawDockTubes()
    if not self.docks then
        return
    end

    local zoom                 = game.camera.zoom or 1

    local station_x, station_y = worldToScreen(self.position.x, self.position.y)
    station_x                  = math.floor(station_x)
    station_y                  = math.floor(station_y)

    local station_r            = math.max(1, math.floor((self.radius or 10) * zoom))
    local tube_thickness       = math.max(1, math.floor(station_r * 0.16))
    local shadow_thickness     = tube_thickness + 2

    -- At very low zoom, keep tubes readable but not huge.
    if zoom <= 0.35 then
        tube_thickness = 1
        shadow_thickness = 2
    end

    local timer = self.timer or 0

    for dock_index, dock in ipairs(self.docks) do
        if dock and not dock.dead and dock.position then
            local dock_x, dock_y = worldToScreen(dock.position.x, dock.position.y)
            dock_x               = math.floor(dock_x)
            dock_y               = math.floor(dock_y)

            local dx             = dock_x - station_x
            local dy             = dock_y - station_y
            local len            = math.sqrt(dx * dx + dy * dy)

            if len > 0 then
                -- Draw from station edge-ish to dock edge-ish, so the line does
                -- not visually flood the station/dock centers too much.
                local dock_r = math.max(1, math.floor((dock.radius or 6) * zoom))

                local ux = dx / len
                local uy = dy / len

                local start_x = math.floor(station_x + ux * math.max(0, station_r * 0.45))
                local start_y = math.floor(station_y + uy * math.max(0, station_r * 0.45))

                local end_x = math.floor(dock_x - ux * math.max(0, dock_r * 0.35))
                local end_y = math.floor(dock_y - uy * math.max(0, dock_r * 0.35))

                -- Dark structural shadow/backing.
                self:drawThickLine(start_x, start_y, end_x, end_y, shadow_thickness, self.tube_colors.shadow)

                -- Main tube.
                self:drawThickLine(start_x, start_y, end_x, end_y, tube_thickness, self.tube_colors.body)

                -- Bright central conduit.
                if tube_thickness >= 3 then
                    line(start_x, start_y, end_x, end_y, self.tube_colors.stripe)
                end

                -- Tube panel bands.
                if zoom > 0.25 then
                    local detail_size = math.max(1, math.floor(tube_thickness * 0.9))

                    for s = 1, 4 do
                        local t = s / 5
                        self:drawTubeDetailLine(start_x, start_y, end_x, end_y, t, detail_size, self.colors.secondary)
                    end
                end

                -- Animated guide lights along the tube.
                if zoom > 0.2 then
                    local light_phase = ((timer + dock_index * 11) % 60) / 60

                    for l = 0, 2 do
                        local t = (light_phase + l / 3) % 1

                        -- Keep lights away from the very ends.
                        t = 0.12 + t * 0.76

                        local lx = math.floor(start_x + (end_x - start_x) * t)
                        local ly = math.floor(start_y + (end_y - start_y) * t)

                        pix(lx, ly, self.tube_colors.light)

                        if tube_thickness >= 3 then
                            pix(lx + 1, ly, self.colors.secondary)
                        end
                    end
                end
            end
        end
    end
end

function SpaceStation:drawBody()
    local screen_x, screen_y = worldToScreen(self.position.x, self.position.y)
    local zoom = game.camera.zoom or 1

    screen_x = math.floor(screen_x)
    screen_y = math.floor(screen_y)

    local r = math.max(1, math.floor(self.radius * zoom))

    -- Decorations extend beyond the base radius.
    local visual_r = math.floor(r * 1.55)

    -- Skip if comfortably off-screen.
    if screen_x < -visual_r - 8 or screen_x > SCREEN_W + visual_r + 8 or
        screen_y < -visual_r - 8 or screen_y > SCREEN_H + visual_r + 8 then
        return
    end

    local primary   = self.colors.primary or self.tube_colors.body
    local secondary = self.colors.secondary or GRAY_MED
    local tertiary  = self.colors.tertiary or BLUE_LITE

    local timer     = self.timer or 0

    -- Very low zoom: readable station marker.
    if r <= 2 then
        pix(screen_x, screen_y, primary)
        pix(screen_x - 1, screen_y, self.colors.primary)
        pix(screen_x + 1, screen_y, self.colors.primary)
        pix(screen_x, screen_y - 1, self.tube_colors.light)
        pix(screen_x, screen_y + 1, self.tube_colors.light)
        return
    end

    -- ==========================================
    -- Outer station frame/ring
    -- ==========================================

    local outer_r = math.max(2, math.floor(r * 1.25))
    local ring_r  = math.max(1, math.floor(r * 0.95))
    local core_r  = math.max(1, math.floor(r * 0.48))
    local inner_r = math.max(1, math.floor(r * 0.26))

    -- Outer dark backing.
    circ(screen_x, screen_y, outer_r + 1, self.tube_colors.shadow)

    -- Outer hull.
    circ(screen_x, screen_y, outer_r, primary)

    -- Cut inward with darker band to imply a ring/constructed hull.
    circ(screen_x, screen_y, ring_r, BLACK)

    -- Mid hub.
    circ(screen_x, screen_y, math.floor(r * 0.78), secondary)

    -- Inner machinery/core.
    circ(screen_x, screen_y, core_r, self.tube_colors.shadow)

    -- Central command core.
    circ(screen_x, screen_y, inner_r, tertiary)

    -- Bright command pixel.
    pix(screen_x, screen_y, self.tube_colors.stripe)

    -- ==========================================
    -- Radial spokes
    -- ==========================================

    if r >= 5 then
        local spoke_count = 8
        local spoke_inner = math.floor(core_r * 0.85)
        local spoke_outer = math.floor(outer_r * 0.95)

        for i = 1, spoke_count do
            local a = ((i - 1) / spoke_count) * math.pi * 2

            local x1 = screen_x + math.floor(math.cos(a) * spoke_inner)
            local y1 = screen_y + math.floor(math.sin(a) * spoke_inner)

            local x2 = screen_x + math.floor(math.cos(a) * spoke_outer)
            local y2 = screen_y + math.floor(math.sin(a) * spoke_outer)

            line(x1, y1, x2, y2, self.tube_colors.body)

            -- Alternate darker reinforcement lines.
            if i % 2 == 0 then
                local a2 = a + 0.045
                local rx1 = screen_x + math.floor(math.cos(a2) * spoke_inner)
                local ry1 = screen_y + math.floor(math.sin(a2) * spoke_inner)
                local rx2 = screen_x + math.floor(math.cos(a2) * spoke_outer)
                local ry2 = screen_y + math.floor(math.sin(a2) * spoke_outer)

                line(rx1, ry1, rx2, ry2, self.colors.secondary)
            end
        end
    end

    -- Re-draw center after spokes so the hub is clean.
    circ(screen_x, screen_y, core_r, self.tube_colors.shadow)
    circ(screen_x, screen_y, inner_r, tertiary)
    pix(screen_x, screen_y, self.tube_colors.stripe)

    -- ==========================================
    -- Hull panels around outer ring
    -- ==========================================

    if r >= 6 then
        local panel_count = 12
        local panel_dist = math.floor(outer_r * 0.82)
        local panel_size = math.max(1, math.floor(r * 0.08))

        for i = 1, panel_count do
            local a = ((i - 1) / panel_count) * math.pi * 2
            local px = screen_x + math.floor(math.cos(a) * panel_dist)
            local py = screen_y + math.floor(math.sin(a) * panel_dist)

            local color = self.colors.secondary

            if i % 3 == 0 then
                color = self.tube_colors.body
            elseif i % 2 == 0 then
                color = self.tube_colors.shadow
            end

            circ(px, py, panel_size, color)
        end
    end

    -- ==========================================
    -- Solar/radiator panels
    -- ==========================================

    if r >= 7 then
        local panel_w = math.max(3, math.floor(r * 0.65))
        local panel_h = math.max(2, math.floor(r * 0.22))
        local gap = math.floor(outer_r * 0.95)

        -- Left/right blue radiator panels.
        rect(screen_x - gap - panel_w, screen_y - math.floor(panel_h / 2), panel_w, panel_h, BLUE_DARK)
        rect(screen_x + gap, screen_y - math.floor(panel_h / 2), panel_w, panel_h, BLUE_DARK)
        line(screen_x - gap - panel_w, screen_y, screen_x - gap, screen_y, self.colors.tertiary)
        line(screen_x + gap, screen_y, screen_x + gap + panel_w, screen_y, self.colors.tertiary)

        -- Panel subdivision lines.
        local divisions = 3
        for i = 1, divisions - 1 do
            local ox = math.floor(panel_w * i / divisions)

            line(
                screen_x - gap - panel_w + ox,
                screen_y - math.floor(panel_h / 2),
                screen_x - gap - panel_w + ox,
                screen_y + math.floor(panel_h / 2),
                self.tube_colors.light
            )

            line(
                screen_x + gap + ox,
                screen_y - math.floor(panel_h / 2),
                screen_x + gap + ox,
                screen_y + math.floor(panel_h / 2),
                self.tube_colors.light
            )
        end
    end

    -- ==========================================
    -- Navigation/blinking lights
    -- ==========================================

    if r >= 4 then
        local light_dist = math.floor(outer_r * 1.05)
        local blink_on = (math.floor(timer / 24) % 2) == 0
        local blink_color = blink_on and YELLOW or ORANGE

        -- Four cardinal lights.
        pix(screen_x + light_dist, screen_y, GREEN_LITE)
        pix(screen_x - light_dist, screen_y, RED)
        pix(screen_x, screen_y - light_dist, blink_color)
        pix(screen_x, screen_y + light_dist, blink_color)

        -- Diagonal white/blue lights.
        if r >= 7 then
            local d = math.floor(light_dist * 0.72)

            pix(screen_x + d, screen_y + d, self.colors.primary)
            pix(screen_x - d, screen_y - d, self.colors.primary)
            pix(screen_x + d, screen_y - d, self.tube_colors.light)
            pix(screen_x - d, screen_y + d, self.tube_colors.light)
        end
    end

    -- ==========================================
    -- Rotating scanner/beacon
    -- ==========================================

    if r >= 6 then
        local beacon_angle = (timer * 0.035) % (math.pi * 2)
        local b1 = math.floor(inner_r * 0.8)
        local b2 = math.floor(outer_r * 1.15)

        local bx1 = screen_x + math.floor(math.cos(beacon_angle) * b1)
        local by1 = screen_y + math.floor(math.sin(beacon_angle) * b1)

        local bx2 = screen_x + math.floor(math.cos(beacon_angle) * b2)
        local by2 = screen_y + math.floor(math.sin(beacon_angle) * b2)

        line(bx1, by1, bx2, by2, self.tube_colors.light)
        pix(bx2, by2, self.colors.primary)
    end
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
    self:drawDockTubes()
    self:drawDocks()
    self:drawBody()
    self:drawLabel()
end
