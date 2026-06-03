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
