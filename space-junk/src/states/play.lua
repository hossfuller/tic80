-- ==========================================
-- STATE: PLAY
-- ==========================================

function inputPlay()
    if btnp(BTN_P1_SELECT) and btnp(BTN_P1_START) then
        changeState(STATE.GAMEOVER)
    end

    game.play.player:input()
end

function updatePlay()
    game.play.player:move()
end

function drawPlay()
    cls(BLACK)

    game.play.player:draw()

    if DEBUG == true then
        local pos = game.play.player:getPosition()
        local rot = game.play.player:getRotation()

        local pos_x   = string.format("%0.2f", pos.x)
        local pos_y   = string.format("%0.2f", pos.y)
        local radians = string.format("%0.2f", rot.rotation)
        local speed   = string.format("%0.2f", rot.speed)

        print("X: " .. pos_x .. "; Y: " .. pos_y, EDGE_X_LEFT, EDGE_Y_TOP, WHITE)
        print("Radians: " .. radians .. "; Speed: " .. speed, EDGE_X_LEFT, EDGE_Y_TOP + Y_PADDING, WHITE)
    end

end
