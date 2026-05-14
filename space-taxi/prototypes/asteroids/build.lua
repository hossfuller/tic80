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
    if newState == STATE.PLAY then
        -- Reset game state for new game
        game.play.score = 0
    end
end


-- [/TQ-Bundler: src.game_state]

-- [TQ-Bundler: src.states.start]

-- ==========================================
-- STATE: START (Main Menu)
-- ==========================================

local function inputStart()
    if btnp(BTN_P1_A) or btnp(BTN_P1_START) then
        changeState(STATE.PLAY)
    end
end

local function updateStart()

end

local function drawStart()
    cls(0)

    local title_y_pos = math.floor(EDGE_Y_BOTTOM / 2) - 3 * Y_PADDING
    drawCenteredText("ASTEROIDS", title_y_pos, ORANGE, nil, 3, nil, YELLOW)
    drawCenteredText("Press Z to start", title_y_pos + 3 * Y_PADDING, WHITE, false, 1, false, GRAY_DARK)
end


-- [/TQ-Bundler: src.states.start]

-- [TQ-Bundler: src.states.play]

-- ==========================================
-- STATE: PLAY
-- ==========================================

local function inputPlay()
    if btnp(BTN_P1_SELECT) and btnp(BTN_P1_START) then
        changeState(STATE.GAMEOVER)
    end
end

local function updatePlay()

end

local function drawPlay()
    cls(PURPLE)




end


-- [/TQ-Bundler: src.states.play]

-- [TQ-Bundler: src.states.gameover]

-- ==========================================
-- STATE: GAMEOVER
-- ==========================================

local function inputGameover()
    if btnp(BTN_P1_A) or btnp(BTN_P1_B) then
        changeState(STATE.START)
    end
end

local function updateGameover()

end

local function drawGameover()
    drawPlay()

    local title_y_pos = math.floor(EDGE_Y_BOTTOM / 2) - 3 * Y_PADDING
    drawCenteredText("GAME OVER", title_y_pos, ORANGE, nil, 3, nil, YELLOW)
    drawCenteredText("Press Z or X to return to start screen", title_y_pos + 3 * Y_PADDING, WHITE, false, 1, false, GRAY_DARK)
end


-- [/TQ-Bundler: src.states.gameover]

-- [TQ-Bundler: src.state_machine]

-- ==========================================
-- STATE MACHINE
-- ==========================================

local states = {
    [STATE.START] = {
        input  = inputStart,
        update = updateStart,
        draw   = drawStart,
    },
    [STATE.PLAY] = {
        input  = inputPlay,
        update = updatePlay,
        draw   = drawPlay,
    },
    [STATE.GAMEOVER] = {
        input  = inputGameover,
        update = updateGameover,
        draw   = drawGameover,
    },
}


-- [/TQ-Bundler: src.state_machine]

-- ==========================================
-- MAIN GAME LOOP
-- ==========================================

-- DELETE THIS LINE ONCE THIS CODE HAS BEEN INCORPORATED:
-- https://bytesnbits.co.uk/wp-content/uploads/2020/01/Asteroids-1.txt

function TIC()
    local currentState = states[game.state]
    if currentState then
        currentState.input()
        currentState.update()
        currentState.draw()
    end
end