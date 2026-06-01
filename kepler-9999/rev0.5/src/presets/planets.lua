-- ==========================================
-- PLANET PRESETS / HELPERS
-- ==========================================

local JUPITER_MASS   = 1000000000
local EARTH_MASS     = 10000000
local JUPITER_RADIUS = 1000
local EARTH_RADIUS   = 100

local PLANET_ATMOSPHERE_COLORS = {
    PURPLE,
    RED,
    ORANGE,
    YELLOW,
    GREEN_LITE,
    GREEN_MED,
    GREEN_DARK,
    BLUE_DARK,
    BLUE_MED,
    BLUE_LITE,
    CYAN,
}

local PLANET_CLOUD_COLORS = {
    WHITE,
    CYAN,
    BLUE_LITE,
    PURPLE,
}

local PLANET_ROCKY_COLORS = {
    RED,
    GRAY_LITE,
    GRAY_MED,
    GRAY_DARK,
}

local PLANET_CRATER_COLORS = {
    GRAY_DARK,
    GRAY_LITE,
    GRAY_MED,
    BLACK,
}

function randomPlanetColorSet(has_atmosphere)
    local source_colors = PLANET_ROCKY_COLORS

    if has_atmosphere then
        source_colors = PLANET_ATMOSPHERE_COLORS
    end

    return {
        primary    = randomChoice(source_colors),
        secondary  = randomChoice(source_colors),
        tertiary   = randomChoice(source_colors),
        cloud      = randomChoice(PLANET_CLOUD_COLORS),
        crater     = randomChoice(PLANET_CRATER_COLORS),
        crater_rim = randomChoice(source_colors),
    }
end

