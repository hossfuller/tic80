-- ==========================================
-- COMET PRESETS / HELPERS
-- ==========================================

local COMET_MAX_MASS        = 1000
local COMET_MIN_MASS        = 10
local COMET_RADIUS_REAL_MIN = 100
local COMET_RADIUS_REAL_MAX = 900
local COMET_SPEED_MIN       = 0.05
local COMET_SPEED_MAX       = 0.5
local COMET_NUM_MIN         = 5
local COMET_NUM_MAX         = 10
local COMET_EVAPORATION_MIN = 0.001
local COMET_EVAPORATION_MAX = 0.08

local COMET_TAIL_LIFE_MIN   = 8
local COMET_TAIL_LIFE_MAX   = 160
local COMET_TAIL_SPEED_MIN  = 0.05
local COMET_TAIL_SPEED_MAX  = 1.25
local COMET_TAIL_SPAWN_MIN  = 0.25
local COMET_TAIL_SPAWN_MAX  = 8

local COMET_COLORS = {
    PURPLE,
    BLUE_DARK ,
    BLUE_MED,
    BLUE_LITE,
    CYAN,
    GRAY_LITE,
    GRAY_MED,
    GRAY_DARK,
}

function randomCometColorSet()
    return {
        primary   = WHITE,
        secondary = randomChoice(COMET_COLORS),
        tertiary  = randomChoice(COMET_COLORS),
    }
end

function randomCometColorList(colors)
    colors = colors or randomCometColorSet()

    return {
        colors.primary,
        colors.secondary,
        colors.tertiary,
    }
end
