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

end

function drawPlay()
    cls(PURPLE)

    game.play.player:draw()

    if DEBUG == true then
        local pos = game.play.player:getPosition()
        local rot = game.play.player:getRotation()

        print("X: " .. tostring(pos.x) .. "; Y: " .. tostring(pos.y), EDGE_X_LEFT, EDGE_Y_TOP, WHITE)
        print("Radians: " .. tostring(rot.rotation) .. "; Speed: " .. tostring(rot.speed), EDGE_X_LEFT, EDGE_Y_TOP + Y_PADDING, WHITE)
    end

end
