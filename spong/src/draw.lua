--[[ DRAW FUNCTIONS ]]--

function DRAW()
    drawCourt()

    drawScores()

    if SHOW_NUM_RETURNS then
        drawReturns()
    end

    -- Draw the moving elements.
    paddle1:draw()
    paddle2:draw()
    ball:draw()
end -- DRAW()


function drawCourt()
    -- Net
    for i = EDGE_Y_TOP + 2, EDGE_Y_BOTTOM, 8 do
        rect(EDGE_X_RIGHT / 2, i, BOUNDARY_WIDTH, 4, GREEN_LITE)
    end
    -- Court boundaries
    line(EDGE_X_LEFT, EDGE_Y_TOP, EDGE_X_RIGHT - 1, EDGE_Y_TOP, YELLOW)
    line(EDGE_X_LEFT, EDGE_Y_BOTTOM, EDGE_X_RIGHT - 1, EDGE_Y_BOTTOM, YELLOW)
end

function print_centered_text(message, height, color, shadow, fixed, scale)
    if height == nil then
        height = math.floor(EDGE_Y_BOTTOM / 2)
    end
    if color == nil then
        color = WHITE
    end
    if shadow == nil then
        shadow = false
    end
    if fixed == nil then
        fixed = true
    end
    if scale == nil then
        scale = 1
    end
    local message_width = print(message, 0, -40, color, fixed, scale)
    local x_pos = ((EDGE_X_RIGHT - message_width) / 2) + 2
    if shadow then
        print(message, x_pos + 1, height + 1, color + 1, fixed, scale)
    end
    print(message, x_pos, height, color, fixed, scale)
end

function drawScores()
    local score_scale = 2
    local score_color = ORANGE
    local y_pos       = EDGE_Y_BOTTOM - 15

    local p1_score_str   = string.format("%2d", paddle1:getScore())
    local p1_score_width = print(p1_score_str, 0, -100, WHITE, true, score_scale, false)
    local p1_x_pos       = math.floor((EDGE_X_RIGHT - BOUNDARY_WIDTH) / 2) - p1_score_width - 4
    print(p1_score_str, p1_x_pos + 1, y_pos + 1, score_color + 1, true, score_scale, false)
    print(p1_score_str, p1_x_pos, y_pos, score_color, true, score_scale, false)

    local p2_score_str = string.format("%-2d", paddle2:getScore())
    local p2_x_pos     = math.floor((EDGE_X_RIGHT - BOUNDARY_WIDTH) / 2) + 10
    print(p2_score_str, p2_x_pos + 1, y_pos + 1, score_color + 1, true, score_scale, false)
    print(p2_score_str, p2_x_pos, y_pos, score_color, true, score_scale, false)
end

function drawReturns()
    local return_scale = 2
    local return_color = GRAY_LITE
    local y_pos        = EDGE_Y_TOP + BOUNDARY_WIDTH + 3

    local p1_return_str   = string.format("%2d", paddle1:getReturns())
    local p1_return_width = print(p1_return_str, 0, -100, WHITE, true, return_scale, false)
    local p1_x_pos       = math.floor((EDGE_X_RIGHT - BOUNDARY_WIDTH) / 2) - p1_return_width - 4
    print(p1_return_str, p1_x_pos + 1, y_pos + 1, return_color + 1, true, return_scale, false)
    print(p1_return_str, p1_x_pos, y_pos, return_color, true, return_scale, false)

    local p2_return_str = string.format("%-2d", paddle2:getReturns())
    local p2_x_pos     = math.floor((EDGE_X_RIGHT - BOUNDARY_WIDTH) / 2) + 10
    print(p2_return_str, p2_x_pos + 1, y_pos + 1, return_color + 1, true, return_scale, false)
    print(p2_return_str, p2_x_pos, y_pos, return_color, true, return_scale, false)
end
