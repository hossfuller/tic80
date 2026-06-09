-- ==========================================
-- MISSIONS
-- ==========================================

local MISSION_PLANET_DOCK_COUNT = 3
local MISSION_SPACE_STATION_COUNT = 5

local MISSION_CARGO_MASS_MIN = 50
local MISSION_CARGO_MASS_MAX = 1000

local MISSION_PASSENGER_MIN = 1
local MISSION_PASSENGER_MAX = 30

local MISSION_TYPE = {
    CARGO                = "cargo",
    PASSENGER            = "passenger",
    CONTRABAND_CARGO     = "contraband_cargo",
    CONTRABAND_PASSENGER = "contraband_passenger",
}

local MISSION_STATUS = {
    AVAILABLE = "available",
    ACCEPTED  = "accepted",
    COMPLETED = "completed",
    FAILED    = "failed",
}

function generateMissionId(length)
    length = length or 6

    local chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    local id = ""

    for i = 1, length do
        local index = math.random(1, #chars)
        id = id .. string.sub(chars, index, index)
    end

    return id
end

function getRandomMissionType()
    local types = {
        MISSION_TYPE.CARGO,
        MISSION_TYPE.PASSENGER,
        MISSION_TYPE.CONTRABAND_CARGO,
        MISSION_TYPE.CONTRABAND_PASSENGER,
    }

    return types[math.random(1, #types)]
end




function createRandomMission(source)
    local destinations = getMissionDestinationsForSource(source)

    if #destinations <= 0 then
        return nil
    end

    local destination = destinations[math.random(1, #destinations)]
    local mission_type = getRandomMissionType()

    local params = {
        source = source,
        destination = destination,
        type = mission_type,
        status = MISSION_STATUS.AVAILABLE,
    }

    if mission_type == MISSION_TYPE.PASSENGER or
        mission_type == MISSION_TYPE.CONTRABAND_PASSENGER
    then
        params.passengers_total = math.random(
            MISSION_PASSENGER_MIN,
            MISSION_PASSENGER_MAX
        )
    else
        params.mass_total = math.random(
            MISSION_CARGO_MASS_MIN,
            MISSION_CARGO_MASS_MAX
        )
    end

    return Mission:new(params)
end

function generateInitialMissions()
    game.play.missions = {}

    -- 3 missions per planet-associated SpaceDock.
    for _, planet in ipairs(game.play.planets or {}) do
        for _, dock in ipairs(planet.docks or {}) do
            if isPlanetDock(dock) then
                local missions = generateMissionsForSource(
                    dock,
                    MISSION_PLANET_DOCK_COUNT
                )

                for _, mission in ipairs(missions) do
                    table.insert(game.play.missions, mission)
                end
            end
        end
    end

    -- 5 missions per SpaceStation.
    for _, station in ipairs(game.play.space_stations or {}) do
        if isSpaceStation(station) then
            local missions = generateMissionsForSource(
                station,
                MISSION_SPACE_STATION_COUNT
            )

            for _, mission in ipairs(missions) do
                table.insert(game.play.missions, mission)
            end
        end
    end
end

function generateMissionsForSource(source, count)
    local generated = {}

    for i = 1, count do
        local mission = createRandomMission(source)

        if mission then
            table.insert(generated, mission)
        end
    end

    return generated
end

function getMissionDestinationsForSource(source)
    local destinations = {}

    -- Missions sourced from a SpaceStation go to planet docks.
    if isSpaceStation(source) then
        return getAllPlanetSpaceDocks()
    end

    -- Missions sourced from a planet SpaceDock can go to:
    -- - another planet's SpaceDock
    -- - a SpaceStation
    if isPlanetDock(source) then
        for _, dock in ipairs(getAllPlanetSpaceDocks()) do
            if dock ~= source then
                table.insert(destinations, dock)
            end
        end

        for _, station in ipairs(getAllSpaceStations()) do
            table.insert(destinations, station)
        end
    end

    return destinations
end

function getAllPlanetSpaceDocksExceptDock(source_dock)
    local docks = {}

    for _, planet in ipairs(game.play.planets or {}) do
        for _, dock in ipairs(planet.docks or {}) do
            if dock ~= source_dock and isPlanetDock(dock) then
                table.insert(docks, dock)
            end
        end
    end

    return docks
end

function allMissionsAreTerminal()
    if not game.play.missions or #game.play.missions <= 0 then
        return true
    end

    for _, mission in ipairs(game.play.missions) do
        if not mission:isTerminal() then
            return false
        end
    end

    return true
end

function maintainMissionGeneration()
    if allMissionsAreTerminal() then
        generateInitialMissions()
    end
end

-- ==========================================
-- DOCK DETECTION AND CLASSIFICATION
-- ==========================================

function getAllPlanetSpaceDocks()
    local docks = {}

    for _, planet in ipairs(game.play.planets or {}) do
        for _, dock in ipairs(planet.docks or {}) do
            if isPlanetDock(dock) then
                table.insert(docks, dock)
            end
        end
    end

    return docks
end

function getAllSpaceStations()
    local stations = {}

    for _, station in ipairs(game.play.space_stations or {}) do
        if isSpaceStation(station) then
            table.insert(stations, station)
        end
    end

    return stations
end

function isSpaceDock(obj)
    return SpaceDock ~= nil and getmetatable(obj) == SpaceDock
end

function isSpaceStation(obj)
    return SpaceStation ~= nil and getmetatable(obj) == SpaceStation
end

function isPlanet(obj)
    return Planet ~= nil and getmetatable(obj) == Planet
end

function isPlanetDock(dock)
    return isSpaceDock(dock) and dock.host and isPlanet(dock.host)
end

function isStationDock(dock)
    return isSpaceDock(dock) and dock.host and isSpaceStation(dock.host)
end
