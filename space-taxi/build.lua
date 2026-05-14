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
    cls(BLACK)

    -- Title
    drawCenteredText("OPTIONS", EDGE_Y_TOP + Y_PADDING, ORANGE, nil, 3, nil, YELLOW)

    -- Options list
    local startY = 50
    local spacing = 20

    for i, item in ipairs(game.options.items) do
        local y = startY + (i - 1) * spacing
        local color = (i == game.options.selected) and YELLOW or WHITE

        -- Draw selector
        if i == game.options.selected then
            print(">", 30 + 1, y + 1, BLACK) -- the shadow
            print(">", 30, y, WHITE)
        end

        -- Draw option name and value
        print(item.name, 45 + 1, y + 1, BLACK) -- the shadow
        print(item.name, 45, y, color)

        if #item.values > 0 and item.values[1] ~= "" then
            local valueText = "< " .. item.values[item.current] .. " >"
            print(valueText, 140 + 1, y + 1, BLACK) -- the shadow
            print(valueText, 140, y, color)
        end
    end

    -- Instructions
    drawCenteredText("UP/DOWN: Select  LEFT/RIGHT: Change", EDGE_Y_BOTTOM - Y_PADDING, WHITE, false, 1, true, BLACK)
end


-- [/TQ-Bundler: src.states.options]

-- [TQ-Bundler: src.states.hiscores]

-- ==========================================
-- STATE: HISCORES
-- ==========================================

-- Persistent memory has 255 slots. We want to save four pieces of data, so that
-- restricts us to 252 slots (63 chunks of 4 slots).
local MAX_PMEM_CHUNKS = 63

local lines = {}


function loadHighScores()
    game.statistics = {}

    -- for idx = 0, MAX_PMEM_CHUNKS do
    --     local base = idx * 4
    --     local date = pmem(base + 0)
    --     if date ~= 0 then
    --         game.statistics[base] = {
    --             date       = date,
    --             difficulty = pmem(base + 1),
    --             timer      = pmem(base + 2),
    --             autonotes  = pmem(base + 3),
    --         }
    --     end
    -- end
end

function sortHighScores()
    -- Collect existing entries (0,4,8,...) into a dense list
    local list = {}
    -- for idx = 0, MAX_PMEM_CHUNKS do
    --     local base = idx * 4
    --     local d = game.statistics[base]
    --     if d then
    --         list[#list + 1] = d
    --     end
    -- end

    -- -- Sort by difficulty desc, then by time asc, then by autonotes asc.
    -- table.sort(list, function(a, b)
    --     if a.difficulty ~= b.difficulty then
    --         return a.difficulty > b.difficulty
    --     end
    --     if a.timer ~= b.timer then
    --         return a.timer < b.timer
    --     end
    --     if a.autonotes ~= b.autonotes then
    --         return a.autonotes < b.autonotes
    --     end
    --     -- optional tiebreaker so order is stable-ish
    --     return a.date > b.date
    -- end)

    -- Write back compacted into chunk keys 0,4,8,...
    game.statistics = {}
    -- for i = 1, #list do
    --     game.statistics[(i - 1) * 4] = list[i]
    -- end
end

local function saveCurrentScore()
    -- Always start from what is currently saved
    loadHighScores()

    -- -- Find next free chunk index in the CURRENT in-memory table
    -- local n = 0
    -- for idx = 0, MAX_PMEM_CHUNKS do
    --     if game.statistics[idx * 4] then n = n + 1 end
    -- end
    -- local base = n * 4
    -- if base > MAX_PMEM_CHUNKS * 4 then
    --     base = MAX_PMEM_CHUNKS * 4 -- will be trimmed after sort
    -- end

    -- -- Map difficulty string -> numeric rank for storage/sorting
    -- local diff = (game.play.difficulty == "Easy" and 0)
    --     or (game.play.difficulty == "Medium" and 1)
    --     or 2

    -- -- Add current result
    -- game.statistics[base] = {
    --     date       = game.play.date,
    --     difficulty = diff,
    --     timer      = game.play.timer:getSeconds(),
    --     autonotes  = game.play.autonotes,
    -- }

    -- Sort + compact keys to 0,4,8,...
    sortHighScores()

    -- -- Save the data.
    for i = 0, 255 do pmem(i, 0) end
    -- for idx = 0, MAX_PMEM_CHUNKS do
    --     local b = idx * 4
    --     local d = game.statistics[b]
    --     if d then
    --         pmem(b + 0, d.date)
    --         pmem(b + 1, d.difficulty)
    --         pmem(b + 2, d.timer)
    --         pmem(b + 3, d.autonotes)
    --     end
    -- end
end


function buildLines()
    -- Show only the saved/sorted entries (0,4,8,...,252)
    lines = {}
    -- for idx = 0, MAX_PMEM_CHUNKS do
    --     local k = idx * 4
    --     local d = game.statistics[k]
    --     if d then
    --         local dt_obj = unix_to_greg_utc(d.date)
    --         local dt_str = convert_datetime_obj_to_string(dt_obj)
    --         table.insert(lines, dt_str)

    --         local diff = (d.difficulty == 0 and "Easy")
    --             or (d.difficulty == 1 and "Medium")
    --             or (d.difficulty == 2 and "Hard")
    --         table.insert(lines, string.format("      Difficulty   %s", diff))

    --         local minutes = math.floor(d.timer / 60)
    --         local seconds = d.timer % 60
    --         table.insert(lines, string.format("      Clock         %02d:%02d", minutes, seconds))

    --         table.insert(lines, string.format("      Auto-Notes  %s", d.autonotes))
    --         table.insert(lines, "") -- blank spacer line
    --     end
    -- end
end

local function updateHiscores()
    if btnPressed(BTN_P1_A) or btnPressed(BTN_P1_B) then
        changeState(STATE.START)
    end
end

local function drawHiscores()
    cls(0)

    -- LAYOUT
    local header_y = EDGE_Y_TOP + Y_PADDING
    local line_h = FIXED_CHAR_HEIGHT + 1
    local view_top = header_y + FIXED_CHAR_HEIGHT + 2 * Y_PADDING
    local view_bottom = EDGE_Y_BOTTOM - 2 * Y_PADDING
    local visible_lines = math.max(1, math.floor((view_bottom - view_top) / line_h))

    -- INPUT
    local max_scroll = math.max(0, #lines - visible_lines)

    -- keyboard (hold+repeat)
    if btnp(BTN_P1_UP, 15, 3) then
        scroll = scroll - 1
    end
    if btnp(BTN_P1_DOWN, 15, 3) then
        scroll = scroll + 1
    end

    -- clamp
    -- scroll = math.max(0, math.min(max_scroll, scroll))

    drawCenteredText("HIGH SCORES", EDGE_Y_TOP + Y_PADDING, ORANGE, nil, 3, nil, YELLOW)

    -- -- draw visible slice
    -- for i = 0, visible_lines - 1 do
    --     local line = lines[scroll + 1 + i] -- Lua arrays are 1-based
    --     if not line then break end
    --     local y = view_top + i * line_h
    --     print(line, X_PADDING + 1, y + 1, BLACK) -- the shadow
    --     print(line, X_PADDING, y, WHITE)
    -- end

    -- -- Small scrollbar indicator
    -- if max_scroll > 0 then
    --     local bar_x = EDGE_X_RIGHT - 4
    --     rect(bar_x, view_top, 2, view_bottom - view_top, GRAY_DARK)
    --     local thumb_h = math.max(4, math.floor((view_bottom - view_top) * (visible_lines / #lines)))
    --     local thumb_y = view_top + math.floor((view_bottom - view_top - thumb_h) * (scroll / max_scroll))
    --     rect(bar_x, thumb_y, 2, thumb_h, GREEN_LITE)
    -- end

    -- Instructions
    drawCenteredText("Press Z or X to return", EDGE_Y_BOTTOM - Y_PADDING, WHITE, false, 1, true, BLACK)
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
    -- drawCenteredText("Press Z to Start", EDGE_Y_BOTTOM / 2 + 30, 12)
    drawCenteredText("Press Z to Start", EDGE_Y_BOTTOM - Y_PADDING, WHITE, false, 1, true, BLACK)
end


-- [/TQ-Bundler: src.states.ready]

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

-- [TQ-Bundler: src.states.pause]

-- ==========================================
-- STATE: PAUSE
-- ==========================================

local function updatePause()
    if btnPressed(BTN_P1_START) then
        changeState(STATE.PLAY)
    end
end

local function drawPause()
    -- Draw the game state (frozen)
    drawGame()

    -- Draw overlay
    drawOverlayBox("PAUSED")

    -- Instructions
    drawCenteredText("Press START to Resume", EDGE_Y_BOTTOM - Y_PADDING, WHITE, false, 1, true, BLACK)
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