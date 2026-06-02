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
