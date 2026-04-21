--[[ DRAW FUNCTIONS ]]--

function DRAW()
    cls(BLACK)

    --- Draw the court, which is stationary.
    drawCourt()

    -- Draw the HUD for each user.
    drawHud(paddle1, ball:isInPlay())
    drawHud(paddle2, ball:isInPlay())

    -- Draw the moving elements.
    paddle1:draw()
    paddle2:draw()
    ball:draw()

    -- print_centered_text("P1.x = " .. paddle1.x, 20)
    -- print_centered_text("P1.y = " .. paddle1.y, 30)
    -- print_centered_text("P1.player = " .. paddle1.player, 40)
    -- print_centered_text("P1.isInPlay() = " .. tostring(paddle1:isInPlay()), 50)

    -- print_centered_text("P2.x = " .. paddle2.x, 70)
    -- print_centered_text("P2.y = " .. paddle2.y, 80)
    -- print_centered_text("P2.player = " .. paddle2.player, 90)
    -- print_centered_text("P2.isInPlay() = " .. tostring(paddle2:isInPlay()), 100)

    -- print_centered_text("Ball.isInPlay() = " .. tostring(ball:isInPlay()), 110)
    -- print_centered_text("Ball.isTouchingPaddle() = " .. tostring(ball:isTouchingPaddle()), 120)
end -- DRAW()

function drawHud(paddle, ball_status)
    local x_pos = EDGE_X_LEFT - HUD_WIDTH
    local y_pos = EDGE_Y_TOP + BOUNDARY_WIDTH

    local red_light_spr_id    = 257
    local yellow_light_spr_id = 259
    local green_light_spr_id  = 261
    local status_light_spr_id = 0

    local score_scale  = 2
    local return_scale = 2
    local score_color  = ORANGE
    local return_color = BLUE_LITE

    if paddle.player == 2 then
        x_pos = EDGE_X_RIGHT + 1
    end

    if paddle:isInPlay() == false then
        status_light_spr_id = red_light_spr_id
    elseif paddle:isInPlay() == true and ball_status == false then
        status_light_spr_id = yellow_light_spr_id
    elseif paddle:isInPlay() == true and ball_status == true then
        status_light_spr_id = green_light_spr_id
    end
    spr(status_light_spr_id, x_pos, y_pos, 0, 1, 0, 0, 2, 4)

    if paddle:getScore() > 9 then
        score_scale = 1
    end
    print(paddle:getScore(), x_pos + 1, y_pos + 36, score_color + 1, true, score_scale, false)
    print(paddle:getScore(), x_pos, y_pos + 35, score_color, true, score_scale, false)

    if SHOW_NUM_RETURNS then
        if paddle:getReturns() > 9 then
            return_scale = 1
        end
        print(paddle:getReturns(), x_pos + 1, y_pos + 51, return_color - 1, true, return_scale, false)
        print(paddle:getReturns(), x_pos, y_pos + 50, return_color, true, return_scale, false)
    end
end

function drawCourt()
    -- Net
    for _i=EDGE_Y_TOP+2,EDGE_Y_BOTTOM,8 do
        rect(EDGE_X_RIGHT/2, _i, BOUNDARY_WIDTH, 4, GREEN_LITE)
    end
    -- Court boundaries
    line(EDGE_X_LEFT, EDGE_Y_TOP, EDGE_X_RIGHT - 1, EDGE_Y_TOP, YELLOW)
    line(EDGE_X_LEFT, EDGE_Y_BOTTOM, EDGE_X_RIGHT - 1, EDGE_Y_BOTTOM, YELLOW)
end

function print_centered_text(message, height, color, shadow, fixed, scale)
    if height == nil then
        height = math.floor(EDGE_Y_BOTTOM/2)
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
