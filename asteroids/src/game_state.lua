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
                regenerate            = false,
                deadstop_allow        = true,
                deadstop_brake        = 0.35,                 -- 0..1, higher = faster stop per frame
                deadstop_snap         = 0.02,                 -- below this speed, just snap to 0
                max_lasers            = 4,
                laser_lifetime        = 60,
                elasticity            = 0.5,
                max_health            = 100,
                max_lives             = 3,
                next_extra_life_score = PTS_FOR_EXTRA_LIFE,
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
            alien = {
                min_level           = 3,
                min_health          = 3,
                cur_health          = 3,
                speed_min           = 0.3,
                speed_max           = 0.7,
                fire_interval_start = 120,   -- frames between shots when aliens first appear
                fire_interval_min   = 25,    -- fastest possible interval
                fire_interval_step  = 10,    -- interval reduction per level after min_level
                laser_speed         = 1.5,
                laser_lifetime      = 90,
                laser_damage        = 35,
            }
        },
        player                = {},
        asteroids             = {},
        alien                 = {},
        date                  = nil,
        diff                  = DIFFICULTY.MEDIUM,
        level                 = 1,
        score                 = 0,
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

        game.play.alien = nil

        game.play.score                               = 0
        game.play.date                                = get_unix_timestamp()
        game.play.level                               = 1
        game.play.params.player.next_extra_life_score = PTS_FOR_EXTRA_LIFE
        game.play.params.alien.cur_health             = game.play.params.alien.min_health

        -- Ensure difficulty is never nil. This should already be maintained by
        -- the options apply function, but this protects saved scores if PLAY is
        -- entered before options are touched.
        game.play.diff   = game.play.diff or DIFFICULTY.MEDIUM

        -- Generate alien if applicable
        generateAlien()

    elseif newState == STATE.GAMEOVER then
        saveCurrentScore()
    elseif newState == STATE.HIGHSCORES then
        loadHighScores()
        sortHighScores()
        buildLines()
        scroll = 0
    end
end


-- ==========================================
-- ENEMY GENERATION
-- ==========================================

function generateAlien()
    local params = game.play.params.alien

    -- Only spawn alien if we've reached the minimum level
    if game.play.level < params.min_level then
        game.play.alien = nil
        return
    end

    -- Random speed within configured range
    local speed = params.speed_min + math.random() * (params.speed_max - params.speed_min)

    -- Randomly choose to spawn from left or right
    local spawn_x   = 0
    local direction = 0  -- Moving right

    if math.random(1, 2) == 1 then
        spawn_x   = EDGE_X_RIGHT - 1
        direction = math.pi -- Moving left
    end

    game.play.alien = Alien:new({
        x              = spawn_x,
        y              = math.random(20, EDGE_Y_BOTTOM - 20),
        speed          = speed,
        direction      = direction,
        max_health     = params.cur_health,
        laser_speed    = params.laser_speed,
        laser_lifetime = params.laser_lifetime,
        laser_damage   = params.laser_damage,
    })

    -- Increment health for next spawn
    params.cur_health = params.cur_health + 1
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