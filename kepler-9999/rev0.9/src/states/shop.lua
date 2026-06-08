-- ==========================================
-- STATE: SHOP
-- ==========================================

function getShopDock()
    local player = game.play.player
    if not player or not player.getDockedSpaceDock then
        return nil
    end
    return player:getDockedSpaceDock()
end

function getShopStation()
    local dock = getShopDock()
    if not dock then
        return nil
    end

    local station = dock.host
    if (
        station and
        SpaceStation ~= nil and
        getmetatable(station) == SpaceStation and
        station.ore_bank
    ) then
        return station
    end

    return nil
end

function canUseShop()
    return getShopStation() ~= nil
end

function shopItemIsAffordable(item)
    local station = getShopStation()
    if not station or not station.ore_bank then
        return false
    end

    local cost = game.shop.upgrade_cost or 100
    return station.ore_bank.cur >= cost
end

function getNextSelectableShopIndex(start_index, direction)
    local items = game.shop.items
    local count = #items
    if count <= 0 then
        return start_index
    end

    local index = start_index
    for _ = 1, count do
        index = index + direction

        if index < 1 then
            index = count
        elseif index > count then
            index = 1
        end

        if shopItemIsAffordable(items[index]) then
            return index
        end
    end

    return start_index
end

function normalizeShopSelection()
    local items = game.shop.items
    if #items <= 0 then
        game.shop.selected = 1
        return
    end

    if game.shop.selected < 1 then
        game.shop.selected = 1
    elseif game.shop.selected > #items then
        game.shop.selected = #items
    end

    -- If current item is not affordable, move to the first affordable item.
    if not shopItemIsAffordable(items[game.shop.selected]) then
        for i, item in ipairs(items) do
            if shopItemIsAffordable(item) then
                game.shop.selected = i
                return
            end
        end
    end
end

function purchaseSelectedShopItem()
    local player = game.play.player
    local station = getShopStation()
    if not player or not station or not station.ore_bank then
        return false
    end

    local item = game.shop.items[game.shop.selected]
    if not item then
        return false
    end

    local cost = game.shop.upgrade_cost or 100
    if station.ore_bank.cur < cost then
        return false
    end

    if item.apply then
        item.apply(player)
        station.ore_bank.cur = station.ore_bank.cur - cost
        if station.ore_bank.cur < 0 then
            station.ore_bank.cur = 0
        end

        normalizeShopSelection()

        return true
    end

    return false
end

function inputShop()
    -- Leave shop.
    if btnp(BTN_P1_B) then
        changeState(STATE.PLAY)
        return
    end

    -- If player is no longer docked at a station dock, close shop.
    if not canUseShop() then
        changeState(STATE.PLAY)
        return
    end

    normalizeShopSelection()

    if btnp(BTN_P1_UP) then
        game.shop.selected = getNextSelectableShopIndex(game.shop.selected, -1)
    end

    if btnp(BTN_P1_DOWN) then
        game.shop.selected = getNextSelectableShopIndex(game.shop.selected, 1)
    end

    if btnp(BTN_P1_A) then
        purchaseSelectedShopItem()
    end
end

function updateShop()
    -- Keep the station/docking state valid.
    if not canUseShop() then
        changeState(STATE.PLAY)
        return
    end

    normalizeShopSelection()
end

function drawShop()
    -- Draw the game behind the shop overlay.
    drawGame()

    local station = getShopStation()
    if not station then
        drawStandardOverlayBox("SHOP UNAVAILABLE")
        return
    end

    drawShopOverlayBox(station)
end

function drawShopOverlayBox(station)
    local items = game.shop.items
    local cost = game.shop.upgrade_cost or 100

    local title = "SHOP"
    local ore_text = "Station Ore: " ..
        tostring(math.floor(station.ore_bank.cur)) ..
        "/" ..
        tostring(math.floor(station.ore_bank.max))

    local footer = "Z: Buy   X: Exit"

    local fixed = false
    local scale = 1
    local smallfont = false

    local title_scale = 2

    local title_w = print(title, 0, -50, WHITE, fixed, title_scale, smallfont)
    local ore_w = print(ore_text, 0, -50, WHITE, fixed, scale, smallfont)
    local footer_w = print(footer, 0, -50, WHITE, fixed, scale, true)

    local option_color = WHITE
    local price_color = YELLOW

    local max_option_w = 0
    local max_price_w = 0

    for _, item in ipairs(items) do
        local option_w = print(item.name, 0, -50, option_color, fixed, scale, smallfont)
        local price_w = print(tostring(cost) .. " ORE", 0, -50, price_color, fixed, scale, smallfont)

        if option_w > max_option_w then
            max_option_w = option_w
        end

        if price_w > max_price_w then
            max_price_w = price_w
        end
    end

    local selector_w = print(">", 0, -50, WHITE, fixed, scale, smallfont)
    local gap_selector = 6
    local gap_price = 12

    local content_w = selector_w + gap_selector + max_option_w + gap_price + max_price_w
    local widest = math.max(title_w, ore_w, footer_w, content_w)

    local box_padding_x = 14
    local box_padding_y = 10
    local row_h = 12

    -- Extra vertical space between the last shop option and the footer.
    local footer_gap = 18

    local box_w = widest + box_padding_x * 2
    local box_h = 26 + row_h * #items + 24 + footer_gap

    local box_x = math.floor((EDGE_X_RIGHT - box_w) / 2)
    local box_y = math.floor((EDGE_Y_BOTTOM - box_h) / 2)

    -- Box.
    rect(box_x, box_y, box_w, box_h, BLACK)
    rectb(box_x, box_y, box_w, box_h, WHITE)
    rectb(box_x + 1, box_y + 1, box_w - 2, box_h - 2, GRAY_DARK)

    -- Title.
    local title_x = box_x + math.floor((box_w - title_w) / 2)
    local title_y = box_y + 8

    -- print(title, title_x + 1, title_y + 1, GRAY_MED, fixed, title_scale, smallfont)
    -- print(title, title_x, title_y, WHITE, fixed, title_scale, smallfont)
    drawCenteredText(title, title_y, RED, false, 2, false, YELLOW)

    -- Station ore.
    local ore_x = box_x + math.floor((box_w - ore_w) / 2)
    local ore_y = title_y + 18

    print(ore_text, ore_x + 1, ore_y + 1, GRAY_DARK, fixed, scale, smallfont)
    print(ore_text, ore_x, ore_y, CYAN, fixed, scale, smallfont)

    -- Item rows.
    local list_x = box_x + box_padding_x
    local list_y = ore_y + 18

    local option_x = list_x + selector_w + gap_selector
    local price_x = option_x + max_option_w + gap_price

    for i, item in ipairs(items) do
        local y = list_y + (i - 1) * row_h
        local affordable = shopItemIsAffordable(item)
        local selected = i == game.shop.selected and affordable

        local row_option_color = WHITE
        local row_price_color = YELLOW
        local shadow_color = GRAY_DARK

        if not affordable then
            row_option_color = GRAY_MED
            row_price_color = GRAY_MED
            shadow_color = BLACK
        end

        if selected then
            print(">", list_x + 1, y + 1, GRAY_DARK, fixed, scale, smallfont)
            print(">", list_x, y, YELLOW, fixed, scale, smallfont)
        end

        local price_text = tostring(cost) .. " ORE"

        -- Shadow.
        print(item.name, option_x + 1, y + 1, shadow_color, fixed, scale, smallfont)
        print(price_text, price_x + 1, y + 1, shadow_color, fixed, scale, smallfont)

        -- Text.
        print(item.name, option_x, y, row_option_color, fixed, scale, smallfont)
        print(price_text, price_x, y, row_price_color, fixed, scale, smallfont)
    end

    -- Footer.
    local footer_x = box_x + math.floor((box_w - footer_w) / 2)
    local footer_y = box_y + box_h - box_padding_y - FIXED_CHAR_HEIGHT

    print(footer, footer_x + 1, footer_y + 1, GRAY_DARK, fixed, scale, true)
    print(footer, footer_x, footer_y, WHITE, fixed, scale, true)
end
