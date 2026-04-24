-- ==========================================
-- DRAW
-- ==========================================

local function drawCenteredText(text, y, color)
    local width = print(text, 0, -10)
    print(text, (SCREEN_W - width) / 2, y, color)
end

local function drawOverlayBox(text)
    local boxW = 120
    local boxH = 40
    local boxX = (SCREEN_W - boxW) / 2
    local boxY = (SCREEN_H - boxH) / 2
    
    -- Draw box background
    rect(boxX, boxY, boxW, boxH, 0)
    rectb(boxX, boxY, boxW, boxH, 12)
    
    -- Draw text
    drawCenteredText(text, boxY + 16, 12)
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
            local x = (SCREEN_W - textWidth) / 2
            print(">", x - 10, y, 12)
        end
        
        drawCenteredText(option, y, color)
    end
    
    -- Instructions
    drawCenteredText("UP/DOWN: Select  Z: Confirm", SCREEN_H - 15, 6)
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
    drawCenteredText("UP/DOWN: Select  LEFT/RIGHT: Change", SCREEN_H - 25, 6)
    drawCenteredText("X: Back", SCREEN_H - 15, 6)
end


function drawGame()
    cls(1)
    
    -- ================================
    -- YOUR GAME RENDERING HERE
    -- ================================
    
    -- Example: Draw player
    rect(game.play.playerX, game.play.playerY, 8, 8, 12)
    
    -- Draw HUD
    print("SCORE: " .. game.play.score, 5, 5, 12)
end

local function drawPlay()
    drawGame()
end


local function drawPause()
    -- Draw the game state (frozen)
    drawGame()
    
    -- Draw overlay
    drawOverlayBox("PAUSED")
    
    -- Instructions
    drawCenteredText("Press X to Resume", SCREEN_H / 2 + 30, 12)
end


local function drawGameover()
    -- Draw the game state (final state)
    drawGame()
    
    -- Draw overlay
    drawOverlayBox("GAME OVER")
    
    -- Show final score
    local scoreText = "Final Score: " .. game.play.score
    drawCenteredText(scoreText, SCREEN_H / 2 + 25, 12)
    
    -- Instructions
    drawCenteredText("Press any button", SCREEN_H / 2 + 40, 6)
end
