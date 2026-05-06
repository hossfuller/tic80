--
-- Bundle file
-- Code changes will be overwritten
--

-- title:   Sudoku for TIC-80
-- author:  Adam Fuller <the.adam.fuller@gmail.com>
-- version: rev4.1
-- script:  lua
-- input: mouse

-- ==========================================
-- INCLUDES
-- ==========================================

-- [TQ-Bundler: src.constants]

-- ==========================================
-- CONSTANTS
-- ==========================================

-- Colors
local BLACK                  = 0
local PURPLE                 = 1
local RED                    = 2
local ORANGE                 = 3
local YELLOW                 = 4
local GREEN_LITE             = 5
local GREEN_MED              = 6
local GREEN_DARK             = 7
local BLUE_DARK              = 8
local BLUE_MED               = 9
local BLUE_LITE              = 10
local CYAN                   = 11
local WHITE                  = 12
local GRAY_LITE              = 13
local GRAY_MED               = 14
local GRAY_DARK              = 15

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
local EDGE_X_LEFT            = 0
local EDGE_X_RIGHT           = 240
local EDGE_Y_TOP             = 0
local EDGE_Y_BOTTOM          = 136

-- Character dimensions (these scale linearly)
local FIXED_CHAR_WIDTH       = 6
local FIXED_CHAR_HEIGHT      = 6

local X_PADDING              = FIXED_CHAR_WIDTH + 2
local Y_PADDING              = FIXED_CHAR_HEIGHT + 2
local CELL_WIDTH_MULTIPLIER  = 1.75
local CELL_HEIGHT_MULTIPLIER = 1.75
local GAP_CELL               = -1 -- between cells inside a house
local GAP_HOUSE              = 0  -- between houses (after col/row 3 and 6)



-- [/TQ-Bundler: src.constants]

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

-- [TQ-Bundler: src.game_state]

-- ==========================================
-- GAME STATE
-- ==========================================

local STATE = {
    TITLE    = "TITLE",
    OPTIONS  = "OPTIONS",
    HISCORES = "HISCORES",
    PUZZLE   = "PUZZLE",
}

local game = {
    state = STATE.TITLE,
    prevState = nil,
    
    -- Menu state
    menu = {
        selected = 1,
        options = {"New Puzzle", "Options", "High Scores"},
    },
    
    -- Options state
    options = {
        selected = 1,
        items = {
            -- {name = "Sound", values = {"On", "Off"}, current = 1},
            {name = "Difficulty", values = {"Easy", "Medium", "Hard"}, current = 2},
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
    play = {},
}

local function changeState(newState)
    game.prevState = game.state
    game.state = newState
    
    -- State entry logic
    if newState == STATE.PUZZLE then
        -- Initialize new puzzle.

    end
end


-- [/TQ-Bundler: src.game_state]

-- [TQ-Bundler: src.states.title]

-- ==========================================
-- STATE: TITLE (Main Menu)
-- ==========================================

local function updateTitle()
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
            changeState(STATE.PUZZLE)
        elseif selected == 2 then
            changeState(STATE.OPTIONS)
        elseif selected == 3 then
            changeState(STATE.HISCORES)
        end
    end
end

local function drawTitle()
    cls(0)
    
    -- Title
    -- @TODO: Replace this with a big-ass graphic.
    drawCenteredText("SUDOKU", 20, WHITE)
    
    -- Menu options
    local start_y = 60
    local spacing = 2 * X_PADDING
    
    for i, option in ipairs(game.menu.options) do
        local y = start_y + (i - 1) * spacing
        local color = (i == game.menu.selected) and WHITE or GREEN_MED
        
        -- Draw selector
        if i == game.menu.selected then
            local textWidth = print(option, 0, -10)
            local x = (EDGE_X_RIGHT - textWidth) / 2
            print(">", x - 10, y, WHITE)
        end
        
        drawCenteredText(option, y, color)
    end
    
    -- Instructions
    drawCenteredText("UP/DOWN: Select  A: Confirm", EDGE_Y_BOTTOM - 15, GREEN_MED)
end


-- [/TQ-Bundler: src.states.title]

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
            changeState(STATE.TITLE)
        end
    end
    
    if btnPressed(BTN_P1_B) then
        changeState(STATE.TITLE)
    end
end

local function drawOptions()
    cls(0)
    
    -- Title
    drawCenteredText("OPTIONS", 20, WHITE)
    
    -- Options list
    local startY = 50
    local spacing = 20
    
    for i, item in ipairs(game.options.items) do
        local y = startY + (i - 1) * spacing
        local color = (i == game.options.selected) and WHITE or GREEN_MED
        
        -- Draw selector
        if i == game.options.selected then
            print(">", 30, y, WHITE)
        end
        
        -- Draw option name and value
        print(item.name, 45, y, color)
        
        if #item.values > 0 and item.values[1] ~= "" then
            local valueText = "< " .. item.values[item.current] .. " >"
            print(valueText, 140, y, color)
        end
    end
    
    -- Instructions
    drawCenteredText("UP/DOWN: Select  LEFT/RIGHT: Change", EDGE_Y_BOTTOM - 25, GREEN_MED)
    drawCenteredText("B: Back", EDGE_Y_BOTTOM - 15, GREEN_MED)
end


-- [/TQ-Bundler: src.states.options]

-- [TQ-Bundler: src.states.hiscores]

-- ==========================================
-- STATE: HISCORES
-- ==========================================

local function updateHiscores()
    if btnPressed(BTN_P1_A) or btnPressed(BTN_P1_B) then
        changeState(STATE.TITLE)
    end
end

local function drawHiscores()
    cls(0)
    
    -- Title
    drawCenteredText("HIGH SCORES", 15, WHITE)
    
    -- Scores list
    local startY = 40
    local spacing = 15
    
    for i, entry in ipairs(game.hiscores) do
        local y = startY + (i - 1) * spacing
        local rankText = string.format("%d.", i)
        local scoreText = string.format("%s %8d", entry.name, entry.score)
        
        print(rankText, 60, y, GREEN_MED)
        print(scoreText, 80, y, WHITE)
    end
    
    -- Instructions
    drawCenteredText("Press A or B to return", EDGE_Y_BOTTOM - 15, GREEN_MED)
end


-- [/TQ-Bundler: src.states.hiscores]

-- [TQ-Bundler: src.states.puzzle]

-- ==========================================
-- STATE: PUZZLE
-- ==========================================

local function updatePuzzle()


end

function drawGame()
    cls(BLACK)
    

end

local function drawPuzzle()
    drawGame()
end


-- [/TQ-Bundler: src.states.puzzle]

-- [TQ-Bundler: src.state_machine]

-- ==========================================
-- STATE MACHINE
-- ==========================================

local states = {
    [STATE.TITLE] = {
        update = updateTitle,
        draw = drawTitle,
    },
    [STATE.OPTIONS] = {
        update = updateOptions,
        draw = drawOptions,
    },
    [STATE.HISCORES] = {
        update = updateHiscores,
        draw = drawHiscores,
    },
    [STATE.PUZZLE] = {
        update = updatePuzzle,
        draw = drawPuzzle,
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