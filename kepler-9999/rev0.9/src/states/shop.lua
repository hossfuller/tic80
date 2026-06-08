-- ==========================================
-- STATE: SHOP
-- ==========================================

function inputShop()
    if btnp(BTN_P1_A) then
        -- Select an option
    end
    if btnp(BTN_P1_B) then
        changeState(STATE.PLAY)
    end
end

function updateShop()

end

function drawShop()
    drawCenteredText("SHOP", EDGE_Y_TOP + Y_PADDING, WHITE, false, 2, false, GRAY_MED)







    drawCenteredText("Press X to exit shop", EDGE_Y_BOTTOM - Y_PADDING, WHITE, false, 1, true, GRAY_MED)
end
