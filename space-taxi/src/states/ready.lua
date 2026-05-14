-- ==========================================
-- STATE: READY
-- ==========================================

local function updateReady()
    if btnPressed(BTN_P1_A) then
        changeState(STATE.PLAY)
    end

    if btnPressed(BTN_P1_B) then
        changeState(STATE.START)
    end
end

local function drawReady()
    -- Draw the game state (paused/initial state)
    drawGame()

    -- Draw overlay
    drawOverlayBox("READY?")

    -- Instructions
    -- drawCenteredText("Press Z to Start", EDGE_Y_BOTTOM / 2 + 30, 12)
    drawCenteredText("Press Z to Start", EDGE_Y_BOTTOM - Y_PADDING, WHITE, false, 1, true, BLACK)
end
