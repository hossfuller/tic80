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

-- ============
-- For testing
-- ============
function updatePlayer()
    local player = game.play.player

    local dx = 0
    local dy = 0

    if btn(BTN_P1_LEFT) then
        dx = dx - 1
    end

    if btn(BTN_P1_RIGHT) then
        dx = dx + 1
    end

    if btn(BTN_P1_UP) then
        dy = dy - 1
    end

    if btn(BTN_P1_DOWN) then
        dy = dy + 1
    end

    -- Normalize diagonal movement.
    if dx ~= 0 and dy ~= 0 then
        local inv = 1 / math.sqrt(2)
        dx = dx * inv
        dy = dy * inv
    end

    player.x = player.x + dx * player.speed
    player.y = player.y + dy * player.speed

    player.x = clamp(player.x, 0, MAP_PIXELS_W - 1)
    player.y = clamp(player.y, 0, MAP_PIXELS_H - 1)
end

function updateCamera()
    local player = game.play.player
    local camera = game.camera

    -- Target camera position places player in center of screen.
    camera.target_x = player.x - SCREEN_W / 2
    camera.target_y = player.y - SCREEN_H / 2

    -- Clamp target so camera does not show outside the map.
    camera.target_x = clamp(camera.target_x, 0, MAP_PIXELS_W - SCREEN_W)
    camera.target_y = clamp(camera.target_y, 0, MAP_PIXELS_H - SCREEN_H)

    -- Smoothly move camera toward target.
    camera.x = lerp(camera.x, camera.target_x, camera.lerp)
    camera.y = lerp(camera.y, camera.target_y, camera.lerp)
end

function updatePlay()
    updatePlayer()
    updateCamera()
end

function drawPlayer()
    local player = game.play.player

    local screen_x, screen_y = worldToScreen(player.x, player.y)

    circ(screen_x, screen_y, 3, CYAN)
    pix(screen_x, screen_y, WHITE)
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

    local screen_x = math.floor(player.x / SCREEN_W)
    local screen_y = math.floor(player.y / SCREEN_H)

    local debug_statements = {
        "Player X: " .. math.floor(player.x),
        "Player Y: " .. math.floor(player.y),
        "Camera X: " .. math.floor(camera.x),
        "Camera Y: " .. math.floor(camera.y),
        "MAP SCREEN: " .. screen_x .. "," .. screen_y,
    }
    for index, debug_msg in ipairs(debug_statements) do
        local debug_color = WHITE
        if index == 3 or index == 4 then
            debug_color = CYAN
        elseif index == 5 then
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

    drawPlayer()

    drawUserHud()
end

function drawPlay()
    drawGame()

    if DEBUG == true then
        drawDebugCameraInfo()
    end
end
