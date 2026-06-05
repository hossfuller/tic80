-- ==========================================
-- CAMERA FUNCTIONS
-- ==========================================

function getPlayerCurrentMapScreen()
    return {
        screen_x = math.floor(game.play.player.position.x / SCREEN_W),
        screen_y = math.floor(game.play.player.position.y / SCREEN_H)
    }
end

function setPlayerStartMapScreen(screen_x, screen_y)
    local player = game.play.player
    local camera = game.camera

    player.position.x = screen_x * SCREEN_W + SCREEN_W / 2
    player.position.y = screen_y * SCREEN_H + SCREEN_H / 2

    camera.x = screen_x * SCREEN_W
    camera.y = screen_y * SCREEN_H

    camera.x = clamp(camera.x, 0, MAP_PIXELS_W - SCREEN_W)
    camera.y = clamp(camera.y, 0, MAP_PIXELS_H - SCREEN_H)

    camera.target_x = camera.x
    camera.target_y = camera.y
end

function resetPlayerAndCamera()
    setPlayerStartMapScreen(0, 0)
end

function updateCamera(player, camera)
    local zoom = camera.zoom or 1

    local visible_w = SCREEN_W / zoom
    local visible_h = SCREEN_H / zoom

    -- Target camera position places player in center of visible world area.
    camera.target_x = player.position.x - visible_w / 2
    camera.target_y = player.position.y - visible_h / 2

    -- Clamp target so camera does not show outside the map.
    camera.target_x = clamp(camera.target_x, 0, MAP_PIXELS_W - visible_w)
    camera.target_y = clamp(camera.target_y, 0, MAP_PIXELS_H - visible_h)

    -- Smoothly move camera toward target.
    camera.x = lerp(camera.x, camera.target_x, camera.lerp)
    camera.y = lerp(camera.y, camera.target_y, camera.lerp)
end

-- ==========================================
-- CAMERA HELPERS
-- ==========================================

function clamp(value, min_value, max_value)
    if value < min_value then
        return min_value
    end

    if value > max_value then
        return max_value
    end

    return value
end

function lerp(a, b, t)
    return a + (b - a) * t
end

function worldToScreen(world_x, world_y)
    local zoom = game.camera.zoom or 1
    return
        (world_x - game.camera.x) * zoom,
        (world_y - game.camera.y) * zoom
end

function updateMouseWheelZoom()
    local mx, my, left, middle, right, scroll_x, scroll_y = mouse()
    local camera = game.camera

    if scroll_y > 0 then
        camera.zoom_index = camera.zoom_index + 1
    elseif scroll_y < 0 then
        camera.zoom_index = camera.zoom_index - 1
    end

    camera.zoom_index = clamp(camera.zoom_index, 1, #camera.zoom_levels)
    camera.zoom = camera.zoom_levels[camera.zoom_index]
end

function togglePlayZoom()
    local camera     = game.camera

    local zoomed_out = 0.1
    local zoomed_in  = 1

    -- Use a threshold instead of exact equality because zoom may become a float.
    if camera.zoom <= 0.1 then
        camera.zoom = zoomed_in
        camera.zoom_index = 5 -- zoom_levels[5] == 1
    else
        camera.zoom = zoomed_out
        camera.zoom_index = 1 -- zoom_levels[1] == 0.1
    end
end
