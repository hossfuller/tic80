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

local DEBUG = false

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

DIFFICULTY = {
    EASY   = 1,
    MEDIUM = 2,
    HARD   = 3,
}
PTS_FOR_EXTRA_LIFE = 100000

game = {
    state = STATE.START,
    prevState = nil,

    -- Menu state
    menu = {
        selected = 1,
        options = { "Start", "Options", "High Scores" },
    },

    -- Options state
    options = {
        selected = 1,
        items = {
            {
                name = "Difficulty",
                values = { "Easy", "Medium", "Hard" },
                current = DIFFICULTY.MEDIUM,

                -- Function to apply this setting.
                -- Difficulty values:
                --   1 = Easy
                --   2 = Medium
                --   3 = Hard
                apply = function(value)
                    -- Store current difficulty for high scores.
                    game.play.diff = value
                    if value == DIFFICULTY.EASY then
                        game.play.params.player.max_lives         = 4
                        game.play.params.player.max_health        = 250
                        game.play.params.player.max_lasers        = 6
                        game.play.params.player.laser_lifetime    = 60
                        game.play.params.asteroids.num_population = 4
                        game.play.params.asteroids.velocity_max   = 0.3
                        game.play.params.asteroids.velocity_min   = 0.05
                    elseif value == DIFFICULTY.MEDIUM then
                        game.play.params.player.max_lives         = 3
                        game.play.params.player.max_health        = 175
                        game.play.params.player.max_lasers        = 5
                        game.play.params.player.laser_lifetime    = 50
                        game.play.params.asteroids.num_population = 6
                        game.play.params.asteroids.velocity_max   = 0.5
                        game.play.params.asteroids.velocity_min   = 0.1
                    elseif value == DIFFICULTY.HARD then
                        game.play.params.player.max_lives         = 3
                        game.play.params.player.max_health        = 100
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
                values = { "On", "Off" },
                current = 1,
                apply = function(value)
                    game.play.params.player.deadstop_allow = (value == 1)
                end,
            },
            {
                name = "Regenerate Health",
                values = { "On", "Off" },
                current = 1,
                apply = function(value)
                    game.play.params.player.regenerate = (value == 1)
                end,
            },
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

    -- Gameplay state
    play = {
        params = {
            player = {
                regenerate     = false,
                deadstop_allow = true,
                deadstop_brake = 0.35,   -- 0..1, higher = faster stop per frame
                deadstop_snap  = 0.02,   -- below this speed, just snap to 0
                max_lasers     = 4,
                laser_lifetime = 60,
                elasticity     = 0.5,
                max_health     = 100,
                max_lives      = 3,
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
                elasticity     = 0.95,
            },
        },
        player                = {},
        asteroids             = {},
        date                  = nil,
        diff                  = DIFFICULTY.MEDIUM,
        level                 = 1,
        score                 = 0,
        next_extra_life_score = PTS_FOR_EXTRA_LIFE,
    },

    high_scores = {},
}


-- ==========================================
-- STATE CHANGE
-- ==========================================

function changeState(newState)
    game.prevState = game.state
    game.state = newState

    -- Generate asteroids for menu-like states, but preserve PLAY -> GAMEOVER
    -- scene.
    if newState ~= STATE.GAMEOVER then
        generateAsteroids()
    end

    if newState == STATE.PLAY then
        -- Reset game state for new game.
        game.play.player = Ship:new({
            color      = BLUE_MED,
            max_health = game.play.params.player.max_health,
            max_lives  = game.play.params.player.max_lives,
            brake      = game.play.params.player.deadstop_brake,
            snap       = game.play.params.player.deadstop_snap,
            shots      = game.play.params.player.max_lasers,
            lifetime   = game.play.params.player.laser_lifetime
        })

        game.play.score                 = 0
        game.play.date                  = get_unix_timestamp()
        game.play.level                 = 1
        game.play.next_extra_life_score = PTS_FOR_EXTRA_LIFE

        -- Ensure difficulty is never nil. This should already be maintained by
        -- the options apply function, but this protects saved scores if PLAY is
        -- entered before options are touched.
        game.play.diff   = game.play.diff or DIFFICULTY.MEDIUM
    elseif newState == STATE.GAMEOVER then
        saveCurrentScore()
    elseif newState == STATE.HIGHSCORES then
        loadHighScores()
        sortHighScores()
        buildLines()
        scroll = 0
    end
end

function generateAsteroids()
    local color = nil
    if game.state == STATE.PLAY then
        color = WHITE
    else
        color = GRAY_LITE
    end

    -- Flush current asteroids table.
    game.play.asteroids = {}

    local params = game.play.params

    -- Increment the number of asteroids as we climb the level ladder.
    local num_extra_asteroids = game.play.level - 1
    params.asteroids.num_population = params.asteroids.num_population + num_extra_asteroids

    for count = 1, params.asteroids.num_population do
        local vel_speed = (
            math.random() *
            (params.asteroids.velocity_max - params.asteroids.velocity_min)
        ) + params.asteroids.velocity_min

        local rot_speed = (
            math.random() *
            (2 * params.asteroids.rotation_max)
        ) - params.asteroids.rotation_max

        local pos_x = math.random(0, EDGE_X_RIGHT - 1)
        local pos_y = 0

        if math.random(1, 2) == 1 then
            pos_x = 0
            pos_y = math.random(0, EDGE_Y_BOTTOM - 1)
        end

        local asteroid = Asteroid:new({
            color          = color,
            x              = pos_x,
            y              = pos_y,
            speed          = vel_speed,
            direction      = math.random() * math.pi * 2,
            elasticity     = params.asteroids.elasticity,
            scale          = 1,
            rotation_speed = rot_speed,
            velocity_max   = params.asteroids.velocity_max,
            velocity_min   = params.asteroids.velocity_min,
            radius         = params.asteroids.radius,
            radius_minus   = params.asteroids.radius_minus,
            radius_plus    = params.asteroids.radius_plus,
            num_vertices   = params.asteroids.num_vertices,
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

    for i = 1, #game.play.asteroids - 1 do
        local asteroid = game.play.asteroids[i]
        for j = i + 1, #game.play.asteroids do
            asteroid:resolveCollision(game.play.asteroids[j])
        end
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

    drawCenteredText("Press Z to select options", EDGE_Y_BOTTOM - Y_PADDING, WHITE, false, 1, false, GRAY_MED)
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

    for i = 1, #game.play.asteroids - 1 do
        local asteroid = game.play.asteroids[i]
        for j = i + 1, #game.play.asteroids do
            asteroid:resolveCollision(game.play.asteroids[j])
        end
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

    if not game.play.player.dead then
        game.play.player:input()
    end
end

function updatePlay()
    local player = game.play.player

    player:move()
    if game.play.params.player.deadstop_allow == true and btn(BTN_P1_DOWN) then
        -- brake and snap can change as player takes damage?
        player:deadStop(
            game.play.params.player.deadstop_brake,
            game.play.params.player.deadstop_snap
        )
    end

    -- Regenerate health if it's been enabled.
    if game.play.params.player.regenerate == true and player:everyNTicks(60) then
        player:regenerateHealth()
    end

    -- Move the laser blast and then check if it hit anything.
    player:moveLaserBlasts()
    hit_asteroid_index = player:checkLaserHit(game.play.asteroids)
    for index, asteroid in ipairs(game.play.asteroids) do
        if hit_asteroid_index == index then
            -- Increment score, and then check if the user earned an extra life.
            game.play.score = game.play.score + asteroid:getPoints()
            while game.play.score >= game.play.next_extra_life_score do
                player.cur_lives = player.cur_lives + 1
                game.play.next_extra_life_score = game.play.next_extra_life_score + PTS_FOR_EXTRA_LIFE
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
        game.play.level = game.play.level + 2
        generateAsteroids()
    end

    -- Now check if any asteroids have hit each other.
    for i = 1, #game.play.asteroids - 1 do
        local asteroid = game.play.asteroids[i]
        for j = i + 1, #game.play.asteroids do
            asteroid:resolveCollision(game.play.asteroids[j])
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
        -- normal collision/damage
        for _, asteroid in ipairs(game.play.asteroids) do
            if player.invulnerable <= 0 and player:resolveCollision(asteroid) then
                player:takesDamage(asteroid:getInducedDamage())
                if player:getHealth() <= 0 then
                    player:kill()
                    break
                end
            end
        end
    end

    -- tick invulnerableerability
    if player.invulnerable > 0 then
        player.invulnerable = player.invulnerable - 1
    end
end

function drawHealthBar()
    local health_bar_length = 100
    local health_bar_height = Y_PADDING
    local health_percentage = game.play.player:getHealthFraction()

    rectb(EDGE_X_LEFT, EDGE_Y_TOP, health_bar_length + 2, health_bar_height, WHITE)
    rect(EDGE_X_LEFT + 1, EDGE_Y_TOP + 1, health_bar_length * health_percentage, health_bar_height - 2, GREEN_MED)

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
    local level_height = used_height
    local level_length = print("LEVEL: " .. string.format("%02d", game.play.level), EDGE_X_LEFT, level_height, WHITE, true)
    return level_length, level_height + Y_PADDING
end

function drawScore(used_height)
    local score_height = used_height + 2
    local score_length = print("SCORE: " .. tostring(game.play.score), EDGE_X_LEFT, score_height, WHITE, true)
    return score_length, score_height + Y_PADDING
end

function drawPlay()
    cls(BLACK)

    local player = game.play.player

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

    for index, asteroid in ipairs(game.play.asteroids) do
        asteroid:draw()
    end

    local health_length, health_height = drawHealthBar()
    local lives_length,  lives_height  = drawCurrentLives(health_length, health_height)
    local score_length, score_height   = drawScore(health_height)
    local level_length, level_height   = drawLevel(score_height)

    if DEBUG == true then
        print("HEALTH: " .. tostring(player:getHealth()), EDGE_X_LEFT, score_height + 2, CYAN, true)
        print("LIVES: " .. tostring(player:getNumLives()), EDGE_X_LEFT, 2*score_height, CYAN, true)

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
    local player = game.play.player

    if player and player.moveParticles then
        player:moveParticles(player.TYPES.EXPLOSION)
        player:moveParticles(player.TYPES.LASER_HIT)
        player:moveParticles(player.TYPES.SPARK)
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
        player:drawParticles(player.TYPES.SMOKE)
        player:drawParticles(player.TYPES.SPARK)
        player:drawParticles(player.TYPES.THRUST)
    end

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
local MAX_PMEM_CHUNKS     = 20
local PMEM_CHUNK_ELEMENTS = 4

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
                diff  = pmem(base + 1),
                level = pmem(base + 2),
                score = pmem(base + 3),
            }
        end
    end
end

function sortHighScores()
    local list = {}

    for idx = 0, MAX_PMEM_CHUNKS do
        local base = idx * PMEM_CHUNK_ELEMENTS
        local d = game.high_scores[base]
        if d then
            list[#list + 1] = d
        end
    end

    table.sort(list, function(a, b)
        -- 1. Difficulty: Hard -> Medium -> Easy
        if a.diff ~= b.diff then
            return a.diff > b.diff
        end

        -- 2. Score: highest -> lowest
        if a.score ~= b.score then
            return a.score > b.score
        end

        -- 3. Level: highest -> lowest
        if a.level ~= b.level then
            return a.level > b.level
        end

        -- Optional final tiebreaker: newest first
        return a.date > b.date
    end)

    game.high_scores = {}

    for i = 1, math.min(#list, MAX_PMEM_CHUNKS + 1) do
        game.high_scores[(i - 1) * PMEM_CHUNK_ELEMENTS] = list[i]
    end
end

function saveCurrentScore()
    loadHighScores()

    local list = {}

    -- Pull saved scores into a list.
    for idx = 0, MAX_PMEM_CHUNKS do
        local base = idx * PMEM_CHUNK_ELEMENTS
        local d = game.high_scores[base]

        if d then
            list[#list + 1] = d
        end
    end

    -- Add current result.
    list[#list + 1] = {
        date  = game.play.date,
        diff  = game.play.diff,
        level = game.play.level,
        score = game.play.score,
    }

    -- Put list back into game.high_scores so sortHighScores() can sort it.
    game.high_scores = {}

    for i = 1, #list do
        game.high_scores[(i - 1) * PMEM_CHUNK_ELEMENTS] = list[i]
    end

    sortHighScores()

    -- Clear pmem.
    for i = 0, 255 do
        pmem(i, 0)
    end

    -- Save compacted/sorted high scores.
    for idx = 0, MAX_PMEM_CHUNKS do
        local base = idx * PMEM_CHUNK_ELEMENTS
        local d = game.high_scores[base]

        if d then
            pmem(base + 0, d.date)
            pmem(base + 1, d.diff)
            pmem(base + 2, d.level)
            pmem(base + 3, d.score)
        end
    end
end

function difficultyToString(diff)
    if diff == 3 then
        return "Hard"
    elseif diff == 2 then
        return "Medium"
    elseif diff == 1 then
        return "Easy"
    end

    return "?"
end

function buildLines()
    lines = {}

    local score_count = 1
    for idx = 0, MAX_PMEM_CHUNKS do
        local k = idx * PMEM_CHUNK_ELEMENTS
        local d = game.high_scores[k]

        if d then
            local dt_obj = unix_to_greg_utc(d.date)
            local dt_str = convert_datetime_obj_to_string(dt_obj)
            local diff_str = difficultyToString(d.diff)

            table.insert(
                lines,
                string.format("%2d", score_count) .. ". " ..
                dt_str ..
                "  " .. string.format("%7d", d.score) ..
                "  L" .. string.format("%02d", d.level) ..
                "  " .. diff_str
            )
            score_count = score_count + 1
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
        print(line, X_PADDING + 1, y + 1, GRAY_MED, true) -- the shadow
        print(line, X_PADDING, y, WHITE, true)
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
    self.acceleration   = params.acceleration   or 0.05
    self.deceleration   = params.deceleration   or 0.01
    self.rotation       = params.rotation       or 5
    self.rotation_speed = params.rotation_speed or 0.07
    self.radius         = params.radius         or 10
    self.shape          = params.shape          or {
        { x = 10,  y = 10  },
        { x = -10, y = 10  },
        { x = -10, y = -10 },
        { x = 10,  y = -10 },
    }
    self.timer = params.timer or 0

    -- For deflections: 1.0 = perfectly elastic, <1.0 loses speed
    self.elasticity = params.elasticity or 0.95

    -- Particle Effects
    self.TYPES = {
        EXPLOSION  = "EXPLOSION",
        LASER_HIT  = "LASER_HIT",
        SPARK      = "SPARK",
        SMOKE_LEAK = "SMOKE_LEAK",
        THRUST     = "THRUST",
    }
    self.EXPLOSION_COLORS  = { YELLOW, ORANGE, RED }
    self.SMOKE_COLORS      = { YELLOW, ORANGE, RED, GRAY_LITE, GRAY_MED, GRAY_DARK }
    self.SMOKE_LEAK_COLORS = { GRAY_LITE, GRAY_MED, GRAY_DARK }
    self.SPARK_COLORS      = { ORANGE }

    self.explosionParticles = {}
    self.laserHitParticles  = {}
    self.smokeParticles     = {}
    self.sparkParticles     = {}
    self.thrustParticles    = {}

    self.smoke_cooldown = 0
    self.max_lifetime   = 30
    self.max_size       = 3
    self.max_speed      = 2
    self.num_particles  = 60
    self.type           = nil

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
-- SPACEOBJ COLLISION DETECTION
-- Had to use AI to resolve some bugs, and hooo-boy, it got wild.
-- ==========================================

function SpaceObj:getBoundingRadius()
    local r2 = 0
    for _, p in ipairs(self.shape) do
        local d2 = p.x * p.x + p.y * p.y
        if d2 > r2 then r2 = d2 end
    end
    return math.sqrt(r2) - 2
end

function SpaceObj:collidesCircle(other)
    local ra = self:getBoundingRadius()
    local rb = other:getBoundingRadius()
    return self:checkSeparation(self.position, other.position, ra + rb)
end

function SpaceObj:checkSeparation(point1, point2, separation)
    -- leaving as squares removes need to do a sqrt
    local separationSq = separation * separation
    local distanceSq =
        ((point1.x - point2.x) * (point1.x - point2.x))
        + ((point1.y - point2.y) * (point1.y - point2.y))
    return (distanceSq <= separationSq)
end

function SpaceObj:separateFrom(other)
    local ra = self:getBoundingRadius()
    local rb = other:getBoundingRadius()

    local dx = self.position.x - other.position.x
    local dy = self.position.y - other.position.y
    local d = math.sqrt(dx * dx + dy * dy)

    if d < 1e-6 then
        dx, dy, d = 1, 0, 1
    end

    local overlap = (ra + rb) - d
    if overlap <= 0 then return end

    local nx, ny     = dx / d, dy / d
    local push       = overlap * 0.5 + 0.01 -- +epsilon helps prevent re-penetration

    self.position.x  = self.position.x + nx * push
    self.position.y  = self.position.y + ny * push
    other.position.x = other.position.x - nx * push
    other.position.y = other.position.y - ny * push
end

function SpaceObj:pointInPolygon(point, shape)
    local first_point   = true
    local last_point    = 0
    local rotated_point = 0
    local on_right      = 0
    local on_left       = 0
    local x_crossing    = 0

    for index, shape_point in ipairs(shape.shape) do
        rotated_point = self:rotatePoint(shape_point, shape.rotation)

        if first_point then
            last_point  = rotated_point
            first_point = false
        else
            start_point = {
                x = last_point.x + shape.position.x,
                y = last_point.y + shape.position.y
            }
            end_point = {
                x = rotated_point.x + shape.position.x,
                y = rotated_point.y + shape.position.y
            }
            if (
                ((start_point.y >= point.y) and (end_point.y < point.y)) or
                ((start_point.y < point.y) and (end_point.y >= point.y))
            ) then
                -- line crosses ray
                if (start_point.x <= point.x) and (end_point.x <= point.x) then
                    -- line is to left
                    on_left = on_left + 1
                elseif (start_point.x >= point.x) and (end_point.x >= point.x) then
                    -- line is to right
                    on_right = on_right + 1
                else
                    -- need to calculate crossing x coordinate
                    if (start_point.y ~= end_point.y) then
                        -- filter out horizontal line
                        x_crossing = start_point.x + (
                            (point.y - start_point.y) * (end_point.x - start_point.x) / (end_point.y - start_point.y)
                        )
                        if (x_crossing >= point.x) then
                            on_right = on_right + 1
                        else
                            on_left = on_left + 1
                        end
                    end
                end
            end

            last_point = rotated_point
        end
    end

    -- only need to check on side
    if (on_right % 2) == 1 then
        -- odd = inside
        return true
    else
        return false
    end
end

function SpaceObj:polygonInPolygon(a, b)
    local ra = a:getBoundingRadius()
    local rb = b:getBoundingRadius()

    if not self:checkSeparation(a.position, b.position, ra + rb) then
        return false
    end

    for _, lp in ipairs(a.shape) do
        local rp = self:rotatePoint(lp, a.rotation)
        local wp = { x = rp.x + a.position.x, y = rp.y + a.position.y }
        if self:pointInPolygon(wp, b) then return true end
    end

    for _, lp in ipairs(b.shape) do
        local rp = self:rotatePoint(lp, b.rotation)
        local wp = { x = rp.x + b.position.x, y = rp.y + b.position.y }
        if self:pointInPolygon(wp, a) then return true end
    end

    return false
end

function SpaceObj:checkCollision(colliding_obj)
    return self:polygonInPolygon(self, colliding_obj)
end

function SpaceObj:deflect(other)
    -- self.elasticity: 1.0 = perfectly elastic, <1.0 loses speed
    local vx = self.velocity.speed * math.cos(self.velocity.direction)
    local vy = self.velocity.speed * math.sin(self.velocity.direction)

    -- If we don't know what we hit, just reverse.
    if not other or not other.position then
        vx, vy = -vx, -vy
    else
        -- Collision normal: from other -> self (center-to-center)
        local nx = self.position.x - other.position.x
        local ny = self.position.y - other.position.y
        local nlen = math.sqrt(nx * nx + ny * ny)

        -- If centers coincide, pick any normal
        if nlen < 1e-6 then
            nx, ny, nlen = 1, 0, 1
        end

        nx, ny = nx / nlen, ny / nlen

        -- Reflect v about normal n:
        -- v' = v - 2*(v·n)*n
        local dot = vx * nx + vy * ny
        vx = vx - 2 * dot * nx
        vy = vy - 2 * dot * ny
    end

    -- Apply self.elasticity
    vx = vx * self.elasticity
    vy = vy * self.elasticity

    -- Convert back to your polar velocity representation
    local speed = math.sqrt(vx * vx + vy * vy)
    local dir = math.atan(vy, vx)
    dir = self:keepAngleInRange(dir)

    -- Clamp speed if you want to keep within your configured limits
    if self.velocity_max then speed = math.min(speed, self.velocity_max) end
    if self.velocity_min then speed = math.max(speed, self.velocity_min) end

    self.velocity.speed = speed
    self.velocity.direction = dir

    -- Small positional nudge along the new direction to reduce "sticking"
    self.position.x = self.position.x + math.cos(dir) * 0.5
    self.position.y = self.position.y + math.sin(dir) * 0.5
end

function SpaceObj:resolveCollision(other)
    if not other then return false end

    -- broad-phase (circle)
    if not self:collidesCircle(other) then
        return false
    end

    -- separate first to prevent sticking/spinning
    self:separateFrom(other)

    -- reflect both velocities using your existing deflect()
    self:deflect(other)
    other:deflect(self)

    return true
end

-- ==========================================
-- SPACEOBJ PARTICLE EFFECTS
-- ==========================================

function SpaceObj:explosionEffect()
    self.type          = self.TYPES.EXPLOSION
    self.deceleration  = 0.015
    self.max_lifetime  = 90
    self.max_size      = 3
    self.max_speed     = 2
    self.num_particles = 100

    local particle_velocity = {}
    for particle = 1, self.num_particles do
        particle_velocity = {
            speed     = math.random() * self.max_speed,
            direction = math.random() * math.pi * 2
        }
        self:spawnParticle(
            self.position,
            particle_velocity,
            self.max_lifetime,
            self.EXPLOSION_COLORS,
            self.max_size,
            self.deceleration,
            self.type
        )
    end
end

function SpaceObj:laserHitEffect(position)
    self.type          = self.TYPES.LASER_HIT
    self.deceleration  = 0.01
    self.max_lifetime  = 30
    self.max_size      = 3
    self.max_speed     = 1
    self.num_particles = 60

    -- Fallback in case no position is passed
    position = position or self.position

    for particle = 1, self.num_particles do
        local particle_velocity = {
            speed     = math.random() * self.max_speed,
            direction = math.random() * math.pi * 2
        }

        self:spawnParticle(
            position,
            particle_velocity,
            self.max_lifetime,
            self.EXPLOSION_COLORS,
            self.max_size,
            self.deceleration,
            self.type
        )
    end
end

function SpaceObj:leakingSmoke(health_fraction)
    -- Check cooldown - don't spawn if still cooling down
    if self.smoke_cooldown > 0 then
        self.smoke_cooldown = self.smoke_cooldown - 1
        return
    end

    self.type         = self.TYPES.SMOKE
    self.max_lifetime = 90
    self.max_size     = 1

    -- Scale particle count based on damage (more damage = more smoke)
    local damage_severity = 1 - (health_fraction / 0.5)
    self.num_particles = math.floor(1 + damage_severity)

    -- Set cooldown based on health: more damage = shorter cooldown (more frequent smoke)
    -- At 50% health: cooldown ~60 frames (1 second)
    -- At 0% health: cooldown ~15 frames (0.25 seconds)
    -- Smoke cooldown attributes can be tinkered like this:
    --  1. Increase `attr_a` to make smoke less frequent at low damage.
    --  2. Decrease `attr_b` to make the frequency diff between low and high
    --     damage smaller.
    --  3. Change self.max_lifetime to control how long each puff lingers.
    local attr_a = 30
    local attr_b = 75
    self.smoke_cooldown = math.floor(attr_a - (damage_severity * attr_b))

    -- Random offset from ship center for spawn position
    local spawn_offset = {
        x = (math.random() * 8) - 4,
        y = (math.random() * 8) - 4
    }
    local rotated_offset = self:rotatePoint(spawn_offset, self.rotation)
    local spawn_position = {
        x = rotated_offset.x + self.position.x,
        y = rotated_offset.y + self.position.y,
    }

    for particle = 1, self.num_particles do
        local particle_velocity = {
            speed     = 0,
            direction = 0
        }
        self:spawnParticle(
            spawn_position,
            particle_velocity,
            self.max_lifetime,
            self.SMOKE_LEAK_COLORS,
            self.max_size,
            0,
            self.type
        )
    end
end

function SpaceObj:sparkEffect(position)
    self.type          = self.TYPES.SPARK
    self.deceleration  = 0.01
    self.max_lifetime  = 30
    self.max_size      = 1
    self.max_speed     = 2
    self.num_particles = 30

    -- Fallback in case no position is passed
    position = position or self.position

    for particle = 1, self.num_particles do
        local particle_velocity = {
            speed     = math.random() * self.max_speed,
            direction = math.random() * math.pi * 2
        }

        self:spawnParticle(
            position,
            particle_velocity,
            self.max_lifetime,
            self.SPARK_COLORS,
            self.max_size,
            self.deceleration,
            self.type
        )
    end
end

function SpaceObj:thrustEffect()
    -- Effect-specific overrides
    self.type          = self.TYPES.THRUST
    self.deceleration  = 0.01
    self.max_lifetime  = 30
    self.max_size      = 1
    self.max_speed     = 2
    self.num_particles = 5

    local thrust_offset           = { x = -5, y = 0 }
    local particle_velocity       = {}
    local direction               = 0
    local relative_spawn_position = self:rotatePoint(thrust_offset, self.rotation)
    local spawn_position          = {
        x = relative_spawn_position.x + self.position.x,
        y = relative_spawn_position.y + self.position.y,
    }

    for particle = 1, self.num_particles do
        direction = self.rotation + math.pi + (math.random() * math.pi / 6) - (math.pi / 12)
        direction = self:keepAngleInRange(direction)
        particle_velocity = {
            speed     = math.random() * self.max_speed,
            direction = direction
        }
        self:spawnParticle(
            spawn_position,
            particle_velocity,
            self.max_lifetime,
            self.SMOKE_COLORS,
            self.max_size,
            self.deceleration,
            self.type
        )
    end
end

function SpaceObj:spawnParticle(
    position,
    velocity,
    max_lifetime,
    colors,
    max_size,
    deceleration,
    particle_type
)
    local particle = {
        position     = {
            x = position.x,
            y = position.y
        },
        velocity     = {
            speed     = velocity.speed,
            direction = velocity.direction
        },
        life_timer   = (max_lifetime / 2) + (math.random() * max_lifetime / 2),
        colors       = colors,
        size         = math.random(1, max_size),
        deceleration = deceleration,
        type         = particle_type
    }

    if particle_type == self.TYPES.EXPLOSION then
        table.insert(self.explosionParticles, particle)
    elseif particle_type == self.TYPES.LASER_HIT then
        table.insert(self.laserHitParticles, particle)
    elseif particle_type == self.TYPES.SMOKE then        
        table.insert(self.smokeParticles, particle)      
    elseif particle_type == self.TYPES.SPARK then
        table.insert(self.sparkParticles, particle)
    elseif particle_type == self.TYPES.THRUST then
        table.insert(self.thrustParticles, particle)
    end
end

function SpaceObj:moveParticles(particle_type)
    local particles = self.explosionParticles

    if particle_type == self.TYPES.LASER_HIT then
        particles = self.laserHitParticles
    elseif particle_type == self.TYPES.SMOKE then
        particles = self.smokeParticles          
    elseif particle_type == self.TYPES.SPARK then
        particles = self.sparkParticles
    elseif particle_type == self.TYPES.THRUST then
        particles = self.thrustParticles
    end

    for index = #particles, 1, -1 do
        local particle = particles[index]

        particle.life_timer = particle.life_timer - 1

        if particle.life_timer < 0 then
            table.remove(particles, index)
        else
            particle.position = self:movePointByVelocity(particle)

            particle.velocity.speed = particle.velocity.speed - particle.deceleration
            if particle.velocity.speed < 0 then
                particle.velocity.speed = 0
            end
        end
    end
end

function SpaceObj:drawParticles(particle_type)
    local particles = self.explosionParticles

    if particle_type == self.TYPES.LASER_HIT then
        particles = self.laserHitParticles
    elseif particle_type == self.TYPES.SMOKE then
        particles = self.smokeParticles          
    elseif particle_type == self.TYPES.SPARK then
        particles = self.sparkParticles
    elseif particle_type == self.TYPES.THRUST then
        particles = self.thrustParticles
    end

    for index, particle in ipairs(particles) do
        local particle_color = particle.colors[math.random(1, #particle.colors)]

        if particle.type == self.TYPES.EXPLOSION or particle.type == self.TYPES.LASER_HIT then
            circ(particle.position.x, particle.position.y, particle.size, particle_color)
        elseif particle.type == self.TYPES.THRUST then
            pix(particle.position.x, particle.position.y, particle_color)
        elseif particle.type == self.TYPES.SMOKE then
            circ(particle.position.x, particle.position.y, particle.size, particle_color)
        else
            rect(particle.position.x, particle.position.y, particle.size, particle.size, particle_color)
        end
    end
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
        speed    = self.rotation_speed
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

    -- Move any particles on the board!
    self:moveParticles(self.TYPES.EXPLOSION)
    self:moveParticles(self.TYPES.LASER_HIT)
    self:moveParticles(self.TYPES.SMOKE)
    self:moveParticles(self.TYPES.SPARK)
    self:moveParticles(self.TYPES.THRUST)
end

-- ==========================================
-- SPACEOBJ DRAW
-- ==========================================

function SpaceObj:drawBody()
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

function SpaceObj:draw()
    self:drawBody()

    self:drawParticles(self.TYPES.EXPLOSION)
    self:drawParticles(self.TYPES.LASER_HIT)
    self:drawParticles(self.TYPES.SPARK)
    self:drawParticles(self.TYPES.THRUST)
end

function SpaceObj:explode()
    -- All space objects explode. How is another matter.
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
    self.max_health    = params.max_health or 1000
    self.cur_health    = self.max_health
    self.max_lives     = params.max_lives or 3
    self.cur_lives     = self.max_lives
    self.invulnerable  = 0
    self.dead          = false
    self.exploded      = false
    self.respawn_timer = 0

    self.deadstop = {
        brake = params.brake or 0.35, -- 0..1, higher = faster stop per frame
        snap  = params.snap  or 0.02  -- below this speed, just snap to 0
    }
    self.radius = params.radius or 10
    self.shape  = params.shape or {
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

function Ship:getHealth()
    if self.cur_health < 0 then
        self.cur_health = 0
    end
    return self.cur_health
end

function Ship:getHealthFraction()
    return self:getHealth() / self.max_health
end

function Ship:getNumLaserBlasts()
    return #self.laser_blasts
end

function Ship:getNumLives()
    return self.cur_lives
end

-- ==========================================
-- SHIP INPUT
-- ==========================================

function Ship:input()
    if btn(BTN_P1_LEFT) then
        self.rotation = self.rotation - self.rotation_speed
    end
    if btn(BTN_P1_RIGHT) then
        self.rotation = self.rotation + self.rotation_speed
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

    self:thrustEffect()
    sfx(3, 10, 10, 3, -8, 1)
end

function Ship:move()
    if not self.dead and btn(BTN_P1_UP) then
        self:thrust()
    end

    if not self.dead then
        self.velocity.speed = self.velocity.speed - self.deceleration
        if self.velocity.speed < 0 then
            self.velocity.speed = 0
        end

        -- Leak smoke when damaged
        local health_frac = self:getHealthFraction()
        if health_frac < 0.5 then
            self:leakingSmoke(health_frac)
        end

        SpaceObj.move(self)
    else
        -- Dead ship body does not move, but particles still animate.
        self:moveParticles(self.TYPES.EXPLOSION)
        self:moveParticles(self.TYPES.LASER_HIT)
        self:moveParticles(self.TYPES.SMOKE)
        self:moveParticles(self.TYPES.THRUST)
        self:updateTimer()
    end
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
        sfx(0, 40, 20, 0, 15, 1)
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
                if self:pointInPolygon(laser.position, asteroid) then
                    local hit_position = {
                        x = laser.position.x,
                        y = laser.position.y
                    }
                    -- Remove laser blast and mark the asteroid hit.
                    table.remove(self.laser_blasts, laser_index)
                    asteroid_was_hit = asteroid_index
                    self:laserHitEffect(hit_position)
                    return asteroid_was_hit
                end
            end
        end
    end
    return asteroid_was_hit
end

function Ship:regenerateHealth()
    if self.cur_health < self.max_health then
        self.cur_health = self.cur_health + 1
    end
    return self.cur_health
end

function Ship:takesDamage(damage)
    if damage == nil then
        damage = 0
    end
    self.cur_health = self.cur_health - damage
    self:sparkEffect()
    sfx(1, 60, 50, 1, 25)

    return self:getHealth()
end

function Ship:kill()
    if self.dead then
        return
    end
    self.dead = true
    self.cur_lives = self.cur_lives - 1
    self.respawn_timer = 90
    self:explode()
end

function Ship:respawn()
    self.dead               = false
    self.exploded           = false
    self.cur_health         = self.max_health
    self.position.x         = EDGE_X_RIGHT / 2
    self.position.y         = EDGE_Y_BOTTOM / 2
    self.velocity.speed     = 0
    self.velocity.direction = 0
    self.rotation           = -math.pi / 2
    self.invulnerable       = 120 -- 2 seconds invulnerable
    self.smoke_cooldown     = 0
end


-- ==========================================
-- SHIP DRAW
-- ==========================================

function Ship:drawLaserBlasts()
    for index, laser in ipairs(self.laser_blasts) do
        spr(1, laser.position.x, laser.position.y, 0)
    end
end

-- This is for when the ship first starts out and is invulnerable.
function Ship:shouldDraw()
    if self.invulnerable <= 0 then
        return true
    end
    -- blink: visible 6 frames, invisible 6 frames
    return (math.floor(self.invulnerable / 6) % 2) == 0
end

function Ship:explode()
    if self.exploded then
        return
    end
    self.exploded = true
    self:explosionEffect()
    sfx(2, 10, 30, 3, 15)
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
    self.base_points  = params.base_points  or 50
    self.clumpiness   = params.clumpiness   or 0.35
    self.scale        = params.scale        or 1  -- set this first!
    self.num_vertices = params.num_vertices or 10
    self.radius       = params.radius       or self.radius or 15
    self.radius_minus = params.radius_minus or 6
    self.radius_plus  = params.radius_plus  or 4
    self.rotation_max = params.rotation_max or 0.03
    self.velocity_max = params.velocity_max or 0.5
    self.velocity_min = params.velocity_min or 0.1
    self.shape        = params.shape        or self:spawn()

    return self
end

-- ==========================================
-- ASTEROID MATH
-- ==========================================

-- ==========================================
-- ASTEROID GETTERS
-- ==========================================

function Asteroid:getInducedDamage()
    return self.radius * 10
end

function Asteroid:getPoints()
    return self.base_points * self.scale
end

function Asteroid:getRadius()
    return self.radius
end

function Asteroid:getScale()
    return self.scale
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

    local baseR    = self.radius
    -- scale the "clumpiness" with size
    local minus    = math.min(self.radius_minus, baseR * self.clumpiness)
    local plus     = math.min(self.radius_plus, baseR * self.clumpiness)

    table.insert(vertices, { x = baseR, y = 0 })

    for vertex = 1, (self.num_vertices - 1) do
        local minr = math.max(1, baseR - minus) -- never <= 0
        local maxr = math.max(minr + 0.01, baseR + plus)

        local r = minr + math.random() * (maxr - minr)
        local a = (math.pi * 2 / self.num_vertices) * vertex

        table.insert(vertices, { x = r * math.cos(a), y = r * math.sin(a) })
    end

    table.insert(vertices, { x = baseR, y = 0 })
    return vertices
end

function Asteroid:move()
    self.rotation = self.rotation + self.rotation_speed

    SpaceObj.move(self)
end

-- ==========================================
-- ASTEROID DRAW
-- ==========================================

function Asteroid:explode()
    local position      = self.position
    local orig_scale    = self.scale

    local asteroid_fragments = {}

    if orig_scale < 4 then
        local new_scale = orig_scale * 2
        for count = 1, 2 do
            local asteroid = Asteroid:new({
                color          = self.color,
                x              = self.position.x,
                y              = self.position.y,
                speed          = (math.random() * (self.velocity_max - self.velocity_min)) + self.velocity_min,
                direction      = math.random() * math.pi * 2,
                acceleration   = self.acceleration,
                deceleration   = self.deceleration,
                elasticity     = self.elasticity,
                scale          = new_scale,
                rotation_speed = (math.random() * (2 * self.rotation_max)) - self.rotation_max,
                radius         = self.radius / new_scale,
                radius_minus   = self.radius_minus,
                radius_plus    = self.radius_plus,
                num_vertices   = self.num_vertices,
            })
            table.insert(asteroid_fragments, asteroid)
        end
    end

    sfx(1, 1, 50, 1, 15)

    return asteroid_fragments
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