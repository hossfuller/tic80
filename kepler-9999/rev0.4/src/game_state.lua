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
            {
                name = "Ship Type",
                values = { "Cruiser", "Freighter", "Passenger", "Smuggler" },
                current = 1,
                apply = function(current)
                    game.params.ship_type = current
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

    -- High scores
    hiscores = {},

    -- Game Parameters
    params = {
        ship_type = 1, -- default ship by default
    },

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
        player = {},
        star   = {},
    },
}


-- ==========================================
-- STATE CHANGE
-- ==========================================

function changeState(newState)
    game.prevState = game.state
    game.state = newState

    if newState == STATE.READY then
        generateBackgroundMap()

        game.play.player = generatePlayer()
        game.play.star   = generateStar()
        resetPlayerAndCamera()
    end
end
