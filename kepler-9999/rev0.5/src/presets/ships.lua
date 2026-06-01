-- ==========================================
-- SPACESHIP PRESETS
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
    name  = "Cruiser",
    shape = {
        { x = 8,  y = 0 },
        { x = -8, y = 6 },
        { x = -4, y = 0 },
        { x = -8, y = -6 },
        { x = 8,  y = 0 },
    },
    colors = {
        primary = BLUE_MED,
    },
    engines   = {
        energy = {
            cur = 300,
            max = 300,
            mul = 1,
            tik = 20,
        },
        life_support = {
            cur = 100,
            max = 100,
            mul = 1,
            tik = 3600,
        },
        shield = {
            cur = 100,
            max = 100,
            mul = 1,
            tik = 60,
        },
    },
    holds = {
        cargo = {
            max = 500, -- (kg)
        },
        passengers = {
            max = 6 * PASSENGER_TOTAL_MASS, -- (individuals and their luggage in kg)
        },
        smuggled = {
            max = 100, -- (kg)
        },
    },
    mass      = 100,   -- (kg)
    max_mass  = 1300,  -- (kg, includes passenger luggage)
    radius    = 10,    -- (pixels)
    max_speed = 2.5,
}

local freighter_ship = {
    name  = "Freighter",
    shape = {
        { x = 16, y = 0 },
        { x = 13, y = 5 },
        { x = 6, y = 5 },
        { x = 4, y = 7 },
        { x = 0, y = 8 },
        { x = -9, y = 8 },
        { x = -9, y = 6 },
        { x = -6, y = 2 },
        { x = -9, y = 0 },
        { x = -6, y = -2 },
        { x = -9, y = -6 },
        { x = -9, y = -8 },
        { x = 0, y = -8 },
        { x = 4, y = -7 },
        { x = 6, y = -5 },
        { x = 13, y = -5 },
        { x = 16, y = 0 },
    },
    colors = {
        primary = GREEN_MED,
    },
    engines   = {
        energy = {
            cur = 1000,
            max = 1000,
            mul = 1,
            tik = 20,
        },
        life_support = {
            cur = 100,
            max = 100,
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
    holds   = {
        cargo = {
            max = 2000, -- (kg)
        },
        passengers = {
            max = 4 * PASSENGER_TOTAL_MASS, -- (individuals in kg)
        },
        smuggled = {
            max = 400, -- (kg)
        },
    },
    mass      = 500,   -- (kg)
    max_mass  = 3300,  -- (kg, includes passenger luggage)
    radius    = 15,    -- (pixels)
    max_speed = 1.5,
}

local passenger_ship = {
    name  = "Passenger Ship",
    shape = {
        { x = 10, y = 0 },
        { x = 9, y = 2 },
        { x = 7, y = 3 },
        { x = -1, y = 3 },
        { x = -3, y = 6 },
        { x = 1, y = 6 },
        { x = 2, y = 7 },
        { x = 1, y = 9 },
        { x = -10, y = 9 },
        { x = -11, y = 7 },
        { x = -10, y = 6 },
        { x = -8, y = 6 },
        { x = -6, y = 3 },
        { x = -8, y = 3 },
        { x = -10, y = 2 },
        { x = -11, y = 0 },
        { x = -10, y = -2 },
        { x = -8, y = -3 },
        { x = -6, y = -3 },
        { x = -8, y = -6 },
        { x = -10, y = -6 },
        { x = -11, y = -7 },
        { x = -10, y = -9 },
        { x = 1, y = -9 },
        { x = 2, y = -7 },
        { x = 1, y = -6 },
        { x = -3, y = -6 },
        { x = -1, y = -3 },
        { x = 7, y = -3 },
        { x = 9, y = -2 },
        { x = 10, y = 0 },
    },
    colors    = {
        primary = WHITE,
    },
    engines   = {
        energy = {
            cur = 500,
            max = 500,
            mul = 1,
            tik = 20,
        },
        life_support = {
            cur = 500,
            max = 500,
            mul = 1,
            tik = 3600,
        },
        shield = {
            cur = 100,
            max = 100,
            mul = 1,
            tik = 60,
        },
    },
    holds = {
        cargo = {
            max = 500, -- (kg)
        },
        passengers = {
            max = 16 * PASSENGER_TOTAL_MASS, -- (individuals in kg)
        },
        smuggled = {
            max = 100, -- (kg)
        },
    },
    mass      = 500,  -- (kg)
    max_mass  = 2700, -- (kg, includes passenger luggage)
    radius    = 15,   -- (pixels)
    max_speed = 2.0,
}

local smuggler_ship = {
    name  = "Smuggler",
    shape = {
        { x = 3, y = 0 },
        { x = 6, y = 3 },
        { x = 0, y = 6 },
        { x = -8, y = 9 },
        { x = -6, y = 3 },
        { x = -9, y = 0 },
        { x = -6, y = -3 },
        { x = -8, y = -9 },
        { x = 0, y = -6 },
        { x = 6, y = -3 },
        { x = 3, y = 0 },
    },
    colors    = {
        primary = RED,
    },
    engines   = {
        energy = {
            cur = 500,
            max = 500,
            mul = 1,
            tik = 20,
        },
        life_support = {
            cur = 100,
            max = 100,
            mul = 1,
            tik = 3600,
        },
        shield = {
            cur = 150,
            max = 150,
            mul = 1,
            tik = 60,
        },
    },
    holds     = {
        cargo = {
            max = 250, -- (kg)
        },
        passengers = {
            max = 2 * PASSENGER_TOTAL_MASS, -- (individuals in kg)
        },
        smuggled = {
            max = 1000, -- (kg)
        },
    },
    mass      = 250,  -- (kg)
    max_mass  = 1700, -- (kg, includes passenger luggage)
    radius    = 10,   -- (pixels)
    max_speed = 2.5,
}

-- Use this in `generatePlayer()`.
ship_presets = {
    cruiser_ship,
    freighter_ship,
    passenger_ship,
    smuggler_ship,
}