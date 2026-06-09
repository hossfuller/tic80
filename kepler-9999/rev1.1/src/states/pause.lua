-- ==========================================
-- STATE: PAUSE
-- ==========================================

function getMissionSourceForDock(dock)
    if not dock then
        return nil
    end

    if isStationDock(dock) then
        return dock.host
    end

    if isPlanetDock(dock) then
        return dock
    end

    return dock
end

function getAvailableMissionsForSource(source)
    local missions = {}

    if not source then
        return missions
    end

    for _, mission in ipairs(game.play.missions or {}) do
        if mission.source == source and mission.status == MISSION_STATUS.AVAILABLE then
            table.insert(missions, mission)
        end
    end

    return missions
end

function getAvailableMissionsForDock(dock)
    local source = getMissionSourceForDock(dock)

    return getAvailableMissionsForSource(source)
end

function inputPause()
    if btnp(BTN_P1_START) then
        changeState(STATE.PLAY)
    end

    if btnp(BTN_P1_SELECT) then
        if not game.play.high_score_saved then
            saveCurrentScore(game.play.player)
            game.play.high_score_saved = true
        end

        changeState(STATE.GAMEOVER)
    end
end

function updatePause()

end

function drawPause()
    -- Draw the game state (frozen)
    drawGame()

    -- Draw overlay
    drawStandardOverlayBox("MISSION BOARD")

    local dock = game.play.player:getDockedSpaceDock()
    local missions = getAvailableMissionsForDock(dock)


    drawCenteredText("Press 'START' (S) to Resume", EDGE_Y_BOTTOM - 2* Y_PADDING, WHITE, false, 1, true, GRAY_MED)
    drawCenteredText("Press 'SELECT' (A) to Quit", EDGE_Y_BOTTOM - Y_PADDING, WHITE, false, 1, true, GRAY_MED)
end
