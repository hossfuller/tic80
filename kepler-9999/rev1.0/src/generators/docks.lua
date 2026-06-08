-- ==========================================
-- SPACESTATION AND SPACEDOCS
-- ==========================================

local STATION_MASS        = 10000
local DOCK_MASS           = 2000  -- definitely destructable, watch your flying!
local STATION_RADIUS      = 100
local STATION_REAL_RADIUS = 25
local DOCK_RADIUS         = 10
local DOCK_REAL_RADIUS    = 10
local DOCK_ORBIT_PADDING  = 35

local STATION_ORE_BANK_MAX = 100000
local DOCK_ORE_BANK_MAX    = 10000

function generateSpaceStationName(index)
    return "Station 9999X"
end

function generateSpaceStationCandidate(index)
    local temp_station = SpaceStation:new({
        name = generateSpaceStationName(index or 1),
        x    = 0,
        y    = 0,
    })
    local margin = getSpaceStationTotalDockReach(temp_station)

    return SpaceStation:new({
        name = generateSpaceStationName(index or 1),
        x    = math.random(math.ceil(margin), math.floor(MAP_PIXELS_W - 1 - margin)),
        y    = math.random(math.ceil(margin), math.floor(MAP_PIXELS_H - 1 - margin)),
    })
end

function spaceStationDocksStayOnMap(station)
    if not station or not station.position then
        return false
    end

    local margin = getSpaceStationTotalDockReach(station)

    return
        station.position.x - margin >= 0 and
        station.position.y - margin >= 0 and
        station.position.x + margin < MAP_PIXELS_W and
        station.position.y + margin < MAP_PIXELS_H
end

function canPlaceSpaceStation(candidate, planets, star)
    if not spaceStationDocksStayOnMap(candidate) then
        return false
    end

    -- SpaceStation is a Planet subclass, so reuse planet placement rules.
    return canPlacePlanet(candidate, planets, star)
end

function getSpaceStationDockOrbitRadius(station)
    return getCollisionRadius(station) + DOCK_RADIUS + DOCK_ORBIT_PADDING
end

function getSpaceStationTotalDockReach(station)
    return getSpaceStationDockOrbitRadius(station) + DOCK_RADIUS
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

function generateSpaceDockName(host_name, index)
    return host_name .. "-DOCK[" .. index .. "]"
end

function generatePlanetSpaceDock(planet, index)
    index = index or 1

    local orbit_radius =
        getCollisionRadius(planet) +
        DOCK_RADIUS +
        35

    return SpaceDock:new({
        name = generateSpaceDockName(planet.name or "Planet", index),
        host = planet,

        orbit = {
            semi_major   = orbit_radius,
            eccentricity = 0.15,
            angle        = randomFloat(0, math.pi * 2),
            phase        = randomFloat(0, math.pi * 2),
            period       = math.random(1200, 2400),
        },
    })
end

function generateSpaceStationDock(station, index, total)
    index = index or 1
    total = total or 6

    local phase        = ((index - 1) / total) * math.pi * 2
    local orbit_radius = getSpaceStationDockOrbitRadius(station)

    return SpaceDock:new({
        name = generateSpaceDockName(station.name or "Station", index),
        host = station,
        orbit = {
            semi_major   = orbit_radius,
            eccentricity = 0,
            angle        = 0,
            phase        = phase,
            period       = 1800,
        },
    })
end

function addSpaceDocksToPlanets(planets)
    planets = planets or {}

    for _, planet in ipairs(planets) do
        planet.docks = planet.docks or {}

        -- Each planet gets exactly one dock.
        if #planet.docks <= 0 then
            table.insert(planet.docks, generatePlanetSpaceDock(planet, 1))
        end
    end
end

function addSpaceDocksToStations(stations)
    stations = stations or {}

    for _, station in ipairs(stations) do
        station.docks = station.docks or {}

        -- Each SpaceStation gets exactly six docks.
        if #station.docks <= 0 then
            for i = 1, 6 do
                table.insert(station.docks, generateSpaceStationDock(station, i, 6))
            end
        end
    end
end
