-- ==========================================
-- STATE: GAMEOVER
-- ==========================================

function updateGameover()
    if btnPressed(BTN_P1_A) or btnPressed(BTN_P1_B) then
        changeState(STATE.START)
    end
end

function drawGameover()
    drawGame()

    drawCenteredText("GAME OVER", EDGE_Y_TOP + Y_PADDING, ORANGE, nil, 3, nil, YELLOW)
    drawCenteredText("Press Z or X to see high scores", EDGE_Y_BOTTOM - Y_PADDING, WHITE, false, 1, false, GRAY_MED)
end
