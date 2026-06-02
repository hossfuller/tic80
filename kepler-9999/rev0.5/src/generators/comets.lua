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

local COMET_COLORS          = {
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
