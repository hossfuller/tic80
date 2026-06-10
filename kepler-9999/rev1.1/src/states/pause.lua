-- ==========================================
-- STATE: PAUSE / MISSION BOARD
-- ==========================================

function getMissionSourceForDock(dock)
    if not dock then
        return nil
    end

    -- A SpaceDock attached to a SpaceStation shows the station mission list.
    if isStationDock(dock) then
        return dock.host
    end

    -- A SpaceDock attached to a Planet shows that dock's mission list.
    if isPlanetDock(dock) then
        return dock
    end

    return dock
end

function getMissionsForSource(source)
    local missions = {}

    if not source then
        return missions
    end

    for _, mission in ipairs(game.play.missions or {}) do
        if mission.source == source then
            table.insert(missions, mission)
        end
    end

    return missions
end

function getMissionsForDock(dock)
    local source = getMissionSourceForDock(dock)

    return getMissionsForSource(source)
end

function missionHasProgressUnderway(mission)
    if not mission or not mission.mass then
        return false
    end

    return (mission.mass.active or 0) > 0 or
        (mission.mass.transported or 0) > 0
end

function getMissionsWithProgressUnderway()
    local missions = {}

    for _, mission in ipairs(game.play.missions or {}) do
        if missionHasProgressUnderway(mission) then
            table.insert(missions, mission)
        end
    end

    return missions
end

function getMissionBoardMissions()
    local player = game.play.player
    local dock = nil

    if player and player.getDockedSpaceDock then
        dock = player:getDockedSpaceDock()
    end

    -- Docked: show missions associated with that SpaceDock/SpaceStation.
    if dock then
        return getMissionsForDock(dock), dock
    end

    -- Undocked: show only missions with some progress underway.
    return getMissionsWithProgressUnderway(), nil
end

function getMissionCompletionPercent(mission)
    if not mission or not mission.mass or not mission.mass.total or mission.mass.total <= 0 then
        return 0
    end

    local fraction = mission.mass.transported / mission.mass.total
    fraction = clamp(fraction, 0, 1)

    return math.floor(fraction * 100)
end

function getPlanetSuffixUpper(planet)
    if not planet or not planet.name then
        return "?"
    end

    local suffix = string.sub(planet.name, -1)
    if suffix == "" then
        suffix = "?"
    end

    return string.upper(suffix)
end

function getPlanetDockMissionLabel(dock)
    if not dock or not dock.host then
        return "Pl Dock ?"
    end

    local suffix = getPlanetSuffixUpper(dock.host)

    return "Pl Dock " .. suffix
end

function getMissionLocationName(obj)
    if not obj then
        return "?"
    end

    -- Missions to/from the SpaceStation itself display as "Station".
    if isSpaceStation(obj) then
        return "Station"
    end

    -- Planet SpaceDocks display as "Pl. X Dock", where X is the final
    -- character of the host planet's name.
    if isPlanetDock(obj) then
        return getPlanetDockMissionLabel(obj)
    end

    -- A SpaceDock attached to a SpaceStation still displays as "Station".
    if isStationDock(obj) then
        return "Station"
    end

    -- Fallback SpaceDock label.
    if isSpaceDock(obj) then
        return "Dock"
    end

    return obj.name or "?"
end

function getMissionTransportText(mission)
    if not mission then
        return "0/0"
    end

    if mission:isPassengerMission() then
        return tostring(math.floor(mission.passengers.transported or 0)) .. "/" ..
            tostring(math.floor(mission.passengers.total or 0)) .. " pass."
    end

    return tostring(math.floor(mission.mass.transported or 0)) .. "/" ..
        tostring(math.floor(mission.mass.total or 0)) .. "kg"
end

function getMissionDoneText(mission)
    if not mission then
        return "0%"
    end

    local transported = 0
    local total = 0

    if mission:isPassengerMission() then
        transported = mission.passengers.transported or 0
        total = mission.passengers.total or 0
    else
        transported = mission.mass.transported or 0
        total = mission.mass.total or 0
    end

    if total <= 0 then
        return "0%"
    end

    local fraction = transported / total
    fraction = clamp(fraction, 0, 1)

    return tostring(math.ceil(fraction * 100)) .. "%"
end

function getMissionManifestHoldType(mission)
    if not mission then
        return nil
    end

    if mission.type == MISSION_TYPE.CARGO then
        return "cargo"
    elseif mission.type == MISSION_TYPE.CONTRABAND_CARGO then
        return "smuggled"
    elseif mission.type == MISSION_TYPE.PASSENGER or
        mission.type == MISSION_TYPE.CONTRABAND_PASSENGER
    then
        return "passengers"
    end

    return nil
end

function getMissionManifestLoadAmount(mission)
    if not mission then
        return 0
    end

    if mission:isPassengerMission() then
        return mission:getRemainingPassengerCount()
    end

    return mission:getRemainingMass()
end

function getMissionManifestLoadMass(mission)
    if not mission then
        return 0
    end

    if mission:isPassengerMission() then
        return mission:getRemainingPassengerCount() * PASSENGER_TOTAL_MASS
    end

    return mission:getRemainingMass()
end

function acceptMissionManifest(ship, mission)
    if not ship or not mission then
        return false
    end

    if not mission:canAct() then
        return false
    end

    local hold_type = getMissionManifestHoldType(mission)
    if not hold_type then
        return false
    end
    if not ship.holds or not ship.holds[hold_type] then
        return false
    end

    local hold = ship.holds[hold_type]
    local free_mass = math.max(0, hold.max - hold.cur)
    if free_mass <= 0 then
        return false
    end

    -- Normal cargo cannot mix with mined ore.
    -- If the cargo hold currently contains ore, do not load normal mission cargo.
    if hold_type == "cargo" then
        if ship.cargo_has_ore == true and ship:getCargoMass() > 0 then
            return false
        end
    end

    if mission:isPassengerMission() then
        local remaining_passengers = mission:getRemainingPassengerCount()
        if remaining_passengers <= 0 then
            return false
        end

        local passenger_capacity = math.floor(free_mass / PASSENGER_TOTAL_MASS)
        if passenger_capacity <= 0 then
            return false
        end

        local passenger_count = math.min(
            remaining_passengers,
            passenger_capacity
        )
        if passenger_count <= 0 then
            return false
        end

        local picked_up = ship:pickupPassengers(passenger_count)
        if not picked_up then
            return false
        end

        local loaded = mission:loadPassengers(passenger_count)
        if loaded <= 0 then
            -- Restore passenger mass if the mission did not accept the load.
            ship:updateHoldMass("passengers", -(passenger_count * PASSENGER_TOTAL_MASS))
            return false
        end
        addShipMissionManifestAmount(ship, mission, loaded)

        -- If for some reason fewer passengers loaded than requested, restore
        -- the difference.
        if loaded < passenger_count then
            local unloaded_count = passenger_count - loaded
            ship:updateHoldMass("passengers", -(unloaded_count * PASSENGER_TOTAL_MASS))
        end

        return true
    end

    local remaining_mass = mission:getRemainingMass()
    if remaining_mass <= 0 then
        return false
    end

    local cargo_mass = math.min(
        remaining_mass,
        free_mass
    )

    cargo_mass = math.floor(cargo_mass)
    if cargo_mass <= 0 then
        return false
    end

    if mission.type == MISSION_TYPE.CONTRABAND_CARGO then
        local picked_up = ship:pickupSmuggledGoods(cargo_mass)
        if not picked_up then
            return false
        end
    else
        local picked_up = ship:pickupCargo(cargo_mass)
        if not picked_up then
            return false
        end

        -- Normal mission cargo is not ore.
        ship.cargo_has_ore = false
    end

    local loaded = mission:loadMass(cargo_mass)
    if loaded <= 0 then
        -- Restore cargo if the mission did not accept the load.
        if mission.type == MISSION_TYPE.CONTRABAND_CARGO then
            ship:updateHoldMass("smuggled", -cargo_mass)
        else
            ship:updateHoldMass("cargo", -cargo_mass)

            if ship:getCargoMass() <= 0 then
                ship.cargo_has_ore = false
            end
        end

        return false
    end
    addShipMissionManifestAmount(ship, mission, loaded)

    -- If for some reason less mass loaded than requested, restore the difference.
    if loaded < cargo_mass then
        local unloaded_mass = cargo_mass - loaded

        if mission.type == MISSION_TYPE.CONTRABAND_CARGO then
            ship:updateHoldMass("smuggled", -unloaded_mass)
        else
            ship:updateHoldMass("cargo", -unloaded_mass)

            if ship:getCargoMass() <= 0 then
                ship.cargo_has_ore = false
            end
        end
    end

    return true
end

function getSelectedMission()
    local missions = getMissionBoardMissions()

    if not missions or #missions <= 0 then
        return nil
    end

    local selected = game.pause.selected_mission or 1
    selected = clamp(selected, 1, #missions)

    return missions[selected]
end

function getMissionBoardDockSubtitle(dock)
    if not dock then
        return "Active Mission Progress"
    end

    if isPlanetDock(dock) then
        local planet_name = dock.host and dock.host.name or "?"
        local short_label = getPlanetDockMissionLabel(dock)

        return "Planet " .. planet_name .. " Dock (" .. short_label .. ") Missions"
    end

    if isStationDock(dock) then
        return "Station Missions"
    end

    return "Dock Missions"
end

function inputPause()
    if btnp(BTN_P1_START) then
        changeState(STATE.PLAY)
        return
    end

    local missions, dock = getMissionBoardMissions()
    if #missions > 0 then
        if btnp(BTN_P1_UP) then
            game.pause.selected_mission = math.max(
                1,
                (game.pause.selected_mission or 1) - 1
            )
        end

        if btnp(BTN_P1_DOWN) then
            game.pause.selected_mission = math.min(
                #missions,
                (game.pause.selected_mission or 1) + 1
            )
        end
    else
        game.pause.selected_mission = 1
    end

    -- Z / Button A: accept selected mission manifest while docked.
    if dock and btnp(BTN_P1_A) then
        local selected = game.pause.selected_mission or 1
        selected = clamp(selected, 1, #missions)

        local mission = missions[selected]
        local player = game.play.player

        if mission and player then
            acceptMissionManifest(player, mission)
        end
    end
end

function updatePause()

end

function drawSelectedMissionDetails(missions, content)
    if not missions or #missions <= 0 then
        return
    end

    local selected = game.pause.selected_mission or 1
    selected = clamp(selected, 1, #missions)

    local mission = missions[selected]
    if not mission then
        return
    end

    local progress_text = mission:getProgressText()
    local status_text   = mission:getStatusLabel()
    local type_text     = mission:getTypeLabel()

    local text = mission.id ..
        " | " ..
        type_text ..
        " | " ..
        status_text ..
        " | " ..
        progress_text

    print(text, content.left, content.bottom - 4 * Y_PADDING, GRAY_LITE, false, 1, true)
end

function drawMissionBoardList(missions, dock)
    drawInfoOverlayBox("MISSION BOARD", function(content)
        local line_h   = 8
        local box_x    = content.left
        local box_y    = content.top

        -- Columns:
        -- TYPE | SRC | DEST | TRANS | DONE
        local type_x   = box_x
        local src_x    = box_x + 52
        local dest_x   = box_x + 94
        local trans_x  = box_x + 138
        local done_x   = box_x + 190

        local subtitle = getMissionBoardDockSubtitle(dock)
        print(subtitle, box_x, box_y - 8, GRAY_LITE, false, 1, true)

        local header_y = box_y + 4
        print("TYPE", type_x, header_y, YELLOW, false, 1, true)
        print("SRC", src_x, header_y, YELLOW, false, 1, true)
        print("DEST", dest_x, header_y, YELLOW, false, 1, true)
        print("TRANS", trans_x, header_y, YELLOW, false, 1, true)
        print("DONE", done_x, header_y, YELLOW, false, 1, true)

        local start_y = header_y + line_h + 2

        if #missions <= 0 then
            local empty_text = nil

            if dock then
                empty_text = "No missions at this dock."
            else
                empty_text = "No active mission progress."
            end

            print(empty_text, box_x, start_y, WHITE, false, 1, true)
            return
        end

        -- Leave bottom space for selected mission details and footer controls.
        local reserved_bottom_h = 5 * Y_PADDING
        local max_visible = math.floor((content.bottom - reserved_bottom_h - start_y) / line_h)
        if max_visible < 1 then
            max_visible = 1
        end

        local selected = game.pause.selected_mission or 1
        selected = clamp(selected, 1, #missions)
        game.pause.selected_mission = selected

        local first = 1
        if selected > max_visible then
            first = selected - max_visible + 1
        end

        local last = math.min(#missions, first + max_visible - 1)

        for i = first, last do
            local mission = missions[i]
            local row     = i - first
            local y       = start_y + row * line_h
            local color   = WHITE

            if mission.status == MISSION_STATUS.COMPLETED then
                color = GREEN_MED
            end

            if i == selected then
                rect(box_x - 3, y - 1, content.w - 2 * X_PADDING + 6, line_h, GRAY_DARK)
            end

            local type_label = mission.getShortTypeLabel and
                mission:getShortTypeLabel() or
                mission:getTypeLabel()

            local src_text   = getMissionLocationName(mission.source)
            local dest_text  = getMissionLocationName(mission.destination)
            local trans_text = getMissionTransportText(mission)
            local done_text  = getMissionDoneText(mission)

            print(type_label, type_x, y, color, false, 1, true)
            print(src_text, src_x, y, color, false, 1, true)
            print(dest_text, dest_x, y, color, false, 1, true)
            print(trans_text, trans_x, y, color, false, 1, true)
            print(done_text, done_x, y, color, false, 1, true)
        end

        drawSelectedMissionDetails(missions, content)

        if #missions > max_visible then
            local scroll_text = tostring(selected) .. "/" .. tostring(#missions)
            local scroll_w = print(scroll_text, -100, -100, GRAY_LITE, false, 1, true)

            print(
                scroll_text,
                content.right - scroll_w,
                content.bottom - 4 * Y_PADDING,
                GRAY_LITE, false, 1, true
            )
        end

        drawCenteredText(
            "UP/DOWN: Select",
            content.bottom - 2 * Y_PADDING,
            WHITE, false, 1, true, GRAY_MED
        )

        local accept_text = nil
        if dock then
            accept_text = "Z: Accept manifest"
        else
            accept_text = "Dock to accept missions"
        end

        drawCenteredText(
            accept_text,
            content.bottom - Y_PADDING,
            WHITE, false, 1, true, GRAY_MED
        )

        drawCenteredText(
            "Press 'START' (S) to Resume",
            content.bottom,
            WHITE, false, 1, true, GRAY_MED
        )
    end)
end

function drawPause()
    -- Draw the game state frozen behind the overlay.
    drawGame()

    local missions, dock = getMissionBoardMissions()

    drawMissionBoardList(missions, dock)
end
