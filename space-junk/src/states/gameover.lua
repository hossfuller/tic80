-- ==========================================
-- STATE: GAMEOVER
-- ==========================================

function inputGameover()
    if btnp(BTN_P1_A) or btnp(BTN_P1_B) then
        changeState(STATE.HIGHSCORES)
    end
end

function updateGameover()

end

function drawGameover()
    drawPlay()

    local title_y_pos = math.floor(EDGE_Y_BOTTOM / 2) - 3 * Y_PADDING
    drawCenteredText("GAME OVER", title_y_pos, ORANGE, nil, 3, nil, YELLOW)
    drawCenteredText("Press Z or X to see high scores", title_y_pos + 3 * Y_PADDING, WHITE, false, 1, false, GRAY_DARK)
end
