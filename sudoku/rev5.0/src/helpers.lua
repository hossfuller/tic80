-- ==========================================
-- HELPERS
-- ==========================================

-- Input tracking for edge detection
local input = {
    prev = {},
    curr = {},
}

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

local function drawOverlayBox(text_array)
    local boxW = 120
    local boxH = 40
    local boxX = math.floor((EDGE_X_RIGHT - boxW) / 2)
    local boxY = math.floor((EDGE_Y_BOTTOM - boxH) / 2)

    -- Draw box background
    rect(boxX, boxY, boxW, boxH, BLACK)
    rectb(boxX, boxY, boxW, boxH, WHITE)

    -- Draw text
    for i, text in ipairs(text_array) do
        drawCenteredText(text, boxY + (i * Y_PADDING), WHITE)
    end
end
