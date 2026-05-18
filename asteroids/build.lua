--
-- Bundle file
-- Code changes will be overwritten
--

-- title:   Asteroids
-- author:  Hoss Fuller
-- desc:    Travel the universe, cleaning up space junk.
-- version: 0.1
-- script:  lua
-- saveid:  asteroids_bang_bang

-- ==========================================
-- INCLUDES
-- ==========================================

-- [TQ-Bundler: src.constants]

-- ==========================================
-- CONSTANTS
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
local EDGE_X_LEFT   = 0
local EDGE_X_RIGHT  = 240
local EDGE_Y_TOP    = 0
local EDGE_Y_BOTTOM = 136

-- Character dimensions (these scale linearly)
local FIXED_CHAR_WIDTH  = 6
local FIXED_CHAR_HEIGHT = 6
local X_PADDING         = FIXED_CHAR_WIDTH + 2
local Y_PADDING         = FIXED_CHAR_HEIGHT + 2

local DEBUG = true

-- [/TQ-Bundler: src.constants]

-- [TQ-Bundler: src.helpers]

-- ==========================================
-- HELPERS
-- ==========================================

-- ==========================================
-- TIME HELPERS
-- ==========================================

mdays_common = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }

function get_unix_timestamp()
    return math.tointeger(tstamp())
end

function convert_datetime_obj_to_string(datetime_obj)
    return string.format(
        "%04d-%02d-%02d",
        datetime_obj.year,
        datetime_obj.month,
        datetime_obj.day
    )
end

function is_greg_leap(y)
    return (y % 4 == 0) and ((y % 100 ~= 0) or (y % 400 == 0))
end

function greg_days_in_month(y, m)
    if m == 2 and is_greg_leap(y) then return 29 end
    return mdays_common[m]
end

-- Unix seconds -> Gregorian UTC date/time (year,month,day,hour,min,sec)
function unix_to_greg_utc(ts)
    local sec_per_day = 86400
    local days        = math.floor(ts / sec_per_day)
    local sod         = ts - days * sec_per_day
    if sod < 0 then
        sod = sod + sec_per_day
        days = days - 1
    end

    local hour = math.floor(sod / 3600); sod = sod - hour * 3600
    local min  = math.floor(sod / 60)
    local sec  = sod - min * 60

    local y    = 1970
    if days >= 0 then
        while true do
            local diy = is_greg_leap(y) and 366 or 365
            if days >= diy then
                days = days - diy
                y = y + 1
            else
                break
            end
        end
    else
        while days < 0 do
            y = y - 1
            local diy = is_greg_leap(y) and 366 or 365
            days = days + diy
        end
    end

    local m = 1
    while true do
        local dim = greg_days_in_month(y, m)
        if days >= dim then
            days = days - dim
            m = m + 1
        else
            break
        end
    end

    local d = days + 1

    return {
        year  = y,
        month = m,
        day   = d,
        hour  = hour,
        min   = min,
        sec   = sec
    }
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


-- [/TQ-Bundler: src.helpers]

-- [TQ-Bundler: src.game_state]

-- ==========================================
-- GAME STATE
-- ==========================================

STATE = {
    START      = "START",
    OPTIONS    = "OPTIONS",
    PLAY       = "PLAY",
    GAMEOVER   = "GAMEOVER",
    HIGHSCORES = "HIGHSCORES",
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
            {
                name = "Difficulty",
                values = {"Easy", "Medium", "Hard"},
                current = 2,
                -- Function to apply this setting
                apply = function(value)
                    if value == 1 then -- Easy
                        game.play.params.player.max_lasers        = 6
                        game.play.params.player.laser_lifetime    = 60
                        game.play.params.asteroids.num_population = 4
                        game.play.params.asteroids.velocity_max   = 0.3
                        game.play.params.asteroids.velocity_min   = 0.05
                    elseif value == 2 then -- Medium
                        game.play.params.player.max_lasers        = 5
                        game.play.params.player.laser_lifetime    = 50
                        game.play.params.asteroids.num_population = 6
                        game.play.params.asteroids.velocity_max   = 0.5
                        game.play.params.asteroids.velocity_min   = 0.1
                    elseif value == 3 then -- Hard
                        game.play.params.player.max_lasers        = 4
                        game.play.params.player.laser_lifetime    = 40
                        game.play.params.asteroids.num_population = 8
                        game.play.params.asteroids.velocity_max   = 0.8
                        game.play.params.asteroids.velocity_min   = 0.2
                    end
                end,
            },
            {
                name = "Dead Stop",
                values = {"On", "Off"},
                current = 1,
                apply = function(value)
                    game.play.params.player.deadstop_allow = (value == 1)
                end,
            },
            {
                name = "Back",
                values = nil,  -- No values means this is an action, not a setting
                current = 1,
                apply = function()
                    changeState(STATE.START)
                end,
            },
        },
    },
    -- For any forthcoming options, make all params below configurable.
    -- Also, as ship takes damage, some parameters should change.

    -- Gameplay state
    play = {
        params = {
            player = {
                deadstop_allow = true,
                deadstop_break = 0.35, -- 0..1, higher = faster stop per frame
                deadstop_snap  = 0.02,   -- below this speed, just snap to 0
                max_lasers     = 4,
                laser_lifetime = 60,
            },
            asteroids = {
                num_population = 5,
                num_vertices   = 10,
                radius         = 15,
                radius_plus    = 4,
                radius_minus   = 6,
                velocity_max   = 0.5,
                velocity_min   = 0.1,
                rotation_max   = 0.03,
            },
        },
        player = {},
        asteroids = {},
        score  = 0,
    },

    high_scores = {},
}


-- ==========================================
-- STATE CHANGE
-- ==========================================

function changeState(newState)
    game.prevState = game.state
    game.state = newState

    -- Generate a bunch of asteroids to dance about each state's screen.
    generateAsteroids()

    if newState == STATE.PLAY then
        -- Reset game state for new game
        game.play.player = Ship:new({
            color       = BLUE_MED,
            brake       = game.play.params.player.deadstop_brake,
            snap        = game.play.params.player.deadstop_snap,
            shots       = game.play.params.player.max_lasers,
            lifetime    = game.play.params.player.laser_lifetime       
        })
        game.play.score  = 0
        -- Generate a bunch of asteroids to actually shoot.

    elseif newState == STATE.HIGHSCORES then
        loadHighScores()
        sortHighScores()
        buildLines()
        scroll = 0
    end
end

function generateAsteroids()
    if game.state == STATE.PLAY then
        color = WHITE
    else
        color = GRAY_LITE
    end

    -- Flush current asteroids table.
    game.play.asteroids = {}

    for count = 1, game.play.params.asteroids.num_population do
        local vel_speed = (math.random() * (game.play.params.asteroids.velocity_max - game.play.params.asteroids.velocity_min)) + game.play.params.asteroids.velocity_min
        local rot_speed = (math.random() * (2 * game.play.params.asteroids.rotation_max)) - game.play.params.asteroids.rotation_max

        local pos_x = math.random(0, (EDGE_X_RIGHT - 1))
        local pos_y = 0
        if math.random(1,2) == 1 then
            pos_x = 0
            pos_y = math.random(0, (EDGE_Y_BOTTOM - 1))
        end

        local asteroid = Asteroid:new({
            color         = color,
            x             = pos_x,
            y             = pos_y,
            speed         = vel_speed,
            direction     = math.random() * math.pi * 2,
            rotationSpeed = rot_speed,
            radius        = game.play.params.asteroids.radius,
            radius_minus  = game.play.params.asteroids.radius_minus,
            radius_plus   = game.play.params.asteroids.radius_plus,
            num_vertices  = game.play.params.asteroids.num_vertices,
        })
        table.insert(game.play.asteroids, asteroid)
    end
end

-- [/TQ-Bundler: src.game_state]

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
            changeState(STATE.PLAY)
        elseif selected == 2 then
            changeState(STATE.OPTIONS)
        elseif selected == 3 then
            changeState(STATE.HIGHSCORES)
        end
    end
end

function updateStart()
    for index, asteroid in ipairs(game.play.asteroids) do
        asteroid:move()
    end
end

function drawStart()
    cls(BLACK)

    for index, asteroid in ipairs(game.play.asteroids) do
        asteroid:draw()
    end

    drawCenteredText("ASTEROIDS!!", EDGE_Y_TOP + Y_PADDING, ORANGE, nil, 3, nil, YELLOW)

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

    drawCenteredText("Press 'START' (S) to select options", EDGE_Y_BOTTOM - Y_PADDING, WHITE, false, 1, false, GRAY_MED)
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
    -- Asteroids still float around in the background
    for index, asteroid in ipairs(game.play.asteroids) do
        asteroid:move()
    end
end

function drawOptions()
    cls(BLACK)

    -- Draw background asteroids
    for index, asteroid in ipairs(game.play.asteroids) do
        asteroid:draw()
    end

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

-- [TQ-Bundler: src.states.play]

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
    game.play.player:moveLaserBlasts()
    hit_asteroid = game.play.player:checkLaserHit(game.play.asteroids)
    if hit_asteroid > -1 then
        asteroid:explode()
        table.remove(game.play.asteroids, hit_asteroid)
    end

    for index, asteroid in ipairs(game.play.asteroids) do
        asteroid:move()
    end
end

function drawPlay()
    cls(BLACK)

    game.play.player:draw()
    game.play.player:drawLaserBlasts()

    for index, asteroid in ipairs(game.play.asteroids) do
        asteroid:draw()
    end

    if DEBUG == true then
        local pos = game.play.player:getPosition()
        local rot = game.play.player:getRotation()

        local pos_x   = string.format("%0.2f", pos.x)
        local pos_y   = string.format("%0.2f", pos.y)
        local radians = string.format("%0.2f", rot.rotation)
        local speed   = string.format("%0.2f", rot.speed)

        print("X: " .. pos_x .. "; Y: " .. pos_y, EDGE_X_LEFT, EDGE_Y_TOP, WHITE)
        print("Radians: " .. radians .. "; Speed: " .. speed, EDGE_X_LEFT, EDGE_Y_TOP + Y_PADDING, WHITE)
        print("Num of Lasers: " .. tostring(game.play.player:getNumOfLaserBlasts()), EDGE_X_LEFT, EDGE_Y_TOP + 2* Y_PADDING, WHITE)
    end

end


-- [/TQ-Bundler: src.states.play]

-- [TQ-Bundler: src.states.gameover]

-- ==========================================
-- STATE: GAMEOVER
-- ==========================================

function inputGameover()
    if btnp(BTN_P1_A) or btnp(BTN_P1_B) then
        changeState(STATE.HIGHSCORES)
    end
end

function updateGameover()

end

function drawGameover()
    drawPlay()

    drawCenteredText("GAME OVER", EDGE_Y_TOP + Y_PADDING, ORANGE, nil, 3, nil, YELLOW)
    drawCenteredText("Press Z or X to see high scores", EDGE_Y_BOTTOM - Y_PADDING, WHITE, false, 1, false, GRAY_MED)
end


-- [/TQ-Bundler: src.states.gameover]

-- [TQ-Bundler: src.states.highscores]

-- ==========================================
-- STATE: HIGH SCORES
-- ==========================================

-- Persistent memory has 255 slots. We want to save two pieces of data: the date
-- and the score. On top of that, we only want to save the top 10 scores. That
-- restricts us to just 20 slots (10 chunks of 2 slots). Since our counter
-- starts at 0, we set MAX_PMEM_CHUNKS equal to 9.
local MAX_PMEM_CHUNKS     = 9
local PMEM_CHUNK_ELEMENTS = 2

-- We'll store our high scores in this table.
local lines = {}

-- ==========================================
-- HIGH SCORE HELPERS
-- ==========================================

function loadHighScores()
    game.high_scores = {}

    for idx = 0, MAX_PMEM_CHUNKS do
        local base = idx * PMEM_CHUNK_ELEMENTS
        local date = pmem(base + 0)
        if date ~= 0 then
            game.high_scores[base] = {
                date  = date,
                score = pmem(base + 1),
            }
        end
    end
end

function sortHighScores()
    -- Collect existing entries (0,2,4,...) into a dense list
    local list = {}
    for idx = 0, MAX_PMEM_CHUNKS do
        local base = idx * PMEM_CHUNK_ELEMENTS
        local d = game.high_scores[base]
        if d then
            list[#list + 1] = d
        end
    end

    -- Sort by score...
    table.sort(list, function(a, b)
        if a.score ~= b.score then
            return a.score > b.score
        end
    end)

    -- Write back compacted into chunk keys 0,2,4,...
    game.high_scores = {}
    for i = 1, #list do
        game.high_scores[(i - 1) * PMEM_CHUNK_ELEMENTS] = list[i]
    end
end

function saveCurrentScore()
    -- Always start from what is currently saved
    loadHighScores()

    -- Find next free chunk index in the CURRENT in-memory table
    local n = 0
    for idx = 0, MAX_PMEM_CHUNKS do
        if game.high_scores[idx * PMEM_CHUNK_ELEMENTS] then
            n = n + 1
        end
    end
    local base = n * PMEM_CHUNK_ELEMENTS
    if base > MAX_PMEM_CHUNKS * PMEM_CHUNK_ELEMENTS then
        base = MAX_PMEM_CHUNKS * PMEM_CHUNK_ELEMENTS -- will be trimmed after sort
    end

    -- Add current result
    game.high_scores[base] = {
        date  = game.play.date,
        score = game.play.score,
    }

    -- Sort + compact keys to 0,4,8,...
    sortHighScores()

    -- -- Save the data.
    for i = 0, 255 do pmem(i, 0) end
    for idx = 0, MAX_PMEM_CHUNKS do
        local b = idx * PMEM_CHUNK_ELEMENTS
        local d = game.high_scores[b]
        if d then
            pmem(b + 0, d.date)
            pmem(b + 1, d.score)
        end
    end
end


function buildLines()
    -- Show only the saved/sorted entries (0,4,8,...,252)
    lines = {}
    for idx = 0, MAX_PMEM_CHUNKS do
        local k = idx * PMEM_CHUNK_ELEMENTS
        local d = game.high_scores[k]
        if d then
            local dt_obj = unix_to_greg_utc(d.date)
            local dt_str = convert_datetime_obj_to_string(dt_obj)
            table.insert(lines, dt_str .. "      " .. d.score)
        end
    end
end

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

    -- LAYOUT
    local header_y = EDGE_Y_TOP + Y_PADDING
    local line_h = FIXED_CHAR_HEIGHT + 1
    local view_top = header_y + FIXED_CHAR_HEIGHT + 2 * Y_PADDING
    local view_bottom = EDGE_Y_BOTTOM - 2 * Y_PADDING
    local visible_lines = math.max(1, math.floor((view_bottom - view_top) / line_h))

    -- INPUT
    local max_scroll = math.max(0, #lines - visible_lines)

    -- keyboard (hold+repeat)
    if btnp(BTN_P1_UP, 15, 3) then
        scroll = scroll - 1
    end
    if btnp(BTN_P1_DOWN, 15, 3) then
        scroll = scroll + 1
    end

    -- clamp
    scroll = math.max(0, math.min(max_scroll, scroll))

    drawCenteredText("HIGH SCORES", EDGE_Y_TOP + Y_PADDING, ORANGE, nil, 3, nil, YELLOW)

    -- draw visible slice
    for i = 0, visible_lines - 1 do
        local line = lines[scroll + 1 + i] -- Lua arrays are 1-based
        if not line then break end
        local y = view_top + i * line_h
        print(line, X_PADDING + 1, y + 1, BLACK) -- the shadow
        print(line, X_PADDING, y, WHITE)
    end

    -- Small scrollbar indicator
    if max_scroll > 0 then
        local bar_x = EDGE_X_RIGHT - 4
        rect(bar_x, view_top, 2, view_bottom - view_top, GRAY_DARK)
        local thumb_h = math.max(4, math.floor((view_bottom - view_top) * (visible_lines / #lines)))
        local thumb_y = view_top + math.floor((view_bottom - view_top - thumb_h) * (scroll / max_scroll))
        rect(bar_x, thumb_y, 2, thumb_h, GREEN_LITE)
    end

    -- Instructions
    drawCenteredText("Press Z or X to return to start screen", EDGE_Y_BOTTOM - Y_PADDING, WHITE, false, 1, true, GRAY_MED)
end

-- [/TQ-Bundler: src.states.highscores]

-- [TQ-Bundler: src.state_machine]

-- ==========================================
-- STATE MACHINE
-- ==========================================

local states = {
    [STATE.START] = {
        input  = inputStart,
        update = updateStart,
        draw   = drawStart,
    },
    [STATE.OPTIONS] = {
        input  = inputOptions,
        update = updateOptions,
        draw   = drawOptions,
    },
    [STATE.PLAY] = {
        input  = inputPlay,
        update = updatePlay,
        draw   = drawPlay,
    },
    [STATE.GAMEOVER] = {
        input  = inputGameover,
        update = updateGameover,
        draw   = drawGameover,
    },
    [STATE.HIGHSCORES] = {
        input  = inputHighScores,
        update = updateHighScores,
        draw   = drawHighScores,
    },
}


-- [/TQ-Bundler: src.state_machine]

-- [TQ-Bundler: src.classes.SpaceObj]

-- ==========================================
-- SPACEOBJ OBJECT
-- ==========================================

SpaceObj = {}
SpaceObj.__index = SpaceObj

function SpaceObj.new(params)
    params       = params or {}
    local self   = setmetatable({}, SpaceObj)

    self.color         = params.color or WHITE
    self.position      = {
        x = params.x or math.floor(EDGE_X_RIGHT / 2),
        y = params.y or math.floor(EDGE_Y_BOTTOM / 2)

    }
    self.velocity = {
        speed     = params.speed     or 0,
        direction = params.direction or 0,
    }
    self.acceleration  = params.acceleration  or 0.05
    self.deceleration  = params.deceleration  or 0.01
    self.rotation      = params.rotation      or 5
    self.rotationSpeed = params.rotationSpeed or 0.07
    self.shape         = params.shape         or {
        { x = 10,  y = 10  },
        { x = -10, y = 10  },
        { x = -10, y = -10 },
        { x = 10,  y = -10 },
    }
    self.timer = params.timer or 0
    
    return self
end

-- ==========================================
-- SPACEOBJ MATH
-- ==========================================

function SpaceObj:keepAngleInRange(angle)
    if angle < 0 then
        while angle < 0 do
            angle = angle + (2 * math.pi)
        end
    end
    if angle > (2 * math.pi) then
        while angle > (2 * math.pi) do
            angle = angle - (2 * math.pi)
        end
    end
    return angle
end

-- 'rotation' parameter is in radians.
function SpaceObj:rotatePoint(point, rotation)
    local rotated_x = (point.x * math.cos(rotation)) - (point.y * math.sin(rotation))
    local rotated_y = (point.y * math.cos(rotation)) + (point.x * math.sin(rotation))
    return { x = rotated_x, y = rotated_y }
end

function SpaceObj:getVectorComponents(vector)
    local xComp = vector.speed * math.cos(vector.direction)
    local yComp = vector.speed * math.sin(vector.direction)

    local components = {
        xComp = xComp,
        yComp = yComp
    }

    return components
end

function SpaceObj:addVectors(vector1, vector2)
    v1Comp = self:getVectorComponents(vector1)
    v2Comp = self:getVectorComponents(vector2)
    resultantX = v1Comp.xComp + v2Comp.xComp
    resultantY = v1Comp.yComp + v2Comp.yComp

    local resVector = self:compToVector(resultantX, resultantY)

    return resVector
end

function SpaceObj:compToVector(x, y)
    local magnitude = math.sqrt((x * x) + (y * y))
    local direction = math.atan(y, x)

    direction = self:keepAngleInRange(direction)

    local vector = {
        speed = magnitude,
        direction = direction
    }

    return vector
end

function SpaceObj:movePointByVelocity(obj)
    if obj == nil then
        obj = self
    end

    components = self:getVectorComponents(obj.velocity)

    local newPosition = {
        x = obj.position.x + components.xComp,
        y = obj.position.y + components.yComp
    }

    return newPosition
end

-- ==========================================
-- SPACEOBJ GETTERS
-- ==========================================

function SpaceObj:getPosition()
    return self.position
end

function SpaceObj:getRotation()
    return {
        rotation = self.rotation,
        speed    = self.rotationSpeed
    }
end

function SpaceObj:getTimer()
    return self.timer
end

function SpaceObj:getVelocity()
    return self.velocity
end

-- Returns true every N ticks
function SpaceObj:everyNTicks(n)
    return (self.timer % n) == 0
end

-- ==========================================
-- SPACEOBJ INPUT
-- ==========================================

-- ==========================================
-- SPACEOBJ UPDATE
-- ==========================================

function SpaceObj:updateTimer()
    self.timer = (self.timer + 1) % 60
end

function SpaceObj:wrapPosition(obj)
    if obj == nil then
        obj = self
    end
    if (obj.position.x >= EDGE_X_RIGHT) then
        obj.position.x = 0
    elseif (obj.position.x < 0) then
        obj.position.x = EDGE_X_RIGHT - 1
    end

    if (obj.position.y >= EDGE_Y_BOTTOM) then
        obj.position.y = 0
    elseif (obj.position.y < 0) then
        obj.position.y = EDGE_Y_BOTTOM - 1
    end
    return obj.position
end

function SpaceObj:move()
    self.position = self:movePointByVelocity()
    self:wrapPosition() -- don't assign if wrapPosition returns nil
    self:updateTimer()
end

-- ==========================================
-- SPACEOBJ DRAW
-- ==========================================

-- Draw the SpaceObj.
function SpaceObj:draw()
    local first_point = true
    local last_point = 0
    local rotated_point = 0
    for index, point in ipairs(self.shape) do
        rotated_point = self:rotatePoint(point, self.rotation)

        if first_point then
            last_point = rotated_point
            first_point = false
        else
            line(
                last_point.x + self.position.x,
                last_point.y + self.position.y,
                rotated_point.x + self.position.x,
                rotated_point.y + self.position.y,
                self.color
            )
            last_point = rotated_point
        end
    end
end


-- [/TQ-Bundler: src.classes.SpaceObj]

-- [TQ-Bundler: src.classes.Ship]

-- ==========================================
-- SHIP OBJECT
-- ==========================================

Ship = setmetatable({}, { __index = SpaceObj })
Ship.__index = Ship

function Ship:new(params)
    params = params or {}
    local self = SpaceObj.new(params) -- build base fields
    setmetatable(self, Ship)          -- make it a Ship instance

    -- Ship-specific properties
    self.deadstop = {
        brake = params.brake or 0.35, -- 0..1, higher = faster stop per frame
        snap  = params.snap  or 0.02  -- below this speed, just snap to 0
    }
    self.shape = params.shape or {
        { x = 8,  y = 0  },
        { x = -8, y = 6  },
        { x = -4, y = 0  },
        { x = -8, y = -6 },
        { x = 8,  y = 0  }
    }

    -- laser blast stuff
    self.laser_blasts = {}
    self.laser_params = {
        lifetime  = params.lifetime or 60,
        max_shots = params.shots    or 4,
        speed     = 2,
        offset    = {
            x = 8,
            y = 0,
        }
    }

    return self
end

-- ==========================================
-- SHIP MATH
-- ==========================================

-- ==========================================
-- SHIP GETTERS
-- ==========================================

-- function Ship:getLaserBlasts()
--     return self.laser_blasts
-- end

function Ship:getNumOfLaserBlasts()
    return #self.laser_blasts
end

-- ==========================================
-- SHIP INPUT
-- ==========================================

function Ship:input()
    if btn(BTN_P1_LEFT) then
        self.rotation = self.rotation - self.rotationSpeed
    end
    if btn(BTN_P1_RIGHT) then
        self.rotation = self.rotation + self.rotationSpeed
    end
    if btnp(BTN_P1_A) then
        self:fireLaserBlast()
    end

    self.rotation = self:keepAngleInRange(self.rotation)
end


-- ==========================================
-- SHIP UPDATE
-- ==========================================

function Ship:deadStop(brake, snap)
    if brake == nil then
        brake = self.deadstop.brake
    end
    if snap == nil then
        snap = self.deadstop.snap
    end
    local s = self.velocity.speed
    if s <= 0 then
        self.velocity.speed = 0
        self.velocity.direction = 0
        return
    end

    -- Smoothly reduce speed; never goes negative
    s = s * (1 - brake)
    if s < snap then
        s = 0
        self.velocity.direction = 0
    end
    self.velocity.speed = s
end

function Ship:thrust()
    local acceleration = {
        speed     = self.acceleration,
        direction = self.rotation
    }
    self.velocity = self:addVectors(self.velocity, acceleration)
end

function Ship:move()
    if btn(BTN_P1_UP) then
        self:thrust()
    end

    self.velocity.speed = self.velocity.speed - self.deceleration
    if self.velocity.speed < 0 then
        self.velocity.speed = 0
    end

    SpaceObj.move(self)
end

function Ship:spawnLaserBlast()
    local rel_spawn_pos = self:rotatePoint(self.laser_params.offset, self.rotation)
    return {
        position = {
            x = rel_spawn_pos.x + self.position.x,
            y = rel_spawn_pos.y + self.position.y,
        },
        velocity = {
            speed = self.laser_params.speed,
            direction = self.rotation,
        },
        lifetime = self.laser_params.lifetime,
    }
end

function Ship:fireLaserBlast()
    if #self.laser_blasts < self.laser_params.max_shots then
        -- Okay to fire
        table.insert(self.laser_blasts, self:spawnLaserBlast())
        sfx(0, 40, 5, 0, 15, 1)
    end
end

function Ship:moveLaserBlasts()
    for index, laser in ipairs(self.laser_blasts) do
        laser.lifetime = laser.lifetime - 1
        if laser.lifetime < 0 then
            table.remove(self.laser_blasts, index)
        else
            laser.position = self:movePointByVelocity(laser)
            laser.position = self:wrapPosition(laser)
        end
    end
end

function Ship:checkLaserHit(asteroids)
    asteroid_was_hit = -1
    for laser_index, laser in ipairs(self.laser_blasts) do
        for asteroid_index, asteroid in ipairs(asteroids) do
            ast_r = asteroid:getRadius()
            ast_r_var = asteroid:getRadiusPlusMinus()
            separation_value = self:checkSeparation(
                laser.position,
                asteroid.position,
                ast_r + ast_r_var.plus
            )
            if separation_value then
                asteroid_was_hit = asteroid_index
                return asteroid_was_hit  -- immediately break out of loop
            end
        end
    end
    return asteroid_was_hit
end

function Ship:checkSeparation(point1, point2, separation)
    -- leaving as squares removes need to do a sqrt
    local separationSq = separation * separation
    local distanceSq =
        ((point1.x - point2.x) * (point1.x - point2.x))
        + ((point1.y - point2.y) * (point1.y - point2.y))
    return (distanceSq <= separationSq)
end


-- ==========================================
-- SHIP DRAW
-- ==========================================

function Ship:drawLaserBlasts()
    for index, laser in ipairs(self.laser_blasts) do
        spr(1, laser.position.x, laser.position.y, 0)
    end
end

-- [/TQ-Bundler: src.classes.Ship]

-- [TQ-Bundler: src.classes.Asteroid]

-- ==========================================
-- ASTEROID OBJECT
-- ==========================================

Asteroid = setmetatable({}, { __index = SpaceObj })
Asteroid.__index = Asteroid

function Asteroid:new(params)
    params = params or {}
    local self = SpaceObj.new(params) -- build base fields
    setmetatable(self, Asteroid)          -- make it a Asteroid instance

    -- Asteroid-specific properties
    self.radius       = params.radius       or 15
    self.radius_minus = params.radius_minus or 6
    self.radius_plus  = params.radius_plus  or 4
    self.num_vertices = params.num_vertices or 10
    self.shape        = params.shape or self:spawn()

    return self
end

-- ==========================================
-- ASTEROID MATH
-- ==========================================

-- ==========================================
-- ASTEROID GETTERS
-- ==========================================

function Asteroid:getRadius()
    return self.radius
end

function Asteroid:getRadiusPlusMinus()
    return {
        plus  = self.radius_plus,
        minus = self.radius_minus
    }
end

-- ==========================================
-- ASTEROID INPUT
-- ==========================================

-- ==========================================
-- ASTEROID UPDATE
-- ==========================================

-- Generates Asteroid shape. Called by default when creating an asteroid with
-- default shape settings.
function Asteroid:spawn()
    local vertices = {}

    -- Insert first vertex using default radius.
    table.insert(vertices, { x = self.radius, y = 0 })

    -- Now do the vertices in between the first and last ones.
    for vertex = 1, (self.num_vertices - 1) do
        local radius = math.random(
            self.radius - self.radius_minus,
            self.radius + self.radius_plus
        )
        local angle = ((math.pi * 2) / self.num_vertices) * vertex
        local vector = {
            speed     = radius,
            direction = angle
        }
        local components = self:getVectorComponents(vector)
        table.insert(vertices, {
            x = components.xComp,
            y = components.yComp
        })
    end

    -- Last vertex is the same as the first vertex
    table.insert(vertices, { x = self.radius, y = 0 })

    return vertices
end

function Asteroid:move()
    self.rotation = self.rotation + self.rotationSpeed

    SpaceObj.move(self)
end

-- ==========================================
-- ASTEROID DRAW
-- ==========================================

function Asteroid:explode()
    -- insert something fancy here.
end

-- [/TQ-Bundler: src.classes.Asteroid]

-- ==========================================
-- MAIN GAME LOOP
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