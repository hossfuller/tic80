-- ==========================================
-- STATE: OPTIONS
-- ==========================================

local function updateOptions()
    local opts = game.options
    
    -- Navigation
    if btnPressed(BTN_P1_UP) then
        opts.selected = opts.selected - 1
        if opts.selected < 1 then
            opts.selected = #opts.items
        end
    end
    
    if btnPressed(BTN_P1_DOWN) then
        opts.selected = opts.selected + 1
        if opts.selected > #opts.items then
            opts.selected = 1
        end
    end
    
    -- Change option value
    local currentItem = opts.items[opts.selected]
    
    if btnPressed(BTN_P1_LEFT) and #currentItem.values > 1 then
        currentItem.current = currentItem.current - 1
        if currentItem.current < 1 then
            currentItem.current = #currentItem.values
        end
    end
    
    if btnPressed(BTN_P1_RIGHT) and #currentItem.values > 1 then
        currentItem.current = currentItem.current + 1
        if currentItem.current > #currentItem.values then
            currentItem.current = 1
        end
    end
    
    -- Select (for Back option) or Back button
    if btnPressed(BTN_P1_A) then
        if opts.items[opts.selected].name == "Back" then
            changeState(STATE.START)
        end
    end
    
    if btnPressed(BTN_P1_B) then
        changeState(STATE.START)
    end
end

local function drawOptions()
    cls(0)
    
    -- Title
    drawCenteredText("OPTIONS", 20, 12)
    
    -- Options list
    local startY = 50
    local spacing = 20
    
    for i, item in ipairs(game.options.items) do
        local y = startY + (i - 1) * spacing
        local color = (i == game.options.selected) and 12 or 6
        
        -- Draw selector
        if i == game.options.selected then
            print(">", 30, y, 12)
        end
        
        -- Draw option name and value
        print(item.name, 45, y, color)
        
        if #item.values > 0 and item.values[1] ~= "" then
            local valueText = "< " .. item.values[item.current] .. " >"
            print(valueText, 140, y, color)
        end
    end
    
    -- Instructions
    drawCenteredText("UP/DOWN: Select  LEFT/RIGHT: Change", EDGE_Y_BOTTOM - 25, 6)
    drawCenteredText("B: Back", EDGE_Y_BOTTOM - 15, 6)
end