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

function drawStandardOverlayBox(text)
    local boxW = 120
    local boxH = 40
    local boxX = (EDGE_X_RIGHT - boxW) / 2
    local boxY = (EDGE_Y_BOTTOM - boxH) / 2

    -- Draw box background
    rect(boxX, boxY, boxW, boxH, 0)
    rectb(boxX, boxY, boxW, boxH, 12)

    -- Draw text
    drawCenteredText(text, boxY + 16, WHITE)
end

function drawControlsOverlayBox(text)
    local boxW = EDGE_X_RIGHT - 3 * X_PADDING
    local boxH = EDGE_Y_BOTTOM - 3 * Y_PADDING
    local boxX = (EDGE_X_RIGHT - boxW) / 2
    local boxY = (EDGE_Y_BOTTOM - boxH) / 2

    rect(boxX, boxY, boxW, boxH, 0)
    rectb(boxX, boxY, boxW, boxH, 12)

    drawCenteredText(text, boxY + Y_PADDING, RED, false, 2, false, YELLOW)
    drawCenteredText("Controls", boxY + 3.5 * Y_PADDING, WHITE)

    local controls_text = {
        { "Up",         "Forward Thrust" },
        { "Down",       "Inertia Brake" },
        { "Left/Right", "Rotate" },
        { "Start (S)",  "Pause" },
        { "Z",          "Harpoon/Dock/Release" },
        { "X",          "Mine/Shop" },
    }

    local keyColor = YELLOW
    local actionColor = WHITE
    local shadowColor = GRAY_DARK

    local scale = 1
    local fixed = false
    local smallfont = false

    -- Measure widest text in each column.
    local maxKeyW = 0
    local maxActionW = 0

    for _, row in ipairs(controls_text) do
        local keyText    = row[1]
        local actionText = row[2]
        local keyW       = print(keyText, 0, -50, keyColor, fixed, scale, smallfont)
        local actionW    = print(actionText, 0, -50, actionColor, fixed, scale, smallfont)

        if keyW > maxKeyW then
            maxKeyW = keyW
        end
        if actionW > maxActionW then
            maxActionW = actionW
        end
    end

    -- Table layout.
    local gapW = 10
    local leftColPadding = 8

    local leftColW = maxKeyW + leftColPadding
    local tableW = leftColW + gapW + maxActionW

    -- Keep the table inside the overlay box.
    local maxTableW = boxW - 2 * X_PADDING
    if tableW > maxTableW then
        tableW = maxTableW
    end

    local tableX = boxX + math.floor((boxW - tableW) / 2)
    local tableY = boxY + 5 * Y_PADDING

    local leftColX = tableX
    local rightColX = tableX + leftColW + gapW

    local rowH = 10

    for i, row in ipairs(controls_text) do
        local keyText = row[1]
        local actionText = row[2]

        local y = tableY + (i - 1) * rowH

        -- Measure left-column/key text.
        local keyW = print(keyText, 0, -50, keyColor, fixed, scale, smallfont)

        -- Center key text inside left column.
        local keyX = leftColX + math.floor((leftColW - keyW) / 2)

        -- Shadow.
        print(keyText, keyX + 1, y + 1, shadowColor, fixed, scale, smallfont)
        print(actionText, rightColX + 1, y + 1, shadowColor, fixed, scale, smallfont)

        -- Actual text.
        print(keyText, keyX, y, keyColor, fixed, scale, smallfont)
        print(actionText, rightColX, y, actionColor, fixed, scale, smallfont)
    end
end
