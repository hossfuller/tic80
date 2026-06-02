-- ==========================================
-- STARS
-- ==========================================

--[[
    These are presets for all the different stellar types that the Kepler-9999
    star can be. These presets are used by the `generateStar()` function.
    Everything is randomly generated but also constrained by real stellar facts.
--]]

-- Heavenly Body constants
local STELLAR_TYPES    = { "O", "B", "A", "F", "G", "K", "M", }
local SOLAR_MASS       = 1000000000000
local MOON_MASS        = 1000000
local SOLAR_RADIUS     = 10000
local MOON_RADIUS      = 100

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

        particles = {
            wind = {
                spawn_chance            = 0.80,
                speed_min               = 0.35,
                speed_max               = 0.80,
                max_distance_multiplier = 2.8,
            },
            flare = {
                spawn_chance            = 0.004,
                particles_per_flare_min = 3,
                particles_per_flare_max = 8,
                speed_min               = 0.35,
                speed_max               = 0.75,
                angle_spread            = math.pi / 10,
                max_distance_multiplier = 2.5,
                evaporate_chance_min    = 0.020,
                evaporate_chance_max    = 0.050,
            },
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

        particles = {
            wind = {
                spawn_chance            = 0.65,
                speed_min               = 0.28,
                speed_max               = 0.65,
                max_distance_multiplier = 2.5,
            },
            flare = {
                spawn_chance            = 0.007,
                particles_per_flare_min = 4,
                particles_per_flare_max = 10,
                speed_min               = 0.40,
                speed_max               = 0.85,
                angle_spread            = math.pi / 9,
                max_distance_multiplier = 2.8,
                evaporate_chance_min    = 0.018,
                evaporate_chance_max    = 0.045,
            },
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

        particles = {
            wind = {
                spawn_chance            = 0.50,
                speed_min               = 0.22,
                speed_max               = 0.55,
                max_distance_multiplier = 2.2,
            },
            flare = {
                spawn_chance            = 0.010,
                particles_per_flare_min = 5,
                particles_per_flare_max = 12,
                speed_min               = 0.45,
                speed_max               = 0.95,
                angle_spread            = math.pi / 8,
                max_distance_multiplier = 3.0,
                evaporate_chance_min    = 0.015,
                evaporate_chance_max    = 0.040,
            },
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

        particles = {
            wind = {
                spawn_chance            = 0.40,
                speed_min               = 0.18,
                speed_max               = 0.45,
                max_distance_multiplier = 2.0,
            },
            flare = {
                spawn_chance            = 0.014,
                particles_per_flare_min = 6,
                particles_per_flare_max = 14,
                speed_min               = 0.50,
                speed_max               = 1.05,
                angle_spread            = math.pi / 7,
                max_distance_multiplier = 3.2,
                evaporate_chance_min    = 0.012,
                evaporate_chance_max    = 0.035,
            },
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

        particles = {
            wind = {
                spawn_chance            = 0.30,
                speed_min               = 0.14,
                speed_max               = 0.38,
                max_distance_multiplier = 1.8,
            },
            flare = {
                spawn_chance            = 0.018,
                particles_per_flare_min = 8,
                particles_per_flare_max = 16,
                speed_min               = 0.55,
                speed_max               = 1.15,
                angle_spread            = math.pi / 7,
                max_distance_multiplier = 3.5,
                evaporate_chance_min    = 0.010,
                evaporate_chance_max    = 0.030,
            },
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

        particles = {
            wind = {
                spawn_chance            = 0.20,
                speed_min               = 0.10,
                speed_max               = 0.30,
                max_distance_multiplier = 1.6,
            },
            flare = {
                spawn_chance            = 0.026,
                particles_per_flare_min = 10,
                particles_per_flare_max = 22,
                speed_min               = 0.65,
                speed_max               = 1.35,
                angle_spread            = math.pi / 6,
                max_distance_multiplier = 3.8,
                evaporate_chance_min    = 0.008,
                evaporate_chance_max    = 0.025,
            },
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

        particles = {
            wind = {
                spawn_chance            = 0.10,
                speed_min               = 0.05,
                speed_max               = 0.18,
                max_distance_multiplier = 1.3,
            },
            flare = {
                spawn_chance            = 0.040,
                particles_per_flare_min = 14,
                particles_per_flare_max = 30,
                speed_min               = 0.75,
                speed_max               = 1.60,
                angle_spread            = math.pi / 5,
                max_distance_multiplier = 4.0,
                evaporate_chance_min    = 0.005,
                evaporate_chance_max    = 0.020,
            },
        },
    },
}

function randomStarCornerPosition()
    local corners = {
        { -- Bottom-left
            x = 0,
            y = MAP_PIXELS_H,
        },
        { -- Bottom-right
            x = MAP_PIXELS_W,
            y = MAP_PIXELS_H,
        },
        { -- Top-right
            x = MAP_PIXELS_W,
            y = 0,
        },
    }
    return corners[math.random(1, #corners)]
end

function generateStar()
    local pos = randomStarCornerPosition()
    return Star:new({
        stellar_type = randomChoice(STELLAR_TYPES),
        x = pos.x,
        y = pos.y,
    })
end
