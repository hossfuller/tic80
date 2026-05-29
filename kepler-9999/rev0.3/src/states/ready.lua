-- ==========================================
-- STATE: READY
-- ==========================================

function inputReady()

end

function updateReady()
    if btnp(BTN_P1_A) or btnp(BTN_P1_START) then
        changeState(STATE.PLAY)
    end

    if btnp(BTN_P1_B) then
        changeState(STATE.START)
    end
end

function drawReady()
    -- Draw the game state (paused/initial state)
    drawGame()

    -- Draw overlay
    drawOverlayBox("READY?")
    drawCenteredText("Press Z to Begin", EDGE_Y_BOTTOM - Y_PADDING, WHITE, false, 1, true, GRAY_MED)
end
