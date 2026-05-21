-- ==========================================
-- STATE: READY
-- ==========================================

function inputReady()

end

function updateReady()
    if btnPressed(BTN_P1_START) then
        changeState(STATE.PLAY)
    end

    if btnPressed(BTN_P1_B) then
        changeState(STATE.START)
    end
end

function drawReady()
    -- Draw the game state (paused/initial state)
    drawGame()

    -- Draw overlay
    drawOverlayBox("READY?")

    -- Instructions
    drawCenteredText("Press 'START' (S) to Begin", EDGE_Y_BOTTOM / 2 + 30, 12)
    -- drawCenteredText("Press 'START' (S) to Begin", EDGE_Y_BOTTOM - Y_PADDING, WHITE, false, 1, false, GRAY_MED)
end
