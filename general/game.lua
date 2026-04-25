--
-- Bundle file
-- Code changes will be overwritten
--

-- title:   General Game Skeleton
-- author:  Adam Fuller <the.adam.fuller@gmail.com>
-- desc:    General game state machine skeleton for TIC-80
-- version: 0.1
-- script:  lua


-- ==========================================
-- INCLUDES
-- ==========================================

-- [TQ-Bundler: src.constants]

-- ==========================================
-- CONSTANTS
-- ==========================================

-- Colors
local BLACK      = 0
local PURPLE     = 1
local RED        = 2
local ORANGE     = 3
local YELLOW     = 4
local GREEN_LITE = 5
local GREEN_MED  = 6
local GREEN_DARK = 7
local BLUE_DARK  = 8
local BLUE_MED   = 9
local BLUE_LITE  = 10
local CYAN       = 11
local WHITE      = 12
local GRAY_LITE  = 13
local GRAY_MED   = 14
local GRAY_DARK  = 15

-- Button mappings
local BTN_P1_UP    = 0
local BTN_P1_DOWN  = 1
local BTN_P1_LEFT  = 2
local BTN_P1_RIGHT = 3
local BTN_P1_A     = 4  -- Primary action / Select
local BTN_P1_B     = 5  -- Secondary action / Back / Pause
local BTN_P1_X     = 6
local BTN_P1_Y     = 7
local BTN_P2_UP    = 8
local BTN_P2_DOWN  = 9
local BTN_P2_LEFT  = 10
local BTN_P2_RIGHT = 11
local BTN_P2_A     = 12
local BTN_P2_B     = 13
local BTN_P2_X     = 14
local BTN_P2_Y     = 15

-- Screen dimensions
local EDGE_X_LEFT    = 0
local EDGE_X_RIGHT   = 240
local EDGE_Y_TOP     = 0
local EDGE_Y_BOTTOM  = 136

-- [/TQ-Bundler: src.constants]

-- [TQ-Bundler: src.game_state]

-- ==========================================
-- GAME STATE
-- ==========================================

local STATE = {
    START    = "START",
    OPTIONS  = "OPTIONS",
    HISCORES = "HISCORES",
    READY    = "READY",
    PLAY     = "PLAY",
    PAUSE    = "PAUSE",
    GAMEOVER = "GAMEOVER",
}

local game = {
    state = STATE.START,
    prevState = nil,
    
    -- Menu state
    menu = {
        selected = 1,
        options = {"New Game", "Options", "High Scores"},
    },
    
    -- Options state
    options = {
        selected = 1,
        items = {
            {name = "Sound", values = {"On", "Off"}, current = 1},
            {name = "Difficulty", values = {"Easy", "Normal", "Hard"}, current = 2},
            {name = "Back", values = {""}, current = 1},
        },
    },
    
    -- High scores
    hiscores = {
        {name = "AAA", score = 10000},
        {name = "BBB", score = 7500},
        {name = "CCC", score = 5000},
        {name = "DDD", score = 2500},
        {name = "EEE", score = 1000},
    },
    
    -- Gameplay state
    play = {
        score = 0,
        -- Add your game-specific state here
        playerX = EDGE_X_RIGHT / 2,
        playerY = EDGE_Y_BOTTOM / 2,
    },
}


-- ==========================================
-- STATE CHANGE
-- ==========================================

local function changeState(newState)
    game.prevState = game.state
    game.state = newState
    
    -- State entry logic
    if newState == STATE.READY then
        -- Reset game state for new game
        game.play.score = 0
        game.play.playerX = EDGE_X_RIGHT / 2
        game.play.playerY = EDGE_Y_BOTTOM / 2
    end
end



-- [/TQ-Bundler: src.game_state]

-- [TQ-Bundler: src.helpers]

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



-- [/TQ-Bundler: src.helpers]

-- [TQ-Bundler: src.states.start]

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



-- [/TQ-Bundler: src.states.start]

-- [TQ-Bundler: src.states.options]

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

-- [/TQ-Bundler: src.states.options]

-- [TQ-Bundler: src.states.hiscores]

-- ==========================================
-- STATE: HISCORES
-- ==========================================

local function updateHiscores()
    if btnPressed(BTN_P1_A) or btnPressed(BTN_P1_B) then
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
    drawCenteredText("Press A or B to return", EDGE_Y_BOTTOM - 15, 6)
end


-- [/TQ-Bundler: src.states.hiscores]

-- [TQ-Bundler: src.states.ready]

-- ==========================================
-- STATE: READY
-- ==========================================

local function updateReady()
    if btnPressed(BTN_P1_A) then
        changeState(STATE.PLAY)
    end
    
    if btnPressed(BTN_P1_B) then
        changeState(STATE.START)
    end
end

local function drawReady()
    -- Draw the game state (paused/initial state)
    drawGame()
    
    -- Draw overlay
    drawOverlayBox("READY?")
    
    -- Instructions
    drawCenteredText("Press A to Start", EDGE_Y_BOTTOM / 2 + 30, 12)
end


-- [/TQ-Bundler: src.states.ready]

-- [TQ-Bundler: src.states.play]

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


-- [/TQ-Bundler: src.states.play]

-- [TQ-Bundler: src.states.pause]

-- ==========================================
-- STATE: PAUSE
-- ==========================================

local function updatePause()
    if btnPressed(BTN_P1_B) then
        changeState(STATE.PLAY)
    end
end

local function drawPause()
    -- Draw the game state (frozen)
    drawGame()
    
    -- Draw overlay
    drawOverlayBox("PAUSED")
    
    -- Instructions
    drawCenteredText("Press B to Resume", EDGE_Y_BOTTOM / 2 + 30, 12)
end


-- [/TQ-Bundler: src.states.pause]

-- [TQ-Bundler: src.states.gameover]

-- ==========================================
-- STATE: GAMEOVER
-- ==========================================

local function updateGameover()
    if btnPressed(BTN_P1_A) or btnPressed(BTN_P1_B) then
        changeState(STATE.START)
    end
end

local function drawGameover()
    -- Draw the game state (final state)
    drawGame()
    
    -- Draw overlay
    drawOverlayBox("GAME OVER")
    
    -- Show final score
    local scoreText = "Final Score: " .. game.play.score
    drawCenteredText(scoreText, EDGE_Y_BOTTOM / 2 + 25, 12)
    
    -- Instructions
    drawCenteredText("Press any button", EDGE_Y_BOTTOM / 2 + 40, 6)
end


-- [/TQ-Bundler: src.states.gameover]

-- [TQ-Bundler: src.state_machine]

-- ==========================================
-- STATE MACHINE
-- ==========================================

local states = {
    [STATE.START] = {
        update = updateStart,
        draw = drawStart,
    },
    [STATE.OPTIONS] = {
        update = updateOptions,
        draw = drawOptions,
    },
    [STATE.HISCORES] = {
        update = updateHiscores,
        draw = drawHiscores,
    },
    [STATE.READY] = {
        update = updateReady,
        draw = drawReady,
    },
    [STATE.PLAY] = {
        update = updatePlay,
        draw = drawPlay,
    },
    [STATE.PAUSE] = {
        update = updatePause,
        draw = drawPause,
    },
    [STATE.GAMEOVER] = {
        update = updateGameover,
        draw = drawGameover,
    },
}


-- [/TQ-Bundler: src.state_machine]

-- ==========================================
-- MAIN TIC FUNCTION
-- ==========================================

function TIC()
    updateInput()
    
    local currentState = states[game.state]
    if currentState then
        currentState.update()
        currentState.draw()
    end
end
-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304000000000
-- </SFX>

-- <TRACKS>
-- 000:100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </TRACKS>

-- <PALETTE>
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

