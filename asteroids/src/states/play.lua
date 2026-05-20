-- ==========================================
-- STATE: PLAY
-- ==========================================

function inputPlay()
    if btnp(BTN_P1_SELECT) and btnp(BTN_P1_START) then
        changeState(STATE.GAMEOVER)
    end

    if not game.play.player.dead then
        game.play.player:input()
    end
end

function updatePlay()
    local player = game.play.player
    local alien = game.play.alien

    player:move()
    if game.play.params.player.deadstop_allow == true and btn(BTN_P1_DOWN) then
        player:deadStop(
            game.play.params.player.deadstop_brake,
            game.play.params.player.deadstop_snap
        )
    end

    -- Regenerate health if it's been enabled.
    if game.play.params.player.regenerate == true and player:everyNTicks(90) then
        player:regenerateHealth()
    end

    -- Move the alien if it exists and is active
    if alien and alien:isActive() then
        alien:move()
    elseif alien and alien.dead then
        -- Still update particles for dead alien
        alien:move()
    end

    -- Move the laser blast and then check if it hit anything.
    player:moveLaserBlasts()
    
    -- Check if laser hit the alien
    if alien and alien:isActive() then
        local alien_hit = player:checkLaserHitAlien(alien)
        if alien_hit then
            game.play.score = game.play.score + alien:getPoints()
            while game.play.score >= game.play.params.player.next_extra_life_score do
                player.cur_lives = player.cur_lives + 1
                game.play.params.player.next_extra_life_score = game.play.params.player.next_extra_life_score + PTS_FOR_EXTRA_LIFE
            end
        end
    end
    
    -- Check if laser hit asteroids
    hit_asteroid_index = player:checkLaserHit(game.play.asteroids)
    for index, asteroid in ipairs(game.play.asteroids) do
        if hit_asteroid_index == index then
            -- Increment score, and then check if the user earned an extra life.
            game.play.score = game.play.score + asteroid:getPoints()
            while game.play.score >= game.play.params.player.next_extra_life_score do
                player.cur_lives = player.cur_lives + 1
                game.play.params.player.next_extra_life_score = game.play.params.player.next_extra_life_score + PTS_FOR_EXTRA_LIFE
            end

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

    -- Move up a level when all asteroids are gone. Then regenerate asteroids.
    if #game.play.asteroids == 0 then
        game.play.level = game.play.level + 1
        generateAsteroids()
        generateAlien()  -- ADD THIS: Regenerate alien on new level
    end

    -- Now check if any asteroids have hit each other.
    for i = 1, #game.play.asteroids - 1 do
        local asteroid = game.play.asteroids[i]
        for j = i + 1, #game.play.asteroids do
            asteroid:resolveCollision(game.play.asteroids[j])
        end
    end

    -- Check if alien collides with asteroids
    if alien and alien:isActive() then
        for _, asteroid in ipairs(game.play.asteroids) do
            if alien:resolveCollision(asteroid) then
                alien:sparkEffect()
            end
        end
    end

    -- if ship is dead, count down and respawn or gameover
    if player.dead then
        player.respawn_timer = player.respawn_timer - 1

        if player.respawn_timer <= 0 then
            if player.cur_lives <= 0 then
                changeState(STATE.GAMEOVER)
                return
            else
                player:respawn()
            end
        end
    else
        -- normal collision/damage with asteroids
        for _, asteroid in ipairs(game.play.asteroids) do
            if player.invulnerable <= 0 and player:resolveCollision(asteroid) then
                player:takesDamage(asteroid:getInducedDamage())
                if player:getHealth() <= 0 then
                    player:kill()
                    break
                end
            end
        end
        
        -- Check player collision with alien
        if alien and alien:isActive() and player.invulnerable <= 0 then
            if player:resolveCollision(alien) then
                player:takesDamage(50)  -- Alien collision damage
                if player:getHealth() <= 0 then
                    player:kill()
                end
            end
        end
    end

    -- tick invulnerability
    if player.invulnerable > 0 then
        player.invulnerable = player.invulnerable - 1
    end
end

function drawPlayerHealthBar()
    local health_bar_length = 100
    local health_bar_height = Y_PADDING
    local health_percentage = game.play.player:getHealthFraction()

    rectb(EDGE_X_LEFT, EDGE_Y_TOP, health_bar_length + 2, health_bar_height, WHITE)
    rect(EDGE_X_LEFT + 1, EDGE_Y_TOP + 1, health_bar_length * health_percentage, health_bar_height - 2, GREEN_MED)

    return health_bar_length, health_bar_height
end

function drawAlienHealthBar()
    local health_bar_length     = 100
    local health_bar_height     = Y_PADDING
    local health_percentage     = game.play.alien:getHealthFraction()
    local right_justified_pos_x = EDGE_X_RIGHT - health_bar_length - 2

    rectb(right_justified_pos_x, EDGE_Y_TOP, health_bar_length + 2, health_bar_height, WHITE)
    rect(right_justified_pos_x + 1, EDGE_Y_TOP + 1, health_bar_length * health_percentage, health_bar_height - 2, RED)

    return health_bar_length, health_bar_height
end

function drawCurrentLives(used_length, used_height)
    local num_lives = game.play.player:getNumLives()
    local start_position = {
        x = used_length + X_PADDING,
        y = Y_PADDING / 2
    }
    for num = 1, num_lives do
        local ship_life = Ship:new({
            color = WHITE,
            x     = start_position.x,
            y     = start_position.y,
            rotation = 0,
            shape = {
                { x = 0,  y = -4 },
                { x = -2, y = 1 },
                { x = 0,  y = 0 },
                { x = 2,  y = 1 },
                { x = 0,  y = -4 }
            }
        })
        ship_life:drawBody()
        start_position.x = start_position.x + X_PADDING
    end
end

function drawLevel(used_height)
    local level_height = used_height + 2
    local level_length = print("LEVEL: " .. string.format("%02d", game.play.level), EDGE_X_LEFT, level_height, WHITE, true)
    return level_length, level_height + Y_PADDING
end

function drawScore(used_height)
    local score_height = used_height
    local score_length = print("SCORE: " .. tostring(game.play.score), EDGE_X_LEFT, score_height, WHITE, true)
    return score_length, score_height + Y_PADDING
end

function drawPlay()
    cls(BLACK)

    local player = game.play.player
    local alien = game.play.alien

    -- Draw ship body only if alive.
    if not player.dead and player:shouldDraw() then
        player:drawBody()
    end

    -- Draw lasers and particle effects even if the ship explodes and isn't
    -- drawn anymore.
    player:drawLaserBlasts()
    player:drawParticles(player.TYPES.EXPLOSION)
    player:drawParticles(player.TYPES.LASER_HIT)
    player:drawParticles(player.TYPES.SMOKE)
    player:drawParticles(player.TYPES.SPARK)
    player:drawParticles(player.TYPES.THRUST)

    -- Draw alien if it exists
    if alien.active then
        alien:draw()
        drawAlienHealthBar()
    end

    for index, asteroid in ipairs(game.play.asteroids) do
        asteroid:draw()
    end

    local health_length, health_height = drawPlayerHealthBar()
    local lives_length,  lives_height  = drawCurrentLives(health_length, health_height)
    local level_length, level_height   = drawLevel(health_height)
    local score_length, score_height   = drawScore(level_height)

    if DEBUG == true then
        print("HEALTH: " .. tostring(player:getHealth()), EDGE_X_LEFT, score_height + 2, CYAN, true)
        print("LIVES: " .. tostring(player:getNumLives()), EDGE_X_LEFT, 2*score_height, CYAN, true)
        print("ALIEN HEALTH: " .. tostring(alien:getHealthFraction()), EDGE_X_LEFT, 3*score_height, CYAN, true)

        local pos     = player:getPosition()
        local rot = player:getRotation()

        local pos_x   = string.format("%0.2f", pos.x)
        local pos_y   = string.format("%0.2f", pos.y)
        local radians = string.format("%0.2f", rot.rotation)
        local speed   = string.format("%0.2f", rot.speed)

        print("X: " .. pos_x .. "; Y: " .. pos_y, EDGE_X_LEFT, EDGE_Y_BOTTOM - 4 * Y_PADDING, GRAY_DARK)
        print("Radians: " .. radians .. "; Speed: " .. speed, EDGE_X_LEFT, EDGE_Y_BOTTOM - 3 * Y_PADDING, GRAY_DARK)
        print("Num of Lasers: " .. tostring(player:getNumLaserBlasts()), EDGE_X_LEFT, EDGE_Y_BOTTOM - 2 * Y_PADDING, GRAY_DARK)
        print("Num of Asteroids: " .. tostring(#game.play.asteroids), EDGE_X_LEFT, EDGE_Y_BOTTOM - Y_PADDING, GRAY_DARK)
    end
end
