--
-- Bundle file
-- Code changes will be overwritten
--

-- title:   Space Taxi
-- author:  Hoss Fuller
-- desc:    Travel the universe, delivering space passengers to their space destinations.
-- version: 0.1
-- script:  lua
-- saveid:  space_taxi

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
local BTN_P1_UP     = 0
local BTN_P1_DOWN   = 1
local BTN_P1_LEFT   = 2
local BTN_P1_RIGHT  = 3
local BTN_P1_A      = 4         -- Primary action / Select
local BTN_P1_B      = 5         -- Secondary action / Back / Pause
local BTN_P1_X      = 6
local BTN_P1_Y      = 7
local BTN_P1_SELECT = BTN_P1_X
local BTN_P1_START  = BTN_P1_Y

-- Screen dimensions
local EDGE_X_LEFT   = 0
local EDGE_X_RIGHT  = 240
local EDGE_Y_TOP    = 0
local EDGE_Y_BOTTOM = 136

-- Character dimensions (these scale linearly)
local FIXED_CHAR_WIDTH  = 6
local FIXED_CHAR_HEIGHT = 6
local X_PADDING         = FIXED_CHAR_WIDTH + 2
local Y_PADDING         = FIXED_CHAR_HEIGHT + 2


-- [/TQ-Bundler: src.constants]

-- [TQ-Bundler: src.helpers]

-- ==========================================
-- HELPERS
-- ==========================================




-- ==========================================
-- DRAWING HELPERS
-- ==========================================

local function drawCenteredText(text, y, color, fixed, scale, smallfont, shadow_color)
    if fixed == nil then
        fixed = false
    end
    if scale == nil then
        scale = 1
    end
    if smallfont == nil then
        smallfont = false
    end
    if shadow_color == nil then
        shadow_color = -1
    end
    local width = print(text, 0, -50, color, fixed, scale, smallfont)

    if shadow_color >= 0 then
        print(text, (EDGE_X_RIGHT - width) / 2 + 1, y + 1, shadow_color, fixed, scale, smallfont)
    end
    print(text, (EDGE_X_RIGHT - width) / 2, y, color, fixed, scale, smallfont)
end


-- [/TQ-Bundler: src.helpers]

-- [TQ-Bundler: src.game_state]

-- ==========================================
-- GAME STATE
-- ==========================================

local STATE = {
    START    = "START",
    PLAY     = "PLAY",
    GAMEOVER = "GAMEOVER",
}

local game = {
    state = STATE.START,
    prevState = nil,

    -- Gameplay state
    play = {
        score = 0,
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
    end
end


-- [/TQ-Bundler: src.game_state]

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
            changeState(STATE.PLAY)
        end
    end
end

local function drawStart()
    cls(0)

    -- Title
    drawCenteredText("ASTEROIDS", EDGE_Y_TOP + Y_PADDING, ORANGE, nil, 3, nil, YELLOW)

    -- Menu options
    local start_y = 60
    local spacing = 2 * X_PADDING

    for i, option in ipairs(game.menu.options) do
        local y = start_y + (i - 1) * spacing
        local color = (i == game.menu.selected) and YELLOW or WHITE

        -- Draw selector
        if i == game.menu.selected then
            local textWidth = print(option, 0, -10)
            local x = (EDGE_X_RIGHT - textWidth) / 2
            print(">", x - 10 + 1, y + 1, GRAY_DARK) -- the shadow
            print(">", x - 10, y, WHITE)
        end

        -- drawCenteredText(option, y, color)
        drawCenteredText(option, y, color, nil, nil, nil, GRAY_DARK)
    end

    -- Instructions
    drawCenteredText("UP/DOWN: Select  Z: Confirm", EDGE_Y_BOTTOM - Y_PADDING, WHITE, false, 1, true, GRAY_DARK)
end


-- [/TQ-Bundler: src.states.start]

-- [TQ-Bundler: src.states.play]

-- ==========================================
-- STATE: PLAY
-- ==========================================

local function updatePlay()
    -- Pause
    if btnPressed(BTN_P1_START) then
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
    -- local speed = 2

    -- if btn(BTN_P1_UP) then
    --     game.play.playerY = game.play.playerY - speed
    -- end
    -- if btn(BTN_P1_DOWN) then
    --     game.play.playerY = game.play.playerY + speed
    -- end
    -- if btn(BTN_P1_LEFT) then
    --     game.play.playerX = game.play.playerX - speed
    -- end
    -- if btn(BTN_P1_RIGHT) then
    --     game.play.playerX = game.play.playerX + speed
    -- end

    -- -- Keep player in bounds
    -- game.play.playerX = math.max(0, math.min(EDGE_X_RIGHT - 8, game.play.playerX))
    -- game.play.playerY = math.max(0, math.min(EDGE_Y_BOTTOM - 8, game.play.playerY))

    -- -- Update score (example)
    -- game.play.score = game.play.score + 1
end

function drawGame()
    cls(PURPLE)

    -- ================================
    -- YOUR GAME RENDERING HERE
    -- ================================

    -- -- Example: Draw player
    -- rect(game.play.playerX, game.play.playerY, 8, 8, 12)

    -- -- Draw HUD
    -- print("SCORE: " .. game.play.score, 5, 5, 12)
end

local function drawPlay()
    drawGame()
end


-- [/TQ-Bundler: src.states.play]

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

    -- -- Show final score
    -- local scoreText = "Final Score: " .. game.play.score
    -- drawCenteredText(scoreText, EDGE_Y_BOTTOM / 2 + 25, 12)

    -- Instructions
    drawCenteredText("Press any button", EDGE_Y_BOTTOM - Y_PADDING, WHITE, false, 1, true, BLACK)
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
    [STATE.PLAY] = {
        update = updatePlay,
        draw = drawPlay,
    },
    [STATE.GAMEOVER] = {
        update = updateGameover,
        draw = drawGameover,
    },
}


-- [/TQ-Bundler: src.state_machine]

-- ==========================================
-- MAIN GAME LOOP
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

