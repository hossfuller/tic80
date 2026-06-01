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

function generateMoons()
    local moons = {}

end