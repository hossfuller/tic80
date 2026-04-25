-- ==========================================
-- HELPERS
-- ==========================================

-- Input tracking for edge detection
local input = {
    prev = {},
    curr = {},
}

-- ==========================================
-- INPUT HELPERS
-- ==========================================

local function updateInput()
    input.prev = input.curr
    input.curr = {}
    for i = 0, 7 do
        input.curr[i] = btn(i)
    end
end

local function btnPressed(id)
    return input.curr[id] and not input.prev[id]
end

-- ==========================================
-- DRAWING HELPERS
-- ==========================================

local function drawCenteredText(text, y, color)
    local width = print(text, 0, -10)
    print(text, (EDGE_X_RIGHT - width) / 2, y, color)
end

local function drawOverlayBox(text)
    local boxW = 120
    local boxH = 40
    local boxX = (EDGE_X_RIGHT - boxW) / 2
    local boxY = (EDGE_Y_BOTTOM - boxH) / 2
    
    -- Draw box background
    rect(boxX, boxY, boxW, boxH, 0)
    rectb(boxX, boxY, boxW, boxH, 12)
    
    -- Draw text
    drawCenteredText(text, boxY + 16, 12)
end

