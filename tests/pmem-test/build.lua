--
-- Bundle file
-- Code changes will be overwritten
--

-- title:   PMEM-TEST
-- author:  Hoss Fuller <hossfuller@proton.me>
-- desc:    Test code reading and writing to the persistent memory. This is a test script for the sudoku app.
-- version: 0.1
-- script:  lua
-- input:   mouse
-- saveid:  pmem_test


-- Colors
local BLACK             = 0
local PURPLE            = 1
local RED               = 2
local ORANGE            = 3
local YELLOW            = 4
local GREEN_LITE        = 5
local GREEN_MED         = 6
local GREEN_DARK        = 7
local BLUE_DARK         = 8
local BLUE_MED          = 9
local BLUE_LITE         = 10
local CYAN              = 11
local WHITE             = 12
local GRAY_LITE         = 13
local GRAY_MED          = 14
local GRAY_DARK         = 15

-- Controls
local P1_UP             = 0
local P1_DOWN           = 1
local P1_LEFT           = 2
local P1_RIGHT          = 3
local P1_A              = 4
local P2_UP             = 8
local P2_DOWN           = 9
local P2_LEFT           = 10
local P2_RIGHT          = 11
local P2_A              = 12

-- Screen dimensions
local EDGE_X_LEFT       = 0
local EDGE_X_RIGHT      = 240
local EDGE_Y_TOP        = 0
local EDGE_Y_BOTTOM     = 136

-- Character dimensions (these scale linearly)
local FIXED_CHAR_WIDTH  = 6
local FIXED_CHAR_HEIGHT = 6

local X_PADDING         = FIXED_CHAR_WIDTH + 2
local Y_PADDING         = FIXED_CHAR_HEIGHT + 2


-- ==========================================
-- DATA
-- ==========================================

local GENERATE_SAVE_DATA = false
local MAX_DATA           = 3    -- Can't go higher than 63!
local MAX_PMEM_CHUNKS    = 63


local test_data = {}
local lines = {} -- rendered text lines
local scroll = 0 -- first visible line index (0-based)

local test_data = {}

local function generate_test_data()
    for i = 0, MAX_DATA do
        local starting_index = i * 4
        test_data[starting_index] = {
            date = math.tointeger(tstamp()),
            difficulty = math.random(0, 2),
            timer = math.random(1, 100),
            autonotes = math.random(0, 20)
        }
        starting_index = starting_index + 1
    end
end

local function save_test_data()
    -- Clear all slots (optional but keeps old data from lingering)
    for i = 0, 255 do pmem(i, 0) end

    for idx = 0, MAX_DATA do
        local base = idx * 4
        local d = test_data[base]
        if d then
            pmem(base + 0, d.date)
            pmem(base + 1, d.difficulty)
            pmem(base + 2, d.timer)
            pmem(base + 3, d.autonotes)
        end
    end
end

local function load_test_data()
    test_data = {}

    for idx = 0, MAX_PMEM_CHUNKS do
        local base = idx * 4
        local date = pmem(base + 0)
        if date ~= 0 then
            test_data[base] = {
                date = date,
                difficulty = pmem(base + 1),
                timer = pmem(base + 2),
                autonotes = pmem(base + 3),
            }
        end
    end
end

local function sort_test_data()
    -- collect existing entries (0,4,8,...) into a dense list
    local list = {}
    for idx = 0, MAX_PMEM_CHUNKS do
        local base = idx * 4
        local d = test_data[base]
        if d then
            list[#list + 1] = d
        end
    end

    -- sort by: difficulty desc, timer asc, autonotes asc
    table.sort(list, function(a, b)
        if a.difficulty ~= b.difficulty then
            return a.difficulty > b.difficulty
        end
        if a.timer ~= b.timer then
            return a.timer < b.timer
        end
        if a.autonotes ~= b.autonotes then
            return a.autonotes < b.autonotes
        end
        -- optional tiebreaker so order is stable-ish
        return a.date > b.date
    end)

    -- write back compacted into chunk keys 0,4,8,...
    test_data = {}
    for i = 1, #list do
        test_data[(i - 1) * 4] = list[i]
    end
end


--[[
-- Persistent memory has 255 slots. We want to save four pieces of data, so that
-- restricts us to 252 slots (63 chunks of 4 slots).
local function saveCurrentScore()
    -- Need to save the following:
    --  1. game.play.date - stored as the unix timestamp.
    --  2. game.play.difficulty - convert to an integer for storage.
    --  3. game.play.timer:getSeconds() - integer of total seconds.
    --  4. game.play.autonotes - already an integer.

    -- Process:
    -- 1. Load the high scores into a table.
    -- 2. Add this latest score to that table.
    -- 3. Sort the high scores table.
    -- 4. If there are more than 252 slots, lop off entries until there are only 252.
    -- 5. Save entire table over again.
end

local function loadHighScores()
    -- Don't sort here. Sorting happens when we want to print them.
    -- Convert game.play.date to a human-readable date after sort but before print.
end

local function sortHighScores()
    -- Sort by difficulty, then by time, then by autonotes.
end
--]]



local function build_lines()
    lines = {}
    table.insert(lines, "PMEM TEST DATA VIEWER")
    table.insert(lines, "--------------------")

    -- show only the entries you created (0,4,8,...,252)
    for idx = 0, MAX_PMEM_CHUNKS do
        local k = idx * 4
        local d = test_data[k]
        if d then
            table.insert(lines, string.format("[%03d] date=%d", k, d.date))
            table.insert(lines, string.format("      diff=%d timer=%d autonotes=%d",
                d.difficulty, d.timer, d.autonotes))
            table.insert(lines, "") -- blank spacer line
        end
    end
end


-- ==========================================
-- TIC-80 callbacks
-- ==========================================

function BOOT()
    if GENERATE_SAVE_DATA then
        generate_test_data()
        save_test_data()
    else
        load_test_data()
        sort_test_data()
    end

    build_lines()
end



-- ==========================================
-- MAIN GAME LOOP
-- ==========================================

function TIC()
    cls(BLACK)

    -- LAYOUT

    local line_h = FIXED_CHAR_HEIGHT + 1
    local view_top = Y_PADDING
    local view_bottom = EDGE_Y_BOTTOM - Y_PADDING
    local visible_lines = math.max(1, math.floor((view_bottom - view_top) / line_h))

    -- INPUT

    local mouse_x, mouse_y, left_click, middle_click, right_click, scroll_x, scroll_y = mouse()
    local max_scroll = math.max(0, #lines - visible_lines)

    -- keyboard (hold+repeat)
    if btnp(P1_UP, 15, 3) then
        scroll = scroll - 1
    end
    if btnp(P1_DOWN, 15, 3) then
        scroll = scroll + 1
    end

    -- mouse wheel (usually +1/-1 per notch; direction can vary by platform)
    if scroll_y ~= 0 then
        -- choose the sign you prefer; if it feels inverted, flip it
        scroll = scroll - scroll_y
    end

    -- clamp
    scroll = math.max(0, math.min(max_scroll, scroll))

    -- UPDATE


    -- DRAW

    -- draw border/header info
    print(string.format("scroll %d/%d", scroll, max_scroll), X_PADDING, 2, GRAY_DARK)

    -- draw visible slice
    for i = 0, visible_lines - 1 do
        local line = lines[scroll + 1 + i] -- Lua arrays are 1-based
        if not line then break end
        local y = view_top + i * line_h
        print(line, X_PADDING, y, WHITE)
    end

    -- optional: small scrollbar indicator
    if max_scroll > 0 then
        local bar_x = EDGE_X_RIGHT - 4
        rect(bar_x, view_top, 2, view_bottom - view_top, GRAY_DARK)
        local thumb_h = math.max(4, math.floor((view_bottom - view_top) * (visible_lines / #lines)))
        local thumb_y = view_top + math.floor((view_bottom - view_top - thumb_h) * (scroll / max_scroll))
        rect(bar_x, thumb_y, 2, thumb_h, GREEN_LITE)
    end

end
