-- ==========================================
-- HELPERS
-- ==========================================

function getOrDefault(value, default)
    if value == nil then
        return default
    end
    return value
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

function drawOverlayBox(text)
    local boxW = 120
    local boxH = 40
    local boxX = (EDGE_X_RIGHT - boxW) / 2
    local boxY = (EDGE_Y_BOTTOM - boxH) / 2

    -- Draw box background
    rect(boxX, boxY, boxW, boxH, 0)
    rectb(boxX, boxY, boxW, boxH, 12)

    -- Draw text
    drawCenteredText(text, boxY + 16, 12)
end
