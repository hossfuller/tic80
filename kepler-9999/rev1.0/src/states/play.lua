-- ==========================================
-- STATE: PLAY
-- ==========================================

function inputPlay()
    if btnp(BTN_P1_START) then
        changeState(STATE.PAUSE)
    end

    if btnp(BTN_P1_SELECT) then
        togglePlayZoom()
    end

    if btnp(BTN_P1_B) then
        local dock = game.play.player:getDockedSpaceDock()
        if dock and dock.host and SpaceStation ~= nil and getmetatable(dock.host) == SpaceStation then
            game.shop.selected = 1
            changeState(STATE.SHOP)
            return
        end
    end

    updateMouseWheelZoom()

    -- Push all button monitoring off on the player class.
    game.play.player:input()
end

function updatePlay()
    if game.play.star then
        game.play.star:update()
    end

    for _, planet in ipairs(game.play.planets) do
        planet:update()
    end

    for _, station in ipairs(game.play.space_stations or {}) do
        station:update()
    end

    -- Apply gravity before movable objects move this frame.
    updateGravity()

    if game.play.comets then
        for _, comet in ipairs(game.play.comets) do
            comet:update()
        end
    end
    maintainCometCount()

    for i = #game.play.asteroids, 1, -1 do
        local asteroid = game.play.asteroids[i]

        asteroid:update()

        if (asteroid:isFinished() or asteroid:isOffMap()) and not asteroid:hasLiveParticles() then
            table.remove(game.play.asteroids, i)
        end
    end

    local player = game.play.player
    player:move()
    updateCamera(player, game.camera)

    -- If ship is dead, count down and respawn or gameover
    if player.dead then
        if player.mortality and
            player.mortality.num_lives <= 0 and
            player.mortality.respawn_timer <= 0
        then
            if not game.play.high_score_saved then
                saveCurrentScore(player)
                game.play.high_score_saved = true
            end

            if player:isFinished() then
                changeState(STATE.GAMEOVER)
                return
            end
        end
    else
        updateCollisions()
    end

    -- tick invulnerability
    if player.mortality.invulnerable > 0 then
        player.mortality.invulnerable = player.mortality.invulnerable - 1
    end
end


function drawStarMap()
    local camera = game.camera
    local zoom = camera.zoom or 1

    -- TIC-80 map() does not handle zooming out below 1x cleanly.
    -- For zoomed-out view, leave the background black.
    if zoom < 1 then
        return
    end

    -- Camera position in pixels.
    local cam_x = math.floor(camera.x)
    local cam_y = math.floor(camera.y)

    -- Convert pixel camera to tile camera.
    local tile_x = math.floor(cam_x / TILE_SIZE)
    local tile_y = math.floor(cam_y / TILE_SIZE)

    -- Pixel offset inside the first visible tile.
    local offset_x = (cam_x % TILE_SIZE) * zoom
    local offset_y = (cam_y % TILE_SIZE) * zoom

    local visible_tiles_w = math.ceil(SCREEN_W / (TILE_SIZE * zoom)) + 1
    local visible_tiles_h = math.ceil(SCREEN_H / (TILE_SIZE * zoom)) + 1

    -- Draw generated star map.
    map(
        tile_x,             -- map x/y in tiles
        tile_y,             -- map x/y in tiles
        visible_tiles_w,
        visible_tiles_h,
        -offset_x,          -- screen x/y in pixels
        -offset_y,          -- screen x/y in pixels
        -1,                 -- transparent color
        zoom
    )
end

function drawShipCargoHoldHud()
    local player             = game.play.player

    local cargo_fraction     = clamp(player:getCargoMassFraction(), 0, 1)
    local passenger_fraction = clamp(player:getPassengerMassFraction(), 0, 1)
    local smuggled_fraction  = clamp(player:getSmuggledMassFraction(), 0, 1)

    local total_fraction     = cargo_fraction + passenger_fraction + smuggled_fraction

    if total_fraction > 1 then
        cargo_fraction     = cargo_fraction / total_fraction
        passenger_fraction = passenger_fraction / total_fraction
        smuggled_fraction  = smuggled_fraction / total_fraction
        total_fraction     = 1
    end

    local label    = "C"

    -- Same width style as E/L/S bars.
    local bar_w    = print("C", -100, -100, WHITE, true, 1, true) + 1
    local bar_h    = 108
    local bar_x    = EDGE_X_LEFT + 3
    local bottom_y = EDGE_Y_BOTTOM - 8
    local bar_y    = bottom_y - bar_h

    -- Label.
    print(label, bar_x, bottom_y, GRAY_MED, true, 1, true)

    -- Border.
    rectb(bar_x, bar_y, bar_w - 1, bar_h - 1, WHITE)

    -- Empty background.
    rect( bar_x + 1, bar_y + 1, bar_w - 2, bar_h - 2, BLACK)

    local inner_x     = bar_x + 1
    local inner_y     = bar_y + 1
    local inner_w     = bar_w - 2
    local inner_h     = bar_h - 2

    local cargo_h     = math.floor(inner_h * cargo_fraction)
    local passenger_h = math.floor(inner_h * passenger_fraction)
    local smuggled_h  = math.floor(inner_h * smuggled_fraction)

    -- Fix possible rounding gap when completely full.
    local used_h      = cargo_h + passenger_h + smuggled_h
    if total_fraction >= 1 and used_h < inner_h then
        cargo_h = cargo_h + (inner_h - used_h)
    end

    -- Draw from bottom upward.
    local cursor_y = inner_y + inner_h

    -- Cargo at bottom.
    if cargo_h > 0 then
        cursor_y = cursor_y - cargo_h
        rect(inner_x, cursor_y, inner_w, cargo_h, GRAY_DARK)
    end

    -- Passengers above cargo.
    if passenger_h > 0 then
        cursor_y = cursor_y - passenger_h
        rect(inner_x, cursor_y, inner_w, passenger_h, GRAY_MED)
    end

    -- Smuggled goods above passengers.
    if smuggled_h > 0 then
        cursor_y = cursor_y - smuggled_h
        rect(inner_x, cursor_y, inner_w, smuggled_h, GRAY_LITE)
    end
end

function drawShipStatusHud()
    local player                = game.play.player

    local bars                  = {
        {
            label      = "V",
            color      = YELLOW,
            value      = player:getVelocityFraction(),
            multiplier = 9,
        },
        {
            label      = "E",
            color      = BLUE_LITE,
            value      = player:getEnergyFraction(),
            multiplier = player:getEnergyMultiplier(),
        },
        {
            label      = "L",
            color      = GREEN_MED,
            value      = player:getLifeSupportFraction(),
            multiplier = player:getLifeSupportMultiplier(),
        },
        {
            label      = "S",
            color      = RED,
            value      = player:getShieldFraction(),
            multiplier = player:getShieldMultiplier(),
        },
    }

    local bar_w                 = print("E", -100, -100, WHITE, true, 1, true) + 1
    local pixels_per_multiplier = 12

    -- Same baseline as drawShipCargoHoldHud().
    local bottom_y              = EDGE_Y_BOTTOM - 8

    -- M bar starts at EDGE_X_LEFT + 3.
    -- Status bars start one bar-width after M.
    local mass_bar_x            = EDGE_X_LEFT + 3
    local start_x               = mass_bar_x + bar_w

    for i, bar in ipairs(bars) do
        local bar_h  = pixels_per_multiplier * clamp(bar.multiplier, 1, 9)
        local bar_x  = start_x + (i - 1) * bar_w
        local bar_y  = bottom_y - bar_h
        local value  = clamp(bar.value, 0, 1)
        local fill_h = math.floor((bar_h - 2) * value)

        -- Label.
        print(bar.label, bar_x, bottom_y, bar.color, true, 1, true)

        -- Border.
        rectb(bar_x, bar_y, bar_w - 1, bar_h - 1, WHITE)

        -- Empty background.
        rect(bar_x + 1, bar_y + 1, bar_w - 2, bar_h - 2, BLACK)

        -- Fill from bottom upward.
        rect(bar_x + 1, bar_y + bar_h - 1 - fill_h, bar_w - 2, fill_h, bar.color)
    end
end

function drawShipLivesHud()
    local player = game.play.player
    if not player or not player.mortality then
        return
    end

    local lives = player.mortality.num_lives or 0
    if lives <= 0 then
        return
    end

    -- Same fixed-small-font character width used by the HUD bars.
    local bar_w = print("E", -100, -100, WHITE, true, 1, true) + 1

    -- Same baseline as drawShipCargoHoldHud() and drawShipStatusHud().
    local bottom_y = EDGE_Y_BOTTOM - 8

    -- Lives column goes immediately to the right of the status bars.
    local cargo_bar_x = EDGE_X_LEFT + 3
    local status_start_x = cargo_bar_x + bar_w
    local status_bar_count = 4

    local lives_x = status_start_x + status_bar_count * bar_w

    -- Keep triangle no wider than one fixed-font character.
    local tri_w = math.max(3, bar_w - 1)
    local tri_h = 5
    local gap = 1

    -- Center the triangle inside its one-character column.
    local tri_x = lives_x + math.floor((bar_w - tri_w) / 2)

    -- Bottom triangle lines up with the printed HUD characters at bottom_y.
    -- The triangle's vertical center is placed near the character's center.
    local char_h = FIXED_CHAR_HEIGHT
    local first_top_y = bottom_y + math.floor((char_h - tri_h) / 2)

    for i = 1, lives do
        -- Bottom life is first, additional lives stack upward.
        local y = first_top_y - (i - 1) * (tri_h + gap)
        local x1 = tri_x + math.floor(tri_w / 2)
        local y1 = y
        local x2 = tri_x
        local y2 = y + tri_h
        local x3 = tri_x + tri_w
        local y3 = y + tri_h

        -- Shadow.
        tri(x1 + 1, y1 + 1, x2 + 1, y2 + 1, x3 + 1, y3 + 1, BLACK)

        -- Life marker.
        tri(x1, y1, x2, y2, x3, y3, WHITE)
    end
end

function drawGame()
    cls(BLACK)

    drawStarMap()

    if game.play.star then
        game.play.star:draw()
    end

    for _, planet in ipairs(game.play.planets) do
        planet:draw()
    end

    for _, station in ipairs(game.play.space_stations or {}) do
        station:draw()
    end

    if game.play.comets then
        for _, comet in ipairs(game.play.comets) do
            comet:draw()
        end
    end

    for _, asteroid in ipairs(game.play.asteroids) do
        asteroid:draw()
    end

    local player = game.play.player
    player:draw()

    if game.camera.zoom >= 0.5 then
        drawShipCargoHoldHud()
        drawShipStatusHud()
        drawShipLivesHud()
    end
end

function drawPlay()
    drawGame()

    if DEBUG == true then
        drawDebugCameraInfo()
    end
end

-- For debug purposes...
function drawDebugCameraInfo()
    local player = game.play.player
    local camera = game.camera

    local screen_x = math.floor(player.position.x / SCREEN_W)
    local screen_y = math.floor(player.position.y / SCREEN_H)

    local debug_statements = {
        -- "Player X: " .. math.floor(player.position.x),
        -- "Player Y: " .. math.floor(player.position.y),
        -- "Player Vs: " .. string.format("%.3f", player.velocity.speed),
        -- "Player Vd: " .. string.format("%.3f", player.velocity.direction),
        -- "Camera X: " .. math.floor(camera.x),
        -- "Camera Y: " .. math.floor(camera.y),
        "MAP SCREEN: " .. screen_x .. "," .. screen_y,
        "Energy: " .. math.floor(player.engines.energy.cur) .. "/" .. player.engines.energy.max,
        "Cargo: " .. player:getCargoMass() .. "/" .. player:getCargoMassMax(),
        "Passengers: " .. player:getPassengerMass() .. "/" .. player:getPassengerMassMax(),
        "Smuggled: " .. player:getSmuggledMass() .. "/" .. player:getSmuggledMassMax(),
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
