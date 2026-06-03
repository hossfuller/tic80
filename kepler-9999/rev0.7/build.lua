--
-- Bundle file
-- Code changes will be overwritten
--

-- title:   Kepler-9999
-- author:  Hoss Fuller
-- version: rev0.7
-- script:  lua
-- input:   mouse
-- saveid:  kepler_9999

-- ==========================================
-- INCLUDES
-- ==========================================

-- [TQ-Bundler: src.constants_system]

-- ==========================================
-- TIC80 CONSTANTS
-- ==========================================

-- Colors
local BLACK      = 0
local PURPLE     = 1
local RED        = 2
local ORANGE     = 3
local YELLOW     = 4
local GREEN_LITE = 5
local GREEN_MED  = 6
local GREEN_DARK = 7
local BLUE_DARK  = 8
local BLUE_MED   = 9
local BLUE_LITE  = 10
local CYAN       = 11
local WHITE      = 12
local GRAY_LITE  = 13
local GRAY_MED   = 14
local GRAY_DARK  = 15

-- Button mappings
local BTN_P1_UP     = 0
local BTN_P1_DOWN   = 1
local BTN_P1_LEFT   = 2
local BTN_P1_RIGHT  = 3
local BTN_P1_A      = 4         -- Primary action / Select
local BTN_P1_B      = 5         -- Secondary action / Back / Pause
local BTN_P1_X      = 6
local BTN_P1_Y      = 7
local BTN_P1_SELECT = BTN_P1_X
local BTN_P1_START  = BTN_P1_Y

-- Screen dimensions
local EDGE_X_LEFT       = 0
local EDGE_X_RIGHT      = 240
local EDGE_Y_TOP        = 0
local EDGE_Y_BOTTOM     = 136

local SCREEN_W          = EDGE_X_RIGHT
local SCREEN_H          = EDGE_Y_BOTTOM

-- Map dimensions
local TILE_SIZE         = 8
local MAP_TILES_W       = 240
local MAP_TILES_H       = 136
local SCREEN_TILES_W    = 30
local SCREEN_TILES_H    = 17

local MAP_PIXELS_W      = MAP_TILES_W * TILE_SIZE
local MAP_PIXELS_H      = MAP_TILES_H * TILE_SIZE

local MAP_SCREENS_W     = 8
local MAP_SCREENS_H     = 8

-- Character dimensions (these scale linearly)
local FIXED_CHAR_WIDTH  = 6
local FIXED_CHAR_HEIGHT = 6
local X_PADDING         = FIXED_CHAR_WIDTH + 2
local Y_PADDING         = FIXED_CHAR_HEIGHT + 2


-- [/TQ-Bundler: src.constants_system]

-- [TQ-Bundler: src.constants_game]

-- ==========================================
-- GAME CONSTANTS
-- ==========================================

local DEBUG = true

local TILE_EMPTY       = 0
local TILE_STAR_DIM    = 1
local TILE_STAR_MED    = 2
local TILE_STAR_BRIGHT = 3

local SPRITESHEET_TILES_W = 16

local TILE_BLACK_HOLE_ID = 16
local TILE_BLACK_HOLE_W  = 4
local TILE_BLACK_HOLE_H  = 4

local TILE_GALAXY_ID = 80
local TILE_GALAXY_W  = 4
local TILE_GALAXY_H  = 4


-- [/TQ-Bundler: src.constants_game]

-- [TQ-Bundler: src.generators.backgroundmap]

-- ==========================================
-- BACKGROUND MAP
-- ==========================================

function generateStarScreen(screen_x, screen_y)
    local start_tile_x = screen_x * SCREEN_TILES_W
    local start_tile_y = screen_y * SCREEN_TILES_H

    local density = math.random(2, 8)

    for local_y = 0, SCREEN_TILES_H - 1 do
        for local_x = 0, SCREEN_TILES_W - 1 do
            local map_x = start_tile_x + local_x
            local map_y = start_tile_y + local_y

            local roll = math.random(1, 100)

            if roll <= density then
                local star_roll = math.random(1, 100)

                if star_roll <= 70 then
                    mset(map_x, map_y, TILE_STAR_DIM)
                elseif star_roll <= 95 then
                    mset(map_x, map_y, TILE_STAR_MED)
                else
                    mset(map_x, map_y, TILE_STAR_BRIGHT)
                end
            else
                mset(map_x, map_y, TILE_EMPTY)
            end
        end
    end

    local landmark_count = math.random(1, 4)

    for i = 1, landmark_count do
        local lx = start_tile_x + math.random(0, SCREEN_TILES_W - 1)
        local ly = start_tile_y + math.random(0, SCREEN_TILES_H - 1)

        mset(lx, ly, TILE_STAR_BRIGHT)
    end
end

function tileRectsOverlap(a, b)
    return
        a.x < b.x + b.w and
        a.x + a.w > b.x and
        a.y < b.y + b.h and
        a.y + a.h > b.y
end

function canPlaceTileObject(candidate, placed_objects)
    for _, object in ipairs(placed_objects) do
        if tileRectsOverlap(candidate, object) then
            return false
        end
    end

    return true
end

function stampTileObjectToMap(base_tile_id, tile_w, tile_h, map_tile_x, map_tile_y)
    for y = 0, tile_h - 1 do
        for x = 0, tile_w - 1 do
            local tile_id = base_tile_id + x + y * SPRITESHEET_TILES_W
            mset(map_tile_x + x, map_tile_y + y, tile_id)
        end
    end
end

function placeRandomTileObjectOnMap(base_tile_id, tile_w, tile_h, placed_objects)
    local max_tile_x = MAP_TILES_W - tile_w
    local max_tile_y = MAP_TILES_H - tile_h

    local attempts = 0
    local max_attempts = 100

    while attempts < max_attempts do
        attempts = attempts + 1

        local map_tile_x = math.random(0, max_tile_x)
        local map_tile_y = math.random(0, max_tile_y)

        local candidate = {
            x = map_tile_x,
            y = map_tile_y,
            w = tile_w,
            h = tile_h,
        }

        if canPlaceTileObject(candidate, placed_objects) then
            stampTileObjectToMap(
                base_tile_id,
                tile_w,
                tile_h,
                map_tile_x,
                map_tile_y
            )

            table.insert(placed_objects, candidate)

            return true
        end
    end

    return false
end

function generateBackgroundMap()
    for screen_y = 0, MAP_SCREENS_H - 1 do
        for screen_x = 0, MAP_SCREENS_W - 1 do
            generateStarScreen(screen_x, screen_y)
        end
    end

    local placed_objects = {}

    local black_hole_count = math.random(1, 3)
    local galaxy_count = math.random(1, 3)

    for i = 1, black_hole_count do
        placeRandomTileObjectOnMap(
            TILE_BLACK_HOLE_ID,
            TILE_BLACK_HOLE_W,
            TILE_BLACK_HOLE_H,
            placed_objects
        )
    end

    for i = 1, galaxy_count do
        placeRandomTileObjectOnMap(
            TILE_GALAXY_ID,
            TILE_GALAXY_W,
            TILE_GALAXY_H,
            placed_objects
        )
    end
end


-- [/TQ-Bundler: src.generators.backgroundmap]

-- [TQ-Bundler: src.generators.ships]

-- ==========================================
-- PLAYER & NPC SHIPS
-- ==========================================

--[[
    These are presets for all the different types of ships a user can play as.
    These presets are used by the `generatePlayer()` function. The user will
    select which ship they want to fly around with at the options screen.
--]]

-- Quick constants to set passenger masses.
local PASSENGER_MASS         = 75
local PASSENGER_LUGGAGE_MASS = 25
local PASSENGER_TOTAL_MASS   = PASSENGER_MASS + PASSENGER_LUGGAGE_MASS

local cruiser_ship = {
    name      = "Cruiser",
    shape     = {
        { x = 8,  y = 0 },
        { x = -8, y = 6 },
        { x = -4, y = 0 },
        { x = -8, y = -6 },
        { x = 8,  y = 0 },
    },
    colors    = {
        primary   = BLUE_MED,
        secondary = BLUE_DARK,
    },
    engines   = {
        energy = {
            cur = 600,
            max = 600,
            mul = 1,
            tik = 20,
        },
        life_support = {
            cur = 350,
            max = 350,
            mul = 1,
            tik = 3600,
        },
        shield = {
            cur = 350,
            max = 350,
            mul = 1,
            tik = 60,
        },
    },
    holds     = {
        cargo = {
            max = 600,
        },
        passengers = {
            max = 6 * PASSENGER_TOTAL_MASS,
        },
        smuggled = {
            max = 100,
        },
    },
    mass      = 180,
    max_mass  = 1480,
    radius    = 10,
    max_speed = 2.3,
}

local freighter_ship = {
    name      = "Freighter",
    shape     = {
        { x = 16, y = 0 },
        { x = 13, y = 5 },
        { x = 6,  y = 5 },
        { x = 4,  y = 7 },
        { x = 0,  y = 8 },
        { x = -9, y = 8 },
        { x = -9, y = 6 },
        { x = -6, y = 2 },
        { x = -9, y = 0 },
        { x = -6, y = -2 },
        { x = -9, y = -6 },
        { x = -9, y = -8 },
        { x = 0,  y = -8 },
        { x = 4,  y = -7 },
        { x = 6,  y = -5 },
        { x = 13, y = -5 },
        { x = 16, y = 0 },
    },
    colors    = {
        primary   = GREEN_MED,
        secondary = GREEN_DARK,
    },
    engines   = {
        energy = {
            cur = 1200,
            max = 1200,
            mul = 1,
            tik = 20,
        },
        life_support = {
            cur = 550,
            max = 550,
            mul = 1,
            tik = 3600,
        },
        shield = {
            cur = 700,
            max = 700,
            mul = 1,
            tik = 60,
        },
    },
    holds     = {
        cargo = {
            max = 2600,
        },
        passengers = {
            max = 4 * PASSENGER_TOTAL_MASS,
        },
        smuggled = {
            max = 150,
        },
    },
    mass      = 900,
    max_mass  = 4050,
    radius    = 16,
    max_speed = 1.2,
}

local passenger_ship = {
    name      = "Passenger Ship",
    shape     = {
        { x = 10,  y = 0 },
        { x = 9,   y = 2 },
        { x = 7,   y = 3 },
        { x = -1,  y = 3 },
        { x = -3,  y = 6 },
        { x = 1,   y = 6 },
        { x = 2,   y = 7 },
        { x = 1,   y = 9 },
        { x = -10, y = 9 },
        { x = -11, y = 7 },
        { x = -10, y = 6 },
        { x = -8,  y = 6 },
        { x = -6,  y = 3 },
        { x = -8,  y = 3 },
        { x = -10, y = 2 },
        { x = -11, y = 0 },
        { x = -10, y = -2 },
        { x = -8,  y = -3 },
        { x = -6,  y = -3 },
        { x = -8,  y = -6 },
        { x = -10, y = -6 },
        { x = -11, y = -7 },
        { x = -10, y = -9 },
        { x = 1,   y = -9 },
        { x = 2,   y = -7 },
        { x = 1,   y = -6 },
        { x = -3,  y = -6 },
        { x = -1,  y = -3 },
        { x = 7,   y = -3 },
        { x = 9,   y = -2 },
        { x = 10,  y = 0 },
    },
    colors    = {
        primary   = WHITE,
        secondary = GRAY_LITE,
    },
    engines   = {
        energy = {
            cur = 900,
            max = 900,
            mul = 1,
            tik = 20,
        },
        life_support = {
            cur = 800,
            max = 800,
            mul = 1,
            tik = 3600,
        },
        shield = {
            cur = 500,
            max = 500,
            mul = 1,
            tik = 60,
        },
    },
    holds     = {
        cargo = {
            max = 350,
        },
        passengers = {
            max = 18 * PASSENGER_TOTAL_MASS,
        },
        smuggled = {
            max = 50,
        },
    },
    mass      = 700,
    max_mass  = 2900,
    radius    = 15,
    max_speed = 1.7,
}

local smuggler_ship = {
    name      = "Smuggler",
    shape     = {
        { x = 3,  y = 0 },
        { x = 6,  y = 3 },
        { x = 0,  y = 6 },
        { x = -8, y = 9 },
        { x = -6, y = 3 },
        { x = -9, y = 0 },
        { x = -6, y = -3 },
        { x = -8, y = -9 },
        { x = 0,  y = -6 },
        { x = 6,  y = -3 },
        { x = 3,  y = 0 },
    },
    colors    = {
        primary   = RED,
        secondary = ORANGE,
    },
    engines   = {
        energy = {
            cur = 800,
            max = 800,
            mul = 1,
            tik = 20,
        },
        life_support = {
            cur = 250,
            max = 250,
            mul = 1,
            tik = 3600,
        },
        shield = {
            cur = 250,
            max = 250,
            mul = 1,
            tik = 60,
        },
    },
    holds     = {
        cargo = {
            max = 300,
        },
        passengers = {
            max = 2 * PASSENGER_TOTAL_MASS,
        },
        smuggled = {
            max = 900,
        },
    },
    mass      = 220,
    max_mass  = 1620,
    radius    = 9,
    max_speed = 3.1,
}

local ship_presets = {
    cruiser_ship,
    freighter_ship,
    passenger_ship,
    smuggler_ship,
}

function generatePlayer()
    local selected_ship = game.params.ship_type or 1
    local preset = ship_presets[selected_ship] or cruiser_ship
    return SpaceShip:new(preset)
end


-- [/TQ-Bundler: src.generators.ships]

-- [TQ-Bundler: src.generators.stars]

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


-- [/TQ-Bundler: src.generators.stars]

-- [TQ-Bundler: src.generators.planets]

-- ==========================================
-- PLANETS
-- ==========================================

local JUPITER_MASS             = 1000000000
local EARTH_MASS               = 10000000
local JUPITER_RADIUS           = 1000
local EARTH_RADIUS             = 100

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

local PLANET_CLOUD_COLORS      = {
    WHITE,
    CYAN,
    BLUE_LITE,
    PURPLE,
}

local PLANET_ROCKY_COLORS      = {
    RED,
    GRAY_LITE,
    GRAY_MED,
    GRAY_DARK,
}

local PLANET_CRATER_COLORS     = {
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

function generatePlanetName(index)
    -- 1 -> b, 2 -> c, 3 -> d, etc.
    local letter = string.char(string.byte("b") + index - 1)
    return "Kepler-9999" .. letter
end

function generatePlanetCandidate(index)
    local has_atmosphere = math.random(1, 100) <= 50
    local radius_real    = randomFloat(EARTH_RADIUS, JUPITER_RADIUS)

    return Planet:new({
        -- Temporary name. Real name gets assigned after sorting by star distance.
        name           = "Unnamed Planet",
        x              = math.random(0, MAP_PIXELS_W - 1),
        y              = math.random(0, MAP_PIXELS_H - 1),
        mass           = randomFloat(EARTH_MASS, JUPITER_MASS),
        radius_real    = radius_real,
        has_atmosphere = has_atmosphere,
        colors         = randomPlanetColorSet(has_atmosphere),
    })
end

function canPlacePlanet(candidate, planets, star)
    -- Keep away from top-left player start area.
    local player_start_x = SCREEN_W / 2
    local player_start_y = SCREEN_H / 2
    local player_padding = MAP_TILES_W

    if objectsTooClose(
            candidate.position.x,
            candidate.position.y,
            candidate.radius,
            player_start_x,
            player_start_y,
            10,
            player_padding
        ) then
        return false
    end

    -- Keep away from star.
    if star then
        local star_padding = MAP_TILES_W

        if objectsTooClose(
                candidate.position.x,
                candidate.position.y,
                candidate.radius,
                star.position.x,
                star.position.y,
                star.radius,
                star_padding
            ) then
            return false
        end
    end

    -- Keep away from other planets.
    for _, planet in ipairs(planets) do
        local planet_padding = MAP_TILES_W

        if objectsTooClose(
                candidate.position.x,
                candidate.position.y,
                candidate.radius,
                planet.position.x,
                planet.position.y,
                planet.radius,
                planet_padding
            ) then
            return false
        end
    end

    return true
end

function assignPlanetNamesByDistanceFromStar(planets, star)
    if not star then
        return
    end

    table.sort(planets, function(a, b)
        local a_distance = distanceSquared(
            a.position.x,
            a.position.y,
            star.position.x,
            star.position.y
        )

        local b_distance = distanceSquared(
            b.position.x,
            b.position.y,
            star.position.x,
            star.position.y
        )

        return a_distance < b_distance
    end)

    for index, planet in ipairs(planets) do
        planet.name = generatePlanetName(index)
    end
end

function generatePlanets()
    local planets = {}

    -- Tune these however you want.
    local planet_count = math.random(3, 7)
    local max_attempts_per_planet = 100

    for i = 1, planet_count do
        local placed = false
        local attempts = 0

        while not placed and attempts < max_attempts_per_planet do
            attempts = attempts + 1

            local candidate = generatePlanetCandidate(i)

            if canPlacePlanet(candidate, planets, game.play.star) then
                table.insert(planets, candidate)
                placed = true
            end
        end
    end

    assignPlanetNamesByDistanceFromStar(planets, game.play.star)

    return planets
end


-- [/TQ-Bundler: src.generators.planets]

-- [TQ-Bundler: src.generators.moons]

-- ==========================================
-- MOONS
-- ==========================================

local MOON_MASS               = 1000000
local MOON_MIN_MASS           = 10000
local MOON_RADIUS             = 100

local MAX_MOONS_PER_PLANET    = 3
local MAX_MOON_ORBIT_APOAPSIS = MAP_TILES_W

local MOON_ROCKY_COLORS       = {
    RED,
    GREEN_DARK,
    BLUE_DARK,
    GRAY_LITE,
    GRAY_MED,
    GRAY_DARK,
}

local MOON_CRATER_COLORS      = {
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

function getMoonCountForPlanet(planet)
    -- Normalize planet mass from Earth-ish to Jupiter-ish.
    local t = (planet.mass - EARTH_MASS) / (JUPITER_MASS - EARTH_MASS)
    t = clamp(t, 0, 1)

    -- More massive planets are more likely to get moons.
    -- Small planets often get 0. Large planets often get 1-3.
    local roll = math.random()

    if roll > t then
        return 0
    end

    if t < 0.33 then
        return math.random(0, 1)
    elseif t < 0.66 then
        return math.random(1, 2)
    end

    return math.random(1, MAX_MOONS_PER_PLANET)
end

function moonOrbitIntersectsExisting(candidate_periapsis, candidate_apoapsis, existing_orbits, padding)
    padding = padding or 0

    for _, orbit in ipairs(existing_orbits) do
        -- Since all moon orbits around a planet share the same focus, a simple
        -- radial range overlap check is enough for generation purposes.
        local separated =
            candidate_apoapsis + padding < orbit.periapsis or
            candidate_periapsis > orbit.apoapsis + padding

        if not separated then
            return true
        end
    end

    return false
end

function calculatePlanetMoonBarycenter(planet, moons)
    local total_mass = planet.mass
    local weighted_x = planet.position.x * planet.mass
    local weighted_y = planet.position.y * planet.mass

    for _, moon in ipairs(moons) do
        total_mass = total_mass + moon.mass
        weighted_x = weighted_x + moon.position.x * moon.mass
        weighted_y = weighted_y + moon.position.y * moon.mass
    end

    return {
        x = weighted_x / total_mass,
        y = weighted_y / total_mass,
    }
end

function generateMoonName(planet, index)
    return planet.name .. "-" .. tostring(index)
end

function generateMoonsForPlanet(planet)
    local moons = {}
    local existing_orbits = {}

    local moon_count = getMoonCountForPlanet(planet)

    local max_apoapsis = MAX_MOON_ORBIT_APOAPSIS
    local min_periapsis = planet.radius + 30

    -- If the planet is so large that this cannot work, skip moons.
    if min_periapsis >= max_apoapsis then
        return moons
    end

    for i = 1, moon_count do
        local placed = false
        local attempts = 0
        local max_attempts = 80

        while not placed and attempts < max_attempts do
            attempts = attempts + 1

            local radius_real = randomFloat(100, 900)
            local draw_radius = Moon:getDrawRadiusFromRealRadius(radius_real)

            local eccentricity = randomFloat(0.05, 0.55)

            -- Constrain semi-major axis so apoapsis never exceeds max_apoapsis.
            local max_semi_major = max_apoapsis / (1 + eccentricity)

            -- Constrain semi-major axis so periapsis clears the planet.
            local min_semi_major = (planet.radius + draw_radius + 8) / (1 - eccentricity)

            -- Safety margin.
            min_semi_major = math.max(min_semi_major, min_periapsis)

            if min_semi_major < max_semi_major then
                local semi_major    = randomFloat(min_semi_major, max_semi_major)

                local periapsis     = semi_major * (1 - eccentricity)
                local apoapsis      = semi_major * (1 + eccentricity)

                local clears_planet = periapsis > planet.radius + draw_radius + 8
                local orbit_padding = draw_radius * 2 + 12

                if clears_planet and
                    apoapsis <= max_apoapsis and
                    not moonOrbitIntersectsExisting(
                        periapsis,
                        apoapsis,
                        existing_orbits,
                        orbit_padding
                    ) then
                    local moon = Moon:new({
                        name           = generateMoonName(planet, i),
                        host           = planet,

                        x              = planet.position.x,
                        y              = planet.position.y,

                        mass           = randomFloat(MOON_MIN_MASS, MOON_MASS),
                        radius_real    = radius_real,
                        radius         = draw_radius,

                        has_atmosphere = false,
                        has_ring       = false,
                        num_rings      = 0,

                        colors         = randomMoonColorSet(),

                        orbit          = {
                            semi_major   = semi_major,
                            eccentricity = eccentricity,
                            angle        = randomFloat(0, math.pi * 2),
                            phase        = randomFloat(0, math.pi * 2),
                            period       = math.random(900, 3600) + math.floor(semi_major * 4),
                        },
                    })

                    table.insert(moons, moon)

                    table.insert(existing_orbits, {
                        periapsis = periapsis,
                        apoapsis  = apoapsis,
                    })

                    placed = true
                end
            end
        end
    end

    -- First place moons around the planet position.
    -- This lets barycenter calculation use real initial moon positions.
    for _, moon in ipairs(moons) do
        moon:updateOrbitPosition(planet.position)
    end

    -- Calculate barycenter after all moons are created and initially placed.
    planet.barycenter = calculatePlanetMoonBarycenter(planet, moons)

    -- Then re-place moons using the barycenter as the focus.
    for _, moon in ipairs(moons) do
        moon:updateOrbitPosition(planet.barycenter)
    end

    return moons
end

function generateMoons()
    for _, planet in ipairs(game.play.planets) do
        planet.moons = generateMoonsForPlanet(planet)
    end
end


-- [/TQ-Bundler: src.generators.moons]

-- [TQ-Bundler: src.generators.comets]

-- ==========================================
-- COMETS
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
    BLUE_DARK,
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

function generateCometCount()
    return math.random(COMET_NUM_MIN, COMET_NUM_MAX)
end

function randomCometSpawnPosition()
    local padding      = X_PADDING + Y_PADDING
    local max_attempts = 80

    for attempt = 1, max_attempts do
        local x = math.random(padding, MAP_PIXELS_W - 1 - padding)
        local y = math.random(padding, MAP_PIXELS_H - 1 - padding)

        if canSpawnCometAtPosition(x, y) then
            return {
                x = x,
                y = y,
            }
        end
    end

    -- Fallback if no clear position is found.
    return {
        x = math.random(padding, MAP_PIXELS_W - 1 - padding),
        y = math.random(padding, MAP_PIXELS_H - 1 - padding),
    }
end

function canSpawnCometAtPosition(x, y)
    local padding = 80

    if game.play.player and game.play.player.position then
        if objectsTooClose(
                x,
                y,
                8,
                game.play.player.position.x,
                game.play.player.position.y,
                game.play.player.radius or 8,
                padding
            ) then
            return false
        end
    end

    if game.play.star and game.play.star.position then
        if objectsTooClose(
                x,
                y,
                8,
                game.play.star.position.x,
                game.play.star.position.y,
                game.play.star.radius or 8,
                padding
            ) then
            return false
        end
    end

    if game.play.planets then
        for _, planet in ipairs(game.play.planets) do
            if objectsTooClose(
                    x,
                    y,
                    8,
                    planet.position.x,
                    planet.position.y,
                    planet.radius or 8,
                    padding
                ) then
                return false
            end
        end
    end

    return true
end

function generateCometName(index)
    return "Comet-" .. tostring(index)
end

function generateComet(index)
    local pos = randomCometSpawnPosition()

    return Comet:new({
        name = generateCometName(index),
        x = pos.x,
        y = pos.y,
    })
end

function generateComets()
    local comets = {}
    local comet_count = generateCometCount()

    game.play.comet_count = comet_count

    for i = 1, comet_count do
        table.insert(comets, generateComet(i))
    end

    game.play.comets = comets
end

function respawnComet(index)
    game.play.comets[index] = generateComet(index)
end

function maintainCometCount()
    if not game.play.comets then
        game.play.comets = {}
    end

    local target_count = game.play.comet_count or COMET_NUM_MIN

    if target_count < COMET_NUM_MIN or target_count > COMET_NUM_MAX then
        target_count = generateCometCount()
        game.play.comet_count = target_count
    end

    -- Replace comets only when they are truly finished.
    for i = #game.play.comets, 1, -1 do
        local comet = game.play.comets[i]

        if not comet or comet:isFinished() or comet:isOffMap() then
            game.play.comets[i] = generateComet(i)
        end
    end

    while #game.play.comets < target_count do
        table.insert(game.play.comets, generateComet(#game.play.comets + 1))
    end

    while #game.play.comets > target_count do
        table.remove(game.play.comets)
    end
end


-- [/TQ-Bundler: src.generators.comets]

-- [TQ-Bundler: src.generators.asteroids]

-- ==========================================
-- ASTEROIDS
-- ==========================================

local ASTEROID_MIN_MASS           = 5
local ASTEROID_MAX_MASS           = 300
local ASTEROID_RADIUS_MIN         = 6
local ASTEROID_RADIUS_MAX         = 10
local ASTEROID_SPEED_MIN          = 0.05
local ASTEROID_SPEED_MAX          = 0.45
local ASTEROID_ROTATION_MAX       = 0.025
local ASTEROID_RADIUS_MINUS       = 6
local ASTEROID_RADIUS_PLUS        = 4
local ASTEROID_VERTICES_MIN       = 7
local ASTEROID_VERTICES_MAX       = 12
local ASTEROID_NUM_MIN            = 5
local ASTEROID_NUM_MAX            = 15
local ASTEROID_MAX_FRAGMENT_SCALE = 4

local ASTEROID_COLORS = {
    GRAY_LITE,
    GRAY_MED,
    GRAY_DARK,
}

function shuffledAsteroidColors()
    local colors = {}

    -- Copy ASTEROID_COLORS so we do not mutate the original.
    for i = 1, #ASTEROID_COLORS do
        colors[i] = ASTEROID_COLORS[i]
    end

    -- Fisher-Yates shuffle.
    for i = #colors, 2, -1 do
        local j = math.random(1, i)
        colors[i], colors[j] = colors[j], colors[i]
    end

    return {
        primary   = colors[1],
        secondary = colors[2],
        tertiary  = colors[3],
    }
end

function randomAsteroidName(index)
    return "Asteroid-" .. tostring(index)
end

function randomAsteroidParams(index)
    return {
        name = randomAsteroidName(index),

        x = randomFloat(0, MAP_PIXELS_W),
        y = randomFloat(0, MAP_PIXELS_H),

        speed = randomFloat(ASTEROID_SPEED_MIN, ASTEROID_SPEED_MAX),
        direction = randomFloat(0, math.pi * 2),

        radius = randomFloat(ASTEROID_RADIUS_MIN, ASTEROID_RADIUS_MAX),
        mass = randomFloat(ASTEROID_MIN_MASS, ASTEROID_MAX_MASS),

        color = randomChoice(ASTEROID_COLORS),

        num_vertices = math.random(ASTEROID_VERTICES_MIN, ASTEROID_VERTICES_MAX),

        rotation_speed = randomFloat(
            -ASTEROID_ROTATION_MAX,
            ASTEROID_ROTATION_MAX
        ),
    }
end

function spawnAsteroids(count)
    local asteroids = {}

    count = count or math.random(ASTEROID_NUM_MIN, ASTEROID_NUM_MAX)

    for i = 1, count do
        table.insert(asteroids, Asteroid:new(randomAsteroidParams(i)))
    end

    return asteroids
end


-- [/TQ-Bundler: src.generators.asteroids]

-- [TQ-Bundler: src.camera]

-- ==========================================
-- CAMERA FUNCTIONS
-- ==========================================

function getPlayerCurrentMapScreen()
    return {
        screen_x = math.floor(game.play.player.position.x / SCREEN_W),
        screen_y = math.floor(game.play.player.position.y / SCREEN_H)
    }
end

function setPlayerStartMapScreen(screen_x, screen_y)
    local player = game.play.player
    local camera = game.camera

    player.position.x = screen_x * SCREEN_W + SCREEN_W / 2
    player.position.y = screen_y * SCREEN_H + SCREEN_H / 2

    camera.x = screen_x * SCREEN_W
    camera.y = screen_y * SCREEN_H

    camera.x = clamp(camera.x, 0, MAP_PIXELS_W - SCREEN_W)
    camera.y = clamp(camera.y, 0, MAP_PIXELS_H - SCREEN_H)

    camera.target_x = camera.x
    camera.target_y = camera.y
end

function resetPlayerAndCamera()
    setPlayerStartMapScreen(0, 0)
end

function updateCamera(player, camera)
    local zoom = camera.zoom or 1

    local visible_w = SCREEN_W / zoom
    local visible_h = SCREEN_H / zoom

    -- Target camera position places player in center of visible world area.
    camera.target_x = player.position.x - visible_w / 2
    camera.target_y = player.position.y - visible_h / 2

    -- Clamp target so camera does not show outside the map.
    camera.target_x = clamp(camera.target_x, 0, MAP_PIXELS_W - visible_w)
    camera.target_y = clamp(camera.target_y, 0, MAP_PIXELS_H - visible_h)

    -- Smoothly move camera toward target.
    camera.x = lerp(camera.x, camera.target_x, camera.lerp)
    camera.y = lerp(camera.y, camera.target_y, camera.lerp)
end

-- ==========================================
-- CAMERA HELPERS
-- ==========================================

function clamp(value, min_value, max_value)
    if value < min_value then
        return min_value
    end

    if value > max_value then
        return max_value
    end

    return value
end

function lerp(a, b, t)
    return a + (b - a) * t
end

function worldToScreen(world_x, world_y)
    local zoom = game.camera.zoom or 1
    return
        (world_x - game.camera.x) * zoom,
        (world_y - game.camera.y) * zoom
end

function updateMouseWheelZoom()
    local mx, my, left, middle, right, scroll_x, scroll_y = mouse()
    local camera = game.camera

    if scroll_y > 0 then
        camera.zoom_index = camera.zoom_index + 1
    elseif scroll_y < 0 then
        camera.zoom_index = camera.zoom_index - 1
    end

    camera.zoom_index = clamp(camera.zoom_index, 1, #camera.zoom_levels)
    camera.zoom = camera.zoom_levels[camera.zoom_index]
end


-- [/TQ-Bundler: src.camera]

-- [TQ-Bundler: src.collisions]

-- ==========================================
-- COLLISION SYSTEM
-- ==========================================

local COLLISION_DAMAGE_SCALE = 1

function getCollisionRadius(obj)
    if not obj then
        return 0
    end

    return obj.collision_radius or obj.radius or 0
end

function objectsCollide(a, b)
    if not a or not b then
        return false
    end

    if a.dead or b.dead then
        return false
    end

    if not a.position or not b.position then
        return false
    end

    local ar = getCollisionRadius(a)
    local br = getCollisionRadius(b)

    return objectsTooClose(
        a.position.x,
        a.position.y,
        ar,
        b.position.x,
        b.position.y,
        br,
        0
    )
end

function getCollisionNormal(a, b)
    local dx = a.position.x - b.position.x
    local dy = a.position.y - b.position.y

    if dx == 0 and dy == 0 then
        local angle = randomFloat(0, math.pi * 2)
        return math.cos(angle), math.sin(angle)
    end

    local dist = math.sqrt(dx * dx + dy * dy)

    return dx / dist, dy / dist
end

function separateCollisionObjects(a, b)
    if not a or not b then
        return
    end

    if not a.position or not b.position then
        return
    end

    local ar = getCollisionRadius(a)
    local br = getCollisionRadius(b)

    local dx = a.position.x - b.position.x
    local dy = a.position.y - b.position.y
    local dist_sq = dx * dx + dy * dy

    if dist_sq <= 0 then
        local angle = randomFloat(0, math.pi * 2)
        dx = math.cos(angle)
        dy = math.sin(angle)
        dist_sq = 1
    end

    local dist = math.sqrt(dist_sq)
    local min_dist = ar + br

    if dist >= min_dist then
        return
    end

    local overlap = min_dist - dist
    local nx = dx / dist
    local ny = dy / dist

    -- If both are movable, split the push.
    a.position.x = a.position.x + nx * overlap * 0.5
    a.position.y = a.position.y + ny * overlap * 0.5

    b.position.x = b.position.x - nx * overlap * 0.5
    b.position.y = b.position.y - ny * overlap * 0.5
end

function deflectObject(obj, normal_x, normal_y)
    if not obj or obj.dead then
        return
    end

    if not obj.velocity then
        return
    end

    local speed = obj.velocity.speed or 0

    -- If object is stationary, give it a tiny bump away from the collision.
    if speed <= 0 then
        obj.velocity.speed = 0.1
        obj.velocity.direction = math.atan(normal_y, normal_x)
        return
    end

    local vx = math.cos(obj.velocity.direction) * speed
    local vy = math.sin(obj.velocity.direction) * speed

    -- Reflect velocity across collision normal.
    local dot = vx * normal_x + vy * normal_y

    local reflected_x = vx - 2 * dot * normal_x
    local reflected_y = vy - 2 * dot * normal_y

    local elasticity = obj.elasticity or 0.75

    reflected_x = reflected_x * elasticity
    reflected_y = reflected_y * elasticity

    local new_speed = math.sqrt(reflected_x * reflected_x + reflected_y * reflected_y)

    obj.velocity.speed = new_speed
    obj.velocity.direction = math.atan(reflected_y, reflected_x)
end

function deflectCollisionPair(a, b)
    separateCollisionObjects(a, b)

    local nx, ny = getCollisionNormal(a, b)

    -- a gets pushed along the normal.
    deflectObject(a, nx, ny)

    -- b gets pushed opposite the normal.
    deflectObject(b, -nx, -ny)
end

--[[
    Now we're checking against large bodies. If the moving object hits a star,
    planet, or moon, it's gone.
--]]
-- If the object hits a star, poof! it's gone.
function checkObjectAgainstStar(obj, star)
    if not obj or not star then
        return
    end

    if obj.dead then
        return
    end

    if objectsCollide(obj, star) then
        applyCollisionDamage(obj, star)
    end
end

function checkObjectAgainstPlanet(obj, planet)
    if not obj or not planet then
        return
    end

    if obj.dead then
        return
    end

    if objectsCollide(obj, planet) then
        applyCollisionDamage(obj, planet)
        return
    end

    if planet.moons then
        for _, moon in ipairs(planet.moons) do
            if objectsCollide(obj, moon) then
                applyCollisionDamage(obj, moon)
                return
            end
        end
    end
end

function checkObjectAgainstLargeBodies(obj)
    if not obj or obj.dead then
        return
    end

    checkObjectAgainstStar(obj, game.play.star)

    if obj.dead then
        return
    end

    for _, planet in ipairs(game.play.planets or {}) do
        checkObjectAgainstPlanet(obj, planet)

        if obj.dead then
            return
        end
    end
end

function getDynamicCollisionObjects()
    local objects = {}

    if game.play.player and not game.play.player.dead then
        table.insert(objects, game.play.player)
    end

    for _, comet in ipairs(game.play.comets or {}) do
        if comet and not comet.dead then
            table.insert(objects, comet)
        end
    end

    for _, asteroid in ipairs(game.play.asteroids or {}) do
        if asteroid and not asteroid.dead then
            table.insert(objects, asteroid)
        end
    end

    return objects
end

function handleDynamicCollision(a, b)
    if not a or not b then
        return
    end

    if a.dead or b.dead then
        return
    end

    if not objectsCollide(a, b) then
        return
    end

    -- Calculate damage before deflection changes velocity.
    local damage_to_b = 0
    local damage_to_a = 0

    if a.induceDamage then
        damage_to_b = a:induceDamage(b)
    end

    if b.induceDamage then
        damage_to_a = b:induceDamage(a)
    end

    -- Bounce/separate surviving dynamic objects.
    deflectCollisionPair(a, b)

    -- Apply damage after deflection so killed objects can still use the
    -- pre-collision damage values.
    if b.takeDamage then
        b:takeDamage(damage_to_b, a)
    end

    if a.takeDamage then
        a:takeDamage(damage_to_a, b)
    end
end

function checkDynamicObjectCollisions(objects)
    local count = #objects

    for i = 1, count - 1 do
        local a = objects[i]

        if a and not a.dead then
            for j = i + 1, count do
                local b = objects[j]

                if b and not b.dead then
                    handleDynamicCollision(a, b)
                end
            end
        end
    end
end

function updateCollisions()
    local objects = getDynamicCollisionObjects()

    -- First: star/planet/moon collisions.
    for _, obj in ipairs(objects) do
        checkObjectAgainstLargeBodies(obj)
    end

    -- Second: dynamic object collisions.
    --
    -- Use the original snapshot so fragments spawned this frame do not also
    -- collide immediately in the same frame.
    checkDynamicObjectCollisions(objects)
end

function applyCollisionDamage(a, b)
    if not a or not b then
        return
    end

    if a.dead or b.dead then
        return
    end

    local damage_to_b = 0
    local damage_to_a = 0

    if a.induceDamage then
        damage_to_b = a:induceDamage(b)
    end

    if b.induceDamage then
        damage_to_a = b:induceDamage(a)
    end

    if b.takeDamage then
        b:takeDamage(damage_to_b, a)
    end

    if a.takeDamage then
        a:takeDamage(damage_to_a, b)
    end
end


-- [/TQ-Bundler: src.collisions]

-- [TQ-Bundler: src.polygons]

-- ==========================================
-- POLYGON FUNCTIONS
-- ==========================================

function polygonSignedArea(points)
    local area = 0

    for i = 1, #points do
        local j = i + 1
        if j > #points then
            j = 1
        end

        area = area + points[i].x * points[j].y - points[j].x * points[i].y
    end

    return area / 2
end

function polygonIsClockwise(points)
    return polygonSignedArea(points) < 0
end

function pointInTriangle(p, a, b, c)
    local function sign(p1, p2, p3)
        return (p1.x - p3.x) * (p2.y - p3.y) -
            (p2.x - p3.x) * (p1.y - p3.y)
    end

    local d1 = sign(p, a, b)
    local d2 = sign(p, b, c)
    local d3 = sign(p, c, a)

    local has_neg = d1 < 0 or d2 < 0 or d3 < 0
    local has_pos = d1 > 0 or d2 > 0 or d3 > 0

    return not (has_neg and has_pos)
end

function polygonVertexIsConvex(prev, current, next, clockwise)
    local cross =
        (current.x - prev.x) * (next.y - current.y) -
        (current.y - prev.y) * (next.x - current.x)

    if clockwise then
        return cross < 0
    else
        return cross > 0
    end
end

function removeDuplicateClosingPoint(points)
    local result = {}

    for i, p in ipairs(points) do
        result[#result + 1] = {
            x = p.x,
            y = p.y,
        }
    end

    if #result >= 2 then
        local first = result[1]
        local last = result[#result]

        if first.x == last.x and first.y == last.y then
            table.remove(result, #result)
        end
    end

    return result
end

function triangulatePolygon(points)
    local polygon = removeDuplicateClosingPoint(points)
    local triangles = {}

    if #polygon < 3 then
        return triangles
    end

    if #polygon == 3 then
        triangles[#triangles + 1] = {
            polygon[1],
            polygon[2],
            polygon[3],
        }
        return triangles
    end

    local clockwise = polygonIsClockwise(polygon)

    -- Build index list so we can remove ears without destroying original points.
    local indices = {}

    for i = 1, #polygon do
        indices[#indices + 1] = i
    end

    local guard = 0
    local max_guard = #polygon * #polygon

    while #indices > 3 and guard < max_guard do
        guard = guard + 1

        local ear_found = false

        for i = 1, #indices do
            local prev_i = i - 1
            local next_i = i + 1

            if prev_i < 1 then
                prev_i = #indices
            end

            if next_i > #indices then
                next_i = 1
            end

            local prev_index = indices[prev_i]
            local curr_index = indices[i]
            local next_index = indices[next_i]

            local prev_point = polygon[prev_index]
            local curr_point = polygon[curr_index]
            local next_point = polygon[next_index]

            if polygonVertexIsConvex(prev_point, curr_point, next_point, clockwise) then
                local contains_point = false

                for j = 1, #indices do
                    local test_index = indices[j]

                    if test_index ~= prev_index and
                        test_index ~= curr_index and
                        test_index ~= next_index then
                        local test_point = polygon[test_index]

                        if pointInTriangle(test_point, prev_point, curr_point, next_point) then
                            contains_point = true
                            break
                        end
                    end
                end

                if not contains_point then
                    triangles[#triangles + 1] = {
                        prev_point,
                        curr_point,
                        next_point,
                    }

                    table.remove(indices, i)
                    ear_found = true
                    break
                end
            end
        end

        -- If no ear was found, the polygon may be self-intersecting,
        -- degenerate, or have duplicate/collinear points causing trouble.
        if not ear_found then
            break
        end
    end

    if #indices == 3 then
        triangles[#triangles + 1] = {
            polygon[indices[1]],
            polygon[indices[2]],
            polygon[indices[3]],
        }
    end

    return triangles
end

function drawFilledPolygon(points, color)
    local triangles = triangulatePolygon(points)

    for _, triangle in ipairs(triangles) do
        local a = triangle[1]
        local b = triangle[2]
        local c = triangle[3]

        tri(
            a.x, a.y,
            b.x, b.y,
            c.x, c.y,
            color
        )
    end
end

function drawPolygonOutline(points, color)
    if #points < 2 then
        return
    end

    for i = 2, #points do
        line(
            points[i - 1].x,
            points[i - 1].y,
            points[i].x,
            points[i].y,
            color
        )
    end

    local first = points[1]
    local last = points[#points]

    if first.x ~= last.x or first.y ~= last.y then
        line(
            last.x,
            last.y,
            first.x,
            first.y,
            color
        )
    end
end

-- [/TQ-Bundler: src.polygons]

-- [TQ-Bundler: src.game_state]

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
        player      = {},
        star        = {},
        planets     = {},
        comets      = {},
        asteroids   = {},
        comet_count = 0,
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

        game.play.player    = generatePlayer()
        game.play.star      = generateStar()
        game.play.planets   = generatePlanets()
        game.play.asteroids = spawnAsteroids()

        generateMoons()
        generateComets()

        resetPlayerAndCamera()
    end
end


-- [/TQ-Bundler: src.game_state]

-- [TQ-Bundler: src.helpers]

-- ==========================================
-- HELPERS
-- ==========================================

function getOrDefault(value, default)
    if value == nil then
        return default
    end
    return value
end

-- ==========================================
-- RANDOMIZATION HELPERS
-- ==========================================

function randomFloat(min_value, max_value)
    return min_value + math.random() * (max_value - min_value)
end

function randomChoice(list)
    return list[math.random(1, #list)]
end

-- ==========================================
-- "DISTANCE" HELPERS
-- ==========================================

function distanceSquared(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1

    return dx * dx + dy * dy
end

function objectsTooClose(a_x, a_y, a_radius, b_x, b_y, b_radius, padding)
    padding = padding or 0

    local min_distance = a_radius + b_radius + padding

    return distanceSquared(a_x, a_y, b_x, b_y) < min_distance * min_distance
end

-- ==========================================
-- DRAWING HELPERS
-- ==========================================

function drawCenteredText(text, y, color, fixed, scale, smallfont, shadow_color)
    if fixed == nil then
        fixed = false
    end
    if scale == nil then
        scale = 1
    end
    if smallfont == nil then
        smallfont = false
    end
    if shadow_color == nil then
        shadow_color = -1
    end
    local width = print(text, 0, -50, color, fixed, scale, smallfont)

    if shadow_color >= 0 then
        print(text, (EDGE_X_RIGHT - width) / 2 + 1, y + 1, shadow_color, fixed, scale, smallfont)
    end
    print(text, (EDGE_X_RIGHT - width) / 2, y, color, fixed, scale, smallfont)
end

function drawOverlayBox(text)
    local boxW = 120
    local boxH = 40
    local boxX = (EDGE_X_RIGHT - boxW) / 2
    local boxY = (EDGE_Y_BOTTOM - boxH) / 2

    -- Draw box background
    rect(boxX, boxY, boxW, boxH, 0)
    rectb(boxX, boxY, boxW, boxH, 12)

    -- Draw text
    drawCenteredText(text, boxY + 16, 12)
end


-- [/TQ-Bundler: src.helpers]

-- [TQ-Bundler: src.states.start]

-- ==========================================
-- STATE: START (Main Menu)
-- ==========================================

function inputStart()
    -- Menu navigation
    if btnp(BTN_P1_UP) then
        game.menu.selected = game.menu.selected - 1
        if game.menu.selected < 1 then
            game.menu.selected = #game.menu.options
        end
    end

    if btnp(BTN_P1_DOWN) or btnp(BTN_P1_SELECT) then
        game.menu.selected = game.menu.selected + 1
        if game.menu.selected > #game.menu.options then
            game.menu.selected = 1
        end
    end

    -- Menu selection
    if btnp(BTN_P1_A) or btnp(BTN_P1_START) then
        local selected = game.menu.selected
        if selected == 1 then
            changeState(STATE.READY)
        elseif selected == 2 then
            changeState(STATE.OPTIONS)
        elseif selected == 3 then
            changeState(STATE.HIGHSCORES)
        end
    end
end

function updateStart()

end

function drawStart()
    cls(BLACK)

    drawCenteredText("KEPLER-9999", EDGE_Y_TOP + Y_PADDING, ORANGE, nil, 3, nil, YELLOW)

    -- Menu options
    local start_y = 60
    local spacing = 2 * X_PADDING

    for i, option in ipairs(game.menu.options) do
        local y = start_y + (i - 1) * spacing
        local color = (i == game.menu.selected) and YELLOW or WHITE

        -- Draw selector
        if i == game.menu.selected then
            local textWidth = print(option, 0, -10)
            local x = (EDGE_X_RIGHT - textWidth) / 2
            print(">", x - 10 + 1, y + 1, GRAY_MED) -- the shadow
            print(">", x - 10, y, WHITE)
        end

        -- drawCenteredText(option, y, color)
        drawCenteredText(option, y, color, nil, nil, nil, GRAY_MED)
    end

    drawCenteredText("Press Z to select options", EDGE_Y_BOTTOM - Y_PADDING, WHITE, false, 1, true, GRAY_MED)
end


-- [/TQ-Bundler: src.states.start]

-- [TQ-Bundler: src.states.options]

-- ==========================================
-- STATE: OPTIONS
-- ==========================================

function applyAllOptions()
    for _, item in ipairs(game.options.items) do
        if item.apply and item.values then
            item.apply(item.current)
        end
    end
end

function inputOptions()
    -- Navigate up/down through menu items
    if btnp(BTN_P1_UP) then
        game.options.selected = game.options.selected - 1
        if game.options.selected < 1 then
            game.options.selected = #game.options.items
        end
    end

    if btnp(BTN_P1_DOWN) then
        game.options.selected = game.options.selected + 1
        if game.options.selected > #game.options.items then
            game.options.selected = 1
        end
    end

    local item = game.options.items[game.options.selected]

    -- If item has values, left/right cycles through them
    if item.values then
        if btnp(BTN_P1_LEFT) then
            item.current = item.current - 1
            if item.current < 1 then
                item.current = #item.values
            end
            if item.apply then
                item.apply(item.current)
            end
        end

        if btnp(BTN_P1_RIGHT) then
            item.current = item.current + 1
            if item.current > #item.values then
                item.current = 1
            end
            if item.apply then
                item.apply(item.current)
            end
        end
    end

    -- A button activates items (for "Back" or items without values)
    if btnp(BTN_P1_A) then
        if item.values == nil and item.apply then
            -- Action item like "Back"
            item.apply()
        end
    end

    -- B button always goes back
    if btnp(BTN_P1_B) then
        changeState(STATE.START)
    end
end

function updateOptions()

end

function drawOptions()
    cls(BLACK)

    -- Title
    drawCenteredText("OPTIONS", EDGE_Y_TOP + Y_PADDING, ORANGE, nil, 3, nil, YELLOW)

    -- Menu items
    local start_y = 50
    local spacing = 2 * Y_PADDING

    for i, item in ipairs(game.options.items) do
        local y = start_y + (i - 1) * spacing
        local is_selected = (i == game.options.selected)
        local name_color = is_selected and YELLOW or WHITE

        -- Draw selector arrow
        if is_selected then
            print(">", X_PADDING + 1, y + 1, BLACK)
            print(">", X_PADDING, y, WHITE)
        end

        -- Draw item name
        local name_x = X_PADDING + 12
        print(item.name, name_x + 1, y + 1, BLACK)
        print(item.name, name_x, y, name_color)

        -- Draw value (if it has one)
        if item.values then
            local value_text = "< " .. item.values[item.current] .. " >"
            local value_x = EDGE_X_RIGHT - X_PADDING - print(value_text, 0, -50)
            local value_color = is_selected and CYAN or GRAY_LITE

            print(value_text, value_x + 1, y + 1, BLACK)
            print(value_text, value_x, y, value_color)
        end
    end

    -- Instructions
    local inst_y = EDGE_Y_BOTTOM - 2 * Y_PADDING
    drawCenteredText("UP/DOWN: Select  LEFT/RIGHT: Change", inst_y, WHITE, false, 1, true, GRAY_MED)
    drawCenteredText("Z: Confirm  X: Back", inst_y + Y_PADDING, WHITE, false, 1, true, GRAY_MED)
end


-- [/TQ-Bundler: src.states.options]

-- [TQ-Bundler: src.states.highscores]

-- ==========================================
-- STATE: HIGH SCORES
-- ==========================================

-- Persistent memory has 255 slots.
MAX_HIGH_SCORES     = 19
PMEM_CHUNK_ELEMENTS = 4

-- We'll store our high scores in this table.
lines = {}

-- ==========================================
-- HIGH SCORE HELPERS
-- ==========================================

-- function loadHighScores()
--     game.high_scores = {}

--     for idx = 0, MAX_HIGH_SCORES do
--         local base = idx * PMEM_CHUNK_ELEMENTS
--         local date = pmem(base + 0)
--         if date ~= 0 then
--             game.high_scores[base] = {
--                 date  = date,
--                 diff  = pmem(base + 1),
--                 level = pmem(base + 2),
--                 score = pmem(base + 3),
--             }
--         end
--     end
-- end

-- function sortHighScores()
--     local list = {}

--     for _, d in pairs(game.high_scores) do
--         if d and d.score and d.score > 0 then
--             list[#list + 1] = d
--         end
--     end

--     table.sort(list, function(a, b)
--         if a.score ~= b.score then
--             return a.score > b.score
--         end

--         if a.diff ~= b.diff then
--             return a.diff > b.diff
--         end

--         if a.level ~= b.level then
--             return a.level > b.level
--         end

--         return a.date > b.date
--     end)

--     game.high_scores = {}

--     for i = 1, math.min(#list, MAX_HIGH_SCORES + 1) do
--         game.high_scores[(i - 1) * PMEM_CHUNK_ELEMENTS] = list[i]
--     end
-- end

-- function saveCurrentScore()
--     loadHighScores()

--     local list = {}

--     -- Pull saved scores into a list.
--     for idx = 0, MAX_HIGH_SCORES do
--         local base = idx * PMEM_CHUNK_ELEMENTS
--         local d = game.high_scores[base]

--         if d then
--             list[#list + 1] = d
--         end
--     end

--     -- Add current result.
--     list[#list + 1] = {
--         date  = game.play.date,
--         diff  = game.play.diff,
--         level = game.play.level,
--         score = game.play.score,
--     }

--     -- Put list back into game.high_scores so sortHighScores() can sort it.
--     game.high_scores = {}

--     for i = 1, #list do
--         game.high_scores[(i - 1) * PMEM_CHUNK_ELEMENTS] = list[i]
--     end

--     sortHighScores()

--     -- Clear pmem.
--     for i = 0, 255 do
--         pmem(i, 0)
--     end

--     -- Save compacted/sorted high scores.
--     for idx = 0, MAX_HIGH_SCORES do
--         local base = idx * PMEM_CHUNK_ELEMENTS
--         local d = game.high_scores[base]

--         if d then
--             pmem(base + 0, d.date)
--             pmem(base + 1, d.diff)
--             pmem(base + 2, d.level)
--             pmem(base + 3, d.score)
--         end
--     end
-- end

-- function difficultyToString(diff)
--     if diff == 3 then
--         return "Hard"
--     elseif diff == 2 then
--         return "Medium"
--     elseif diff == 1 then
--         return "Easy"
--     end

--     return "?"
-- end

-- function buildLines()
--     lines = {}

--     local score_count = 1
--     for idx = 0, MAX_HIGH_SCORES do
--         local k = idx * PMEM_CHUNK_ELEMENTS
--         local d = game.high_scores[k]

--         if d then
--             local dt_obj = unix_to_greg_utc(d.date)
--             local dt_str = convert_datetime_obj_to_string(dt_obj)
--             local diff_str = difficultyToString(d.diff)

--             table.insert(
--                 lines,
--                 string.format("%2d", score_count) .. ". " ..
--                 dt_str ..
--                 "  " .. string.format("%7d", d.score) ..
--                 "  L" .. string.format("%02d", d.level) ..
--                 "  " .. diff_str
--             )
--             score_count = score_count + 1
--         end
--     end
-- end

-- ==========================================
-- MAIN HIGH SCORE FUNCTIONS
-- ==========================================

function inputHighScores()
    if btnp(BTN_P1_A) or btnp(BTN_P1_B) then
        changeState(STATE.START)
    end
end

function updateHighScores()

end

function drawHighScores()
    cls(BLACK)

    -- -- LAYOUT
    -- local header_y = EDGE_Y_TOP + Y_PADDING
    -- local line_h = FIXED_CHAR_HEIGHT + 1
    -- local view_top = header_y + FIXED_CHAR_HEIGHT + 2 * Y_PADDING
    -- local view_bottom = EDGE_Y_BOTTOM - 2 * Y_PADDING
    -- local visible_lines = math.max(1, math.floor((view_bottom - view_top) / line_h))

    -- -- INPUT
    -- local max_scroll = math.max(0, #lines - visible_lines)

    -- -- keyboard (hold+repeat)
    -- if btnp(BTN_P1_UP, 15, 3) then
    --     scroll = scroll - 1
    -- end
    -- if btnp(BTN_P1_DOWN, 15, 3) then
    --     scroll = scroll + 1
    -- end

    -- -- clamp
    -- scroll = math.max(0, math.min(max_scroll, scroll))

    drawCenteredText("HIGH SCORES", EDGE_Y_TOP + Y_PADDING, ORANGE, nil, 3, nil, YELLOW)

    -- -- draw visible slice
    -- for i = 0, visible_lines - 1 do
    --     local line = lines[scroll + 1 + i] -- Lua arrays are 1-based
    --     if not line then break end
    --     local y = view_top + i * line_h
    --     print(line, X_PADDING + 1, y + 1, GRAY_MED, true) -- the shadow
    --     print(line, X_PADDING, y, WHITE, true)
    -- end

    -- -- Small scrollbar indicator
    -- if max_scroll > 0 then
    --     local bar_x = EDGE_X_RIGHT - 4
    --     rect(bar_x, view_top, 2, view_bottom - view_top, GRAY_DARK)
    --     local thumb_h = math.max(4, math.floor((view_bottom - view_top) * (visible_lines / #lines)))
    --     local thumb_y = view_top + math.floor((view_bottom - view_top - thumb_h) * (scroll / max_scroll))
    --     rect(bar_x, thumb_y, 2, thumb_h, GREEN_LITE)
    -- end

    -- Instructions
    drawCenteredText("Press Z to Return", EDGE_Y_BOTTOM - Y_PADDING, WHITE, false, 1, true, GRAY_MED)
end


-- [/TQ-Bundler: src.states.highscores]

-- [TQ-Bundler: src.states.ready]

-- ==========================================
-- STATE: READY
-- ==========================================

function inputReady()

end

function updateReady()
    if btnp(BTN_P1_A) or btnp(BTN_P1_START) then
        changeState(STATE.PLAY)
    end

    if btnp(BTN_P1_B) then
        changeState(STATE.START)
    end
end

function drawReady()
    -- Draw the game state (paused/initial state)
    drawGame()

    -- Draw overlay
    drawOverlayBox("READY?")
    drawCenteredText("Press Z to Begin", EDGE_Y_BOTTOM - Y_PADDING, WHITE, false, 1, true, GRAY_MED)
end


-- [/TQ-Bundler: src.states.ready]

-- [TQ-Bundler: src.states.play]

-- ==========================================
-- STATE: PLAY
-- ==========================================

function inputPlay()
    if btnp(BTN_P1_START) then
        changeState(STATE.PAUSE)
    end

    updateMouseWheelZoom()

    -- Push all button monitoring off on the player class.
    game.play.player:input()
end

function updatePlay()
    if game.play.star then
        game.play.star:update()
    end

    for _, planet in ipairs(game.play.planets) do
        planet:update()
    end

    if game.play.comets then
        for _, comet in ipairs(game.play.comets) do
            comet:update()
        end
    end
    maintainCometCount()

    for i = #game.play.asteroids, 1, -1 do
        local asteroid = game.play.asteroids[i]

        asteroid:update()

        if (asteroid:isFinished() or asteroid:isOffMap()) and not asteroid:hasLiveParticles() then
            table.remove(game.play.asteroids, i)
        end
    end

    local player = game.play.player
    player:move()
    updateCamera(player, game.camera)

    -- If ship is dead, count down and respawn or gameover
    if player.dead then
        player.mortality.respawn_timer = player.mortality.respawn_timer - 1

        if player.mortality.respawn_timer <= 0 then
            if player.mortality.num_lives <= 0 then
                changeState(STATE.GAMEOVER)
                return

            -- We'll figure this out later
            -- else
            --     player:respawn()
            end
        end
    else
        updateCollisions()
    end

    -- tick invulnerability
    if player.mortality.invulnerable > 0 then
        player.mortality.invulnerable = player.mortality.invulnerable - 1
    end

    -- FOR TESTING
    if DEBUG then
        if player:everyNTicks(60) then
            local mode = math.random(1, 3)
            local plus_minus = math.random(0, 1) == 1
            if mode == 1 then
                if plus_minus then
                    if player:pickupCargo(mode * 10) then
                        trace("Picked up " .. tostring(mode * 10) .. "kg of cargo")
                    end
                else
                    if player:deliverCargo(mode * 10) then
                        trace("Delivered " .. tostring(mode * 10) .. "kg of cargo")
                    end
                end
            elseif mode == 2 then
                if plus_minus then
                    if player:pickupPassengers(mode) then
                        trace("Picked up " .. tostring(mode) .. " passengers")
                    end
                else
                    if player:deliverPassengers(mode) then
                        trace("Delivered " .. tostring(mode) .. " passengers")
                    end
                end
            elseif mode == 3 then
                if plus_minus then
                    if player:pickupSmuggledGoods(mode * 10) then
                        trace("Picked up " .. tostring(mode * 10) .. "kg of smuggled goods")
                    end
                else
                    if player:deliverSmuggledGoods(mode * 10) then
                        trace("Delivered " .. tostring(mode * 10) .. "kg of smuggled goods")
                    end
                end
            end
        end
    end
end


function drawStarMap()
    local camera = game.camera
    local zoom = camera.zoom or 1

    -- TIC-80 map() does not handle zooming out below 1x cleanly.
    -- For zoomed-out view, leave the background black.
    if zoom < 1 then
        return
    end

    -- Camera position in pixels.
    local cam_x = math.floor(camera.x)
    local cam_y = math.floor(camera.y)

    -- Convert pixel camera to tile camera.
    local tile_x = math.floor(cam_x / TILE_SIZE)
    local tile_y = math.floor(cam_y / TILE_SIZE)

    -- Pixel offset inside the first visible tile.
    local offset_x = (cam_x % TILE_SIZE) * zoom
    local offset_y = (cam_y % TILE_SIZE) * zoom

    local visible_tiles_w = math.ceil(SCREEN_W / (TILE_SIZE * zoom)) + 1
    local visible_tiles_h = math.ceil(SCREEN_H / (TILE_SIZE * zoom)) + 1

    -- Draw generated star map.
    map(
        tile_x,             -- map x/y in tiles
        tile_y,             -- map x/y in tiles
        visible_tiles_w,
        visible_tiles_h,
        -offset_x,          -- screen x/y in pixels
        -offset_y,          -- screen x/y in pixels
        -1,                 -- transparent color
        zoom
    )
end

function drawShipCargoHoldHud()
    local player             = game.play.player

    local cargo_fraction     = clamp(player:getCargoMassFraction(), 0, 1)
    local passenger_fraction = clamp(player:getPassengerMassFraction(), 0, 1)
    local smuggled_fraction  = clamp(player:getSmuggledMassFraction(), 0, 1)

    local total_fraction     = cargo_fraction + passenger_fraction + smuggled_fraction

    if total_fraction > 1 then
        cargo_fraction     = cargo_fraction / total_fraction
        passenger_fraction = passenger_fraction / total_fraction
        smuggled_fraction  = smuggled_fraction / total_fraction
        total_fraction     = 1
    end

    local label    = "C"

    -- Same width style as E/L/S bars.
    local bar_w    = print("C", -100, -100, WHITE, true, 1, true) + 1
    local bar_h    = 108
    local bar_x    = EDGE_X_LEFT + 3
    local bottom_y = EDGE_Y_BOTTOM - 8
    local bar_y    = bottom_y - bar_h

    -- Label.
    print(label, bar_x, bottom_y, GRAY_MED, true, 1, true)

    -- Border.
    rectb(bar_x, bar_y, bar_w - 1, bar_h - 1, WHITE)

    -- Empty background.
    rect( bar_x + 1, bar_y + 1, bar_w - 2, bar_h - 2, BLACK)

    local inner_x     = bar_x + 1
    local inner_y     = bar_y + 1
    local inner_w     = bar_w - 2
    local inner_h     = bar_h - 2

    local cargo_h     = math.floor(inner_h * cargo_fraction)
    local passenger_h = math.floor(inner_h * passenger_fraction)
    local smuggled_h  = math.floor(inner_h * smuggled_fraction)

    -- Fix possible rounding gap when completely full.
    local used_h      = cargo_h + passenger_h + smuggled_h
    if total_fraction >= 1 and used_h < inner_h then
        cargo_h = cargo_h + (inner_h - used_h)
    end

    -- Draw from bottom upward.
    local cursor_y = inner_y + inner_h

    -- Cargo at bottom.
    if cargo_h > 0 then
        cursor_y = cursor_y - cargo_h
        rect(inner_x, cursor_y, inner_w, cargo_h, GRAY_DARK)
    end

    -- Passengers above cargo.
    if passenger_h > 0 then
        cursor_y = cursor_y - passenger_h
        rect(inner_x, cursor_y, inner_w, passenger_h, GRAY_MED)
    end

    -- Smuggled goods above passengers.
    if smuggled_h > 0 then
        cursor_y = cursor_y - smuggled_h
        rect(inner_x, cursor_y, inner_w, smuggled_h, GRAY_LITE)
    end
end

function drawShipStatusHud()
    local player                = game.play.player

    local bars                  = {
        {
            label      = "V",
            color      = YELLOW,
            value      = player:getVelocityFraction(),
            multiplier = 9,
        },
        {
            label      = "E",
            color      = BLUE_LITE,
            value      = player:getEnergyFraction(),
            multiplier = player:getEnergyMultiplier(),
        },
        {
            label      = "L",
            color      = GREEN_MED,
            value      = player:getLifeSupportFraction(),
            multiplier = player:getLifeSupportMultiplier(),
        },
        {
            label      = "S",
            color      = RED,
            value      = player:getShieldFraction(),
            multiplier = player:getShieldMultiplier(),
        },
    }

    local bar_w                 = print("E", -100, -100, WHITE, true, 1, true) + 1
    local pixels_per_multiplier = 12

    -- Same baseline as drawShipCargoHoldHud().
    local bottom_y              = EDGE_Y_BOTTOM - 8

    -- M bar starts at EDGE_X_LEFT + 3.
    -- Status bars start one bar-width after M.
    local mass_bar_x            = EDGE_X_LEFT + 3
    local start_x               = mass_bar_x + bar_w

    for i, bar in ipairs(bars) do
        local bar_h  = pixels_per_multiplier * clamp(bar.multiplier, 1, 9)
        local bar_x  = start_x + (i - 1) * bar_w
        local bar_y  = bottom_y - bar_h
        local value  = clamp(bar.value, 0, 1)
        local fill_h = math.floor((bar_h - 2) * value)

        -- Label.
        print(bar.label, bar_x, bottom_y, bar.color, true, 1, true)

        -- Border.
        rectb(bar_x, bar_y, bar_w - 1, bar_h - 1, WHITE)

        -- Empty background.
        rect(bar_x + 1, bar_y + 1, bar_w - 2, bar_h - 2, BLACK)

        -- Fill from bottom upward.
        rect(bar_x + 1, bar_y + bar_h - 1 - fill_h, bar_w - 2, fill_h, bar.color)
    end
end

function drawGame()
    cls(BLACK)

    drawStarMap()

    if game.play.star then
        game.play.star:draw()
    end

    for _, planet in ipairs(game.play.planets) do
        planet:draw()
    end

    if game.play.comets then
        for _, comet in ipairs(game.play.comets) do
            comet:draw()
        end
    end

    for _, asteroid in ipairs(game.play.asteroids) do
        asteroid:draw()
    end

    local player = game.play.player
    player:draw()

    drawShipCargoHoldHud()
    drawShipStatusHud()
end

function drawPlay()
    drawGame()

    if DEBUG == true then
        drawDebugCameraInfo()
    end
end

-- For debug purposes...
function drawDebugCameraInfo()
    local player = game.play.player
    local camera = game.camera

    local screen_x = math.floor(player.position.x / SCREEN_W)
    local screen_y = math.floor(player.position.y / SCREEN_H)

    local debug_statements = {
        -- "Player X: " .. math.floor(player.position.x),
        -- "Player Y: " .. math.floor(player.position.y),
        -- "Player Vs: " .. string.format("%.3f", player.velocity.speed),
        -- "Player Vd: " .. string.format("%.3f", player.velocity.direction),
        -- "Camera X: " .. math.floor(camera.x),
        -- "Camera Y: " .. math.floor(camera.y),
        "MAP SCREEN: " .. screen_x .. "," .. screen_y,
        "Energy: " .. math.floor(player.engines.energy.cur) .. "/" .. player.engines.energy.max,
        "Cargo: " .. player:getCargoMass() .. "/" .. player:getCargoMassMax(),
        "Passengers: " .. player:getPassengerMass() .. "/" .. player:getPassengerMassMax(),
        "Smuggled: " .. player:getSmuggledMass() .. "/" .. player:getSmuggledMassMax(),
    }
    for index, debug_msg in ipairs(debug_statements) do
        local debug_color = BLUE_LITE
        if index == 3 or index == 4 then
            debug_color = CYAN
        elseif index == 5 or index == 6 then
            debug_color = WHITE
        elseif index > 6 then
            debug_color = YELLOW
        end
        local len = print(debug_msg, -10, -10, debug_color, true)
        print(
            debug_msg,
            EDGE_X_RIGHT - len,
            EDGE_Y_TOP + (index - 1) * Y_PADDING,
            debug_color,
            true
        )
    end
end


-- [/TQ-Bundler: src.states.play]

-- [TQ-Bundler: src.states.pause]

-- ==========================================
-- STATE: PAUSE
-- ==========================================

function inputPause()
    if btnp(BTN_P1_START) then
        changeState(STATE.PLAY)
    end
    if btnp(BTN_P1_SELECT) then
        changeState(STATE.GAMEOVER)
    end
end

function updatePause()

end

function drawPause()
    -- Draw the game state (frozen)
    drawGame()

    -- Draw overlay
    drawOverlayBox("PAUSED")
    drawCenteredText("Press 'START' (S) to Resume", EDGE_Y_BOTTOM - 2* Y_PADDING, WHITE, false, 1, true, GRAY_MED)
    drawCenteredText("Press 'SELECT' (A) to Quit", EDGE_Y_BOTTOM - Y_PADDING, WHITE, false, 1, true, GRAY_MED)
end


-- [/TQ-Bundler: src.states.pause]

-- [TQ-Bundler: src.states.gameover]

-- ==========================================
-- STATE: GAMEOVER
-- ==========================================

function inputGameover()
    if btnp(BTN_P1_A) or btnp(BTN_P1_B) then
        changeState(STATE.START)
    end
end

function updateGameover()

end

function drawGameover()
    drawGame()

    drawOverlayBox("GAME OVER")
    drawCenteredText("Press Z to Continue", EDGE_Y_BOTTOM - Y_PADDING, WHITE, false, 1, true, GRAY_MED)
end


-- [/TQ-Bundler: src.states.gameover]

-- [TQ-Bundler: src.state_machine]

-- ==========================================
-- STATE MACHINE
-- ==========================================

states = {
    [STATE.START] = {
        input  = inputStart,
        update = updateStart,
        draw = drawStart,
    },
    [STATE.OPTIONS] = {
        input  = inputOptions,
        update = updateOptions,
        draw = drawOptions,
    },
    [STATE.HIGHSCORES] = {
        input  = inputHighScores,
        update = updateHighScores,
        draw   = drawHighScores,
    },
    [STATE.READY] = {
        input  = inputReady,
        update = updateReady,
        draw = drawReady,
    },
    [STATE.PLAY] = {
        input  = inputPlay,
        update = updatePlay,
        draw = drawPlay,
    },
    [STATE.PAUSE] = {
        input  = inputPause,
        update = updatePause,
        draw = drawPause,
    },
    [STATE.GAMEOVER] = {
        input  = inputGameover,
        update = updateGameover,
        draw = drawGameover,
    },
}


-- [/TQ-Bundler: src.state_machine]

-- [TQ-Bundler: src.classes.KeplerObj]

-- ==========================================
-- KEPLEROBJ OBJECT
-- ==========================================

KeplerObj = {}
KeplerObj.__index = KeplerObj

function KeplerObj:new(params)
    params = params or {}
    local self = setmetatable({}, KeplerObj)

    self.name = params.name or "Kepler System Object"

    local colors = params.colors or {}
    self.colors  = {
        primary   = colors.primary   or BLUE_MED,
        secondary = colors.secondary or WHITE,
        tertiary  = colors.tertiary  or YELLOW,
    }
    self.color = self.colors.primary    -- In case it's a one-color object.

    self.mass   = params.mass or 100   -- (kg)
    self.radius = params.radius or 10  -- (m)

    self.position = {
        x = params.x or math.floor(EDGE_X_RIGHT / 2),
        y = params.y or math.floor(EDGE_Y_BOTTOM / 2)
    }
    self.velocity = {
        speed     = params.speed     or 0,
        direction = params.direction or 0,
    }
    self.acceleration   = params.acceleration   or 0.05
    self.deceleration   = params.deceleration   or 0.01
    self.rotation       = params.rotation       or 5
    self.rotation_speed = params.rotation_speed or 0.07

    self.max_mass  = params.max_mass  or 1    -- (kg)
    self.max_speed = params.max_speed or 1.0

    -- For deflections: 1.0 = perfectly elastic, <1.0 loses speed
    -- More massive bodies have a higher elasticity. Smaller things like ships
    -- have tiny elasticity.
    self.elasticity = params.elasticity or 1.0

    -- Lifecycle state.
    -- dead:     The object should no longer update position/velocity.
    -- exploded: The object's explosion has already been triggered.
    self.dead     = params.dead or false
    self.exploded = params.exploded or false

    self.timer = params.timer or 0

    return self
end

-- ==========================================
-- KEPLEROBJ GETTERS
-- ==========================================

function KeplerObj:getTimer()
    return self.timer
end

-- Returns true every N ticks
function KeplerObj:everyNTicks(n)
    return (self.timer % n) == 0
end

function KeplerObj:getVelocity()
    return self.velocity.speed
end

function KeplerObj:getVelocityFraction()
    return self:getVelocity() / self.max_speed
end

function KeplerObj:isFinished()
    return self.dead
end

-- ==========================================
-- KEPLEROBJ MATH
-- ==========================================

function KeplerObj:keepAngleInRange(angle)
    if angle < 0 then
        while angle < 0 do
            angle = angle + (2 * math.pi)
        end
    end
    if angle > (2 * math.pi) then
        while angle > (2 * math.pi) do
            angle = angle - (2 * math.pi)
        end
    end
    return angle
end

-- 'rotation' parameter is in radians.
function KeplerObj:rotatePoint(point, rotation)
    local rotated_x = (point.x * math.cos(rotation)) - (point.y * math.sin(rotation))
    local rotated_y = (point.y * math.cos(rotation)) + (point.x * math.sin(rotation))
    return { x = rotated_x, y = rotated_y }
end

function KeplerObj:getVectorComponents(vector)
    local xComp = vector.speed * math.cos(vector.direction)
    local yComp = vector.speed * math.sin(vector.direction)

    local components = {
        xComp = xComp,
        yComp = yComp
    }

    return components
end

function KeplerObj:addVectors(vector1, vector2)
    local v1Comp = self:getVectorComponents(vector1)
    local v2Comp = self:getVectorComponents(vector2)

    local resultantX = v1Comp.xComp + v2Comp.xComp
    local resultantY = v1Comp.yComp + v2Comp.yComp

    local resVector = self:compToVector(resultantX, resultantY)

    return resVector
end

function KeplerObj:compToVector(x, y)
    local magnitude = math.sqrt((x * x) + (y * y))
    local direction = math.atan(y, x)

    direction = self:keepAngleInRange(direction)

    local vector = {
        speed     = magnitude,
        direction = direction
    }

    return vector
end

function KeplerObj:movePointByVelocity(obj)
    if obj == nil then
        obj = self
    end

    -- Dead objects do not update position.
    if obj.dead then
        return {
            x = obj.position.x,
            y = obj.position.y,
        }
    end

    local components  = self:getVectorComponents(obj.velocity)
    local newPosition = {
        x = obj.position.x + components.xComp,
        y = obj.position.y + components.yComp
    }

    return newPosition
end

-- ==========================================
-- KEPLEROBJ PHYSICS
-- ==========================================

-- ==========================================
-- KEPLEROBJ COLLISION DAMAGE
-- ==========================================

function KeplerObj:induceDamage(obj)
    if not obj then
        return 0
    end

    if self.dead or obj.dead then
        return 0
    end

    if not self.position or not obj.position then
        return 0
    end

    if not self.velocity then
        return 0
    end

    local self_comp = self:getVectorComponents(
        self.velocity or { speed = 0, direction = 0 }
    )

    local self_vx = self_comp.xComp
    local self_vy = self_comp.yComp

    local obj_vx = 0
    local obj_vy = 0

    if obj.getVectorComponents then
        local obj_comp = obj:getVectorComponents(
            obj.velocity or { speed = 0, direction = 0 }
        )

        obj_vx = obj_comp.xComp
        obj_vy = obj_comp.yComp
    elseif obj.velocity then
        obj_vx = math.cos(obj.velocity.direction or 0) * (obj.velocity.speed or 0)
        obj_vy = math.sin(obj.velocity.direction or 0) * (obj.velocity.speed or 0)
    end

    local rel_vx = self_vx - obj_vx
    local rel_vy = self_vy - obj_vy

    -- getCollisionNormal(obj, self) points from self toward obj.
    local nx, ny = getCollisionNormal(obj, self)

    -- Only the velocity component going into the collision counts.
    local inbound_speed = rel_vx * nx + rel_vy * ny

    if inbound_speed <= 0 then
        return 0
    end

    local mass = self.mass or 0

    return 0.5 * mass * inbound_speed * inbound_speed * COLLISION_DAMAGE_SCALE
end

function KeplerObj:takeDamage(damage, other)
    damage = damage or 0

    if self.dead then
        return false
    end

    if damage <= 0 then
        return false
    end

    self.mass = (self.mass or 0) - damage

    if self.mass <= 0 then
        self.mass = 0
        self:kill()
        return true
    end

    return false
end


-- ==========================================
-- KEPLEROBJ INPUT
-- ==========================================

-- ==========================================
-- KEPLEROBJ UPDATE
-- ==========================================

function KeplerObj:updateTimer()
    self.timer = (self.timer + 1) % 36000
end

function KeplerObj:move()
    if self.dead then
        return
    end
end

-- ==========================================
-- KEPLEROBJ LIFECYCLE
-- ==========================================

function KeplerObj:kill()
    if self.dead then
        return
    end
    self.dead = true
    return self:explode()
end

function KeplerObj:explode()
    if self.exploded then
        return
    end
    self.exploded = true
    self:explosionEffect()
    return self.dead and self.exploded
end

function KeplerObj:explosionEffect()
    -- Empty stub.
    -- Child objects can override this to spawn particles, fragments, sounds, etc.
end

-- ==========================================
-- KEPLEROBJ DRAW
-- ==========================================

function KeplerObj:drawBody()

end

function KeplerObj:draw()
    self:drawBody()

    -- Anything else to draw, like particle effects?
end

-- [/TQ-Bundler: src.classes.KeplerObj]

-- [TQ-Bundler: src.classes.SpaceShip]

-- ==========================================
-- SPACESHIP OBJECT
-- ==========================================

SpaceShip = setmetatable({}, { __index = KeplerObj })
SpaceShip.__index = SpaceShip

function SpaceShip:new(params)
    params = params or {}
    local self = KeplerObj:new(params) -- build base fields
    setmetatable(self, SpaceShip)     -- make it a SpaceShip instance

    -- For regenerating the various attributes. Lower number means slower
    -- regeneration. These also act as a multiplier for the max values.
    self.engines = {
        energy = {
            cur = params.engines.energy.cur or 250,
            max = params.engines.energy.max or 250,
            mul = params.engines.energy.mul or 1,
            tik = params.engines.energy.tik or 20,
        },
        life_support = {
            cur = params.engines.life_support.cur or 100,
            max = params.engines.life_support.max or 100,
            mul = params.engines.life_support.mul or 1,
            tik = params.engines.life_support.tik or 3600,
        },
        shield = {
            cur = params.engines.shield.cur or 100,
            max = params.engines.shield.max or 100,
            mul = params.engines.shield.mul or 1,
            tik = params.engines.shield.tik or 60,
        },
    }

    -- Cargo/passenger holds. Everything is measured in kg and limited by the
    -- max_mass property.
    self.holds = {
        cargo = {
            cur = params.holds.cargo.cur or 0,   -- (kg)
            max = params.holds.cargo.max or 500, -- (kg)
        },
        passengers = {
            cur = params.holds.passengers.cur or 0,      -- (kg)
            max = params.holds.passengers.max or 6 * PASSENGER_TOTAL_MASS, -- (individuals in kg)
        },
        smuggled = {
            cur = params.holds.smuggled.cur or 0,   -- (kg)
            max = params.holds.smuggled.max or 100, -- (kg)
        },
    }

    self.mass       = params.mass       or 100   -- (kg)
    self.radius     = params.radius     or 10    -- (pixels)
    self.elasticity = params.elasticity or 0.5
    self.max_mass   = params.max_mass   or 1300  -- (kg)
    self.max_speed  = params.max_speed  or 2.5

    -- The default SpaceShip shape
    self.shape = params.shape or {
        { x = 8,  y = 0 },
        { x = -8, y = 6 },
        { x = -4, y = 0 },
        { x = -8, y = -6 },
        { x = 8,  y = 0 }
    }

    local deadstop = params.deadstop or {}
    self.deadstop  = {
        brake = deadstop.brake or 0.05, -- 0..1, higher = faster stop per frame
        snap  = deadstop.snap  or 0.02  -- below this speed, just snap to 0
    }

    self.mortality = {
        num_lives     = params.num_lives or 1,
        invulnerable  = 0,
        dead          = false,
        exploded      = false,
        respawn_timer = 0,
    }

    -- Particle Effects: all particles use the same simple particle tuning vars.
    self.particles  = {
        explosion = {
            colors = params.explosion_colors or {
                WHITE,
                YELLOW,
                ORANGE,
                RED,
                GRAY_LITE,
                GRAY_MED,
                GRAY_DARK,
            },
            params = {
                count_min    = 70,
                count_max    = 110,
                speed_min    = 0.8,
                speed_max    = 4.2,
                life_min     = 35,
                life_max     = 95,
                size_min     = 1,
                size_max     = 3,
                drag         = 0.975,
                spawn_radius = (self.radius or 10) * 1.6,
            },
            particles = {},
        },
        smoke = {
            colors = params.smoke_colors or {
                GRAY_DARK,
                GRAY_MED,
                GRAY_LITE,
            },
            params = {
                -- Spawn chance is calculated from life support fraction.
                spawn_chance_min = 0.04,
                spawn_chance_max = 0.65,
                count_min        = 1,
                count_max        = 2,
                speed_min        = 0.05,
                speed_max        = 0.45,
                life_min         = 32,
                life_max         = 90,
                size_min         = 1,
                size_max         = 3,
                drag             = 0.985,
                diffuse_speed    = 0.35,                -- Random outward diffusion.
                trail_strength   = 0.65,                -- smoke trails opposite current ship movement
                spawn_radius     = self.radius or 10,
            },
            particles = {},
        },
        spark = {
            colors = params.spark_colors or {
                YELLOW,
                ORANGE,
                RED,
                WHITE,
            },
            params = {
                count_min    = 6,
                count_max    = 14,
                speed_min    = 0.5,
                speed_max    = 2.2,
                life_min     = 8,
                life_max     = 22,
                size_min     = 1,
                size_max     = 1,
                drag         = 0.92,
                spawn_radius = self.radius or 10,
            },
            particles = {},
        },

        thrust = {
            colors = params.thrust_colors or {
                BLUE_LITE,
                CYAN,
                WHITE,
                ORANGE,
            },
            params = {
                count_min      = 1,
                count_max      = 3,
                speed_min      = 0.4,
                speed_max      = 1.4,
                life_min       = 8,
                life_max       = 18,
                size_min       = 1,
                size_max       = 2,
                drag           = 0.94,
                spread         = math.pi / 7,         -- Exhaust cone behind the ship.
                backend_offset = self.radius or 10,   -- Spawn just behind ship center.
                side_jitter    = 3,                   -- Slight side jitter so exhaust is not a single line.
            },
            particles = {},
        },
    }

    return self
end

-- ==========================================
-- SPACESHIP STATUS GETTERS
-- ==========================================

function SpaceShip:getEnergy()
    if self.engines.energy.cur < 0 then
        self.engines.energy.cur = 0
    end
    return self.engines.energy.cur
end

function SpaceShip:getEnergyFraction()
    return self:getEnergy() / self.engines.energy.max
end

function SpaceShip:getEnergyMultiplier()
    return self.engines.energy.mul
end

function SpaceShip:getLifeSupport()
    if self.engines.life_support.cur < 0 then
        self.engines.life_support.cur = 0
    end
    return self.engines.life_support.cur
end

function SpaceShip:getLifeSupportFraction()
    return self:getLifeSupport() / self.engines.life_support.max
end

function SpaceShip:getLifeSupportMultiplier()
    return self.engines.life_support.mul
end

function SpaceShip:getShield()
    if self.engines.shield.cur < 0 then
        self.engines.shield.cur = 0
    end
    return self.engines.shield.cur
end

function SpaceShip:getShieldFraction()
    return self:getShield() / self.engines.shield.max
end

function SpaceShip:getShieldMultiplier()
    return self.engines.shield.mul
end


function SpaceShip:getHoldMassMax()
    return self.holds.cargo.max + self.holds.passengers.max + self.holds.smuggled.max
end

function SpaceShip:getCargoMass()
    return self.holds.cargo.cur
end

function SpaceShip:getCargoMassMax()
    return self.holds.cargo.max
end

function SpaceShip:getCargoMassFraction()
    return self:getCargoMass() / self:getHoldMassMax()
end

function SpaceShip:getPassengerMass()
    return self.holds.passengers.cur
end

function SpaceShip:getPassengerMassMax()
    return self.holds.passengers.max
end
function SpaceShip:getPassengerMassFraction()
    return self:getPassengerMass() / self:getHoldMassMax()
end

function SpaceShip:getSmuggledMass()
    return self.holds.smuggled.cur
end

function SpaceShip:getSmuggledMassMax()
    return self.holds.smuggled.max
end

function SpaceShip:getSmuggledMassFraction()
    return self:getSmuggledMass() / self:getHoldMassMax()
end

function SpaceShip:getTotalMass()
    return self.mass + self:getCargoMass() + self:getPassengerMass() + self:getSmuggledMass()
end

function SpaceShip:getTotalMassFraction()
    return self:getTotalMass() / self.max_mass
end

-- ==========================================
-- SPACESHIP ENGINE MANAGEMENT
-- ==========================================

-- TODO:
-- 1. Whenever one of these values regenerates, it pulls from energy. Unless
--    energy regenerates, and that happens on its own.
-- 2. Whenever one of these values gets upgraded, the ship's mass increases.

function SpaceShip:modifyEngineMaxValue(type, upgrade)
    if type == nil then
        type = "energy"
    end
    if upgrade == nil then
        upgrade = false
    end

    local new_engine_max = nil
    if type == "energy" then
        local max_chunk = math.floor(self.engines.energy.max / self.engines.energy.mul)
        if upgrade then
            self.engines.energy.mul = self.engines.energy.mul + 1
        else
            self.engines.energy.mul = self.engines.energy.mul - 1
        end
        if self.engines.energy.mul > 9 then
            self.engines.energy.mul = 9
        elseif self.engines.energy.mul < 1 then
            self.engines.energy.mul = 1
        end
        self.engines.energy.max = max_chunk * self.engines.energy.mul
        new_engine_max = self.engines.energy.mul
    elseif type == "life_support" then
        local max_chunk = math.floor(self.engines.life_support.max / self.engines.life_support.mul)
        if upgrade then
            self.engines.life_support.mul = self.engines.life_support.mul + 1
        else
            self.engines.life_support.mul = self.engines.life_support.mul - 1
        end
        if self.engines.life_support.mul > 9 then
            self.engines.life_support.mul = 9
        elseif self.engines.life_support.mul < 1 then
            self.engines.life_support.mul = 1
        end
        self.engines.life_support.max = max_chunk * self.engines.life_support.mul
        new_engine_max = self.engines.life_support.mul
    elseif type == "shield" then
        local max_chunk = math.floor(self.engines.shield.max / self.engines.shield.mul)
        if upgrade then
            self.engines.shield.mul = self.engines.shield.mul + 1
        else
            self.engines.shield.mul = self.engines.shield.mul - 1
        end
        if self.engines.shield.mul > 9 then
            self.engines.shield.mul = 9
        elseif self.engines.shield.mul < 1 then
            self.engines.shield.mul = 1
        end
        self.engines.shield.max = max_chunk * self.engines.shield.mul
        new_engine_max = self.engines.shield.mul
    end
    return new_engine_max
end

function SpaceShip:upgradeEnergyEngine()
    return self:modifyEngineMaxValue("energy", true)
end

function SpaceShip:degradeEnergyEngine()
    return self:modifyEngineMaxValue("energy", false)
end

function SpaceShip:upgradeLifeSupportEngine()
    return self:modifyEngineMaxValue("life_support", true)
end

function SpaceShip:degradeLifeSupportEngine()
    return self:modifyEngineMaxValue("life_support", false)
end

function SpaceShip:upgradeShieldEngine()
    return self:modifyEngineMaxValue("shield", true)
end

function SpaceShip:degradeShieldEngine()
    return self:modifyEngineMaxValue("shield", false)
end

function SpaceShip:modifyEngineCurrentValue(type, value)
    if type == nil then
        type = "energy"
    end
    if value == nil then
        value = 10
    end

    local new_engine_cur = nil
    if type == "energy" then
        self.engines.energy.cur = self.engines.energy.cur + value
        if self.engines.energy.cur > self.engines.energy.max then
            self.engines.energy.cur = self.engines.energy.max
        elseif self.engines.energy.cur < 0 then
            self.engines.energy.cur = 0
        end
        new_engine_cur = self.engines.energy.cur
    elseif type == "life_support" then
        self.engines.life_support.cur = self.engines.life_support.cur + value
        if self.engines.life_support.cur > self.engines.life_support.max then
            self.engines.life_support.cur = self.engines.life_support.max
        elseif self.engines.life_support.cur < 0 then
            self.engines.life_support.cur = 0
        end
        new_engine_cur = self.engines.life_support.cur
    elseif type == "shield" then
        self.engines.shield.cur = self.engines.shield.cur + value
        if self.engines.shield.cur > self.engines.shield.max then
            self.engines.shield.cur = self.engines.shield.max
        elseif self.engines.shield.cur < 0 then
            self.engines.shield.cur = 0
        end
        new_engine_cur = self.engines.shield.cur
    end
    return new_engine_cur
end

function SpaceShip:drainEnergy()
    return self:modifyEngineCurrentValue("energy", -1)
end

function SpaceShip:regenerateEnergy()
    return self:modifyEngineCurrentValue("energy", 1)
end

function SpaceShip:drainLifeSupport()
    return self:modifyEngineCurrentValue("life_support", -1)
end

function SpaceShip:regenerateLifeSupport()
    return self:modifyEngineCurrentValue("life_support", 1)
end

function SpaceShip:drainShield()
    return self:modifyEngineCurrentValue("shield", -1)
end

function SpaceShip:regenerateShield()
    return self:modifyEngineCurrentValue("shield", 1)
end

function SpaceShip:regenerateEnginesOnTimer()
    if self:everyNTicks(self.engines.energy.tik) then
        self:regenerateEnergy()
    end
    if (
        self:everyNTicks(self.engines.life_support.tik) and
        self:getEnergyFraction() > 0.99 and
        self:getShieldFraction() > 0.99
    ) then
        self:regenerateLifeSupport()
    end
    if self:everyNTicks(self.engines.shield.tik) then
        self:regenerateShield()
    end
end

-- ==========================================
-- SPACESHIP MASS MANAGEMENT
-- ==========================================

function SpaceShip:updateHoldMass(hold_type, mass)
    if hold_type == nil then
        hold_type = "cargo"
    end
    if mass == nil then
        mass = 100
    end

    local hold = self.holds[hold_type]
    if hold == nil then
        return false
    end

    local new_mass = hold.cur + mass
    if new_mass < 0 then
        new_mass = 0
    elseif new_mass > hold.max then
        return false
    end
    hold.cur = new_mass
    return true
end

function SpaceShip:pickupCargo(cargo_mass)
    return self:updateHoldMass("cargo", cargo_mass)
end

function SpaceShip:deliverCargo(cargo_mass)
    return self:updateHoldMass("cargo", -cargo_mass)
end

function SpaceShip:pickupPassengers(num_passengers)
    return self:updateHoldMass("passengers", num_passengers * PASSENGER_TOTAL_MASS)
end

function SpaceShip:deliverPassengers(num_passengers)
    return self:updateHoldMass("passengers", -num_passengers * PASSENGER_TOTAL_MASS)
end

function SpaceShip:pickupSmuggledGoods(smuggled_mass)
    return self:updateHoldMass("smuggled", smuggled_mass)
end

function SpaceShip:deliverSmuggledGoods(smuggled_mass)
    return self:updateHoldMass("smuggled", -smuggled_mass)
end


-- ==========================================
-- SPACESHIP PARTICLE EFFECTS
-- ==========================================

function SpaceShip:getParticleSystem(type)
    if not self.particles then
        return nil
    end

    return self.particles[type]
end

function SpaceShip:addParticle(type, particle)
    local system = self:getParticleSystem(type)

    if not system then
        return
    end

    table.insert(system.particles, particle)
end

function SpaceShip:spawnParticleBurst(type, origin_x, origin_y, base_direction, spread, count)
    local system = self:getParticleSystem(type)

    if not system then
        return
    end

    local p = system.params
    local colors = system.colors

    count = count or math.random(p.count_min or 1, p.count_max or 1)
    spread = spread or math.pi * 2

    for i = 1, count do
        local direction

        if base_direction then
            direction = base_direction + randomFloat(-spread, spread)
        else
            direction = randomFloat(0, math.pi * 2)
        end

        direction = self:keepAngleInRange(direction)

        local speed = randomFloat(p.speed_min or 0.1, p.speed_max or 1)
        local life = math.random(p.life_min or 10, p.life_max or 30)
        local size = math.random(p.size_min or 1, p.size_max or 1)

        local spawn_radius = p.spawn_radius or 0
        local spawn_angle = self:keepAngleInRange(randomFloat(0, math.pi * 2))
        local spawn_dist = randomFloat(0, spawn_radius)

        local offset = self:rotatePoint({
            x = spawn_dist,
            y = 0
        }, spawn_angle)

        local sx = origin_x + offset.x
        local sy = origin_y + offset.y

        self:addParticle(type, {
            position = {
                x = sx,
                y = sy,
            },
            velocity = {
                speed     = speed,
                direction = direction,
            },
            life     = life,
            max_life = life,
            color    = randomChoice(colors),
            size     = size,
            drag     = p.drag or 1,
            gravity  = {
                speed     = p.gravity_speed or 0,
                direction = p.gravity_direction or 0,
            },
        })
    end
end

function SpaceShip:updateParticleList(type)
    local system = self:getParticleSystem(type)

    if not system then
        return
    end

    local particles = system.particles
    for i = #particles, 1, -1 do
        local particle = particles[i]
        particle.life = particle.life - 1

        if particle.life <= 0 then
            table.remove(particles, i)
        else
            if particle.gravity and particle.gravity.speed and particle.gravity.speed ~= 0 then
                particle.velocity = self:addVectors(particle.velocity, particle.gravity)
            end

            particle.velocity.speed = particle.velocity.speed * (particle.drag or 1)
            particle.velocity.direction = self:keepAngleInRange(particle.velocity.direction or 0)

            local components = self:getVectorComponents(particle.velocity)

            particle.position.x = particle.position.x + components.xComp
            particle.position.y = particle.position.y + components.yComp
        end
    end
end

function SpaceShip:updateParticles()
    if not self.particles then
        return
    end

    self:updateParticleList("explosion")
    self:updateParticleList("smoke")
    self:updateParticleList("spark")
    self:updateParticleList("thrust")
end

function SpaceShip:drawParticles(type)
    local system = self:getParticleSystem(type)

    if not system then
        return
    end

    local zoom = game.camera.zoom or 1

    for _, particle in ipairs(system.particles) do
        local screen_x, screen_y = worldToScreen(
            particle.position.x,
            particle.position.y
        )

        screen_x = math.floor(screen_x)
        screen_y = math.floor(screen_y)

        if screen_x >= -4 and screen_x <= SCREEN_W + 4 and
            screen_y >= -4 and screen_y <= SCREEN_H + 4 then
            local life_fraction = particle.life / particle.max_life
            local size = math.max(1, math.floor((particle.size or 1) * zoom))

            if life_fraction < 0.35 then
                size = 1
            end

            if size <= 1 then
                pix(screen_x, screen_y, particle.color)
            else
                circ(screen_x, screen_y, size, particle.color)
            end
        end
    end
end

function SpaceShip:drawAllParticles()
    if not self.particles then
        return
    end

    -- Draw smoke/explosion behind hotter particles.
    self:drawParticles("smoke")
    self:drawParticles("explosion")
    self:drawParticles("thrust")
    self:drawParticles("spark")
end


function SpaceShip:explosionEffect()
    local system = self:getParticleSystem("explosion")

    if not system then
        return
    end

    local p = system.params
    local count = math.random(p.count_min or 20, p.count_max or 40)
    self:spawnParticleBurst(
        "explosion",
        self.position.x,
        self.position.y,
        nil,
        math.pi * 2,
        count
    )
end

function SpaceShip:smokeEffect()
    local system = self:getParticleSystem("smoke")
    if not system then
        return
    end

    local life_fraction = self:getLifeSupportFraction()
    if life_fraction > 0.5 then
        return
    end

    local p               = system.params
    local damage_fraction = clamp((0.5 - life_fraction) / 0.5, 0, 1)
    local spawn_chance    =
        (p.spawn_chance_min or 0.04) +
        damage_fraction * ((p.spawn_chance_max or 0.65) - (p.spawn_chance_min or 0.04))

    if math.random() > spawn_chance then
        return
    end

    local count = math.random(p.count_min or 1, p.count_max or 2)
    local ship_speed = self.velocity and self.velocity.speed or 0

    for i = 1, count do
        local spawn_radius = p.spawn_radius or self.radius or 10
        local spawn_angle  = self:keepAngleInRange(randomFloat(0, math.pi * 2))
        local spawn_dist   = randomFloat(0, spawn_radius * 0.7)
        local spawn_offset = self:rotatePoint({
            x = spawn_dist,
            y = 0,
        }, spawn_angle)
        local x              = self.position.x + spawn_offset.x
        local y              = self.position.y + spawn_offset.y
        local diffuse_angle  = self:keepAngleInRange(randomFloat(0, math.pi * 2))
        local diffuse_speed  = randomFloat(0.02, p.diffuse_speed or 0.35)
        local smoke_velocity = {
            speed = diffuse_speed,
            direction = diffuse_angle,
        }

        -- If the ship is moving, smoke trails behind it.
        if ship_speed > 0.05 then
            local trail_strength = p.trail_strength or 0.65
            local trail_velocity = {
                speed = ship_speed * trail_strength,
                direction = self:keepAngleInRange(self.velocity.direction + math.pi),
            }
            smoke_velocity = self:addVectors(smoke_velocity, trail_velocity)
        end

        smoke_velocity.direction = self:keepAngleInRange(
            smoke_velocity.direction or 0
        )

        local life = math.random(p.life_min or 30, p.life_max or 80)
        local size = math.random(p.size_min or 1, p.size_max or 3)
        self:addParticle("smoke", {
            position = {
                x = x,
                y = y,
            },
            velocity = smoke_velocity,
            life     = life,
            max_life = life,
            color    = randomChoice(system.colors),
            size     = size,
            drag     = p.drag or 0.985,
            gravity  = {
                speed     = p.gravity_speed or 0,
                direction = p.gravity_direction or 0,
            },
        })
    end
end

function SpaceShip:sparkEffect()
    local system = self:getParticleSystem("spark")

    if not system then
        return
    end

    local p         = system.params
    local count     = math.random(p.count_min or 4, p.count_max or 10)
    local direction = nil
    if self.velocity and self.velocity.speed and self.velocity.speed > 0.05 then
        direction = self:keepAngleInRange(self.velocity.direction + math.pi)
    end

    self:spawnParticleBurst(
        "spark",
        self.position.x,
        self.position.y,
        direction,
        math.pi / 1.5,
        count
    )
end

function SpaceShip:thrustEffect()
    local system = self:getParticleSystem("thrust")

    if not system then
        return
    end

    local p                 = system.params
    local exhaust_direction = self:keepAngleInRange(self.rotation + math.pi)
    local backend_distance  = p.backend_offset or self.radius or 10
    local side_jitter       = p.side_jitter or 0
    local count             = math.random(p.count_min or 1, p.count_max or 1)

    for i = 1, count do
        local jitter = randomFloat(-side_jitter, side_jitter)

        -- Local-space rear exhaust point.
        -- x is behind the ship, y is side jitter.
        local offset = self:rotatePoint({
            x = -backend_distance,
            y = jitter,
        }, self.rotation)
        local x = self.position.x + offset.x
        local y = self.position.y + offset.y
        local direction = self:keepAngleInRange(
            exhaust_direction + randomFloat(-(p.spread or 0.2), p.spread or 0.2)
        )
        local speed = randomFloat(p.speed_min or 0.2, p.speed_max or 1)
        local exhaust_velocity = {
            speed = speed,
            direction = direction,
        }
        -- Include a little of the ship velocity so exhaust feels attached.
        local ship_velocity = {
            speed = (self.velocity and self.velocity.speed or 0) * 0.25,
            direction = self.velocity and self.velocity.direction or 0,
        }
        local particle_velocity = self:addVectors(exhaust_velocity, ship_velocity)
        particle_velocity.direction = self:keepAngleInRange(
            particle_velocity.direction or 0
        )

        local life = math.random(p.life_min or 8, p.life_max or 18)
        local size = math.random(p.size_min or 1, p.size_max or 2)
        self:addParticle("thrust", {
            position = {
                x = x,
                y = y,
            },
            velocity = particle_velocity,
            life     = life,
            max_life = life,
            color    = randomChoice(system.colors),
            size     = size,
            drag     = p.drag or 0.94,
            gravity  = {
                speed = p.gravity_speed or 0,
                direction = p.gravity_direction or 0,
            },
        })
    end
end


-- ==========================================
-- SPACESHIP COLLISION DAMAGE
-- ==========================================

function SpaceShip:takeDamage(damage, other)
    damage = damage or 0

    if self.dead then
        return false
    end

    if damage <= 0 then
        return false
    end

    -- Optional: ignore damage while invulnerable.
    if self.mortality and self.mortality.invulnerable > 0 then
        return false
    end

    local remaining_damage = damage

    -- 1. Shields absorb damage first.
    local shield = self.engines.shield

    if shield.cur > 0 then
        local absorbed = math.min(shield.cur, remaining_damage)

        shield.cur = shield.cur - absorbed
        remaining_damage = remaining_damage - absorbed

        if shield.cur < 0 then
            shield.cur = 0
        end
    end

    -- 2. Remaining damage hits life support.
    local life_support = self.engines.life_support

    if remaining_damage > 0 and life_support.cur > 0 then
        local absorbed = math.min(life_support.cur, remaining_damage)

        life_support.cur = life_support.cur - absorbed
        remaining_damage = remaining_damage - absorbed

        if life_support.cur < 0 then
            life_support.cur = 0
        end
    end

    -- 3. If life support is depleted, the ship dies.
    if life_support.cur <= 0 then
        life_support.cur = 0
        self:kill()
        return true
    end

    -- Damaged but survived.
    self:sparkEffect()

    return false
end

-- ==========================================
-- SPACESHIP INPUT
-- ==========================================

function SpaceShip:deadStop()
    local s = self.velocity.speed
    if self.velocity.speed <= 0 then
        self.velocity.speed     = 0
        self.velocity.direction = 0
        return
    end

    -- Smoothly reduce speed; never goes negative
    self.velocity.speed = self.velocity.speed * (1 - self.deadstop.brake)
    if self.velocity.speed < self.deadstop.snap then
        self.velocity.speed     = 0
        self.velocity.direction = 0
    end
end

function SpaceShip:thrust()
    local load_fraction = clamp(self:getTotalMassFraction(), 0, 1)

    -- At full mass:
    -- acceleration is 65% of base
    -- max speed is 85% of base
    local acceleration_penalty = 1 - load_fraction * 0.35
    local speed_penalty        = 1 - load_fraction * 0.15

    local acceleration = {
        speed     = self.acceleration * acceleration_penalty,
        direction = self.rotation
    }

    self.velocity = self:addVectors(self.velocity, acceleration)

    local effective_max_speed = self.max_speed * speed_penalty

    if self.velocity.speed > effective_max_speed then
        self.velocity.speed = effective_max_speed
    end

    self:thrustEffect()
    -- sfx(3, 10, 10, 3, -8, 1)
end

function SpaceShip:input()
    if self.dead or self:getEnergy() <= 0 then
        return
    end

    local used_energy = false

    if btn(BTN_P1_UP) then
        self:thrust()
        used_energy = true
    end

    if btn(BTN_P1_DOWN) then
        self:deadStop()
        used_energy = true
    end

    if btn(BTN_P1_LEFT) then
        self.rotation = self.rotation - self.rotation_speed
        used_energy = true
    end

    if btn(BTN_P1_RIGHT) then
        self.rotation = self.rotation + self.rotation_speed
        used_energy = true
    end

    self.rotation = self:keepAngleInRange(self.rotation)

    if used_energy then
        self:drainEnergy()
    end
end

-- ==========================================
-- SPACESHIP UPDATE
-- ==========================================

function SpaceShip:move()
    self:updateTimer()

    if not self.dead then
        self.position = self:movePointByVelocity()

        self.position.x = clamp(self.position.x, 0, MAP_PIXELS_W - 1)
        self.position.y = clamp(self.position.y, 0, MAP_PIXELS_H - 1)

        self:regenerateEnginesOnTimer()

        -- Emit smoke if life support is damaged enough.
        self:smokeEffect()
    end

    -- Particles continue moving even after the ship dies.
    self:updateParticles()
end

function SpaceShip:kill()
    if self.dead then
        return
    end
    self.dead = true
    self.mortality.num_lives = self.mortality.num_lives - 1
    self.mortality.respawn_timer = 90
    self:explode()
end

-- ==========================================
-- SPACESHIP DRAW
-- ==========================================

-- This is for when the ship first starts out and is invulnerable.
function SpaceShip:shouldDraw()
    if self.mortality.invulnerable <= 0 then
        return true
    end
    -- blink: visible 6 frames, invisible 6 frames
    return (math.floor(self.mortality.invulnerable / 6) % 2) == 0
end

function SpaceShip:getScreenShapePoints()
    local screen_x, screen_y = worldToScreen(self.position.x, self.position.y)
    local zoom = game.camera.zoom or 1

    screen_x = math.floor(screen_x)
    screen_y = math.floor(screen_y)

    local points = {}

    for i, point in ipairs(self.shape) do
        local rotated_point = self:rotatePoint(point, self.rotation)

        points[i] = {
            x = math.floor(screen_x + rotated_point.x * zoom),
            y = math.floor(screen_y + rotated_point.y * zoom),
        }
    end

    return points
end

function SpaceShip:drawBody()
    local zoom = game.camera.zoom or 1

    if zoom <= 0.25 then
        local x, y = worldToScreen(self.position.x, self.position.y)

        x = math.floor(x)
        y = math.floor(y)

        pix(x, y, self.colors.primary)
        pix(x - 1, y, self.colors.primary)
        pix(x + 1, y, self.colors.primary)
        pix(x, y - 1, self.colors.primary)
        pix(x, y + 1, self.colors.primary)

        return
    end

    local points = self:getScreenShapePoints()

    -- Draw a ship-shaped mask first.
    drawFilledPolygon(points, self.colors.secondary)

    -- Draw the ship outline on top.
    drawPolygonOutline(points, self.colors.primary)
end

function SpaceShip:draw()
    -- Draw particles behind/in front of body.
    self:drawParticles("explosion")
    self:drawParticles("thrust")

    if not self.dead and self:shouldDraw() then
        self:drawBody()
    end

    self:drawParticles("smoke")
    self:drawParticles("spark")
end

function SpaceShip:explode()
    if self.exploded then
        return
    end
    self.exploded = true
    self:explosionEffect()
    -- sfx(2, 10, 30, 3, 15)
end


-- [/TQ-Bundler: src.classes.SpaceShip]

-- [TQ-Bundler: src.classes.Star]

-- ==========================================
-- STAR OBJECT
-- ==========================================

Star = setmetatable({}, { __index = KeplerObj })
Star.__index = Star

function Star:new(params)
    params = params or {}

    -- Pick a stellar type if one was not supplied.
    params.stellar_type = params.stellar_type or randomChoice(STELLAR_TYPES)

    -- Apply stellar-profile values before calling KeplerObj.new().
    local profile = STELLAR_PROFILES[params.stellar_type] or STELLAR_PROFILES.G

    local mass_solar_units   = randomFloat(profile.mass_min, profile.mass_max)
    local radius_solar_units = randomFloat(profile.radius_min, profile.radius_max)

    params.mass        = params.mass or mass_solar_units * SOLAR_MASS
    params.radius_real = params.radius_real or radius_solar_units * SOLAR_RADIUS
    params.temperature = params.temperature or math.floor(randomFloat(profile.temp_min, profile.temp_max))

    -- Important:
    -- `radius` is currently used by drawBody() as a pixel radius.
    -- A real stellar radius would be enormous, so keep drawing radius separate.
    params.radius = params.radius or Star:getDrawRadiusForType(params.stellar_type)

    params.colors = params.colors or {
        primary   = profile.colors.primary,
        secondary = profile.colors.secondary,
        tertiary  = profile.colors.tertiary,
    }

    params.velocity = {
        speed     = 0,
        direction = 0,
    }

    params.acceleration = 0
    params.deceleration = 0

    local self = KeplerObj:new(params)
    setmetatable(self, Star)

    self.name               = params.name or "Kepler-9999"
    self.stellar_type       = params.stellar_type
    self.temperature        = params.temperature
    self.radius_real        = params.radius_real

    self.mass_solar         = mass_solar_units
    self.radius_solar       = radius_solar_units

    self.velocity.speed     = 0
    self.velocity.direction = 0
    self.acceleration       = 0
    self.deceleration       = 0

    local particle_profile  = profile.particles or {}
    local wind_profile      = particle_profile.wind or {}
    local flare_profile     = particle_profile.flare or {}

    self.particles = {
        wind = {
            particles               = {},
            spawn_chance            = getOrDefault(wind_profile.spawn_chance, 0.30),
            speed_min               = getOrDefault(wind_profile.speed_min, 0.15),
            speed_max               = getOrDefault(wind_profile.speed_max, 0.45),
            max_distance_multiplier = getOrDefault(wind_profile.max_distance_multiplier, 2),
            colors                  = wind_profile.colors or {
                self.colors.secondary,
                self.colors.tertiary,
            },
        },
        flare = {
            particles               = {},
            spawn_chance            = getOrDefault(flare_profile.spawn_chance, 0.015),
            particles_per_flare_min = getOrDefault(flare_profile.particles_per_flare_min, 8),
            particles_per_flare_max = getOrDefault(flare_profile.particles_per_flare_max, 18),
            speed_min               = getOrDefault(flare_profile.speed_min, 0.55),
            speed_max               = getOrDefault(flare_profile.speed_max, 1.25),
            angle_spread            = getOrDefault(flare_profile.angle_spread, math.pi / 7),
            max_distance_multiplier = getOrDefault(flare_profile.max_distance_multiplier, 4),
            evaporate_chance_min    = getOrDefault(flare_profile.evaporate_chance_min, 0.005),
            evaporate_chance_max    = getOrDefault( flare_profile.evaporate_chance_max, 0.025),
            colors                  = flare_profile.colors or {
                self.colors.primary,
                self.colors.secondary,
                self.colors.tertiary,
                WHITE,
            },
        },
    }

    return self
end


-- ==========================================
-- STAR GETTERS
-- ==========================================

-- ==========================================
-- STAR MATH
-- ==========================================

-- ==========================================
-- STAR PHYSICS
-- ==========================================

-- ==========================================
-- STAR COLLISION DETECTION
-- ==========================================

-- Treat everything like a circle

-- Deflection only works on objects below a certain mass, with the object of the
-- lesser mass being deflected harder than the more massive object.

-- When there's a collision, calculate the energy of the collision and destroy
-- one or both objects depending on how massive the collision is.

-- ==========================================
-- STAR INPUT
-- ==========================================

-- ==========================================
-- STAR UPDATE
-- ==========================================

function Star:spawnWindParticle()
    local system = self.particles.wind

    local angle = randomFloat(0, math.pi * 2)

    -- Start exactly on the star surface.
    local start_x = self.position.x + math.cos(angle) * self.radius
    local start_y = self.position.y + math.sin(angle) * self.radius

    local speed = randomFloat(system.speed_min, system.speed_max)
    local max_distance = self.radius * system.max_distance_multiplier

    local particle = {
        x            = start_x,
        y            = start_y,
        origin_x     = start_x,
        origin_y     = start_y,
        direction    = angle,
        speed        = speed,
        max_distance = max_distance,
        color        = randomChoice(system.colors),
        size         = 1,
    }

    table.insert(system.particles, particle)
end

function Star:spawnFlare()
    local system = self.particles.flare

    -- One surface location for the whole flare clump.
    local base_angle = randomFloat(0, math.pi * 2)

    local start_x = self.position.x + math.cos(base_angle) * self.radius
    local start_y = self.position.y + math.sin(base_angle) * self.radius

    local count = math.random(
        system.particles_per_flare_min,
        system.particles_per_flare_max
    )

    for i = 1, count do
        local angle_offset = randomFloat(-system.angle_spread, system.angle_spread)
        local direction = base_angle + angle_offset

        local speed = randomFloat(system.speed_min, system.speed_max)

        -- Each particle can die at a different range up to max_distance_multiplier.
        local max_distance = randomFloat(
            self.radius * 1.1,
            self.radius * system.max_distance_multiplier
        )
        local particle = {
            x                = start_x,
            y                = start_y,
            origin_x         = start_x,
            origin_y         = start_y,
            direction        = direction,
            speed            = speed,
            max_distance     = max_distance,
            color            = randomChoice(system.colors),
            size             = math.random(1, 2),
            evaporate_chance = randomFloat(system.evaporate_chance_min, system.evaporate_chance_max),
        }
        table.insert(system.particles, particle)
    end
end

function Star:updateParticleList(particles, evaporates)
    for i = #particles, 1, -1 do
        local particle = particles[i]

        particle.x = particle.x + math.cos(particle.direction) * particle.speed
        particle.y = particle.y + math.sin(particle.direction) * particle.speed

        local dx = particle.x - particle.origin_x
        local dy = particle.y - particle.origin_y
        local distance = math.sqrt(dx * dx + dy * dy)

        local remove_particle = false

        if distance >= particle.max_distance then
            remove_particle = true
        end

        -- Flares can randomly evaporate before reaching max distance.
        if evaporates and particle.evaporate_chance then
            if math.random() < particle.evaporate_chance then
                remove_particle = true
            end
        end

        if remove_particle then
            table.remove(particles, i)
        end
    end
end

function Star:update()
    self:updateTimer()

    -- Lazy stellar wind.
    if math.random() < self.particles.wind.spawn_chance then
        self:spawnWindParticle()
    end

    -- Occasional flare clump.
    if math.random() < self.particles.flare.spawn_chance then
        self:spawnFlare()
    end

    self:updateParticleList(self.particles.wind.particles, false)
    self:updateParticleList(self.particles.flare.particles, true)
end

-- ==========================================
-- STAR DRAW
-- ==========================================

function Star:getDrawRadiusForType(stellar_type)
    local multiplier = 21
    if stellar_type == "O" then
        return 8 * multiplier
    elseif stellar_type == "B" then
        return 7 * multiplier
    elseif stellar_type == "A" then
        return 6 * multiplier
    elseif stellar_type == "F" then
        return 5 * multiplier
    elseif stellar_type == "G" then
        return 5 * multiplier
    elseif stellar_type == "K" then
        return 4 * multiplier
    elseif stellar_type == "M" then
        return 3 * multiplier
    end

    return 5 * multiplier
end

function Star:drawBody()
    local screen_x, screen_y = worldToScreen(self.position.x, self.position.y)
    local zoom = game.camera.zoom or 1

    screen_x = math.floor(screen_x)
    screen_y = math.floor(screen_y)

    local r = math.max(1, math.floor(self.radius * zoom))
    local outer_extra = math.max(1, math.floor(2 * zoom))
    local middle_extra = math.max(1, math.floor(1 * zoom))

    circ(screen_x, screen_y, r + outer_extra, self.colors.tertiary)
    circ(screen_x, screen_y, r + middle_extra, self.colors.secondary)
    circ(screen_x, screen_y, r, self.colors.primary)
end


function Star:drawParticleList(particles)
    local zoom = game.camera.zoom or 1

    for _, particle in ipairs(particles) do
        local screen_x, screen_y = worldToScreen(particle.x, particle.y)

        screen_x = math.floor(screen_x)
        screen_y = math.floor(screen_y)

        local size = math.max(1, math.floor(particle.size * zoom))

        if size <= 1 then
            pix(screen_x, screen_y, particle.color)
        else
            circ(screen_x, screen_y, size, particle.color)
        end
    end
end

function Star:draw()
    self:drawParticleList(self.particles.wind.particles)
    self:drawBody()
    self:drawParticleList(self.particles.flare.particles)
end


-- [/TQ-Bundler: src.classes.Star]

-- [TQ-Bundler: src.classes.Planet]

-- ==========================================
-- PLANET OBJECT
-- ==========================================

Planet = setmetatable({}, { __index = KeplerObj })
Planet.__index = Planet

function Planet:new(params)
    params = params or {}

    -- Random physical properties.
    params.mass = params.mass or randomFloat(EARTH_MASS, JUPITER_MASS)

    -- Keep real radius separate from draw radius, like Star does.
    params.radius_real = params.radius_real or randomFloat(EARTH_RADIUS, JUPITER_RADIUS)

    -- Atmosphere.
    if params.has_atmosphere == nil then
        params.has_atmosphere = math.random(1, 100) <= 50
    end

    -- Colors depend on whether atmosphere exists.
    params.colors = params.colors or randomPlanetColorSet(params.has_atmosphere)

    -- Important:
    -- `radius` is used as the draw radius in pixels.
    params.radius = params.radius or Planet:getDrawRadiusFromRealRadius(params.radius_real)

    -- For now, planets are static.
    params.velocity = {
        speed = 0,
        direction = 0,
    }

    params.acceleration = 0
    params.deceleration = 0

    local self = KeplerObj:new(params)
    setmetatable(self, Planet)

    self.name           = params.name or "Planet"
    self.radius_real    = params.radius_real
    self.has_atmosphere = params.has_atmosphere

    if self.has_atmosphere then
        self.colors.cloud = params.colors.cloud or PLANET_CLOUD_COLORS[math.random(1, #PLANET_CLOUD_COLORS)]
    else
        self.craters           = {}
        self.colors.crater     = params.colors.crater or GRAY_DARK
        self.colors.crater_rim = params.colors.crater_rim or self.colors.secondary

        local crater_count = params.crater_count or math.random(
            math.floor(params.radius * 0.2),
            math.floor(params.radius * 0.45)
        )

        for i = 1, crater_count do
            -- Generate random point inside unit circle.
            local angle = randomFloat(0, math.pi * 2)
            local dist = math.sqrt(randomFloat(0, 1))

            -- Store normalized coordinates.
            -- These are relative to the planet radius, so they scale with zoom.
            local crater = {
                x = math.cos(angle) * dist,
                y = math.sin(angle) * dist,
                r = randomFloat(0.04, 0.16),
            }

            table.insert(self.craters, crater)
        end
    end

    self.velocity.speed     = 0
    self.velocity.direction = 0
    self.acceleration       = 0
    self.deceleration       = 0

    -- Visual details.
    self.surface_band_offset = math.random(0, 100)

    self.has_ring  = params.has_ring
    self.num_rings = params.num_rings or 0
    if self.has_ring == nil then
        self.has_ring = math.random(1, 100) <= 12
    end
    if self.has_ring then
        self.num_rings = math.random(1,15)
    end

    return self
end

-- ==========================================
-- PLANET GETTERS
-- ==========================================

function Planet:getDrawRadiusFromRealRadius(radius_real)
    -- Maps EARTH_RADIUS..JUPITER_RADIUS to about 4..18 pixels.
    local min_draw_radius = 40
    local max_draw_radius = 75

    radius_real = radius_real or EARTH_RADIUS

    local t = (radius_real - EARTH_RADIUS) / (JUPITER_RADIUS - EARTH_RADIUS)
    t = clamp(t, 0, 1)

    return math.floor(min_draw_radius + t * (max_draw_radius - min_draw_radius))
end

-- ==========================================
-- PLANET UPDATE
-- ==========================================

function Planet:update()
    self:updateTimer()

    if self.moons then
        for _, moon in ipairs(self.moons) do
            moon:update()
        end
    end
end

-- ==========================================
-- PLANET DRAW
-- ==========================================

function Planet:drawCraters(screen_x, screen_y, r, zoom)
    if self.has_atmosphere then
        return
    end

    if not self.craters then
        return
    end

    -- Too small to show useful crater detail.
    if r < 5 then
        return
    end

    local crater_color = self.colors.crater
    local rim_color = self.colors.crater_rim

    for i = 1, #self.craters do
        local crater = self.craters[i]

        local crater_x = math.floor(screen_x + crater.x * r)
        local crater_y = math.floor(screen_y + crater.y * r)
        local crater_r = math.max(1, math.floor(crater.r * r))

        -- Keep the whole crater inside the planet disk.
        local dx = crater_x - screen_x
        local dy = crater_y - screen_y
        local dist_from_center = math.sqrt(dx * dx + dy * dy)

        if dist_from_center + crater_r <= r then
            -- Rim/highlight.
            circ(crater_x - 1, crater_y - 1, crater_r, self.colors.crater_rim)
            circ(crater_x, crater_y, crater_r, crater_color)
            circ(crater_x, crater_y, math.max(1, crater_r - 1), crater_color)
        end
    end
end

function Planet:drawAtmosphere(screen_x, screen_y, r, zoom)
    if not self.has_atmosphere then
        return
    end
    local atmosphere_extra = math.max(1, math.floor(4 * zoom))
    circ(screen_x, screen_y, r + atmosphere_extra, self.colors.tertiary)
end

function Planet:drawRing(screen_x, screen_y, r, zoom)
    if not self.has_ring then
        return
    end

    -- Simple flattened ring.
    local ring_w = math.max(2, math.floor(r * 2.8))
    local ring_h = math.max(1, math.floor(r * 0.7))

    for ring_num = 0, self.num_rings, 1 do
        ellib(screen_x, screen_y, ring_w + ring_num, ring_h + ring_num, self.colors.tertiary)
    end
end

function Planet:drawClouds(screen_x, screen_y, r, zoom)
    if not self.has_atmosphere then
        return
    end

    -- Too small to show useful cloud detail.
    if r < 6 then
        return
    end

    -- Cloud bands should cover almost the whole planet,
    -- from near the north pole to near the south pole.
    local band_spacing = math.max(4, math.floor(r * 0.18))
    local band_count = math.max(3, math.floor((r * 2) / band_spacing))

    -- Used to make each planet's clouds look different.
    local seed = self.surface_band_offset or 0

    for band = 1, band_count do
        -- Place bands from near top pole to near bottom pole.
        local t = 0

        if band_count > 1 then
            t = (band - 1) / (band_count - 1)
        end

        -- t = 0 gives top pole, t = 1 gives bottom pole.
        -- Use 0.92 instead of 1.0 so the bands do not collapse to zero width.
        local y_offset = math.floor(-r * 0.80 + t * (r * 1.84))

        -- Slight per-band wobble so they are not perfectly parallel.
        y_offset = y_offset + math.floor(math.sin(seed + band * 2.1) * r * 0.05)

        -- Clamp y_offset so it stays inside the planet.
        y_offset = clamp(y_offset, -r + 1, r - 1)

        -- Width of the planet at this y coordinate.
        local half_width = math.floor(
            math.sqrt(math.max(0, r * r - y_offset * y_offset))
        )

        -- Near the poles the width gets very small.
        -- Skip if there is basically no room to draw.
        if half_width > 1 then
            local band_height = math.max(2, math.floor(r * 0.08))
            local puff_step = math.max(3, math.floor(r * 0.16))

            -- Offset the start position per planet/band.
            local x_start = -half_width + ((seed + band * 7) % puff_step)

            -- Make sure tiny polar bands still get at least one puff.
            if half_width < puff_step then
                x_start = 0
            end

            for x_offset = x_start, half_width, puff_step do
                -- Deterministic pseudo-random value based on band/position.
                local n = math.sin((x_offset + seed * 13 + band * 31) * 12.9898) * 43758.5453
                n = n - math.floor(n)

                -- Leave some gaps.
                if n > 0.25 then
                    local puff_r = math.floor(band_height * (0.7 + n * 1.2))

                    -- Keep puffs mostly inside the planet disk.
                    local max_puff_r = half_width - math.abs(x_offset)
                    puff_r = math.floor(math.min(puff_r, max_puff_r))

                    if puff_r > 0 then
                        local puff_y = y_offset + math.floor((n - 0.5) * band_height)

                        -- Final safety check: keep puff center inside planet.
                        local dx = x_offset
                        local dy = puff_y

                        if dx * dx + dy * dy <= r * r then
                            circ(
                                screen_x + math.floor(x_offset),
                                screen_y + math.floor(puff_y),
                                puff_r,
                                self.colors.cloud
                            )
                        end
                    end
                end
            end
        end
    end
end

function Planet:drawMoonsBehind()
    if not self.moons then
        return
    end

    for _, moon in ipairs(self.moons) do
        if moon.orbit_depth and moon.orbit_depth < 0 then
            moon:draw()
        end
    end
end

function Planet:drawMoonsInFront()
    if not self.moons then
        return
    end

    for _, moon in ipairs(self.moons) do
        if not moon.orbit_depth or moon.orbit_depth >= 0 then
            moon:draw()
        end
    end
end

function Planet:drawBody()
    local screen_x, screen_y = worldToScreen(self.position.x, self.position.y)
    local zoom = game.camera.zoom or 1

    screen_x = math.floor(screen_x)
    screen_y = math.floor(screen_y)

    local r = math.max(1, math.floor(self.radius * zoom))

    -- Skip if comfortably off-screen.
    if screen_x < -r - 4 or screen_x > SCREEN_W + r + 4 or
        screen_y < -r - 4 or screen_y > SCREEN_H + r + 4 then
        return
    end

    -- Draw ring behind the planet.
    self:drawRing(screen_x, screen_y, r, zoom)

    -- Atmosphere glow.
    self:drawAtmosphere(screen_x, screen_y, r, zoom)

    -- Planet body.
    circ(screen_x, screen_y, r, self.colors.primary)

    -- Craters for planets without atmospheres.
    self:drawCraters(screen_x, screen_y, r, zoom)

    -- Puffy cloud bands for planets with atmospheres.
    self:drawClouds(screen_x, screen_y, r, zoom)
end

function Planet:drawLabel()
    local zoom = game.camera.zoom or 1

    -- Labels are only visible when zoomed out.
    if zoom >= 1 then
        return
    end

    local screen_x, screen_y = worldToScreen(self.position.x, self.position.y)

    screen_x = math.floor(screen_x)
    screen_y = math.floor(screen_y)

    local r    = math.max(1, math.floor(self.radius * zoom))
    local text = self.name or "Planet"

    -- TIC-80 print() returns the rendered text width.
    local text_w = print(text, 0, -100, WHITE, true, 1, true)

    local label_x = math.floor(screen_x - text_w / 2)
    local label_y = screen_y + r + 4

    -- Skip labels that are clearly off-screen.
    if label_x > SCREEN_W or label_x + text_w < 0 or
        label_y > SCREEN_H or label_y + FIXED_CHAR_HEIGHT < 0 then
        return
    end

    -- Shadow.
    print(text, label_x + 1, label_y + 1, BLACK, true, 1, true)

    -- Label.
    print(text, label_x, label_y, WHITE, true, 1, true)
end

function Planet:draw()
    -- Moons on the far side are drawn first, so the planet can eclipse them.
    self:drawMoonsBehind()

    -- Planet body/rings/clouds/etc.
    self:drawBody()

    -- Moons on the near side are drawn after, so they can eclipse the planet.
    self:drawMoonsInFront()

    -- Labels still go on top.
    self:drawLabel()
end


-- [/TQ-Bundler: src.classes.Planet]

-- [TQ-Bundler: src.classes.Moon]

-- ==========================================
-- MOON OBJECT
-- ==========================================

Moon = setmetatable({}, { __index = Planet })
Moon.__index = Moon

function Moon:new(params)
    params = params or {}

    params.has_atmosphere = false
    params.has_ring = false
    params.num_rings = 0

    params.mass = params.mass or randomFloat(MOON_MIN_MASS, MOON_MASS)

    params.radius_real = params.radius_real or randomFloat(100, 900)
    params.radius = params.radius or Moon:getDrawRadiusFromRealRadius(params.radius_real)

    params.colors = params.colors or randomMoonColorSet()

    -- Important:
    -- Planet:new is defined with colon syntax, so call it using colon syntax.
    local self = Planet:new(params)
    setmetatable(self, Moon)

    self.name = params.name or "Moon"
    self.host = params.host

    self.has_atmosphere = false
    self.has_ring = false
    self.num_rings = 0

    local orbit = params.orbit or {}

    self.orbit = {
        semi_major   = orbit.semi_major or 100,
        eccentricity = orbit.eccentricity or randomFloat(0.05, 0.55),
        angle        = orbit.angle or randomFloat(0, math.pi * 2),
        phase        = orbit.phase or randomFloat(0, math.pi * 2),
        period       = orbit.period or math.random(900, 3600),
    }

    self.orbit.semi_minor =
        self.orbit.semi_major *
        math.sqrt(1 - self.orbit.eccentricity * self.orbit.eccentricity)

    return self
end

-- ==========================================
-- MOON GETTERS
-- ==========================================

-- ==========================================
-- MOON UPDATE
-- ==========================================

function Moon:updateOrbitPosition(focus)
    if not focus then
        return
    end

    local orbit = self.orbit

    local a = orbit.semi_major
    local b = orbit.semi_minor
    local e = orbit.eccentricity

    -- Treat phase as eccentric anomaly.
    local E = orbit.phase

    -- Ellipse relative to one focus.
    -- Center-relative ellipse:
    --   x = a * cos(E)
    --   y = b * sin(E)
    --
    -- Focus-relative version shifts x by -a*e.
    local local_x = a * math.cos(E) - a * e
    local local_y = b * math.sin(E)

    -- Used only for draw order.
    -- Negative means "behind" the planet, positive means "in front".
    self.orbit_depth = local_y

    -- Rotate ellipse.
    local cos_a = math.cos(orbit.angle)
    local sin_a = math.sin(orbit.angle)

    local rotated_x = local_x * cos_a - local_y * sin_a
    local rotated_y = local_x * sin_a + local_y * cos_a

    self.position.x = focus.x + rotated_x
    self.position.y = focus.y + rotated_y
end

function Moon:update()
    self:updateTimer()

    if not self.host then
        return
    end

    local focus = self.host.barycenter or self.host.position

    self.orbit.phase = self.orbit.phase + ((math.pi * 2) / self.orbit.period)

    if self.orbit.phase > math.pi * 2 then
        self.orbit.phase = self.orbit.phase - math.pi * 2
    end

    self:updateOrbitPosition(focus)
end

-- ==========================================
-- MOON DRAW
-- ==========================================

function Moon:getDrawRadiusFromRealRadius(radius_real)
    -- Moon real radius range: 100..900.
    -- Draw radius range: 4..12 pixels.
    local min_real_radius = 100
    local max_real_radius = 900

    local min_draw_radius = 4
    local max_draw_radius = 12

    radius_real = radius_real or min_real_radius

    local t = (radius_real - min_real_radius) / (max_real_radius - min_real_radius)
    t = clamp(t, 0, 1)

    return math.floor(min_draw_radius + t * (max_draw_radius - min_draw_radius))
end

function Moon:drawBody()
    local zoom = game.camera.zoom or 1

    local screen_x, screen_y = worldToScreen(self.position.x, self.position.y)

    screen_x = math.floor(screen_x)
    screen_y = math.floor(screen_y)

    -- Keep moons visible at low zoom.
    local r = math.max(1, math.floor(self.radius * zoom))

    -- Skip if comfortably off-screen.
    if screen_x < -r - 4 or screen_x > SCREEN_W + r + 4 or
        screen_y < -r - 4 or screen_y > SCREEN_H + r + 4 then
        return
    end

    circ(screen_x, screen_y, r, self.colors.primary)

    -- Only draw crater detail when the moon is large enough to show it.
    if r >= 4 then
        self:drawCraters(screen_x, screen_y, r, zoom)
    end
end

function Moon:drawLabel()
    -- No labels for moons for now.
end

function Moon:draw()
    self:drawBody()
end


-- [/TQ-Bundler: src.classes.Moon]

-- [TQ-Bundler: src.classes.Comet]

-- ==========================================
-- COMET OBJECT
-- ==========================================

Comet = setmetatable({}, { __index = KeplerObj })
Comet.__index = Comet

function Comet:new(params)
    params = params or {}

    params.mass = params.mass or randomFloat(COMET_MIN_MASS, COMET_MAX_MASS)

    params.radius_real = params.radius_real or randomFloat(
        COMET_RADIUS_REAL_MIN,
        COMET_RADIUS_REAL_MAX
    )
    params.radius = params.radius or Comet:getDrawRadiusFromRealRadius(params.radius_real)

    params.colors = params.colors or randomCometColorSet()

    local direction     = params.direction or randomFloat(0, math.pi * 2)
    local speed         = params.speed or randomFloat(COMET_SPEED_MIN, COMET_SPEED_MAX)
    params.direction    = direction
    params.speed        = speed
    params.acceleration = 0
    params.deceleration = 0

    local self = KeplerObj:new(params)
    setmetatable(self, Comet)

    self.name = params.name or "Comet"

    self.radius_real    = params.radius_real
    self.mass_initial   = self.mass
    self.radius_initial = self.radius
    self.draw_scale     = 1

    self.color_list = randomCometColorList(self.colors)

    -- Lump circles are generated once so the comet has a stable shape.
    self.lumps = {}
    local lump_count = params.lump_count or math.random(4, 8)

    for i = 1, lump_count do
        local angle = randomFloat(0, math.pi * 2)
        local dist = randomFloat(0, self.radius * 0.55)

        table.insert(self.lumps, {
            x = math.cos(angle) * dist,
            y = math.sin(angle) * dist,
            r = randomFloat(self.radius * 0.35, self.radius * 0.75),
            color = randomChoice(self.color_list),
        })
    end

    -- Guarantee one central lump.
    table.insert(self.lumps, {
        x = 0,
        y = 0,
        r = self.radius,
        color = self.colors.primary,
    })

    self.tail_particles = {}
    self.tail_spawn_carry = 0

    return self
end

-- ==========================================
-- COMET GETTERS
-- ==========================================

function Comet:isFinished()
    return self.dead and #self.tail_particles <= 0
end

function Comet:getDrawRadiusFromRealRadius(radius_real)
    -- Comet real radius range: 100..900.
    -- Draw radius range: 3..9 pixels.
    local min_draw_radius = 3
    local max_draw_radius = 9

    radius_real = radius_real or COMET_RADIUS_REAL_MIN

    local t = (radius_real - COMET_RADIUS_REAL_MIN) /
        (COMET_RADIUS_REAL_MAX - COMET_RADIUS_REAL_MIN)

    t = clamp(t, 0, 1)

    return math.floor(min_draw_radius + t * (max_draw_radius - min_draw_radius))
end

function Comet:getDistanceToStar()
    if not game.play.star then
        return nil
    end

    local star = game.play.star
    local dx = self.position.x - star.position.x
    local dy = self.position.y - star.position.y

    return math.sqrt(dx * dx + dy * dy)
end

function Comet:getTailStrength()
    if not game.play.star then
        return 0
    end

    local distance_to_star = self:getDistanceToStar()

    if not distance_to_star then
        return 0
    end

    -- Approx max possible map distance from the star to any map corner.
    local star = game.play.star

    local d1 = math.sqrt((star.position.x - 0) ^ 2 + (star.position.y - 0) ^ 2)
    local d2 = math.sqrt((star.position.x - MAP_PIXELS_W) ^ 2 + (star.position.y - 0) ^ 2)
    local d3 = math.sqrt((star.position.x - 0) ^ 2 + (star.position.y - MAP_PIXELS_H) ^ 2)
    local d4 = math.sqrt((star.position.x - MAP_PIXELS_W) ^ 2 + (star.position.y - MAP_PIXELS_H) ^ 2)

    local max_distance = math.max(d1, d2, d3, d4)

    if max_distance <= 0 then
        return 0
    end

    -- Farthest from star => 0 tail.
    -- Closest to star => near 1 tail.
    local strength = 1 - (distance_to_star / max_distance)

    return clamp(strength, 0, 1)
end

function Comet:isOffMap()
    local padding = self.radius + 80

    return
        self.position.x < -padding or
        self.position.x > MAP_PIXELS_W + padding or
        self.position.y < -padding or
        self.position.y > MAP_PIXELS_H + padding
end

-- ==========================================
-- COMET UPDATE
-- ==========================================

function Comet:move()
    if self.dead then
        return
    end

    local components = self:getVectorComponents(self.velocity)

    self.position.x = self.position.x + components.xComp
    self.position.y = self.position.y + components.yComp
end

function Comet:getTailDirection()
    -- Comet tails usually point away from the star.
    if game.play.star then
        local star = game.play.star
        local dx = self.position.x - star.position.x
        local dy = self.position.y - star.position.y

        if dx ~= 0 or dy ~= 0 then
            return math.atan(dy, dx)
        end
    end

    -- Fallback: trail opposite movement direction.
    return self.velocity.direction + math.pi
end

function Comet:spawnTailParticles()
    local strength = self:getTailStrength()
    local mass_fraction = 1

    if self.mass_initial and self.mass_initial > 0 then
        mass_fraction = clamp(self.mass / self.mass_initial, 0, 1)
    end

    local shedding_bonus = 1 + (1 - mass_fraction) * 2

    -- No tail when very far away.
    if strength <= 0.05 then
        return
    end

    local tail_direction = self:getTailDirection()

    -- Spawn rate increases near the star.
    local spawn_amount = (
        COMET_TAIL_SPAWN_MIN +
        strength * (COMET_TAIL_SPAWN_MAX - COMET_TAIL_SPAWN_MIN)
    ) * shedding_bonus

    self.tail_spawn_carry = self.tail_spawn_carry + spawn_amount

    local spawn_count = math.floor(self.tail_spawn_carry)
    self.tail_spawn_carry = self.tail_spawn_carry - spawn_count

    -- Tail length increases near the star.
    local max_tail_life = math.floor(
        COMET_TAIL_LIFE_MIN +
        strength * (COMET_TAIL_LIFE_MAX - COMET_TAIL_LIFE_MIN)
    )

    local max_tail_speed =
        COMET_TAIL_SPEED_MIN +
        strength * (COMET_TAIL_SPEED_MAX - COMET_TAIL_SPEED_MIN)

    for i = 1, spawn_count do
        local spread = randomFloat(-0.08, 0.08)
        local direction = tail_direction + spread

        local spawn_back = randomFloat(0, self.radius)
        local spawn_side = randomFloat(-self.radius * 0.5, self.radius * 0.5)

        local side_angle = direction + math.pi / 2

        local px =
            self.position.x +
            math.cos(direction) * spawn_back +
            math.cos(side_angle) * spawn_side

        local py =
            self.position.y +
            math.sin(direction) * spawn_back +
            math.sin(side_angle) * spawn_side

        table.insert(self.tail_particles, {
            x = px,
            y = py,
            direction = direction,
            speed = randomFloat(0.05, max_tail_speed),
            life = max_tail_life,
            max_life = max_tail_life,
            size = math.random(1, 2),
            color = randomChoice(self.color_list),
        })
    end
end

function Comet:updateTailParticles()
    for i = #self.tail_particles, 1, -1 do
        local particle = self.tail_particles[i]

        particle.life = particle.life - 1

        if particle.life <= 0 then
            table.remove(self.tail_particles, i)
        else
            particle.x = particle.x + math.cos(particle.direction) * particle.speed
            particle.y = particle.y + math.sin(particle.direction) * particle.speed

            -- Slight slowdown/drift.
            particle.speed = particle.speed * 0.985
        end
    end
end

function Comet:evaporate()
    if self.dead then
        return
    end

    local strength = self:getTailStrength()

    if strength <= 0.05 then
        return
    end

    local curved_strength = strength ^ 3
    local evaporation_rate =
        COMET_EVAPORATION_MIN +
        curved_strength * (COMET_EVAPORATION_MAX - COMET_EVAPORATION_MIN)

    self.mass = self.mass - evaporation_rate

    if self.mass <= 0 then
        self.mass = 0
        self:kill()
        return
    end

    local mass_fraction = clamp(self.mass / self.mass_initial, 0, 1)

    -- Square root gives a nicer radius-vs-mass feel than linear shrink.
    self.draw_scale = math.sqrt(mass_fraction)

    self.radius = math.max(1, self.radius_initial * self.draw_scale)
end

function Comet:update()
    self:updateTimer()

    if not self.dead then
        self:move()
        self:evaporate()

        -- Only living comets spawn new tail particles.
        if not self.dead then
            self:spawnTailParticles()
        end
    end

    -- Existing tail particles continue after the comet dies.
    self:updateTailParticles()
end

-- ==========================================
-- COMET DRAW
-- ==========================================

function Comet:drawTailParticles()
    for _, particle in ipairs(self.tail_particles) do
        local screen_x, screen_y = worldToScreen(particle.x, particle.y)

        screen_x = math.floor(screen_x)
        screen_y = math.floor(screen_y)

        -- Skip if off-screen.
        if screen_x >= 0 and screen_x < SCREEN_W and
            screen_y >= 0 and screen_y < SCREEN_H then
            pix(screen_x, screen_y, particle.color)
        end
    end
end

function Comet:drawBody()
    local zoom = game.camera.zoom or 1

    local screen_x, screen_y = worldToScreen(self.position.x, self.position.y)

    screen_x = math.floor(screen_x)
    screen_y = math.floor(screen_y)

    local scale = self.draw_scale or 1
    local r     = math.max(1, math.floor(self.radius_initial * scale * zoom))

    -- Skip if comfortably off-screen.
    if screen_x < -r - 8 or screen_x > SCREEN_W + r + 8 or
        screen_y < -r - 8 or screen_y > SCREEN_H + r + 8 then
        return
    end

    -- Draw lump composed of squished-together colored circles.
    for _, lump in ipairs(self.lumps) do
        local lx = screen_x + math.floor(lump.x * scale * zoom)
        local ly = screen_y + math.floor(lump.y * scale * zoom)
        local lr = math.max(1, math.floor(lump.r * scale * zoom))

        circ(lx, ly, lr, lump.color)
    end
end

function Comet:draw()
    -- Tail can remain after body is gone.
    self:drawTailParticles()

    if not self.dead then
        self:drawBody()
    end
end


-- [/TQ-Bundler: src.classes.Comet]

-- [TQ-Bundler: src.classes.Asteroid]

-- ==========================================
-- ASTEROID OBJECT
-- ==========================================

--[[
    Adapted from the Asteroids clone.
--]]

Asteroid = setmetatable({}, { __index = KeplerObj })
Asteroid.__index = Asteroid

function Asteroid:new(params)
    params = params or {}

    params.mass   = params.mass or randomFloat(ASTEROID_MIN_MASS, ASTEROID_MAX_MASS)
    params.radius = params.radius or randomFloat(ASTEROID_RADIUS_MIN, ASTEROID_RADIUS_MAX)
    params.colors = params.colors or shuffledAsteroidColors()
    params.color  = params.color or params.colors.primary

    local direction     = params.direction or randomFloat(0, math.pi * 2)
    local speed         = params.speed or randomFloat(ASTEROID_SPEED_MIN, ASTEROID_SPEED_MAX)
    params.direction    = direction
    params.speed        = speed
    params.acceleration = params.acceleration or 0
    params.deceleration = params.deceleration or 0

    local self = KeplerObj:new(params)
    setmetatable(self, Asteroid)

    self.name = params.name or "Asteroid"

    -- Asteroid-specific properties, adapted from your old class.
    -- self.base_points    = params.base_points or 50
    self.clumpiness   = params.clumpiness or 0.35
    self.scale        = params.scale or 1
    self.num_vertices = params.num_vertices or math.random(ASTEROID_VERTICES_MIN, ASTEROID_VERTICES_MAX)

    self.radius       = params.radius or self.radius or 15
    self.radius_minus = params.radius_minus or ASTEROID_RADIUS_MINUS
    self.radius_plus  = params.radius_plus or ASTEROID_RADIUS_PLUS

    self.rotation       = params.rotation or randomFloat(0, math.pi * 2)
    self.rotation_max   = params.rotation_max or ASTEROID_ROTATION_MAX
    self.rotation_speed = params.rotation_speed or randomFloat(-self.rotation_max, self.rotation_max)

    self.velocity_min = params.velocity_min or ASTEROID_SPEED_MIN
    self.velocity_max = params.velocity_max or ASTEROID_SPEED_MAX

    -- Stable polygon shape.
    self.shape = params.shape or self:spawn()

    self.particle_systems = {
        explosion = {
            colors = params.explosion_colors or {
                WHITE,
                YELLOW,
                ORANGE,
                RED,
                GRAY_LITE,
                GRAY_MED,
            },
            params = {
                count_min    = 12,
                count_max    = 24,
                speed_min    = 0.25,
                speed_max    = 1.7,
                life_min     = 15,
                life_max     = 38,
                size_min     = 1,
                size_max     = 2,
                drag         = 0.965,
                spawn_radius = self.radius or 8,
            },
            particles = {},
        },
    }

    return self
end

-- ==========================================
-- ASTEROID GETTERS
-- ==========================================

function Asteroid:getRadius()
    return self.radius
end

function Asteroid:getScale()
    return self.scale
end

function Asteroid:getRadiusPlusMinus()
    return {
        plus  = self.radius_plus,
        minus = self.radius_minus,
    }
end

function Asteroid:isOffMap()
    local padding = self.radius + 80

    return
        self.position.x < -padding or
        self.position.x > MAP_PIXELS_W + padding or
        self.position.y < -padding or
        self.position.y > MAP_PIXELS_H + padding
end

-- ==========================================
-- ASTEROID SHAPE
-- ==========================================

function Asteroid:spawn()
    local vertices = {}

    local baseR    = self.radius

    -- Scale the "clumpiness" with size.
    local minus    = math.min(self.radius_minus, baseR * self.clumpiness)
    local plus     = math.min(self.radius_plus, baseR * self.clumpiness)

    table.insert(vertices, { x = baseR, y = 0 })

    for vertex = 1, self.num_vertices - 1 do
        local minr = math.max(1, baseR - minus)
        local maxr = math.max(minr + 0.01, baseR + plus)

        local r = randomFloat(minr, maxr)
        local a = (math.pi * 2 / self.num_vertices) * vertex

        table.insert(vertices, {
            x = r * math.cos(a),
            y = r * math.sin(a),
        })
    end

    table.insert(vertices, { x = baseR, y = 0 })

    return vertices
end


-- ==========================================
-- ASTEROID PARTICLE EFFECTS
-- ==========================================

function Asteroid:getParticleSystem(type)
    if not self.particle_systems then
        return nil
    end

    return self.particle_systems[type]
end

function Asteroid:hasLiveParticles()
    for _, system in pairs(self.particle_systems or {}) do
        if system.particles and #system.particles > 0 then
            return true
        end
    end

    return false
end

function Asteroid:spawnParticleBurst(type, x, y, direction, spread, count)
    local system = self:getParticleSystem(type)

    if not system then
        return
    end

    local p = system.params
    local particles = system.particles

    direction = direction or 0
    spread    = spread or math.pi * 2

    for i = 1, count do
        local particle_direction = direction - spread / 2 + math.random() * spread
        local spawn_radius       = p.spawn_radius or 0
        local spawn_angle        = math.random() * math.pi * 2
        local spawn_distance     = math.random() * spawn_radius

        local px = x + math.cos(spawn_angle) * spawn_distance
        local py = y + math.sin(spawn_angle) * spawn_distance

        table.insert(particles, {
            position = {
                x = px,
                y = py,
            },
            velocity = {
                speed     = randomFloat(p.speed_min or 0.1, p.speed_max or 1),
                direction = particle_direction,
            },
            life     = math.random(p.life_min or 10, p.life_max or 30),
            max_life = p.life_max or 30,
            size     = math.random(p.size_min or 1, p.size_max or 2),
            color    = system.colors[math.random(1, #system.colors)],
            drag     = p.drag or 1,
        })
    end
end

function Asteroid:updateParticleList(type)
    local system = self:getParticleSystem(type)

    if not system then
        return
    end

    local particles = system.particles

    for i = #particles, 1, -1 do
        local particle = particles[i]
        particle.life = particle.life - 1

        if particle.life <= 0 then
            table.remove(particles, i)
        else
            particle.velocity.speed = particle.velocity.speed * (particle.drag or 1)
            particle.velocity.direction = self:keepAngleInRange(particle.velocity.direction or 0)

            local components = self:getVectorComponents(particle.velocity)

            particle.position.x = particle.position.x + components.xComp
            particle.position.y = particle.position.y + components.yComp
        end
    end
end

function Asteroid:drawParticles(type)
    local system = self:getParticleSystem(type)

    if not system then
        return
    end

    local zoom = game.camera.zoom or 1

    for _, particle in ipairs(system.particles) do
        local screen_x, screen_y = worldToScreen(
            particle.position.x,
            particle.position.y
        )

        local size = math.max(1, particle.size * zoom)
        local alpha = particle.life / particle.max_life
        alpha = math.max(0, math.min(1, alpha))

        local color = particle.color or WHITE
        circ(math.floor(screen_x), math.floor(screen_y), size, color)
    end
end

function Asteroid:explosionEffect()
    local system = self:getParticleSystem("explosion")

    if not system then
        return
    end

    local p          = system.params
    local base_count = math.random(
        p.count_min or 12,
        p.count_max or 24
    )

    local radius_scale = math.max(0.75, (self.radius or 10) / 10)
    local count        = math.floor(base_count * radius_scale)
    self:spawnParticleBurst(
        "explosion",
        self.position.x,
        self.position.y,
        nil,
        math.pi * 2,
        count
    )
end


-- ==========================================
-- ASTEROID UPDATE
-- ==========================================

function Asteroid:move()
    if self.dead then
        return
    end

    local components = self:getVectorComponents(self.velocity)
    self.position.x = self.position.x + components.xComp
    self.position.y = self.position.y + components.yComp
    self.rotation   = self.rotation + self.rotation_speed
end

function Asteroid:update()
    self:updateTimer()

    -- Particles should keep updating even after the asteroid body is dead.
    self:updateParticleList("explosion")

    if self.dead then
        return
    end

    self:move()
end

-- ==========================================
-- ASTEROID COLLISION DAMAGE
-- ==========================================

function Asteroid:takeDamage(damage, other)
    damage = damage or 0

    if self.dead then
        return false
    end

    if damage <= 0 then
        return false
    end

    self.mass = (self.mass or 0) - damage

    if self.mass > 0 then
        return false
    end

    self.mass = 0

    -- Store collision info for Asteroid:explode().
    if other and other.position and self.position then
        local nx, ny = getCollisionNormal(self, other)

        self.break_normal = {
            x = nx,
            y = ny,
        }

        self.break_other = other
    else
        local direction = self.velocity and self.velocity.direction or randomFloat(0, math.pi * 2)

        self.break_normal = {
            x = math.cos(direction),
            y = math.sin(direction),
        }

        self.break_other = other
    end

    local fragments = self:kill()

    for _, fragment in ipairs(fragments or {}) do
        table.insert(game.play.asteroids, fragment)
    end

    return true
end

-- ==========================================
-- ASTEROID EXPLOSION
-- ==========================================

function Asteroid:explode()
    if self.exploded then
        return {}
    end

    self.exploded = true

    local asteroid_fragments = {}

    local orig_scale = self.scale or 1

    if orig_scale < ASTEROID_MAX_FRAGMENT_SCALE then
        local new_scale = orig_scale * 2

        -- Default break direction if no collision normal was supplied.
        local break_nx = 0
        local break_ny = 0

        if self.break_normal then
            break_nx = self.break_normal.x or 0
            break_ny = self.break_normal.y or 0
        end

        if break_nx == 0 and break_ny == 0 then
            break_nx = math.cos(self.velocity.direction or 0)
            break_ny = math.sin(self.velocity.direction or 0)
        end

        local break_angle = math.atan(break_ny, break_nx)

        -- Perpendicular direction for splitting the two fragments apart.
        local side_angle = break_angle + math.pi / 2

        for count = 1, 2 do
            local side_sign = -1

            if count == 2 then
                side_sign = 1
            end

            local fragment_radius = math.max(2, self.radius / new_scale)

            -- Send both fragments mostly away from the collision,
            -- but split them left/right so they visibly separate.
            local fragment_direction =
                break_angle +
                side_sign * randomFloat(0.35, 0.85)

            -- Move the spawned fragments slightly outside the impact area.
            local spawn_push = self.radius + fragment_radius + 2

            local spawn_x =
                self.position.x +
                math.cos(break_angle) * spawn_push +
                math.cos(side_angle) * side_sign * fragment_radius

            local spawn_y =
                self.position.y +
                math.sin(break_angle) * spawn_push +
                math.sin(side_angle) * side_sign * fragment_radius

            -- If the asteroid hit a large body, push fragments outside that body.
            -- This prevents fragments from spawning inside a planet/star/moon and
            -- instantly dying on the next frame.
            local other = self.break_other

            if other and other.position then
                local other_radius = getCollisionRadius(other)
                local dx = spawn_x - other.position.x
                local dy = spawn_y - other.position.y
                local dist_sq = dx * dx + dy * dy

                if dist_sq > 0 then
                    local dist = math.sqrt(dist_sq)
                    local min_dist = other_radius + fragment_radius + 2

                    if dist < min_dist then
                        local nx = dx / dist
                        local ny = dy / dist

                        spawn_x = other.position.x + nx * min_dist
                        spawn_y = other.position.y + ny * min_dist
                    end
                else
                    spawn_x = other.position.x + math.cos(break_angle) * (other_radius + fragment_radius + 2)
                    spawn_y = other.position.y + math.sin(break_angle) * (other_radius + fragment_radius + 2)
                end
            end

            local asteroid = Asteroid:new({
                name           = "Asteroid Fragment",
                colors         = self.colors,
                color          = self.color,
                x              = spawn_x,
                y              = spawn_y,
                speed          = randomFloat(self.velocity_min, self.velocity_max) + 0.15,
                direction      = fragment_direction,
                acceleration   = self.acceleration,
                deceleration   = self.deceleration,
                elasticity     = self.elasticity,
                scale          = new_scale,
                rotation_speed = randomFloat(-self.rotation_max, self.rotation_max),
                radius         = fragment_radius,
                radius_minus   = self.radius_minus,
                radius_plus    = self.radius_plus,
                num_vertices   = self.num_vertices,
                clumpiness     = self.clumpiness,
            })
            table.insert(asteroid_fragments, asteroid)
        end
    end

    self:explosionEffect()

    return asteroid_fragments
end

-- ==========================================
-- ASTEROID DRAW
-- ==========================================

function Asteroid:getRotatedPoint(point)
    local cos_r = math.cos(self.rotation)
    local sin_r = math.sin(self.rotation)

    return {
        x = point.x * cos_r - point.y * sin_r,
        y = point.x * sin_r + point.y * cos_r,
    }
end

function Asteroid:draw()
    local zoom               = game.camera.zoom or 1
    local screen_x, screen_y = worldToScreen(self.position.x, self.position.y)
    local screen_radius      = self.radius * zoom

    -- If the asteroid body and its particles are offscreen, skip drawing.
    -- The extra padding helps avoid clipping explosion particles.
    local padding = screen_radius + 64

    if screen_x < -padding or
        screen_x > SCREEN_W + padding or
        screen_y < -padding or
        screen_y > SCREEN_H + padding then
        return
    end

    -- Draw the asteroid body only while alive.
    if not self.dead then
        local cx = math.floor(screen_x)
        local cy = math.floor(screen_y)

        for i = 1, #self.shape - 1 do
            local p1 = self:getRotatedPoint(self.shape[i])
            local p2 = self:getRotatedPoint(self.shape[i + 1])

            local x1 = math.floor(screen_x + p1.x * zoom)
            local y1 = math.floor(screen_y + p1.y * zoom)
            local x2 = math.floor(screen_x + p2.x * zoom)
            local y2 = math.floor(screen_y + p2.y * zoom)

            tri(cx, cy, x1, y1, x2, y2, self.colors.secondary)
            line(x1, y1, x2, y2, self.colors.primary)
        end
    end

    -- Draw explosion particles even after the asteroid body is gone.
    self:drawParticles("explosion")
end


-- [/TQ-Bundler: src.classes.Asteroid]

-- ==========================================
-- MAIN TIC FUNCTION
-- ==========================================

function BOOT()
    math.randomseed(tstamp() + time())

    applyAllOptions()
    changeState(STATE.START)
end


function TIC()
    local currentState = states[game.state]
    if currentState then
        currentState.input()
        currentState.update()
        currentState.draw()
    end
end
