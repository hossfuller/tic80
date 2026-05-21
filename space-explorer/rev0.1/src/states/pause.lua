-- ==========================================
-- STATE: PAUSE
-- ==========================================

local function updatePause()
    if btnPressed(BTN_P1_B) then
        changeState(STATE.PLAY)
    end
end

local function drawPause()
    -- Draw the game state (frozen)
    drawGame()
    
    -- Draw overlay
    drawOverlayBox("PAUSED")
    
    -- Instructions
    drawCenteredText("Press B to Resume", EDGE_Y_BOTTOM / 2 + 30, 12)
end
