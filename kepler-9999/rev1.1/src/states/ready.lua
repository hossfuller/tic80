-- ==========================================
-- STATE: READY
-- ==========================================

function inputReady()

end

function updateReady()
    if btnp(BTN_P1_A) or btnp(BTN_P1_START) then
        changeState(STATE.PLAY)
    end

    if btnp(BTN_P1_B) then
        changeState(STATE.START)
    end
end

function drawReady()
    -- Draw the game state (paused/initial state)
    drawGame()

    -- Draw overlay
    drawControlsOverlayBox("READY?")
    drawCenteredText("Press Z to Begin", EDGE_Y_BOTTOM - Y_PADDING, WHITE, false, 1, true, GRAY_MED)
end

function drawControlsOverlayBox(text)
    local box_width  = EDGE_X_RIGHT - 3 * X_PADDING
    local box_height = EDGE_Y_BOTTOM - 3 * Y_PADDING
    local box_pos_x  = (EDGE_X_RIGHT - box_width) / 2
    local box_pos_y  = (EDGE_Y_BOTTOM - box_height) / 2

    rect(box_pos_x, box_pos_y, box_width, box_height, 0)
    rectb(box_pos_x, box_pos_y, box_width, box_height, 12)

    drawCenteredText(text, box_pos_y + Y_PADDING, RED, false, 2, false, YELLOW)

    local controls_text    = {
        { "Up",         "Forward Thrust" },
        { "Down",       "Inertia Brake" },
        { "Left/Right", "Rotate" },
        { "Select (A)", "View Space Map" },
        { "Start (S)",  "Pause/Missions List" },
        { "Z",          "Harpoon/Dock/Release" },
        { "X",          "Mine/Station Shop" },
    }

    local key_color        = YELLOW
    local action_color     = WHITE
    local shadow_color     = GRAY_DARK

    local scale            = 1
    local fixed            = false
    local smallfont        = false

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

    local left_column_width   = max_key_width + left_column_padding
    local table_width         = left_column_width + gap_width + max_action_width

    -- Keep the table inside the overlay box.
    local max_table_width     = box_width - 2 * X_PADDING
    if table_width > max_table_width then
        table_width = max_table_width
    end

    local table_pos_x        = box_pos_x + math.floor((box_width - table_width) / 2)
    local table_pos_y        = box_pos_y + 5 * Y_PADDING

    local left_column_pos_x  = table_pos_x
    local right_column_pos_x = table_pos_x + left_column_width + gap_width

    local rowH               = 10

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
