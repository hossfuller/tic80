-- ==========================================
-- SPACESTATION AND SPACEDOCS
-- ==========================================

local STATION_MASS        = 10000
local DOCK_MASS           = 1000
local STATION_RADIUS      = 100
local STATION_REAL_RADIUS = 25
local DOCK_RADIUS         = 10

function generateSpaceDockName(host_name, index)
    return host_name .. "-DOCK[" .. index .. "]"
end

function generateSpaceStationName(index)
    return "Station 9999X"
end

function generateSpaceStationCandidate(index)
    return SpaceStation:new({
        name = generateSpaceStationName(index or 1),
        x    = math.random(0, MAP_PIXELS_W - 1),
        y    = math.random(0, MAP_PIXELS_H - 1),
    })
end

function canPlaceSpaceStation(candidate, planets, star)
    -- SpaceStation is a Planet subclass, so reuse planet placement rules.
    return canPlacePlanet(candidate, planets, star)
end

function generateSpaceStations(planets)
    local stations = {}

    local station_count = 1
    local max_attempts_per_station = 100

    planets = planets or game.play.planets or {}

    for i = 1, station_count do
        local placed = false
        local attempts = 0

        while not placed and attempts < max_attempts_per_station do
            attempts = attempts + 1

            local candidate = generateSpaceStationCandidate(i)

            -- Reuse planet placement by passing all existing planet-like bodies.
            local planet_like_objects = {}

            for _, planet in ipairs(planets) do
                table.insert(planet_like_objects, planet)
            end

            for _, station in ipairs(stations) do
                table.insert(planet_like_objects, station)
            end

            if canPlaceSpaceStation(candidate, planet_like_objects, game.play.star) then
                table.insert(stations, candidate)
                placed = true
            end
        end
    end

    return stations
end
