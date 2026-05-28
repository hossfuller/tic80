-- ==========================================
-- SPACESHIP PRESETS
-- ==========================================

--[[
    These are presets for all the different types of ships a user can play as.
    These presets are used by the `generatePlayer()` function. The user will
    select which ship they want to fly around with at the options screen.
--]]


local default_ship = {
    shape = {
        { x = 8,  y = 0 },
        { x = -8, y = 6 },
        { x = -4, y = 0 },
        { x = -8, y = -6 },
        { x = 8,  y = 0 },
    },
    engines = {
        energy = {
            cur = 250,
            max = 250,
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

local freight_ship = {
    shape     = {
        { x = 8,  y = 0 },
        { x = -8, y = 6 },
        { x = -4, y = 0 },
        { x = -8, y = -6 },
        { x = 8,  y = 0 },
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
    shape = {
        { x = 8,  y = 0 },
        { x = -8, y = 6 },
        { x = -4, y = 0 },
        { x = -8, y = -6 },
        { x = 8,  y = 0 },
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
    shape     = {
        { x = 8,  y = 0 },
        { x = -8, y = 6 },
        { x = -4, y = 0 },
        { x = -8, y = -6 },
        { x = 8,  y = 0 },
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
    default_ship,
    freight_ship,
    passenger_ship,
    smuggler_ship,
}
















-- local freight_shape = {
--     { x = -7, y = 0 },
--     { x = -4, y = 1 },
--     { x = -2, y = 4 },
--     { x = -4, y = 4 },
--     { x = -6, y = 6 },
--     { x = -7, y = 9 },
--     { x = -1, y = 9 },
--     { x = 2,  y = 7 },
--     { x = 5,  y = 4 },
--     { x = 7,  y = 0 },
--     { x = 5,  y = -4 },
--     { x = 2,  y = -7 },
--     { x = -1, y = -9 },
--     { x = -7, y = -9 },
--     { x = -6, y = -6 },
--     { x = -4, y = -4 },
--     { x = -2, y = -4 },
--     { x = -4, y = -1 },
--     { x = -7, y = -0 },
--     { x = 5,  y = 4 },
--     { x = 3,  y = 1 },
--     { x = 2,  y = 0 },
--     { x = 3,  y = -1 },
--     { x = 5,  y = -4 },

-- }
-- local smuggler_shape = {
--     { x = -5, y = -5 },
--     { x = 0,  y = -4 },
--     { x = 5,  y = 0 },
--     { x = 0,  y = 4 },
--     { x = -5, y = 5 },
--     { x = -4, y = 3 },
--     { x = -3, y = 0 },
--     { x = -4, y = -3 },
--     { x = -5, y = -5 },
-- }
-- local passenger_shape = {
--     { x = -6, y = -0 },
--     { x = 8,  y = -3 },
--     { x = 6,  y = 0 },
--     { x = 8,  y = 3 },
--     { x = -6, y = 0 },
--     { x = -4, y = 1 },
--     { x = -2, y = 6 },
--     { x = 2,  y = 2 },
--     { x = -4, y = 1 },
--     { x = 0,  y = 3 },
--     { x = -4, y = 1 },
--     { x = -2, y = -6 },
--     { x = 2,  y = -2 },
--     { x = -4, y = -1 },
--     { x = 0,  y = -3 },

-- }
