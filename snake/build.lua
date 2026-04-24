--
-- Bundle file
-- Code changes will be overwritten
--

-- title:   Snake Clone
-- author:  Adam Fuller <the.adam.fuller@gmail.com>
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
local P1_UP    = 0
local P1_DOWN  = 1
local P1_LEFT  = 2
local P1_RIGHT = 3
local P1_A     = 4
local P1_B     = 5
local P1_X     = 6
local P1_Y     = 7
local P2_UP    = 8
local P2_DOWN  = 9
local P2_LEFT  = 10
local P2_RIGHT = 11
local P2_A     = 12
local P2_B     = 13
local P2_X     = 14
local P2_Y     = 15
-- local BTN_UP     = P1_UP
-- local BTN_DOWN   = P1_DOWN
-- local BTN_LEFT   = P1_LEFT
-- local BTN_RIGHT  = P1_RIGHT
-- local BTN_Z      = P1_A  -- Primary action / Select
-- local BTN_X      = P1_B  -- Secondary action / Back / Pause


-- Screen dimensions
local EDGE_X_LEFT    = 0
local EDGE_X_RIGHT   = 240
local EDGE_Y_TOP     = 0
local EDGE_Y_BOTTOM  = 136
local SCREEN_W = EDGE_X_RIGHT
local SCREEN_H = EDGE_Y_BOTTOM


local STATE = {
    START    = "START",
    OPTIONS  = "OPTIONS",
    HISCORES = "HISCORES",
    READY    = "READY",
    PLAY     = "PLAY",
    PAUSE    = "PAUSE",
    GAMEOVER = "GAMEOVER",
}


--[[ TODO LIST ]]--

-- TODO: Add a way to pause the game.
-- TODO: Do power ups!



-- [/TQ-Bundler: src.constants]

-- [TQ-Bundler: src.helpers]

-- ==========================================
-- HELPERS
-- ==========================================


-- [/TQ-Bundler: src.helpers]

-- [TQ-Bundler: src.state_machine]

-- ==========================================
-- STATE MACHINE
-- ==========================================

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
        playerX = SCREEN_W / 2,
        playerY = SCREEN_H / 2,
    },
}


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


local function changeState(newState)
    game.prevState = game.state
    game.state = newState
    
    -- State entry logic
    if newState == STATE.READY then
        -- Reset game state for new game
        game.play.score = 0
        game.play.playerX = SCREEN_W / 2
        game.play.playerY = SCREEN_H / 2
    end
end


-- [/TQ-Bundler: src.state_machine]

-- [TQ-Bundler: src.input]

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


-- [/TQ-Bundler: src.input]

-- [TQ-Bundler: src.update]

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


-- [/TQ-Bundler: src.update]

-- [TQ-Bundler: src.draw]

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


-- [/TQ-Bundler: src.draw]

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