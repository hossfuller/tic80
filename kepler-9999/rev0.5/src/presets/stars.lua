-- ==========================================
-- STAR PRESETS
-- ==========================================

--[[
    These are presets for all the different stellar types that the Kepler-9999
    star can be. These presets are used by the `generateStar()` function.
    Everything is randomly generated but also constrained by real stellar facts.
--]]

-- Heavenly Body constants
local STELLAR_TYPES  = { "O", "B", "A", "F", "G", "K", "M", }
local SOLAR_MASS     = 1000000000000
local JUPITER_MASS   = 1000000000
local MOON_MASS      = 1000000
local SOLAR_RADIUS   = 10000
local JUPITER_RADIUS = 1000
local MOON_RADIUS    = 100


local STELLAR_PROFILES = {
    O = {
        mass_min = 16,
        mass_max = 90,

        radius_min = 6.6,
        radius_max = 20,

        temp_min = 33000,
        temp_max = 50000,

        colors = {
            primary   = BLUE_LITE,
            secondary = BLUE_MED,
            tertiary  = WHITE,
        },
    },

    B = {
        mass_min = 2.1,
        mass_max = 16,

        radius_min = 1.8,
        radius_max = 6.6,

        temp_min = 10000,
        temp_max = 33000,

        colors = {
            primary   = BLUE_LITE,
            secondary = WHITE,
            tertiary  = CYAN,
        },
    },

    A = {
        mass_min = 1.4,
        mass_max = 2.1,

        radius_min = 1.4,
        radius_max = 1.8,

        temp_min = 7500,
        temp_max = 10000,

        colors = {
            primary   = WHITE,
            secondary = BLUE_LITE,
            tertiary  = CYAN,
        },
    },

    F = {
        mass_min = 1.04,
        mass_max = 1.4,

        radius_min = 1.15,
        radius_max = 1.4,

        temp_min = 6000,
        temp_max = 7500,

        colors = {
            primary   = WHITE,
            secondary = YELLOW,
            tertiary  = GRAY_LITE,
        },
    },

    G = {
        mass_min = 0.8,
        mass_max = 1.04,

        radius_min = 0.96,
        radius_max = 1.15,

        temp_min = 5200,
        temp_max = 6000,

        colors = {
            primary   = YELLOW,
            secondary = ORANGE,
            tertiary  = WHITE,
        },
    },

    K = {
        mass_min = 0.45,
        mass_max = 0.8,

        radius_min = 0.7,
        radius_max = 0.96,

        temp_min = 3700,
        temp_max = 5200,

        colors = {
            primary   = ORANGE,
            secondary = RED,
            tertiary  = YELLOW,
        },
    },

    M = {
        mass_min = 0.08,
        mass_max = 0.45,

        radius_min = 0.1,
        radius_max = 0.7,

        temp_min = 2400,
        temp_max = 3700,

        colors = {
            primary   = RED,
            secondary = ORANGE,
            tertiary  = GRAY_DARK,
        },
    },
}
