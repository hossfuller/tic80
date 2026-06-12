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
