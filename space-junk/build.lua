--
-- Bundle file
-- Code changes will be overwritten
--

-- title:   Space Junk
-- author:  Hoss Fuller
-- desc:    Travel the universe, cleaning up space junk.
-- version: 0.1
-- script:  lua
-- saveid:  space_junk

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

local DEBUG = true

-- [/TQ-Bundler: src.constants]

-- [TQ-Bundler: src.helpers]

-- ==========================================
-- HELPERS
-- ==========================================

-- ==========================================
-- TIME HELPERS
-- ==========================================

mdays_common = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }

function get_unix_timestamp()
    return math.tointeger(tstamp())
end

function convert_datetime_obj_to_string(datetime_obj)
    return string.format(
        "%04d-%02d-%02d",
        datetime_obj.year,
        datetime_obj.month,
        datetime_obj.day
    )
end

function is_greg_leap(y)
    return (y % 4 == 0) and ((y % 100 ~= 0) or (y % 400 == 0))
end

function greg_days_in_month(y, m)
    if m == 2 and is_greg_leap(y) then return 29 end
    return mdays_common[m]
end

-- Unix seconds -> Gregorian UTC date/time (year,month,day,hour,min,sec)
function unix_to_greg_utc(ts)
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
-- DRAWING HELPERS
-- ==========================================

function drawCenteredText(text, y, color, fixed, scale, smallfont, shadow_color)
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

STATE = {
    START      = "START",
    PLAY       = "PLAY",
    GAMEOVER   = "GAMEOVER",
    HIGHSCORES = "HIGHSCORES",
}

game = {
    state = STATE.START,
    prevState = nil,

    -- Gameplay state
    play = {
        player = {},
        score  = 0,
    },

    high_scores = {},
}


-- ==========================================
-- STATE CHANGE
-- ==========================================

function changeState(newState)
    game.prevState = game.state
    game.state = newState

    -- State entry logic
    if newState == STATE.PLAY then
        -- Reset game state for new game
        game.play.player = SpaceShip.new()
        game.play.score  = 0

    elseif newState == STATE.HIGHSCORES then
        loadHighScores()
        sortHighScores()
        buildLines()
        scroll = 0
    end
end


-- [/TQ-Bundler: src.game_state]

-- [TQ-Bundler: src.states.start]

-- ==========================================
-- STATE: START (Main Menu)
-- ==========================================

function inputStart()
    if btnp(BTN_P1_A) or btnp(BTN_P1_START) then
        changeState(STATE.PLAY)
    end
end

function updateStart()

end

function drawStart()
    cls(0)

    local title_y_pos = math.floor(EDGE_Y_BOTTOM / 2) - 3 * Y_PADDING
    drawCenteredText("SPACE JUNK", title_y_pos, ORANGE, nil, 3, nil, YELLOW)
    drawCenteredText("Press Z to start", title_y_pos + 3 * Y_PADDING, WHITE, false, 1, false, GRAY_DARK)
end


-- [/TQ-Bundler: src.states.start]

-- [TQ-Bundler: src.states.play]

-- ==========================================
-- STATE: PLAY
-- ==========================================

function inputPlay()
    if btnp(BTN_P1_SELECT) and btnp(BTN_P1_START) then
        changeState(STATE.GAMEOVER)
    end

    game.play.player:input()
end

function updatePlay()

end

function drawPlay()
    cls(PURPLE)

    game.play.player:draw()

    if DEBUG == true then
        local pos = game.play.player:getPosition()
        local rot = game.play.player:getRotation()

        print("X: " .. tostring(pos.x) .. "; Y: " .. tostring(pos.y), EDGE_X_LEFT, EDGE_Y_TOP, WHITE)
        print("Radians: " .. tostring(rot.rotation) .. "; Speed: " .. tostring(rot.speed), EDGE_X_LEFT, EDGE_Y_TOP + Y_PADDING, WHITE)
    end

end


-- [/TQ-Bundler: src.states.play]

-- [TQ-Bundler: src.states.gameover]

-- ==========================================
-- STATE: GAMEOVER
-- ==========================================

function inputGameover()
    if btnp(BTN_P1_A) or btnp(BTN_P1_B) then
        changeState(STATE.HIGHSCORES)
    end
end

function updateGameover()

end

function drawGameover()
    drawPlay()

    local title_y_pos = math.floor(EDGE_Y_BOTTOM / 2) - 3 * Y_PADDING
    drawCenteredText("GAME OVER", title_y_pos, ORANGE, nil, 3, nil, YELLOW)
    drawCenteredText("Press Z or X to see high scores", title_y_pos + 3 * Y_PADDING, WHITE, false, 1, false, GRAY_DARK)
end


-- [/TQ-Bundler: src.states.gameover]

-- [TQ-Bundler: src.states.highscores]

-- ==========================================
-- STATE: HIGH SCORES
-- ==========================================

-- Persistent memory has 255 slots. We want to save two pieces of data: the date
-- and the score. On top of that, we only want to save the top 10 scores. That
-- restricts us to just 20 slots (10 chunks of 2 slots). Since our counter
-- starts at 0, we set MAX_PMEM_CHUNKS equal to 9.
local MAX_PMEM_CHUNKS     = 9
local PMEM_CHUNK_ELEMENTS = 2

-- We'll store our high scores in this table.
local lines = {}

-- ==========================================
-- HIGH SCORE HELPERS
-- ==========================================

function loadHighScores()
    game.high_scores = {}

    for idx = 0, MAX_PMEM_CHUNKS do
        local base = idx * PMEM_CHUNK_ELEMENTS
        local date = pmem(base + 0)
        if date ~= 0 then
            game.high_scores[base] = {
                date  = date,
                score = pmem(base + 1),
            }
        end
    end
end

function sortHighScores()
    -- Collect existing entries (0,2,4,...) into a dense list
    local list = {}
    for idx = 0, MAX_PMEM_CHUNKS do
        local base = idx * PMEM_CHUNK_ELEMENTS
        local d = game.high_scores[base]
        if d then
            list[#list + 1] = d
        end
    end

    -- Sort by score...
    table.sort(list, function(a, b)
        if a.score ~= b.score then
            return a.score > b.score
        end
    end)

    -- Write back compacted into chunk keys 0,2,4,...
    game.high_scores = {}
    for i = 1, #list do
        game.high_scores[(i - 1) * PMEM_CHUNK_ELEMENTS] = list[i]
    end
end

function saveCurrentScore()
    -- Always start from what is currently saved
    loadHighScores()

    -- Find next free chunk index in the CURRENT in-memory table
    local n = 0
    for idx = 0, MAX_PMEM_CHUNKS do
        if game.high_scores[idx * PMEM_CHUNK_ELEMENTS] then
            n = n + 1
        end
    end
    local base = n * PMEM_CHUNK_ELEMENTS
    if base > MAX_PMEM_CHUNKS * PMEM_CHUNK_ELEMENTS then
        base = MAX_PMEM_CHUNKS * PMEM_CHUNK_ELEMENTS -- will be trimmed after sort
    end

    -- Add current result
    game.high_scores[base] = {
        date  = game.play.date,
        score = game.play.score,
    }

    -- Sort + compact keys to 0,4,8,...
    sortHighScores()

    -- -- Save the data.
    for i = 0, 255 do pmem(i, 0) end
    for idx = 0, MAX_PMEM_CHUNKS do
        local b = idx * PMEM_CHUNK_ELEMENTS
        local d = game.high_scores[b]
        if d then
            pmem(b + 0, d.date)
            pmem(b + 1, d.score)
        end
    end
end


function buildLines()
    -- Show only the saved/sorted entries (0,4,8,...,252)
    lines = {}
    for idx = 0, MAX_PMEM_CHUNKS do
        local k = idx * PMEM_CHUNK_ELEMENTS
        local d = game.high_scores[k]
        if d then
            local dt_obj = unix_to_greg_utc(d.date)
            local dt_str = convert_datetime_obj_to_string(dt_obj)
            table.insert(lines, dt_str .. "      " .. d.score)
        end
    end
end

-- ==========================================
-- MAIN HIGH SCORE FUNCTIONS
-- ==========================================

function inputHighScores()
    if btnp(BTN_P1_A) or btnp(BTN_P1_B) then
        changeState(STATE.START)
    end
end

function updateHighScores()

end

function drawHighScores()
    cls(BLACK)

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
    scroll = math.max(0, math.min(max_scroll, scroll))

    drawCenteredText("HIGH SCORES", EDGE_Y_TOP + Y_PADDING, ORANGE, nil, 3, nil, YELLOW)

    -- draw visible slice
    for i = 0, visible_lines - 1 do
        local line = lines[scroll + 1 + i] -- Lua arrays are 1-based
        if not line then break end
        local y = view_top + i * line_h
        print(line, X_PADDING + 1, y + 1, BLACK) -- the shadow
        print(line, X_PADDING, y, WHITE)
    end

    -- Small scrollbar indicator
    if max_scroll > 0 then
        local bar_x = EDGE_X_RIGHT - 4
        rect(bar_x, view_top, 2, view_bottom - view_top, GRAY_DARK)
        local thumb_h = math.max(4, math.floor((view_bottom - view_top) * (visible_lines / #lines)))
        local thumb_y = view_top + math.floor((view_bottom - view_top - thumb_h) * (scroll / max_scroll))
        rect(bar_x, thumb_y, 2, thumb_h, GREEN_LITE)
    end

    -- Instructions
    drawCenteredText("Press Z or X to return to start screen", EDGE_Y_BOTTOM - Y_PADDING, WHITE, false, 1, true, BLACK)
end

-- [/TQ-Bundler: src.states.highscores]

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
    [STATE.HIGHSCORES] = {
        input  = inputHighScores,
        update = updateHighScores,
        draw   = drawHighScores,
    },
}


-- [/TQ-Bundler: src.state_machine]

-- [TQ-Bundler: src.classes.SpaceShip]

-- ==========================================
-- SPACESHIP OBJECT
-- ==========================================

SpaceShip = {}
SpaceShip.__index = SpaceShip

-- Creates a new SpaceShip instance
function SpaceShip.new(params)
    params             = params or {}
    local self         = setmetatable({}, SpaceShip)

    self.color    = params.color or BLUE_MED
    self.position = {
        x = params.x or math.floor(EDGE_X_RIGHT / 2),
        y = params.y or math.floor(EDGE_Y_BOTTOM / 2)

    }
    self.rotation      = params.rotation or 5
    self.rotationSpeed = params.rotationSpeed or 0.07
    self.shape         = params.shape or {
        {x=8, y=0},
        {x=-8, y=6},
        {x=-4, y=0},
        {x=-8, y=-6},
        {x=8, y=0}
	}
    return self
end

-- ==========================================
-- SPACESHIP HELPERS
-- ==========================================

function SpaceShip:getPosition()
    return self.position
end

function SpaceShip:getRotation()
    return {
        rotation = self.rotation,
        speed    = self.rotationSpeed
    }
end


-- ==========================================
-- SPACESHIP INPUT
-- ==========================================

function SpaceShip:input()
    if btn(BTN_P1_LEFT) then
        self.rotation = self.rotation - self.rotationSpeed
    end
    if btn(BTN_P1_RIGHT) then
        self.rotation = self.rotation + self.rotationSpeed
    end

    self.rotation = self:keepAngleInRange(self.rotation)
end

-- ==========================================
-- SPACESHIP UPDATE
-- ==========================================

function SpaceShip:keepAngleInRange(angle)
    if angle < 0 then
        while angle < 0 do
            angle = angle + (2 * math.pi)
        end
    end
    if angle > (2 * math.pi) then
        while angle > (2 * math.pi) do
            angle = angle - (2 * math.pi)
        end
    end
    return angle
end

-- 'rotation' parameter is in radians.
function SpaceShip:rotatePoint(point, rotation)
    local rotated_x = (point.x * math.cos(rotation)) - (point.y * math.sin(rotation))
    local rotated_y = (point.y * math.cos(rotation)) + (point.x * math.sin(rotation))
    return { x = rotated_x, y = rotated_y }
end

-- ==========================================
-- SPACESHIP DRAW
-- ==========================================

-- Draw the spaceship.
function SpaceShip:draw()
    local first_point = true
    local last_point = 0
    local rotated_point = 0
    for index, point in ipairs(self.shape) do
        rotated_point = self:rotatePoint(point, self.rotation)

        if first_point then
            last_point = rotated_point
            first_point = false
        else
            line(
                last_point.x + self.position.x,
                last_point.y + self.position.y,
                rotated_point.x + self.position.x,
                rotated_point.y + self.position.y,
                self.color
            )
            last_point = rotated_point
        end
    end
end


-- [/TQ-Bundler: src.classes.SpaceShip]

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