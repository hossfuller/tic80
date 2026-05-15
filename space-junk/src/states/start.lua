-- ==========================================
-- STATE: START (Main Menu)
-- ==========================================

function inputStart()
    if btnp(BTN_P1_A) or btnp(BTN_P1_START) then
        changeState(STATE.PLAY)
    end
end

function updateStart()

end

function drawStart()
    cls(0)

    local title_y_pos = math.floor(EDGE_Y_BOTTOM / 2) - 3 * Y_PADDING
    drawCenteredText("SPACE JUNK", title_y_pos, ORANGE, nil, 3, nil, YELLOW)
    drawCenteredText("Press Z to start", title_y_pos + 3 * Y_PADDING, WHITE, false, 1, false, GRAY_DARK)
end
