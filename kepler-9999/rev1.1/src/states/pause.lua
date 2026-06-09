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

function drawSelectedMissionDetails(missions)
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
    local status_text = mission:getStatusLabel()
    local type_text = mission:getTypeLabel()

    local text = mission.id ..
        " | " ..
        type_text ..
        " | " ..
        status_text ..
        " | " ..
        progress_text

    print(
        text,
        EDGE_X_LEFT + 16,
        EDGE_Y_BOTTOM - 4 * Y_PADDING,
        GRAY_LITE,
        false,
        1,
        true
    )
end

function drawMissionBoardList(missions, dock)
    local box_x = EDGE_X_LEFT + 16
    local box_y = EDGE_Y_TOP + 28
    local line_h = 8

    local id_x = box_x
    local type_x = box_x + 42
    local status_x = box_x + 112
    local pct_x = box_x + 190

    local subtitle = nil

    if dock then
        subtitle = "Dock Missions"
    else
        subtitle = "Active Mission Progress"
    end

    print(subtitle, box_x, box_y - 10, GRAY_LITE, false, 1, true)

    local header_y = box_y

    print("ID", id_x, header_y, YELLOW, false, 1, true)
    print("TYPE", type_x, header_y, YELLOW, false, 1, true)
    print("STATUS", status_x, header_y, YELLOW, false, 1, true)
    print("DONE", pct_x, header_y, YELLOW, false, 1, true)

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

    local max_visible = math.floor((EDGE_Y_BOTTOM - start_y - 24) / line_h)

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
        local row = i - first
        local y = start_y + row * line_h

        local color = WHITE

        if mission.status == MISSION_STATUS.COMPLETED then
            color = GREEN_MED
        elseif mission.status == MISSION_STATUS.FAILED then
            color = RED
        elseif mission.status == MISSION_STATUS.IN_PROGRESS then
            color = WHITE
        end

        if i == selected then
            rect(
                box_x - 3,
                y - 1,
                EDGE_X_RIGHT - box_x - 12,
                line_h,
                GRAY_DARK
            )
        end

        local pct = getMissionCompletionPercent(mission)
        local pct_text = tostring(pct) .. "%"

        local type_label = mission.getShortTypeLabel and
            mission:getShortTypeLabel() or
            mission:getTypeLabel()

        print(mission.id, id_x, y, color, false, 1, true)
        print(type_label, type_x, y, color, false, 1, true)
        print(mission:getStatusLabel(), status_x, y, color, false, 1, true)
        print(pct_text, pct_x, y, color, false, 1, true)
    end

    drawSelectedMissionDetails(missions)

    if #missions > max_visible then
        local scroll_text = tostring(selected) .. "/" .. tostring(#missions)
        local scroll_w = print(scroll_text, -100, -100, GRAY_LITE, false, 1, true)

        print(
            scroll_text,
            EDGE_X_RIGHT - scroll_w - X_PADDING,
            EDGE_Y_BOTTOM - 3 * Y_PADDING,
            GRAY_LITE,
            false,
            1,
            true
        )
    end
end

function drawPause()
    -- Draw the game state frozen behind the overlay.
    drawGame()

    drawStandardOverlayBox("MISSION BOARD")

    local missions, dock = getMissionBoardMissions()

    drawMissionBoardList(missions, dock)

    drawCenteredText(
        "UP/DOWN: Select",
        EDGE_Y_BOTTOM - 3 * Y_PADDING,
        WHITE, false, 1, true, GRAY_MED
    )

    drawCenteredText(
        "Press 'START' (S) to Resume",
        EDGE_Y_BOTTOM - 2 * Y_PADDING,
        WHITE, false, 1, true, GRAY_MED
    )

    drawCenteredText(
        "Press 'SELECT' (A) to Quit",
        EDGE_Y_BOTTOM - Y_PADDING,
        WHITE, false, 1, true, GRAY_MED
    )
end
