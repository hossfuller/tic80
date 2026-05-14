-- ==========================================
-- STATE: HISCORES
-- ==========================================

local function updateHiscores()
    if btnPressed(BTN_P1_A) or btnPressed(BTN_P1_B) then
        changeState(STATE.START)
    end
end

local function drawHiscores()
    cls(0)
    
    -- Title
    drawCenteredText("HIGH SCORES", 15, 12)
    
    -- Scores list
    local startY = 40
    local spacing = 15
    
    for i, entry in ipairs(game.hiscores) do
        local y = startY + (i - 1) * spacing
        local rankText = string.format("%d.", i)
        local scoreText = string.format("%s %8d", entry.name, entry.score)
        
        print(rankText, 60, y, 6)
        print(scoreText, 80, y, 12)
    end
    
    -- Instructions
    drawCenteredText("Press A or B to return", EDGE_Y_BOTTOM - 15, 6)
end
