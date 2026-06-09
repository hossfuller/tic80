-- ==========================================
-- HELPERS
-- ==========================================

function getOrDefault(value, default)
    if value == nil then
        return default
    end
    return value
end

function getUnixTimestampSeconds()
    local ts = tstamp()

    -- TIC-80 tstamp() is commonly milliseconds.
    if ts > 100000000000 then
        ts = math.floor(ts / 1000)
    end

    return ts
end

-- ==========================================
-- RANDOMIZATION HELPERS
-- ==========================================

function randomFloat(min_value, max_value)
    return min_value + math.random() * (max_value - min_value)
end

function randomChoice(list)
    return list[math.random(1, #list)]
end

-- ==========================================
-- "DISTANCE" HELPERS
-- ==========================================

function distanceSquared(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1

    return dx * dx + dy * dy
end

function objectsTooClose(a_x, a_y, a_radius, b_x, b_y, b_radius, padding)
    padding = padding or 0

    local min_distance = a_radius + b_radius + padding

    return distanceSquared(a_x, a_y, b_x, b_y) < min_distance * min_distance
end

-- ==========================================
-- DRAWING HELPERS
-- ==========================================

function drawCenteredText(text, y, color, fixed, scale, smallfont, shadow_color)
    if fixed == nil then
        fixed = false
    end
    if scale == nil then
        scale = 1
    end
    if smallfont == nil then
        smallfont = false
    end
    if shadow_color == nil then
        shadow_color = -1
    end
    local width = print(text, 0, -50, color, fixed, scale, smallfont)

    if shadow_color >= 0 then
        print(text, (EDGE_X_RIGHT - width) / 2 + 1, y + 1, shadow_color, fixed, scale, smallfont)
    end
    print(text, (EDGE_X_RIGHT - width) / 2, y, color, fixed, scale, smallfont)
end

function drawStandardOverlayBox(text)
    local box_width  = 120
    local box_height = 40
    local box_pos_x  = (EDGE_X_RIGHT - box_width) / 2
    local box_pos_y  = (EDGE_Y_BOTTOM - box_height) / 2

    -- Draw box background
    rect(box_pos_x, box_pos_y, box_width, box_height, 0)
    rectb(box_pos_x, box_pos_y, box_width, box_height, 12)

    -- Draw text
    drawCenteredText(text, box_pos_y + 16, WHITE)
end