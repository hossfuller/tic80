-- ==========================================
-- STATE: GAMEOVER
-- ==========================================

local function updateGameover()
    if btnPressed(BTN_P1_A) or btnPressed(BTN_P1_B) then
        changeState(STATE.START)
    end
end

local function drawGameover()
    -- Draw the game state (final state)
    drawGame()
    
    -- Draw overlay
    drawOverlayBox("GAME OVER")
    
    -- Show final score
    local scoreText = "Final Score: " .. game.play.score
    drawCenteredText(scoreText, EDGE_Y_BOTTOM / 2 + 25, 12)
    
    -- Instructions
    drawCenteredText("Press any button", EDGE_Y_BOTTOM / 2 + 40, 6)
end
