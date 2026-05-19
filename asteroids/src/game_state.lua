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
                        game.play.params.player.max_lives         = 3
                        game.play.params.player.max_health        = 250
                        game.play.params.player.max_lasers        = 6
                        game.play.params.player.laser_lifetime    = 60
                        game.play.params.asteroids.num_population = 4
                        game.play.params.asteroids.velocity_max   = 0.3
                        game.play.params.asteroids.velocity_min   = 0.05
                    elseif value == 2 then -- Medium
                        game.play.params.player.max_lives         = 2
                        game.play.params.player.max_health        = 175
                        game.play.params.player.max_lasers        = 5
                        game.play.params.player.laser_lifetime    = 50
                        game.play.params.asteroids.num_population = 6
                        game.play.params.asteroids.velocity_max   = 0.5
                        game.play.params.asteroids.velocity_min   = 0.1
                    elseif value == 3 then -- Hard
                        game.play.params.player.max_lives         = 1
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
                deadstop_break = 0.35,   -- 0..1, higher = faster stop per frame
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
        player    = {},
        asteroids = {},
        score     = 0,
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
            color      = BLUE_MED,
            max_health = game.play.params.player.max_health,
            max_lives  = game.play.params.player.max_lives,
            brake      = game.play.params.player.deadstop_brake,
            snap       = game.play.params.player.deadstop_snap,
            shots      = game.play.params.player.max_lasers,
            lifetime   = game.play.params.player.laser_lifetime
        })
        game.play.score  = 0

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
            color          = color,
            x              = pos_x,
            y              = pos_y,
            speed          = vel_speed,
            direction      = math.random() * math.pi * 2,
            elasticity     = game.play.params.asteroids.elasticity,
            scale          = 1,
            rotation_speed = rot_speed,
            velocity_max   = game.play.params.asteroids.velocity_max,
            velocity_min   = game.play.params.asteroids.velocity_min,
            radius         = game.play.params.asteroids.radius,
            radius_minus   = game.play.params.asteroids.radius_minus,
            radius_plus    = game.play.params.asteroids.radius_plus,
            num_vertices   = game.play.params.asteroids.num_vertices,
        })
        table.insert(game.play.asteroids, asteroid)
    end
end