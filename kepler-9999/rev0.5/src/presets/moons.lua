-- ==========================================
-- MOON PRESETS / HELPERS
-- ==========================================

local MOON_MASS     = 1000000
local MOON_MIN_MASS = 10000
local MOON_RADIUS   = 100

local MAX_MOONS_PER_PLANET    = 3
local MAX_MOON_ORBIT_APOAPSIS = MAP_TILES_W

local MOON_ROCKY_COLORS = {
    RED,
    GREEN_DARK,
    BLUE_DARK,
    GRAY_LITE,
    GRAY_MED,
    GRAY_DARK,
}

local MOON_CRATER_COLORS = {
    GRAY_DARK,
    GRAY_LITE,
    GRAY_MED,
    BLACK,
}

function randomMoonColorSet()
    local source_colors = MOON_ROCKY_COLORS

    return {
        primary    = randomChoice(source_colors),
        secondary  = randomChoice(source_colors),
        tertiary   = randomChoice(source_colors),
        crater     = randomChoice(MOON_CRATER_COLORS),
        crater_rim = randomChoice(source_colors),
    }
end
