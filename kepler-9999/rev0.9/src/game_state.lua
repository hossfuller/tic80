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
    SHOP       = "SHOP",
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

    -- Shop state
    shop = {
        selected = 1,
        upgrade_base_cost = 100,
        items = {
            {
                name = "Upgrade Energy Generator",
                engine_type = "energy",
                apply = function(player)
                    return player:upgradeEnergyEngine()
                end,
            },
            {
                name = "Upgrade Life Support",
                engine_type = "life_support",
                apply = function(player)
                    return player:upgradeLifeSupportEngine()
                end,
            },
            {
                name = "Upgrade Shields",
                engine_type = "shield",
                apply = function(player)
                    return player:upgradeShieldEngine()
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
        x           = 0,
        y           = 0,
        target_x    = 0,
        target_y    = 0,
        lerp        = 0.08,
        zoom        = 1,
        zoom_index  = 5,
        zoom_levels = { 0.1, 0.15, 0.25, 0.5, 1 },
    },

    -- Gameplay state
    play = {
        player         = {},
        star           = {},
        planets        = {},
        comets         = {},
        asteroids      = {},
        comet_count    = 0,
        space_stations = {},
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

        game.play.player         = generatePlayer()
        game.play.star           = generateStar()
        game.play.planets        = generatePlanets()
        game.play.asteroids      = spawnAsteroids()
        game.play.space_stations = generateSpaceStations(game.play.planets)

        generateMoons()
        generateComets()

        addSpaceDocksToPlanets(game.play.planets)
        addSpaceDocksToStations(game.play.space_stations)

        resetPlayerAndCamera()
    end
end
