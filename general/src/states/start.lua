-- ==========================================
-- STATE: START (Main Menu)
-- ==========================================

local function updateStart()
    -- Menu navigation
    if btnPressed(BTN_P1_UP) then
        game.menu.selected = game.menu.selected - 1
        if game.menu.selected < 1 then
            game.menu.selected = #game.menu.options
        end
    end
    
    if btnPressed(BTN_P1_DOWN) then
        game.menu.selected = game.menu.selected + 1
        if game.menu.selected > #game.menu.options then
            game.menu.selected = 1
        end
    end
    
    -- Menu selection
    if btnPressed(BTN_P1_A) then
        local selected = game.menu.selected
        if selected == 1 then
            changeState(STATE.READY)
        elseif selected == 2 then
            changeState(STATE.OPTIONS)
        elseif selected == 3 then
            changeState(STATE.HISCORES)
        end
    end
end

local function drawStart()
    cls(0)
    
    -- Title
    drawCenteredText("GAME TITLE", 20, 12)
    
    -- Menu options
    local startY = 60
    local spacing = 15
    
    for i, option in ipairs(game.menu.options) do
        local y = startY + (i - 1) * spacing
        local color = (i == game.menu.selected) and 12 or 6
        
        -- Draw selector
        if i == game.menu.selected then
            local textWidth = print(option, 0, -10)
            local x = (EDGE_X_RIGHT - textWidth) / 2
            print(">", x - 10, y, 12)
        end
        
        drawCenteredText(option, y, color)
    end
    
    -- Instructions
    drawCenteredText("UP/DOWN: Select  A: Confirm", EDGE_Y_BOTTOM - 15, 6)
end

