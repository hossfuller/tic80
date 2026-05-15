-- ==========================================
-- GAME STATE
-- ==========================================

STATE = {
    START      = "START",
    PLAY       = "PLAY",
    GAMEOVER   = "GAMEOVER",
    HIGHSCORES = "HIGHSCORES",
}

game = {
    state = STATE.START,
    prevState = nil,

    -- For any forthcoming options, make all params below configurable.
    -- Also, as ship takes damage, some parameters should change.

    -- Gameplay state
    play = {
        params = {
            player = {
                deadstop_allow = true,
                deadstop_break = 0.35, -- 0..1, higher = faster stop per frame
                deadstop_snap  = 0.02,   -- below this speed, just snap to 0
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

    -- State entry logic
    if newState == STATE.PLAY then
        -- Reset game state for new game
        game.play.player = Ship:new({
            color = BLUE_MED,
            brake = game.play.params.player.deadstop_brake,
            snap  = game.play.params.player.deadstop_snap,
        })
        game.play.score  = 0

        -- Generate Asteroids
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

    elseif newState == STATE.HIGHSCORES then
        loadHighScores()
        sortHighScores()
        buildLines()
        scroll = 0
    end
end
