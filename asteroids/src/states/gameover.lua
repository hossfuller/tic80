-- ==========================================
-- STATE: GAMEOVER
-- ==========================================

function inputGameover()
    if btnp(BTN_P1_A) or btnp(BTN_P1_B) then
        changeState(STATE.HIGHSCORES)
    end
end

function updateGameover()
    local player = game.play.player

    if player and player.moveParticles then
        player:moveParticles(player.TYPES.EXPLOSION)
        player:moveParticles(player.TYPES.LASER_HIT)
        player:moveParticles(player.TYPES.THRUST)
    end

    for index, asteroid in ipairs(game.play.asteroids) do
        asteroid:move()
    end
end

function drawGameover()
    cls(BLACK)

    for index, asteroid in ipairs(game.play.asteroids) do
        asteroid:draw()
    end

    local player = game.play.player
    if player then
        player:drawParticles(player.TYPES.EXPLOSION)
        player:drawParticles(player.TYPES.LASER_HIT)
        player:drawParticles(player.TYPES.THRUST)
    end

    drawCenteredText("GAME OVER", EDGE_Y_TOP + Y_PADDING, ORANGE, nil, 3, nil, YELLOW)
    drawCenteredText("Press Z or X to see high scores", EDGE_Y_BOTTOM - Y_PADDING, WHITE, false, 1, false, GRAY_MED)
end
