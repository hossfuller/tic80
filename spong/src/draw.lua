--[[ DRAW FUNCTIONS ]]--

function DRAW()
    cls(BLACK)

    -- Draw the court, which is stationary.
    drawCourt()

    -- -- Draw score and other situational information
    -- -- if ALWAYS_SHOW_SCORE or (
    -- --     paddle1:isInPlay() == false
    -- --     or paddle1:isInPlay() == false
    -- --     or ball:isInPlay() == false
    -- -- ) then
    -- --     drawScoreBug()
    -- -- end
    -- drawScoreBug()

    -- Draw the moving elements.
    paddle1:draw()
    paddle2:draw()
    ball:draw()

    -- print_centered_text("P1.x = " .. paddle1.x, 20)
    -- print_centered_text("P1.y = " .. paddle1.y, 30)
    -- print_centered_text("P1.player = " .. paddle1.player, 40)
    print_centered_text("P1.isInPlay() = " .. tostring(paddle1:isInPlay()), 50)

    -- print_centered_text("P2.x = " .. paddle2.x, 70)
    -- print_centered_text("P2.y = " .. paddle2.y, 80)
    -- print_centered_text("P2.player = " .. paddle2.player, 90)
    print_centered_text("P2.isInPlay() = " .. tostring(paddle2:isInPlay()), 100)

    print_centered_text("Ball.isInPlay() = " .. tostring(ball:isInPlay()), 120)
end -- DRAW()

function drawCourt()
    -- Net
    for _i=EDGE_Y_TOP+2,EDGE_Y_BOTTOM,8 do
        rect(EDGE_X_RIGHT/2, _i, BOUNDARY_WIDTH, 4, GREEN_LITE)
    end
    -- Court boundaries
    line(EDGE_X_LEFT, EDGE_Y_TOP, EDGE_X_RIGHT - 1, EDGE_Y_TOP, YELLOW)
    line(EDGE_X_LEFT, EDGE_Y_BOTTOM, EDGE_X_RIGHT - 1, EDGE_Y_BOTTOM, YELLOW)
end

-- function drawScoreBug()
--     local score_line = string.format("%d - %d", paddle1:getScore(), paddle2:getScore())
--     print_centered_text(score_line, BOUNDARY_WIDTH + 2, BLUE_LITE, true, 2)

--     if SHOW_NUM_RETURNS then
--         local returns_line = string.format("%d   %d", paddle1:getReturns(), paddle2:getReturns())
--         print_centered_text(returns_line, EDGE_Y_BOTTOM - 9, GRAY_LITE, true, 1)
--     end
-- end

function print_centered_text(message, height, color, shadow, scale)
    if height == nil then
        height = math.floor(EDGE_Y_BOTTOM/2)
    end
    if color == nil then
        color = WHITE
    end
    if shadow == nil then
        shadow = false
    end
    if scale == nil then
        scale = 1
    end
    local message_width = print(message, 0, -40, color, true, scale)
    local x_pos = ((EDGE_X_RIGHT - message_width) / 2) + 2
    if shadow then
        print(message, x_pos + 1, height + 1, color + 1, true, scale)
    end
    print(message, x_pos, height, color, true, scale)
end
