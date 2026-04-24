-- ==========================================
-- UPDATE
-- ==========================================

local function updateStart()
    -- Menu navigation
    if btnPressed(BTN_UP) then
        game.menu.selected = game.menu.selected - 1
        if game.menu.selected < 1 then
            game.menu.selected = #game.menu.options
        end
    end
    
    if btnPressed(BTN_DOWN) then
        game.menu.selected = game.menu.selected + 1
        if game.menu.selected > #game.menu.options then
            game.menu.selected = 1
        end
    end
    
    -- Menu selection
    if btnPressed(BTN_Z) then
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

local function updateOptions()
    local opts = game.options
    
    -- Navigation
    if btnPressed(BTN_UP) then
        opts.selected = opts.selected - 1
        if opts.selected < 1 then
            opts.selected = #opts.items
        end
    end
    
    if btnPressed(BTN_DOWN) then
        opts.selected = opts.selected + 1
        if opts.selected > #opts.items then
            opts.selected = 1
        end
    end
    
    -- Change option value
    local currentItem = opts.items[opts.selected]
    
    if btnPressed(BTN_LEFT) and #currentItem.values > 1 then
        currentItem.current = currentItem.current - 1
        if currentItem.current < 1 then
            currentItem.current = #currentItem.values
        end
    end
    
    if btnPressed(BTN_RIGHT) and #currentItem.values > 1 then
        currentItem.current = currentItem.current + 1
        if currentItem.current > #currentItem.values then
            currentItem.current = 1
        end
    end
    
    -- Select (for Back option) or Back button
    if btnPressed(BTN_Z) then
        if opts.items[opts.selected].name == "Back" then
            changeState(STATE.START)
        end
    end
    
    if btnPressed(BTN_X) then
        changeState(STATE.START)
    end
end

local function updateHiscores()
    if btnPressed(BTN_Z) or btnPressed(BTN_X) then
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
    drawCenteredText("Press Z or X to return", SCREEN_H - 15, 6)
end


local function updateReady()
    if btnPressed(BTN_Z) then
        changeState(STATE.PLAY)
    end
    
    if btnPressed(BTN_X) then
        changeState(STATE.START)
    end
end


local function drawReady()
    -- Draw the game state (paused/initial state)
    drawGame()
    
    -- Draw overlay
    drawOverlayBox("READY?")
    
    -- Instructions
    drawCenteredText("Press Z to Start", SCREEN_H / 2 + 30, 12)
end


local function updatePlay()
    -- Pause
    if btnPressed(BTN_X) then
        changeState(STATE.PAUSE)
        return
    end
    
    -- Game over (for testing - press UP+DOWN)
    if btn(BTN_UP) and btn(BTN_DOWN) then
        changeState(STATE.GAMEOVER)
        return
    end
    
    -- ================================
    -- YOUR GAME LOGIC HERE
    -- ================================
    local speed = 2
    
    if btn(BTN_UP) then
        game.play.playerY = game.play.playerY - speed
    end
    if btn(BTN_DOWN) then
        game.play.playerY = game.play.playerY + speed
    end
    if btn(BTN_LEFT) then
        game.play.playerX = game.play.playerX - speed
    end
    if btn(BTN_RIGHT) then
        game.play.playerX = game.play.playerX + speed
    end
    
    -- Keep player in bounds
    game.play.playerX = math.max(0, math.min(SCREEN_W - 8, game.play.playerX))
    game.play.playerY = math.max(0, math.min(SCREEN_H - 8, game.play.playerY))
    
    -- Update score (example)
    game.play.score = game.play.score + 1
end


local function updatePause()
    if btnPressed(BTN_X) then
        changeState(STATE.PLAY)
    end
end


local function updateGameover()
    if btnPressed(BTN_Z) or btnPressed(BTN_X) then
        changeState(STATE.START)
    end
end
