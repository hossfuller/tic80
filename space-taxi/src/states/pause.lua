-- ==========================================
-- STATE: PAUSE
-- ==========================================

local function updatePause()
    if btnPressed(BTN_P1_START) then
        changeState(STATE.PLAY)
    end
end

local function drawPause()
    -- Draw the game state (frozen)
    drawGame()

    -- Draw overlay
    drawOverlayBox("PAUSED")

    -- Instructions
    drawCenteredText("Press START to Resume", EDGE_Y_BOTTOM - Y_PADDING, WHITE, false, 1, true, BLACK)
end
