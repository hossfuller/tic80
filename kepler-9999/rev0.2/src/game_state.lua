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

        generateBackgroundMap()
        resetPlayerAndCamera()
    end
end
