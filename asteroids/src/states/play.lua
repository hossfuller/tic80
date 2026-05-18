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
    if game.play.params.player.deadstop_allow == true and btn(BTN_P1_DOWN) then
        -- brake and snap can change as player takes damage?
        game.play.player:deadStop(
            game.play.params.player.deadstop_break,
            game.play.params.player.deadstop_snap
        )
    end

    -- Move the laser blast and then check if it hit anything.
    game.play.player:moveLaserBlasts()
    hit_asteroid_index = game.play.player:checkLaserHit(game.play.asteroids)
    for index, asteroid in ipairs(game.play.asteroids) do
        if hit_asteroid_index == index then
            game.play.score = game.play.score + asteroid:getPoints()
            local fragments = asteroid:explode()

            -- remove original asteroid from list of asteroids
            table.remove(game.play.asteroids, hit_asteroid_index)

            -- If the asteroid was big enough to break into pieces, add the
            -- pieces to the asteroids table.
            if fragments ~= nil then
                for frag_index, fragment in ipairs(fragments) do
                    table.insert(game.play.asteroids, fragment)
                end
            end
        else
            asteroid:move()
        end
    end

    -- Now check if any asteroids have hit the ship.
    for index, asteroid in ipairs(game.play.asteroids) do
        if game.play.player:polygonInPolygon(game.play.player, asteroid) then
            changeState(STATE.GAMEOVER)
        end
    end
end

function drawPlay()
    cls(BLACK)

    game.play.player:draw()
    game.play.player:drawLaserBlasts()

    for index, asteroid in ipairs(game.play.asteroids) do
        asteroid:draw()
    end

    print("SCORE: " .. tostring(game.play.score), EDGE_X_LEFT, EDGE_Y_TOP, CYAN, true)


    if DEBUG == true then
        local pos = game.play.player:getPosition()
        local rot = game.play.player:getRotation()

        local pos_x   = string.format("%0.2f", pos.x)
        local pos_y   = string.format("%0.2f", pos.y)
        local radians = string.format("%0.2f", rot.rotation)
        local speed   = string.format("%0.2f", rot.speed)

        print("X: " .. pos_x .. "; Y: " .. pos_y, EDGE_X_LEFT, EDGE_Y_BOTTOM - 4 * Y_PADDING, GRAY_DARK)
        print("Radians: " .. radians .. "; Speed: " .. speed, EDGE_X_LEFT, EDGE_Y_BOTTOM - 3 * Y_PADDING, GRAY_DARK)
        print("Num of Lasers: " .. tostring(game.play.player:getNumOfLaserBlasts()), EDGE_X_LEFT, EDGE_Y_BOTTOM - 2 * Y_PADDING, GRAY_DARK)
        print("Num of Asteroids: " .. tostring(#game.play.asteroids), EDGE_X_LEFT, EDGE_Y_BOTTOM - Y_PADDING, GRAY_DARK)
    end

end
