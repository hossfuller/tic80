-- ==========================================
-- STATE: PLAY
-- ==========================================

function inputPlay()
    if btnp(BTN_P1_START) then
        changeState(STATE.PAUSE)
    end

    -- Push all button monitoring off on the player class.
    -- if not game.play.player.dead then
    --     game.play.player:input()
    -- end
end

function updatePlay()

end

function drawUserHud()

end


function drawGame()
    cls(BLACK)

    -- ================================
    -- YOUR GAME RENDERING HERE
    -- ================================

    drawUserHud()
end

function drawPlay()
    drawGame()

    if DEBUG == true then
        print("HEALTH: " .. tostring(player:getHealth()), EDGE_X_LEFT, score_height + 2, CYAN, true)
        print("LIVES: " .. tostring(player:getNumLives()), EDGE_X_LEFT, 2 * score_height, CYAN, true)
        print("ALIEN HEALTH: " .. tostring(alien:getHealthFraction()), EDGE_X_LEFT, 3 * score_height, CYAN, true)

        local pos     = player:getPosition()
        local rot     = player:getRotation()

        local pos_x   = string.format("%0.2f", pos.x)
        local pos_y   = string.format("%0.2f", pos.y)
        local radians = string.format("%0.2f", rot.rotation)
        local speed   = string.format("%0.2f", rot.speed)

        print("X: " .. pos_x .. "; Y: " .. pos_y, EDGE_X_LEFT, EDGE_Y_BOTTOM - 4 * Y_PADDING, GRAY_DARK)
        print("Radians: " .. radians .. "; Speed: " .. speed, EDGE_X_LEFT, EDGE_Y_BOTTOM - 3 * Y_PADDING, GRAY_DARK)
        print("Num of Lasers: " .. tostring(player:getNumLaserBlasts()), EDGE_X_LEFT, EDGE_Y_BOTTOM - 2 * Y_PADDING,
            GRAY_DARK)
        print("Num of Asteroids: " .. tostring(#game.play.asteroids), EDGE_X_LEFT, EDGE_Y_BOTTOM - Y_PADDING, GRAY_DARK)
    end
end
