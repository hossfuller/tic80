-- ==========================================
-- STATE: PAUSE
-- ==========================================

function inputPause()
    if btnPressed(BTN_P1_START) then
        changeState(STATE.PLAY)
    end
end

function updatePause()

end

function drawPause()
    -- Draw the game state (frozen)
    drawGame()

    -- Draw overlay
    drawOverlayBox("PAUSED")

    -- Instructions
    drawCenteredText("Press 'START' (S) to Resume", EDGE_Y_BOTTOM / 2 + 30, 12)
    -- drawCenteredText("Press 'START' (S) to Resume", EDGE_Y_BOTTOM - Y_PADDING, WHITE, false, 1, false, GRAY_MED)
end
