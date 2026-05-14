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
local BTN_P1_UP    = 0
local BTN_P1_DOWN  = 1
local BTN_P1_LEFT  = 2
local BTN_P1_RIGHT = 3
local BTN_P1_A     = 4  -- Primary action / Select
local BTN_P1_B     = 5  -- Secondary action / Back / Pause
local BTN_P1_X     = 6
local BTN_P1_Y     = 7

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
-- TIME HELPERS
-- ==========================================

local mdays_common = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }

local function get_unix_timestamp()
    return math.tointeger(tstamp())
end

local function convert_datetime_obj_to_string(datetime_obj)
    return string.format(
        "%04d-%02d-%02d",
        datetime_obj.year,
        datetime_obj.month,
        datetime_obj.day
    )
end

local function is_greg_leap(y)
    return (y % 4 == 0) and ((y % 100 ~= 0) or (y % 400 == 0))
end

local function greg_days_in_month(y, m)
    if m == 2 and is_greg_leap(y) then return 29 end
    return mdays_common[m]
end

-- Unix seconds -> Gregorian UTC date/time (year,month,day,hour,min,sec)
local function unix_to_greg_utc(ts)
    local sec_per_day = 86400
    local days        = math.floor(ts / sec_per_day)
    local sod         = ts - days * sec_per_day
    if sod < 0 then
        sod = sod + sec_per_day
        days = days - 1
    end

    local hour = math.floor(sod / 3600); sod = sod - hour * 3600
    local min  = math.floor(sod / 60)
    local sec  = sod - min * 60

    local y    = 1970
    if days >= 0 then
        while true do
            local diy = is_greg_leap(y) and 366 or 365
            if days >= diy then
                days = days - diy
                y = y + 1
            else
                break
            end
        end
    else
        while days < 0 do
            y = y - 1
            local diy = is_greg_leap(y) and 366 or 365
            days = days + diy
        end
    end

    local m = 1
    while true do
        local dim = greg_days_in_month(y, m)
        if days >= dim then
            days = days - dim
            m = m + 1
        else
            break
        end
    end

    local d = days + 1

    return {
        year  = y,
        month = m,
        day   = d,
        hour  = hour,
        min   = min,
        sec   = sec
    }
end


-- ==========================================
-- INPUT HELPERS
-- ==========================================

-- Input tracking for edge detection
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

local function drawOverlayBox(text_array)
    local boxW = 120
    local boxH = 40
    local boxX = math.floor((EDGE_X_RIGHT - boxW) / 2)
    local boxY = math.floor((EDGE_Y_BOTTOM - boxH) / 2)

    -- Draw box background
    rect(boxX, boxY, boxW, boxH, BLACK)
    rectb(boxX, boxY, boxW, boxH, WHITE)

    -- Draw text
    for i, text in ipairs(text_array) do
        drawCenteredText(text, boxY + (i * Y_PADDING), WHITE)
    end
end


-- [/TQ-Bundler: src.helpers]

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
        options = { "New Game", "Options", "High Scores" },
    },

    -- Options state
    options = {
        selected = 1,
        items = {
            { name = "Sound",      values = { "On", "Off" },            current = 1 },
            { name = "Difficulty", values = { "Easy", "Normal", "Hard" }, current = 2 },
            { name = "Back",       values = { "" },                     current = 1 },
        },
    },

    -- High scores
    hiscores = {
        { name = "AAA", score = 10000 },
        { name = "BBB", score = 7500 },
        { name = "CCC", score = 5000 },
        { name = "DDD", score = 2500 },
        { name = "EEE", score = 1000 },
    },

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
    -- drawCenteredText("SPACE TAXI", 20, 12)
    drawCenteredText("SPACE TAXI", EDGE_Y_TOP + Y_PADDING, ORANGE, nil, 3, nil, YELLOW)

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

-- include "src.states.options"
-- include "src.states.hiscores"
-- include "src.states.ready"
-- include "src.states.play"
-- include "src.states.pause"
-- include "src.states.gameover"

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