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
    COLLECT_ORE          = "collect_ore",
    REPAIR_DOCK          = "repair_dock",
}

local MISSION_STATUS = {
    ACTIVE    = "active",
    COMPLETED = "completed",
}

local MISSION_PROFILE = {
    [1] = { -- Cruiser
        cargo_weight      = 0.40,
        passenger_weight  = 0.40,
        contraband_weight = 0.10,
        ore_weight        = 0.10,
        cargo_mass_min    = MISSION_CARGO_MASS_MIN,
        cargo_mass_max    = MISSION_CARGO_MASS_MAX,
        passenger_min     = MISSION_PASSENGER_MIN,
        passenger_max     = MISSION_PASSENGER_MAX,
    },

    [2] = { -- Freighter
        cargo_weight      = 0.60,
        passenger_weight  = 0.15,
        contraband_weight = 0.10,
        ore_weight        = 0.15,
        cargo_mass_min    = 300,
        cargo_mass_max    = 1800,
        passenger_min     = 1,
        passenger_max     = 2 * 4,
    },

    [3] = { -- Passenger
        cargo_weight      = 0.15,
        passenger_weight  = 0.65,
        contraband_weight = 0.10,
        ore_weight        = 0.10,
        cargo_mass_min    = 2 * 350,
        cargo_mass_max    = 2500,
        passenger_min     = 6,
        passenger_max     = 30,
    },

    [4] = { -- Smuggler
        cargo_weight      = 0.15,
        passenger_weight  = 0.15,
        contraband_weight = 0.55,
        ore_weight        = 0.15,
        cargo_mass_min    = 50,
        cargo_mass_max    = 900,
        passenger_min     = 1,
        passenger_max     = 8,
    },
}

-- ==========================================
-- MISSIONS CREATION
-- ==========================================

function getMissionProfileForCurrentShip()
    local ship_type = game.params.ship_type or 1
    return MISSION_PROFILE[ship_type] or MISSION_PROFILE[1]
end

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
    local profile           = getMissionProfileForCurrentShip()
    local contraband_weight = profile.contraband_weight or 0.10
    local passenger_weight  = profile.passenger_weight or 0.45
    local ore_weight        = profile.ore_weight or 0.00
    local contraband_cutoff = contraband_weight
    local passenger_cutoff  = contraband_cutoff + passenger_weight
    local ore_cutoff        = passenger_cutoff + ore_weight
    local roll              = math.random()

    if roll < contraband_cutoff then
        if math.random() < 0.5 then
            return MISSION_TYPE.CONTRABAND_CARGO
        else
            return MISSION_TYPE.CONTRABAND_PASSENGER
        end
    elseif roll < passenger_cutoff then
        return MISSION_TYPE.PASSENGER
    elseif roll < ore_cutoff then
        return MISSION_TYPE.COLLECT_ORE
    else
        return MISSION_TYPE.CARGO
    end
end

function createRandomMission(source)
    if not source then
        return nil
    end

    local profile      = getMissionProfileForCurrentShip()
    local mission_type = getRandomMissionType()
    local destination  = nil

    if mission_type == MISSION_TYPE.COLLECT_ORE then
        -- ORE collection happens at the same dock/station that requested it.
        destination = source
    else
        local destinations = getMissionDestinationsForSource(source)
        if #destinations <= 0 then
            return nil
        end
        destination = destinations[math.random(1, #destinations)]
    end

    local params = {
        source      = source,
        destination = destination,
        type        = mission_type,
        status      = MISSION_STATUS.ACTIVE,
    }

    if mission_type == MISSION_TYPE.PASSENGER or
        mission_type == MISSION_TYPE.CONTRABAND_PASSENGER
    then
        params.passengers_total = math.random(
            profile.passenger_min or MISSION_PASSENGER_MIN,
            profile.passenger_max or MISSION_PASSENGER_MAX
        )
    else
        -- Regular cargo, contraband cargo, and ORE collection all use cargo mass sizing.
        params.mass_total = math.random(
            profile.cargo_mass_min or MISSION_CARGO_MASS_MIN,
            profile.cargo_mass_max or MISSION_CARGO_MASS_MAX
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
    removeCompletedRepairMissions()

    local had_missions = game.play.missions and #game.play.missions > 0

    if allMissionsAreTerminal() then
        if had_missions then
            local reward_text = rewardShipWithRandomUpgrade(game.play.player)

            if notifyMissionReward then
                notifyMissionReward(reward_text)
            end
        end

        generateInitialMissions()
    end
end

-- ==========================================
-- MISSION DOCK REPAIR CODE
-- ==========================================

function removeCompletedRepairMissions()
    if not game.play.missions then
        return
    end

    for i = #game.play.missions, 1, -1 do
        local mission = game.play.missions[i]

        if mission and
            mission:isDockRepairMission() and
            mission:isCompleted()
        then
            table.remove(game.play.missions, i)
        end
    end
end

function getPrimarySpaceStation()
    for _, station in ipairs(game.play.space_stations or {}) do
        if isSpaceStation(station) then
            return station
        end
    end

    return nil
end

function hasActiveRepairMissionForDock(dock)
    if not dock then
        return false
    end

    for _, mission in ipairs(game.play.missions or {}) do
        if mission and
            mission:canAct() and
            mission:isDockRepairMission() and
            mission.repair_target == dock
        then
            return true
        end
    end

    return false
end

function createDockRepairMission(dock, station)
    if not dock or not station then
        return nil
    end

    if hasActiveRepairMissionForDock(dock) then
        return nil
    end

    local mission = Mission:new({
        source        = station,
        destination   = station,
        type          = MISSION_TYPE.REPAIR_DOCK,
        status        = MISSION_STATUS.ACTIVE,
        mass_total    = DOCK_MASS,
        repair_target = dock,
    })

    table.insert(game.play.missions, mission)

    return mission
end

function removeMissionsInvolvingDock(dock)
    if not dock or not game.play.missions then
        return
    end

    for i = #game.play.missions, 1, -1 do
        local mission = game.play.missions[i]

        if mission and
            not mission:isDockRepairMission() and
            (
                mission.source == dock or
                mission.destination == dock
            )
        then
            table.remove(game.play.missions, i)
        end
    end
end

function clearShipManifestForDockMissions(ship, dock)
    if not ship or not dock or not game.play.missions then
        return
    end

    for _, mission in ipairs(game.play.missions or {}) do
        if mission and
            (
                mission.source == dock or
                mission.destination == dock
            )
        then
            removeShipMissionManifestAmount(ship, mission, 999999999)
        end
    end
end

function onSpaceDockDestroyed(dock)
    if not dock then
        return
    end

    -- Clear carried manifest entries before removing the missions from the
    -- global mission list.
    if game.play.player then
        clearShipManifestForDockMissions(game.play.player, dock)
    end

    -- Remove stale missions sourced from or destined to the destroyed dock.
    removeMissionsInvolvingDock(dock)

    -- Repair missions are issued by the SpaceStation.
    -- If this is a station-attached dock, use its host station.
    -- If this is a planet dock, use the primary station.
    local station = nil

    if isStationDock(dock) then
        station = dock.host
    else
        station = getPrimarySpaceStation()
    end

    createDockRepairMission(dock, station)
end

function shouldDeferSpaceDockRestore(dock)
    if not dock then
        return false
    end

    -- Only station-attached docks need delayed restore.
    if not isStationDock(dock) then
        return false
    end

    local ship = game
        and game.play
        and game.play.player

    if not ship or not ship.getDockedSpaceDock then
        return false
    end

    -- Station-attached repaired docks regenerate only after undocking from the
    -- station/dock interaction.
    return ship:getDockedSpaceDock() ~= nil
end

function restorePendingStationSpaceDocks()
    if not game or not game.play or not game.play.space_stations then
        return
    end

    for _, station in ipairs(game.play.space_stations) do
        if station.docks then
            for _, dock in ipairs(station.docks) do
                if dock.pending_restore and dock.restore then
                    dock:restore()
                end
            end
        end
    end
end

-- ==========================================
-- MISSION LEVEL-COMPLETE UPGRADES
-- ==========================================

function getAvailableMissionRewardUpgrades(ship)
    local upgrades = {}

    if ship:canUpgradeEngine("energy") then
        table.insert(upgrades, {
            label = "Energy Generator Upgraded",
            apply = function()
                return ship:upgradeEngine("energy")
            end,
        })
    end

    if ship:canUpgradeEngine("life_support") then
        table.insert(upgrades, {
            label = "Life Support Upgraded",
            apply = function()
                return ship:upgradeEngine("life_support")
            end,
        })
    end

    if ship:canUpgradeEngine("shield") then
        table.insert(upgrades, {
            label = "Shields Upgraded",
            apply = function()
                return ship:upgradeEngine("shield")
            end,
        })
    end

    if ship:canUpgradeMaxSpeed() then
        table.insert(upgrades, {
            label = "Engine Tuning Improved",
            apply = function()
                return ship:upgradeMaxSpeed()
            end,
        })
    end

    if ship:canUpgradeHold("cargo") then
        table.insert(upgrades, {
            label = "Cargo Hold Expanded",
            apply = function()
                return ship:upgradeHold("cargo")
            end,
        })
    end

    if ship:canUpgradeHold("passengers") then
        table.insert(upgrades, {
            label = "Passenger Hold Expanded",
            apply = function()
                return ship:upgradeHold("passengers")
            end,
        })
    end

    if ship:canUpgradeHold("smuggled") then
        table.insert(upgrades, {
            label = "Smuggled Hold Expanded",
            apply = function()
                return ship:upgradeHold("smuggled")
            end,
        })
    end

    return upgrades
end

function rewardShipWithRandomUpgrade(ship)
    if not ship then
        return nil
    end

    local upgrades = getAvailableMissionRewardUpgrades(ship)

    if #upgrades <= 0 then
        return nil
    end

    local reward = upgrades[math.random(1, #upgrades)]

    if reward and reward.apply then
        local ok = reward.apply()
        if ok then
            return reward.label
        end
    end

    return nil
end

-- ==========================================
-- MISSION UNLOADING WHILE DOCKED
-- ==========================================

function getMissionDestinationForDock(dock)
    if not dock then
        return nil
    end

    -- Dock attached to a SpaceStation represents the SpaceStation destination.
    if isStationDock(dock) then
        return dock.host
    end

    -- Planet SpaceDock represents itself.
    if isPlanetDock(dock) then
        return dock
    end

    return dock
end

function missionIsDestinedForDock(mission, dock)
    if not mission or not dock then
        return false
    end

    local destination = getMissionDestinationForDock(dock)

    return mission.destination == destination
end

function getActiveMissionsDestinedForDock(dock)
    local missions = {}

    if not dock then
        return missions
    end

    for _, mission in ipairs(game.play.missions or {}) do
        if mission and
            mission:canAct() and
            missionIsDestinedForDock(mission, dock)
        then
            local can_deliver_here = false

            -- ORE delivery missions, including dock repair missions, are
            -- delivered directly from generic mined ORE in the cargo hold.
            -- They do not need mission.mass.active > 0.
            if mission:isOreDeliveryMission() then
                can_deliver_here = true
            elseif mission:isPassengerMission() then
                can_deliver_here = (mission.passengers.active or 0) > 0
            else
                can_deliver_here = (mission.mass.active or 0) > 0
            end

            if can_deliver_here then
                table.insert(missions, mission)
            end
        end
    end

    return missions
end

function getMissionDeliveryHoldType(mission)
    return getMissionManifestHoldType(mission)
end

function getMissionDeliveryRatePerTick(mission)
    -- Same general feel as ore unloading: gradual automatic unloading.
    -- Cargo/smuggled goods unload 1 kg per TIC.
    -- Passengers unload 1 passenger per TIC.
    return 1
end

function deliverMissionCargoAtDock(ship, mission)
    if not ship or not mission then
        return 0
    end

    if not mission:canAct() or not mission:isCargoMission() then
        return 0
    end

    -- ORE delivery missions consume mined ORE directly from the normal cargo
    -- hold. This includes:
    -- - MISSION_TYPE.COLLECT_ORE
    -- - MISSION_TYPE.REPAIR_DOCK
    -- They do not use mission.mass.active and do not use ship.mission_manifest.
    if mission:isOreDeliveryMission() then
        if ship.cargo_has_ore ~= true then
            return 0
        end

        if not ship.holds or not ship.holds.cargo then
            return 0
        end

        local cargo_hold = ship.holds.cargo
        if cargo_hold.cur <= 0 then
            return 0
        end

        local rate = getMissionDeliveryRatePerTick(mission)
        local remaining = math.max(0, mission.mass.total - mission.mass.transported)
        local requested_amount = math.min(
            rate,
            cargo_hold.cur,
            remaining
        )
        requested_amount = math.floor(requested_amount)
        if requested_amount <= 0 then
            return 0
        end

        local removed_from_ship = ship:updateHoldMass("cargo", -requested_amount)
        if not removed_from_ship then
            return 0
        end

        local delivered = mission:deliverOreMass(requested_amount)
        if delivered <= 0 then
            ship:updateHoldMass("cargo", requested_amount)
            return 0
        end

        ship:updateMassDelivered(delivered)

        if ship:getCargoMass() <= 0 then
            ship.cargo_has_ore = false
        end

        if notifyMassDelivered then
            notifyMassDelivered()
        end

        return delivered
    end

    local hold_type = getMissionDeliveryHoldType(mission)
    if not hold_type then
        return 0
    end

    if not ship.holds or not ship.holds[hold_type] then
        return 0
    end

    local hold = ship.holds[hold_type]
    if hold.cur <= 0 then
        return 0
    end

    local rate = getMissionDeliveryRatePerTick(mission)
    local requested_amount = math.min(
        rate,
        hold.cur,
        mission.mass.active or 0
    )

    requested_amount = math.floor(requested_amount)
    if requested_amount <= 0 then
        return 0
    end

    -- First remove from the ship hold.
    local removed_from_ship = ship:updateHoldMass(hold_type, -requested_amount)
    if not removed_from_ship then
        return 0
    end

    -- Then update mission progress.
    local delivered = mission:deliverMass(requested_amount)
    if delivered <= 0 then
        -- Should not normally happen, but restore the ship hold if mission
        -- delivery failed.
        ship:updateHoldMass(hold_type, requested_amount)
        return 0
    end

    removeShipMissionManifestAmount(ship, mission, delivered)

    -- Mission delivery counts toward score/mass delivered.
    ship:updateMassDelivered(delivered)

    -- Normal cargo hold is no longer ore if emptied.
    if hold_type == "cargo" and ship:getCargoMass() <= 0 then
        ship.cargo_has_ore = false
    end

    if notifyMassDelivered then
        notifyMassDelivered()
    end

    return delivered
end

function deliverMissionPassengersAtDock(ship, mission)
    if not ship or not mission then
        return 0
    end

    if not mission:canAct() or not mission:isPassengerMission() then
        return 0
    end

    if not ship.holds or not ship.holds.passengers then
        return 0
    end

    local passenger_hold = ship.holds.passengers
    if passenger_hold.cur <= 0 then
        return 0
    end

    local active_passengers = mission.passengers.active or 0
    if active_passengers <= 0 then
        return 0
    end

    local passenger_rate = getMissionDeliveryRatePerTick(mission)
    local available_passengers_on_ship = math.floor(
        passenger_hold.cur / PASSENGER_TOTAL_MASS
    )
    local passenger_count = math.min(
        passenger_rate,
        available_passengers_on_ship,
        active_passengers
    )
    if passenger_count <= 0 then
        return 0
    end

    local passenger_mass = passenger_count * PASSENGER_TOTAL_MASS

    -- First remove passenger mass from the ship.
    local removed_from_ship = ship:updateHoldMass("passengers", -passenger_mass)

    if not removed_from_ship then
        return 0
    end

    -- Then update mission progress.
    local delivered_passengers = mission:deliverPassengers(passenger_count)

    if delivered_passengers <= 0 then
        -- Restore if mission delivery failed.
        ship:updateHoldMass("passengers", passenger_mass)
        return 0
    end
    removeShipMissionManifestAmount(ship, mission, delivered_passengers)

    local delivered_mass = delivered_passengers * PASSENGER_TOTAL_MASS

    -- Passenger delivery also counts as delivered mass/score.
    ship:updateMassDelivered(delivered_mass)

    if notifyMassDelivered then
        notifyMassDelivered()
    end

    return delivered_mass
end

function deliverMissionManifestAtDock(ship, dock)
    if not ship or not dock then
        return 0
    end

    local total_delivered_mass = 0
    local missions = getActiveMissionsDestinedForDock(dock)

    for _, mission in ipairs(missions) do
        local delivered_mass = 0

        if mission:isPassengerMission() then
            delivered_mass = deliverMissionPassengersAtDock(ship, mission)
        else
            delivered_mass = deliverMissionCargoAtDock(ship, mission)
        end

        total_delivered_mass = total_delivered_mass + delivered_mass
    end

    return total_delivered_mass
end

-- ==========================================
-- MISSION MANIFEST HELPERS
-- ==========================================

function getCarriedMissionsForShip(ship)
    local carried = {}

    if not ship or not game or not game.play or not game.play.missions then
        return carried
    end

    for _, mission in ipairs(game.play.missions) do
        if (
                mission and
                mission.canAct and
                mission:canAct() and
                getShipMissionManifestAmount(ship, mission) > 0
            ) then
            table.insert(carried, mission)
        end
    end

    return carried
end

function getShipMissionManifestBucket(ship, mission)
    if not ship or not mission then
        return nil
    end

    if not ship.mission_manifest then
        ship.mission_manifest = {
            cargo = {},
            passengers = {},
            smuggled = {},
        }
    end

    -- ORE delivery missions do not use the ship mission manifest. The cargo
    -- hold contains generic mined ORE, not mission-owned cargo.
    if mission:isOreDeliveryMission() then
        return nil
    end

    if mission.type == MISSION_TYPE.CARGO then
        return ship.mission_manifest.cargo
    elseif mission.type == MISSION_TYPE.CONTRABAND_CARGO then
        return ship.mission_manifest.smuggled
    elseif mission.type == MISSION_TYPE.PASSENGER or
        mission.type == MISSION_TYPE.CONTRABAND_PASSENGER
    then
        return ship.mission_manifest.passengers
    end

    return nil
end

function getShipMissionManifestAmount(ship, mission)
    local bucket = getShipMissionManifestBucket(ship, mission)

    if not bucket or not mission or not mission.id then
        return 0
    end

    return bucket[mission.id] or 0
end

function addShipMissionManifestAmount(ship, mission, amount)
    local bucket = getShipMissionManifestBucket(ship, mission)

    if not bucket or not mission or not mission.id then
        return false
    end

    amount = math.floor(amount or 0)

    if amount <= 0 then
        return false
    end

    bucket[mission.id] = (bucket[mission.id] or 0) + amount

    return true
end

function removeShipMissionManifestAmount(ship, mission, amount)
    local bucket = getShipMissionManifestBucket(ship, mission)

    if not bucket or not mission or not mission.id then
        return 0
    end

    amount = math.floor(amount or 0)

    if amount <= 0 then
        return 0
    end

    local current = bucket[mission.id] or 0
    local removed = math.min(current, amount)

    current = current - removed

    if current <= 0 then
        bucket[mission.id] = nil
    else
        bucket[mission.id] = current
    end

    return removed
end

function clearShipMissionManifest(ship)
    if not ship then
        return
    end

    ship.mission_manifest = {
        cargo = {},
        passengers = {},
        smuggled = {},
    }
end

function clearCarriedMissionManifestForDestroyedShip(ship)
    if not ship then
        return
    end

    for _, mission in ipairs(game.play.missions or {}) do
        if mission and mission.onShipDestroyed then
            mission:onShipDestroyed()
        end
    end

    clearShipMissionManifest(ship)
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
