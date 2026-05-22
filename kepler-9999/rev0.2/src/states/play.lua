-- ==========================================
-- STATE: PLAY
-- ==========================================

function inputPlay()
    if btnp(BTN_P1_START) then
        changeState(STATE.PAUSE)
    end

    -- Push all button monitoring off on the player class.
    if not game.play.player.dead then
        game.play.player:input()
    end
end

function updatePlay()
    local player = game.play.player
    player:move()
    updateCamera(player, game.camera)

    -- Regenerate energy, life support, and shields. tik check happens within
    -- the regenerate function.
    -- if player:everyNTicks(90) then
    --     player:regenerateHealth()
    -- end

    -- If ship is dead, count down and respawn or gameover
    if player.mortality.dead then
        player.mortality.respawn_timer = player.mortality.respawn_timer - 1

        if player.mortality.respawn_timer <= 0 then
            if player.mortality.num_lives <= 0 then
                changeState(STATE.GAMEOVER)
                return

            -- We'll figure this out later
            -- else
            --     player:respawn()
            end
        end
    else
        -- Check for collisions.
    end

    -- tick invulnerability
    if player.mortality.invulnerable > 0 then
        player.mortality.invulnerable = player.mortality.invulnerable - 1
    end

end


function drawStarMap()
    local camera = game.camera

    -- Camera position in pixels.
    local cam_x = math.floor(camera.x)
    local cam_y = math.floor(camera.y)

    -- Convert pixel camera to tile camera.
    local tile_x = math.floor(cam_x / TILE_SIZE)
    local tile_y = math.floor(cam_y / TILE_SIZE)

    -- Pixel offset inside the first visible tile.
    local offset_x = cam_x % TILE_SIZE
    local offset_y = cam_y % TILE_SIZE

    -- Draw generated star map.
    map(
        tile_x,             -- map x/y in tiles
        tile_y,             -- map x/y in tiles
        SCREEN_TILES_W + 1,
        SCREEN_TILES_H + 1,
        -offset_x,          -- screen x/y in pixels
        -offset_y,          -- screen x/y in pixels
        -1                  -- transparent color
    )
end

function drawUserHud()

end

function drawDebugCameraInfo()
    local player = game.play.player
    local camera = game.camera

    local screen_x = math.floor(player.position.x / SCREEN_W)
    local screen_y = math.floor(player.position.y / SCREEN_H)

    local debug_statements = {
        "Player X: " .. math.floor(player.position.x),
        "Player Y: " .. math.floor(player.position.y),
        "Player Vs: " .. string.format("%.3f", player.velocity.speed),
        "Player Vd: " .. string.format("%.3f", player.velocity.direction),
        "Camera X: " .. math.floor(camera.x),
        "Camera Y: " .. math.floor(camera.y),
        "MAP SCREEN: " .. screen_x .. "," .. screen_y,
    }
    for index, debug_msg in ipairs(debug_statements) do
        local debug_color = BLUE_LITE
        if index == 3 or index == 4 then
            debug_color = CYAN
        elseif index == 5 or index == 6 then
            debug_color = WHITE
        elseif index > 6 then
            debug_color = YELLOW
        end
        local len = print(debug_msg, -10, -10, debug_color, true)
        print(
        debug_msg,
        EDGE_X_RIGHT - len,
        EDGE_Y_TOP + (index - 1) * Y_PADDING,
        debug_color,
        true
    )
    end
end

function drawGame()
    cls(BLACK)

    drawStarMap()

    local player = game.play.player
    if not player.mortality.dead and player:shouldDraw() then
        player:drawBody()
    end

    -- Draw particle effects even if the ship explodes and isn't drawn anymore.
    -- player:drawParticles(player.TYPES.EXPLOSION)
    -- player:drawParticles(player.TYPES.SMOKE)
    -- player:drawParticles(player.TYPES.SPARK)
    -- player:drawParticles(player.TYPES.THRUST)

    drawUserHud()
end

function drawPlay()
    drawGame()

    if DEBUG == true then
        drawDebugCameraInfo()
    end
end
