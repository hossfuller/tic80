-- ==========================================
-- STATE: TITLE (Main Menu)
-- ==========================================

local function updateTitle()
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
            changeState(STATE.PUZZLE)
        elseif selected == 2 then
            changeState(STATE.OPTIONS)
        elseif selected == 3 then
            changeState(STATE.STATISTICS)
        end
    end
end

local function drawTitle()
    cls(BLACK)

    -- Draw the background.
    map(0, 0, 30, 17, 0, 0)

    -- Title
    drawCenteredText("SUSSUDIOKU!!", 20, ORANGE, nil, 3, nil, YELLOW)

    -- Menu options
    local start_y = 60
    local spacing = 2 * X_PADDING

    for i, option in ipairs(game.menu.options) do
        local y = start_y + (i - 1) * spacing
        local color = (i == game.menu.selected) and ORANGE or WHITE

        -- Draw selector
        if i == game.menu.selected then
            local textWidth = print(option, 0, -10)
            local x = (EDGE_X_RIGHT - textWidth) / 2
            print(">", x - 10 + 1, y + 1, BLACK) -- the shadow
            print(">", x - 10, y, WHITE)
        end

        -- drawCenteredText(option, y, color)
        drawCenteredText(option, y, color, nil, nil, nil, BLACK)
    end

    -- Instructions
    drawCenteredText("UP/DOWN: Select  A: Confirm", EDGE_Y_BOTTOM - Y_PADDING, WHITE, false, 1, true, BLACK)
end
