-- ==========================================
-- GENERATORS
-- ==========================================

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

-- ==========================================
-- KEPLER OBJECTS, INCLUDING SHIPS
-- ==========================================

--[[
Important shape rules
This triangulation assumes your polygon is:

- Simple — edges do not cross each other.
- Ordered — points go around the outline in clockwise or counter-clockwise order.
- Not full of duplicate points — except the final point may duplicate the first point.
- Not self-intersecting.

Performance note
For one player ship, recalculating triangulation every frame is totally fine.

But if you later have many polygon ships/enemies with fixed shapes, you may want to triangulate the local shape once and then rotate/draw the triangle vertices each frame. For now, this version is simpler and reusable.
--]]


function generatePlayer()
    local selected_ship = game.params.ship_type or 1
    local preset = ship_presets[selected_ship] or cruiser_ship
    return SpaceShip:new(preset)
end

--[[ STARS ]]--

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

--[[ PLANETS ]] --

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

--[[ MOONS ]] --

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
