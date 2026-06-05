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

function drawControlsOverlayBox(text)
    local box_width  = EDGE_X_RIGHT - 3 * X_PADDING
    local box_height = EDGE_Y_BOTTOM - 3 * Y_PADDING
    local box_pos_x  = (EDGE_X_RIGHT - box_width) / 2
    local box_pos_y  = (EDGE_Y_BOTTOM - box_height) / 2

    rect(box_pos_x, box_pos_y, box_width, box_height, 0)
    rectb(box_pos_x, box_pos_y, box_width, box_height, 12)

    drawCenteredText(text, box_pos_y + Y_PADDING, RED, false, 2, false, YELLOW)

    local controls_text = {
        { "Up",         "Forward Thrust" },
        { "Down",       "Inertia Brake" },
        { "Left/Right", "Rotate" },
        { "Select (A)", "View Space Map" },
        { "Start (S)",  "Pause" },
        { "Z",          "Harpoon/Dock/Release" },
        { "X",          "Mine/Shop" },
    }

    local key_color    = YELLOW
    local action_color = WHITE
    local shadow_color = GRAY_DARK

    local scale     = 1
    local fixed     = false
    local smallfont = false

    -- Measure widest text in each column.
    local max_key_width    = 0
    local max_action_width = 0

    drawCenteredText("Controls", box_pos_y + 3.5 * Y_PADDING, action_color, fixed, scale, smallfont, shadow_color)

    for _, row in ipairs(controls_text) do
        local key_text     = row[1]
        local action_text  = row[2]
        local key_width    = print(key_text, 0, -50, key_color, fixed, scale, smallfont)
        local action_width = print(action_text, 0, -50, action_color, fixed, scale, smallfont)
        if key_width > max_key_width then
            max_key_width = key_width
        end
        if action_width > max_action_width then
            max_action_width = action_width
        end
    end

    -- Table layout.
    local gap_width           = 10
    local left_column_padding = 8

    local left_column_width = max_key_width + left_column_padding
    local table_width       = left_column_width + gap_width + max_action_width

    -- Keep the table inside the overlay box.
    local max_table_width = box_width - 2 * X_PADDING
    if table_width > max_table_width then
        table_width = max_table_width
    end

    local table_pos_x = box_pos_x + math.floor((box_width - table_width) / 2)
    local table_pos_y = box_pos_y + 5 * Y_PADDING

    local left_column_pos_x  = table_pos_x
    local right_column_pos_x = table_pos_x + left_column_width + gap_width

    local rowH = 10

    for i, row in ipairs(controls_text) do
        local key_text = row[1]
        local action_text = row[2]

        local y = table_pos_y + (i - 1) * rowH

        -- Measure left-column/key text.
        local key_width = print(key_text, 0, -50, key_color, fixed, scale, smallfont)

        -- Center key text inside left column.
        local key_pos_x = left_column_pos_x + math.floor((left_column_width - key_width) / 2)

        -- Shadow.
        print(key_text, key_pos_x + 1, y + 1, shadow_color, fixed, scale, smallfont)
        print(action_text, right_column_pos_x + 1, y + 1, shadow_color, fixed, scale, smallfont)

        -- Actual text.
        print(key_text, key_pos_x, y, key_color, fixed, scale, smallfont)
        print(action_text, right_column_pos_x, y, action_color, fixed, scale, smallfont)
    end
end
