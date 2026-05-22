--
-- Bundle file
-- Code changes will be overwritten
--

-- title:   Kepler-9999
-- author:  Hoss Fuller
-- version: rev0.1
-- script:  lua
-- input:   mouse
-- saveid:  kepler_9999

-- ==========================================
-- INCLUDES
-- ==========================================

-- [TQ-Bundler: src.constants_tic80]

-- ==========================================
-- TIC80 CONSTANTS
-- ==========================================

-- Colors
local BLACK      = 0
local PURPLE     = 1
local RED        = 2
local ORANGE     = 3
local YELLOW     = 4
local GREEN_LITE = 5
local GREEN_MED  = 6
local GREEN_DARK = 7
local BLUE_DARK  = 8
local BLUE_MED   = 9
local BLUE_LITE  = 10
local CYAN       = 11
local WHITE      = 12
local GRAY_LITE  = 13
local GRAY_MED   = 14
local GRAY_DARK  = 15

-- Button mappings
local BTN_P1_UP     = 0
local BTN_P1_DOWN   = 1
local BTN_P1_LEFT   = 2
local BTN_P1_RIGHT  = 3
local BTN_P1_A      = 4         -- Primary action / Select
local BTN_P1_B      = 5         -- Secondary action / Back / Pause
local BTN_P1_X      = 6
local BTN_P1_Y      = 7
local BTN_P1_SELECT = BTN_P1_X
local BTN_P1_START  = BTN_P1_Y

-- Screen dimensions
local EDGE_X_LEFT       = 0
local EDGE_X_RIGHT      = 240
local EDGE_Y_TOP        = 0
local EDGE_Y_BOTTOM     = 136

local SCREEN_W          = EDGE_X_RIGHT
local SCREEN_H          = EDGE_Y_BOTTOM

-- Map dimensions
local TILE_SIZE         = 8
local MAP_TILES_W       = 240
local MAP_TILES_H       = 136
local SCREEN_TILES_W    = 30
local SCREEN_TILES_H    = 17

local MAP_PIXELS_W      = MAP_TILES_W * TILE_SIZE
local MAP_PIXELS_H      = MAP_TILES_H * TILE_SIZE

local MAP_SCREENS_W     = 8
local MAP_SCREENS_H     = 8

-- Character dimensions (these scale linearly)
local FIXED_CHAR_WIDTH  = 6
local FIXED_CHAR_HEIGHT = 6
local X_PADDING         = FIXED_CHAR_WIDTH + 2
local Y_PADDING         = FIXED_CHAR_HEIGHT + 2


-- [/TQ-Bundler: src.constants_tic80]

-- [TQ-Bundler: src.constants_game]

-- ==========================================
-- GAME CONSTANTS
-- ==========================================

local DEBUG = true

local TILE_EMPTY       = 0
local TILE_STAR_DIM    = 1
local TILE_STAR_MED    = 2
local TILE_STAR_BRIGHT = 3


-- [/TQ-Bundler: src.constants_game]

-- [TQ-Bundler: src.generators]

-- ==========================================
-- GENERATORS
-- ==========================================

function generateStarScreen(screen_x, screen_y)
    local start_tile_x = screen_x * SCREEN_TILES_W
    local start_tile_y = screen_y * SCREEN_TILES_H

    -- Give every screen slightly different density.
    -- Example: 2% to 8% chance per tile.
    local density = math.random(2, 8)

    for local_y = 0, SCREEN_TILES_H - 1 do
        for local_x = 0, SCREEN_TILES_W - 1 do
            local map_x = start_tile_x + local_x
            local map_y = start_tile_y + local_y

            local roll = math.random(1, 100)

            if roll <= density then
                local star_roll = math.random(1, 100)

                if star_roll <= 70 then
                    mset(map_x, map_y, TILE_STAR_DIM)
                elseif star_roll <= 95 then
                    mset(map_x, map_y, TILE_STAR_MED)
                else
                    mset(map_x, map_y, TILE_STAR_BRIGHT)
                end
            else
                mset(map_x, map_y, TILE_EMPTY)
            end
        end
    end

    -- Optional: place a few brighter landmark stars per screen.
    local landmark_count = math.random(1, 4)

    for i = 1, landmark_count do
        local lx = start_tile_x + math.random(0, SCREEN_TILES_W - 1)
        local ly = start_tile_y + math.random(0, SCREEN_TILES_H - 1)

        mset(lx, ly, TILE_STAR_BRIGHT)
    end
end

function generateStarMap()
    -- Clear the whole map first.
    for y = 0, MAP_TILES_H - 1 do
        for x = 0, MAP_TILES_W - 1 do
            mset(x, y, TILE_EMPTY)
        end
    end

    -- Generate each of the 8x8 map screens separately.
    for screen_y = 0, MAP_SCREENS_H - 1 do
        for screen_x = 0, MAP_SCREENS_W - 1 do
            generateStarScreen(screen_x, screen_y)
        end
    end
end


-- [/TQ-Bundler: src.generators]

-- [TQ-Bundler: src.game_state]

-- ==========================================
-- GAME STATE
-- ==========================================

STATE = {
    START      = "START",
    OPTIONS    = "OPTIONS",
    HIGHSCORES = "HIGHSCORES",
    READY      = "READY",
    PLAY       = "PLAY",
    PAUSE      = "PAUSE",
    GAMEOVER   = "GAMEOVER",
}

game = {
    state = STATE.START,
    prevState = nil,

    -- Menu state
    menu = {
        selected = 1,
        options = {"Start", "Options", "High Scores"},
    },

    -- Options state
    options = {
        selected = 1,
        items = {
            -- {name = "Sound", values = {"On", "Off"}, current = 1},
            -- {name = "Difficulty", values = {"Easy", "Normal", "Hard"}, current = 2},
            -- {name = "Back", values = {""}, current = 1},
            {
                name = "Back",
                values = nil, -- No values means this is an action, not a setting.
                current = 1,
                apply = function()
                    changeState(STATE.START)
                end,
            },
        },
    },

    -- High scores
    hiscores = {},

    -- Game Parameters
    params = {},

    -- The top-down camera
    camera = {
        x = 0,
        y = 0,

        target_x = 0,
        target_y = 0,

        lerp = 0.08,
    },

    -- Gameplay state
    play = {
        -- player = {},

        -- ============
        -- For testing
        -- ============
        player = {
            x = MAP_PIXELS_W / 2,
            y = MAP_PIXELS_H / 2,
            speed = 2,
        },
    },
}


-- ==========================================
-- STATE CHANGE
-- ==========================================

function changeState(newState)
    game.prevState = game.state
    game.state = newState

    if newState == STATE.READY then
        math.randomseed(tstamp() + time())

        generateStarMap()
        resetPlayerAndCamera()
    end
end

function resetPlayerAndCamera()
    local player = game.play.player
    local camera = game.camera

    -- Start somewhere in the middle of the full 64-screen map.
    player.x = MAP_PIXELS_W / 2
    player.y = MAP_PIXELS_H / 2

    camera.x = player.x - SCREEN_W / 2
    camera.y = player.y - SCREEN_H / 2

    camera.x = clamp(camera.x, 0, MAP_PIXELS_W - SCREEN_W)
    camera.y = clamp(camera.y, 0, MAP_PIXELS_H - SCREEN_H)

    camera.target_x = camera.x
    camera.target_y = camera.y
end


-- [/TQ-Bundler: src.game_state]

-- [TQ-Bundler: src.helpers]

-- ==========================================
-- HELPERS
-- ==========================================

-- ==========================================
-- TIME HELPERS
-- ==========================================

-- mdays_common = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }

-- function get_unix_timestamp()
--     return math.tointeger(tstamp())
-- end

-- function convert_datetime_obj_to_string(datetime_obj)
--     return string.format(
--         "%04d-%02d-%02d",
--         datetime_obj.year,
--         datetime_obj.month,
--         datetime_obj.day
--     )
-- end

-- function is_greg_leap(y)
--     return (y % 4 == 0) and ((y % 100 ~= 0) or (y % 400 == 0))
-- end

-- function greg_days_in_month(y, m)
--     if m == 2 and is_greg_leap(y) then return 29 end
--     return mdays_common[m]
-- end

-- -- Unix seconds -> Gregorian UTC date/time (year,month,day,hour,min,sec)
-- function unix_to_greg_utc(ts)
--     local sec_per_day = 86400
--     local days        = math.floor(ts / sec_per_day)
--     local sod         = ts - days * sec_per_day
--     if sod < 0 then
--         sod = sod + sec_per_day
--         days = days - 1
--     end

--     local hour = math.floor(sod / 3600); sod = sod - hour * 3600
--     local min  = math.floor(sod / 60)
--     local sec  = sod - min * 60

--     local y    = 1970
--     if days >= 0 then
--         while true do
--             local diy = is_greg_leap(y) and 366 or 365
--             if days >= diy then
--                 days = days - diy
--                 y = y + 1
--             else
--                 break
--             end
--         end
--     else
--         while days < 0 do
--             y = y - 1
--             local diy = is_greg_leap(y) and 366 or 365
--             days = days + diy
--         end
--     end

--     local m = 1
--     while true do
--         local dim = greg_days_in_month(y, m)
--         if days >= dim then
--             days = days - dim
--             m = m + 1
--         else
--             break
--         end
--     end

--     local d = days + 1

--     return {
--         year  = y,
--         month = m,
--         day   = d,
--         hour  = hour,
--         min   = min,
--         sec   = sec
--     }
-- end

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
    return world_x - game.camera.x, world_y - game.camera.y
end

-- ==========================================
-- DRAWING HELPERS
-- ==========================================

function drawCenteredText(text, y, color, fixed, scale, smallfont, shadow_color)
    if fixed == nil then
        fixed = false
    end
    if scale == nil then
        scale = 1
    end
    if smallfont == nil then
        smallfont = false
    end
    if shadow_color == nil then
        shadow_color = -1
    end
    local width = print(text, 0, -50, color, fixed, scale, smallfont)

    if shadow_color >= 0 then
        print(text, (EDGE_X_RIGHT - width) / 2 + 1, y + 1, shadow_color, fixed, scale, smallfont)
    end
    print(text, (EDGE_X_RIGHT - width) / 2, y, color, fixed, scale, smallfont)
end

function drawOverlayBox(text)
    local boxW = 120
    local boxH = 40
    local boxX = (EDGE_X_RIGHT - boxW) / 2
    local boxY = (EDGE_Y_BOTTOM - boxH) / 2

    -- Draw box background
    rect(boxX, boxY, boxW, boxH, 0)
    rectb(boxX, boxY, boxW, boxH, 12)

    -- Draw text
    drawCenteredText(text, boxY + 16, 12)
end


-- [/TQ-Bundler: src.helpers]

-- [TQ-Bundler: src.states.start]

-- ==========================================
-- STATE: START (Main Menu)
-- ==========================================

function inputStart()
    -- Menu navigation
    if btnp(BTN_P1_UP) then
        game.menu.selected = game.menu.selected - 1
        if game.menu.selected < 1 then
            game.menu.selected = #game.menu.options
        end
    end

    if btnp(BTN_P1_DOWN) or btnp(BTN_P1_SELECT) then
        game.menu.selected = game.menu.selected + 1
        if game.menu.selected > #game.menu.options then
            game.menu.selected = 1
        end
    end

    -- Menu selection
    if btnp(BTN_P1_A) or btnp(BTN_P1_START) then
        local selected = game.menu.selected
        if selected == 1 then
            changeState(STATE.READY)
        elseif selected == 2 then
            changeState(STATE.OPTIONS)
        elseif selected == 3 then
            changeState(STATE.HIGHSCORES)
        end
    end
end

function updateStart()

end

function drawStart()
    cls(BLACK)

    drawCenteredText("KEPLER-9999", EDGE_Y_TOP + Y_PADDING, ORANGE, nil, 3, nil, YELLOW)

    -- Menu options
    local start_y = 60
    local spacing = 2 * X_PADDING

    for i, option in ipairs(game.menu.options) do
        local y = start_y + (i - 1) * spacing
        local color = (i == game.menu.selected) and YELLOW or WHITE

        -- Draw selector
        if i == game.menu.selected then
            local textWidth = print(option, 0, -10)
            local x = (EDGE_X_RIGHT - textWidth) / 2
            print(">", x - 10 + 1, y + 1, GRAY_MED) -- the shadow
            print(">", x - 10, y, WHITE)
        end

        -- drawCenteredText(option, y, color)
        drawCenteredText(option, y, color, nil, nil, nil, GRAY_MED)
    end

    drawCenteredText("Press Z to select options", EDGE_Y_BOTTOM - Y_PADDING, WHITE, false, 1, true, GRAY_MED)
end


-- [/TQ-Bundler: src.states.start]

-- [TQ-Bundler: src.states.options]

-- ==========================================
-- STATE: OPTIONS
-- ==========================================

function applyAllOptions()
    for _, item in ipairs(game.options.items) do
        if item.apply and item.values then
            item.apply(item.current)
        end
    end
end

function inputOptions()
    -- Navigate up/down through menu items
    if btnp(BTN_P1_UP) then
        game.options.selected = game.options.selected - 1
        if game.options.selected < 1 then
            game.options.selected = #game.options.items
        end
    end

    if btnp(BTN_P1_DOWN) then
        game.options.selected = game.options.selected + 1
        if game.options.selected > #game.options.items then
            game.options.selected = 1
        end
    end

    local item = game.options.items[game.options.selected]

    -- If item has values, left/right cycles through them
    if item.values then
        if btnp(BTN_P1_LEFT) then
            item.current = item.current - 1
            if item.current < 1 then
                item.current = #item.values
            end
            if item.apply then
                item.apply(item.current)
            end
        end

        if btnp(BTN_P1_RIGHT) then
            item.current = item.current + 1
            if item.current > #item.values then
                item.current = 1
            end
            if item.apply then
                item.apply(item.current)
            end
        end
    end

    -- A button activates items (for "Back" or items without values)
    if btnp(BTN_P1_A) then
        if item.values == nil and item.apply then
            -- Action item like "Back"
            item.apply()
        end
    end

    -- B button always goes back
    if btnp(BTN_P1_B) then
        changeState(STATE.START)
    end
end

function updateOptions()

end

function drawOptions()
    cls(BLACK)

    -- Title
    drawCenteredText("OPTIONS", EDGE_Y_TOP + Y_PADDING, ORANGE, nil, 3, nil, YELLOW)

    -- Menu items
    local start_y = 50
    local spacing = 2 * Y_PADDING

    for i, item in ipairs(game.options.items) do
        local y = start_y + (i - 1) * spacing
        local is_selected = (i == game.options.selected)
        local name_color = is_selected and YELLOW or WHITE

        -- Draw selector arrow
        if is_selected then
            print(">", X_PADDING + 1, y + 1, BLACK)
            print(">", X_PADDING, y, WHITE)
        end

        -- Draw item name
        local name_x = X_PADDING + 12
        print(item.name, name_x + 1, y + 1, BLACK)
        print(item.name, name_x, y, name_color)

        -- Draw value (if it has one)
        if item.values then
            local value_text = "< " .. item.values[item.current] .. " >"
            local value_x = EDGE_X_RIGHT - X_PADDING - print(value_text, 0, -50)
            local value_color = is_selected and CYAN or GRAY_LITE

            print(value_text, value_x + 1, y + 1, BLACK)
            print(value_text, value_x, y, value_color)
        end
    end

    -- Instructions
    local inst_y = EDGE_Y_BOTTOM - 2 * Y_PADDING
    drawCenteredText("UP/DOWN: Select  LEFT/RIGHT: Change", inst_y, WHITE, false, 1, true, GRAY_MED)
    drawCenteredText("Z: Confirm  X: Back", inst_y + Y_PADDING, WHITE, false, 1, true, GRAY_MED)
end


-- [/TQ-Bundler: src.states.options]

-- [TQ-Bundler: src.states.highscores]

-- ==========================================
-- STATE: HIGH SCORES
-- ==========================================

-- Persistent memory has 255 slots.
MAX_HIGH_SCORES     = 19
PMEM_CHUNK_ELEMENTS = 4

-- We'll store our high scores in this table.
lines = {}

-- ==========================================
-- HIGH SCORE HELPERS
-- ==========================================

-- function loadHighScores()
--     game.high_scores = {}

--     for idx = 0, MAX_HIGH_SCORES do
--         local base = idx * PMEM_CHUNK_ELEMENTS
--         local date = pmem(base + 0)
--         if date ~= 0 then
--             game.high_scores[base] = {
--                 date  = date,
--                 diff  = pmem(base + 1),
--                 level = pmem(base + 2),
--                 score = pmem(base + 3),
--             }
--         end
--     end
-- end

-- function sortHighScores()
--     local list = {}

--     for _, d in pairs(game.high_scores) do
--         if d and d.score and d.score > 0 then
--             list[#list + 1] = d
--         end
--     end

--     table.sort(list, function(a, b)
--         if a.score ~= b.score then
--             return a.score > b.score
--         end

--         if a.diff ~= b.diff then
--             return a.diff > b.diff
--         end

--         if a.level ~= b.level then
--             return a.level > b.level
--         end

--         return a.date > b.date
--     end)

--     game.high_scores = {}

--     for i = 1, math.min(#list, MAX_HIGH_SCORES + 1) do
--         game.high_scores[(i - 1) * PMEM_CHUNK_ELEMENTS] = list[i]
--     end
-- end

-- function saveCurrentScore()
--     loadHighScores()

--     local list = {}

--     -- Pull saved scores into a list.
--     for idx = 0, MAX_HIGH_SCORES do
--         local base = idx * PMEM_CHUNK_ELEMENTS
--         local d = game.high_scores[base]

--         if d then
--             list[#list + 1] = d
--         end
--     end

--     -- Add current result.
--     list[#list + 1] = {
--         date  = game.play.date,
--         diff  = game.play.diff,
--         level = game.play.level,
--         score = game.play.score,
--     }

--     -- Put list back into game.high_scores so sortHighScores() can sort it.
--     game.high_scores = {}

--     for i = 1, #list do
--         game.high_scores[(i - 1) * PMEM_CHUNK_ELEMENTS] = list[i]
--     end

--     sortHighScores()

--     -- Clear pmem.
--     for i = 0, 255 do
--         pmem(i, 0)
--     end

--     -- Save compacted/sorted high scores.
--     for idx = 0, MAX_HIGH_SCORES do
--         local base = idx * PMEM_CHUNK_ELEMENTS
--         local d = game.high_scores[base]

--         if d then
--             pmem(base + 0, d.date)
--             pmem(base + 1, d.diff)
--             pmem(base + 2, d.level)
--             pmem(base + 3, d.score)
--         end
--     end
-- end

-- function difficultyToString(diff)
--     if diff == 3 then
--         return "Hard"
--     elseif diff == 2 then
--         return "Medium"
--     elseif diff == 1 then
--         return "Easy"
--     end

--     return "?"
-- end

-- function buildLines()
--     lines = {}

--     local score_count = 1
--     for idx = 0, MAX_HIGH_SCORES do
--         local k = idx * PMEM_CHUNK_ELEMENTS
--         local d = game.high_scores[k]

--         if d then
--             local dt_obj = unix_to_greg_utc(d.date)
--             local dt_str = convert_datetime_obj_to_string(dt_obj)
--             local diff_str = difficultyToString(d.diff)

--             table.insert(
--                 lines,
--                 string.format("%2d", score_count) .. ". " ..
--                 dt_str ..
--                 "  " .. string.format("%7d", d.score) ..
--                 "  L" .. string.format("%02d", d.level) ..
--                 "  " .. diff_str
--             )
--             score_count = score_count + 1
--         end
--     end
-- end

-- ==========================================
-- MAIN HIGH SCORE FUNCTIONS
-- ==========================================

function inputHighScores()
    if btnp(BTN_P1_A) or btnp(BTN_P1_B) then
        changeState(STATE.START)
    end
end

function updateHighScores()

end

function drawHighScores()
    cls(BLACK)

    -- -- LAYOUT
    -- local header_y = EDGE_Y_TOP + Y_PADDING
    -- local line_h = FIXED_CHAR_HEIGHT + 1
    -- local view_top = header_y + FIXED_CHAR_HEIGHT + 2 * Y_PADDING
    -- local view_bottom = EDGE_Y_BOTTOM - 2 * Y_PADDING
    -- local visible_lines = math.max(1, math.floor((view_bottom - view_top) / line_h))

    -- -- INPUT
    -- local max_scroll = math.max(0, #lines - visible_lines)

    -- -- keyboard (hold+repeat)
    -- if btnp(BTN_P1_UP, 15, 3) then
    --     scroll = scroll - 1
    -- end
    -- if btnp(BTN_P1_DOWN, 15, 3) then
    --     scroll = scroll + 1
    -- end

    -- -- clamp
    -- scroll = math.max(0, math.min(max_scroll, scroll))

    drawCenteredText("HIGH SCORES", EDGE_Y_TOP + Y_PADDING, ORANGE, nil, 3, nil, YELLOW)

    -- -- draw visible slice
    -- for i = 0, visible_lines - 1 do
    --     local line = lines[scroll + 1 + i] -- Lua arrays are 1-based
    --     if not line then break end
    --     local y = view_top + i * line_h
    --     print(line, X_PADDING + 1, y + 1, GRAY_MED, true) -- the shadow
    --     print(line, X_PADDING, y, WHITE, true)
    -- end

    -- -- Small scrollbar indicator
    -- if max_scroll > 0 then
    --     local bar_x = EDGE_X_RIGHT - 4
    --     rect(bar_x, view_top, 2, view_bottom - view_top, GRAY_DARK)
    --     local thumb_h = math.max(4, math.floor((view_bottom - view_top) * (visible_lines / #lines)))
    --     local thumb_y = view_top + math.floor((view_bottom - view_top - thumb_h) * (scroll / max_scroll))
    --     rect(bar_x, thumb_y, 2, thumb_h, GREEN_LITE)
    -- end

    -- Instructions
    drawCenteredText("Press Z to Return", EDGE_Y_BOTTOM - Y_PADDING, WHITE, false, 1, true, GRAY_MED)
end


-- [/TQ-Bundler: src.states.highscores]

-- [TQ-Bundler: src.states.ready]

-- ==========================================
-- STATE: READY
-- ==========================================

function inputReady()

end

function updateReady()
    if btnp(BTN_P1_START) then
        changeState(STATE.PLAY)
    end

    if btnp(BTN_P1_B) then
        changeState(STATE.START)
    end
end

function drawReady()
    -- Draw the game state (paused/initial state)
    drawGame()

    -- Draw overlay
    drawOverlayBox("READY?")
    drawCenteredText("Press 'START' (S) to Begin", EDGE_Y_BOTTOM - Y_PADDING, WHITE, false, 1, true, GRAY_MED)
end


-- [/TQ-Bundler: src.states.ready]

-- [TQ-Bundler: src.states.play]

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
        0                   -- transparent color
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
        if index == 2 or index == 3 then
            debug_color = CYAN
        elseif index == 4 then
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


-- [/TQ-Bundler: src.states.play]

-- [TQ-Bundler: src.states.pause]

-- ==========================================
-- STATE: PAUSE
-- ==========================================

function inputPause()
    if btnp(BTN_P1_START) then
        changeState(STATE.PLAY)
    end
    if btnp(BTN_P1_SELECT) then
        changeState(STATE.GAMEOVER)
    end
end

function updatePause()

end

function drawPause()
    -- Draw the game state (frozen)
    drawGame()

    -- Draw overlay
    drawOverlayBox("PAUSED")
    drawCenteredText("Press 'START' (S) to Resume", EDGE_Y_BOTTOM - 2* Y_PADDING, WHITE, false, 1, true, GRAY_MED)
    drawCenteredText("Press 'SELECT' (A) to Quit", EDGE_Y_BOTTOM - Y_PADDING, WHITE, false, 1, true, GRAY_MED)
end


-- [/TQ-Bundler: src.states.pause]

-- [TQ-Bundler: src.states.gameover]

-- ==========================================
-- STATE: GAMEOVER
-- ==========================================

function inputGameover()
    if btnp(BTN_P1_A) or btnp(BTN_P1_B) then
        changeState(STATE.START)
    end
end

function updateGameover()

end

function drawGameover()
    drawGame()

    drawOverlayBox("GAME OVER")
    drawCenteredText("Press Z to Continue", EDGE_Y_BOTTOM - Y_PADDING, WHITE, false, 1, true, GRAY_MED)
end


-- [/TQ-Bundler: src.states.gameover]

-- [TQ-Bundler: src.state_machine]

-- ==========================================
-- STATE MACHINE
-- ==========================================

states = {
    [STATE.START] = {
        input  = inputStart,
        update = updateStart,
        draw = drawStart,
    },
    [STATE.OPTIONS] = {
        input  = inputOptions,
        update = updateOptions,
        draw = drawOptions,
    },
    [STATE.HIGHSCORES] = {
        input  = inputHighScores,
        update = updateHighScores,
        draw   = drawHighScores,
    },
    [STATE.READY] = {
        input  = inputReady,
        update = updateReady,
        draw = drawReady,
    },
    [STATE.PLAY] = {
        input  = inputPlay,
        update = updatePlay,
        draw = drawPlay,
    },
    [STATE.PAUSE] = {
        input  = inputPause,
        update = updatePause,
        draw = drawPause,
    },
    [STATE.GAMEOVER] = {
        input  = inputGameover,
        update = updateGameover,
        draw = drawGameover,
    },
}


-- [/TQ-Bundler: src.state_machine]

-- ==========================================
-- MAIN TIC FUNCTION
-- ==========================================

function BOOT()
    applyAllOptions()
    changeState(STATE.START)
end


function TIC()
    local currentState = states[game.state]
    if currentState then
        currentState.input()
        currentState.update()
        currentState.draw()
    end
end

-- <TILES>
-- 001:00000000000000000000000000000000000b0000000000000000000000000000
-- 002:0000000000020000000000000000000000000000000000000000000000000000
-- 003:0000000000000000000000000000000000000000000000000000000000000004
-- 016:c00000000c00000000c00000000cc000000ccc000000ccc000000ccc000000cc
-- 017:00000000000000000000000000000000000000000000000000000011c0001111
-- 018:0000000000000000000001110001111201122222112222331122233322233334
-- 019:0011000011111000121221101121211122111211322112113321121133232111
-- 032:0000000c00000000000000000000000100000011000001110000011100001112
-- 033:cc111122ccc111241ccc444011ccc000114c0000124000002440000024000000
-- 034:2233344344443433000444430000443300000432000044330000433300044432
-- 035:3223211232322111223211212322112122211221321112102211111023111100
-- 048:0001122200011212001121230012112300111233001112330111223301212333
-- 049:2400000034000000240000003440004434404444444444224334223344333332
-- 050:004433320443332344432233443223312222222122222311223332112333221c
-- 051:331210003111000011210000121000001110000010000000c0000000c0000000
-- 064:0121222301212233012212330112122201121222001112220001111100000111
-- 065:3333333323333232333333322333332222222221222221101111100011100000
-- 066:233221cc22221000221100001010000000000000000000000000000000000000
-- 067:cc000000ccc000000ccc000000ccc0000000c00000000c00000000c00000000c
-- 080:0000000000000000000000000000000000000000000000000000000800000008
-- 081:0000000000000000000000000000008800088888088888888888888988899999
-- 082:0000000000000082000088228888822188888388c98888389999988199999991
-- 083:0222221122112211114121112221211823111118111114101211110021111100
-- 096:0000008800000088000008880000888800008889000088890008889900088899
-- 097:88999999899999aa9999aaaa999aaabb99aaabbb99aabcbb9aaabbbb9aabbbbb
-- 098:999c9912aaaa9122aaaaa121baaa1111bbba1211bbb12111bb122111bb121141
-- 099:2141280011112000111120001312800011228000112800001128000012880000
-- 112:000888990008889900038c890008888900083889008228880022128800212282
-- 113:9caabbbb9aaabbb499aaab1199aaa111999a1141991111111221111122111411
-- 114:b11111111111311111111119131111991111399911129998122299882299888c
-- 115:28880000948000009880000088800000880c0000880000008000000000000000
-- 128:0221212202111311221111112111111121141111111111221111222811222000
-- 129:1111131211111188141122881122280022288800288880008400000000000000
-- 130:9888888088888000888000004000c00000000000000000000000000000000000
-- </TILES>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304000000000
-- </SFX>

-- <TRACKS>
-- 000:100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </TRACKS>

-- <PALETTE>
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

