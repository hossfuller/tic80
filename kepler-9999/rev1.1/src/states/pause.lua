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

function getMissionLocationName(obj)
    if not obj then
        return "?"
    end

    -- If the object is a SpaceDock, display the host planet/station name.
    if isSpaceDock(obj) then
        if obj.host then
            if obj.host.name then
                return obj.host.name
            end

            -- Fallback labels if host has no name field.
            if isPlanet(obj.host) then
                return "Planet"
            elseif isSpaceStation(obj.host) then
                return "Station"
            end
        end

        return "Dock"
    end

    -- If the object is a SpaceStation, display its name.
    if isSpaceStation(obj) then
        return obj.name or "Station"
    end

    -- If the object is a Planet, display its name.
    if isPlanet(obj) then
        return obj.name or "Planet"
    end

    return obj.name or "?"
end

function getMissionTransportText(mission)
    if not mission then
        return "0/0"
    end

    if mission:isPassengerMission() then
        return tostring(math.floor(mission.passengers.transported or 0)) ..
            "/" ..
            tostring(math.floor(mission.passengers.total or 0))
    end

    return tostring(math.floor(mission.mass.transported or 0)) ..
        "/" ..
        tostring(math.floor(mission.mass.total or 0))
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

function inputPause()
    if btnp(BTN_P1_START) then
        changeState(STATE.PLAY)
        return
    end

    if btnp(BTN_P1_SELECT) then
        if not game.play.high_score_saved then
            saveCurrentScore(game.play.player)
            game.play.high_score_saved = true
        end

        changeState(STATE.GAMEOVER)
        return
    end

    local missions = getMissionBoardMissions()

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

        local subtitle = nil

        if dock then
            subtitle = "Dock Missions"
        else
            subtitle = "Active Mission Progress"
        end

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
            elseif mission.status == MISSION_STATUS.FAILED then
                color = RED
            elseif mission.status == MISSION_STATUS.IN_PROGRESS then
                color = WHITE
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
            -- content.bottom - 3 * Y_PADDING,
            content.bottom - 2 * Y_PADDING,
            WHITE, false, 1, true, GRAY_MED
        )

        drawCenteredText(
            "Z: Accept manifest",
            -- content.bottom - 2 * Y_PADDING,
            content.bottom - Y_PADDING,
            WHITE, false, 1, true, GRAY_MED
        )

        drawCenteredText(
            "Press 'START' (S) to Resume",
            -- content.bottom - Y_PADDING,
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
