-- ==========================================
-- MOON PRESETS / HELPERS
-- ==========================================

local MOON_MASS   = 1000000
local MOON_RADIUS = 100

local MOON_ROCKY_COLORS      = {
    RED,
    GRAY_LITE,
    GRAY_MED,
    GRAY_DARK,
}

local MOON_CRATER_COLORS     = {
    GRAY_DARK,
    GRAY_LITE,
    GRAY_MED,
    BLACK,
}

function randomPlanetColorSet()
    local source_colors = MOON_ROCKY_COLORS

    return {
        primary    = randomChoice(source_colors),
        secondary  = randomChoice(source_colors),
        tertiary   = randomChoice(source_colors),
        crater     = randomChoice(MOON_CRATER_COLORS),
        crater_rim = randomChoice(source_colors),
    }
end
