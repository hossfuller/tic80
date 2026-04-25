-- ==========================================
-- STATE: PLAY
-- ==========================================

local function updatePlay()
    -- Pause
    if btnPressed(BTN_P1_B) then
        changeState(STATE.PAUSE)
        return
    end
    
    -- Game over (for testing - press UP+DOWN)
    if btn(BTN_P1_UP) and btn(BTN_P1_DOWN) then
        changeState(STATE.GAMEOVER)
        return
    end
    
    -- ================================
    -- YOUR GAME LOGIC HERE
    -- ================================
    local speed = 2
    
    if btn(BTN_P1_UP) then
        game.play.playerY = game.play.playerY - speed
    end
    if btn(BTN_P1_DOWN) then
        game.play.playerY = game.play.playerY + speed
    end
    if btn(BTN_P1_LEFT) then
        game.play.playerX = game.play.playerX - speed
    end
    if btn(BTN_P1_RIGHT) then
        game.play.playerX = game.play.playerX + speed
    end
    
    -- Keep player in bounds
    game.play.playerX = math.max(0, math.min(EDGE_X_RIGHT - 8, game.play.playerX))
    game.play.playerY = math.max(0, math.min(EDGE_Y_BOTTOM - 8, game.play.playerY))
    
    -- Update score (example)
    game.play.score = game.play.score + 1
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
