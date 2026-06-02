-- ==========================================
-- ASTEROIDS
-- ==========================================

local ASTEROID_MIN_MASS           = 5
local ASTEROID_MAX_MASS           = 300
local ASTEROID_RADIUS_MIN         = 6
local ASTEROID_RADIUS_MAX         = 22
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
