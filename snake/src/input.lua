-- ==========================================
-- INPUT
-- ==========================================

-- -- Input tracking for edge detection
local input = {
    prev = {},
    curr = {},
}

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
