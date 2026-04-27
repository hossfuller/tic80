--
-- Bundle file
-- Code changes will be overwritten
--

-- title:   Clock
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
local BLACK         = 0
local PURPLE        = 1
local RED           = 2
local ORANGE        = 3
local YELLOW        = 4
local GREEN_LITE    = 5
local GREEN_MED     = 6
local GREEN_DARK    = 7
local BLUE_DARK     = 8
local BLUE_MED      = 9
local BLUE_LITE     = 10
local CYAN          = 11
local WHITE         = 12
local GRAY_LITE     = 13
local GRAY_MED      = 14
local GRAY_DARK     = 15

-- Button mappings
local BTN_P1_UP     = 0
local BTN_P1_DOWN   = 1
local BTN_P1_LEFT   = 2
local BTN_P1_RIGHT  = 3
local BTN_P1_A      = 4 -- Primary action / Select
local BTN_P1_B      = 5 -- Secondary action / Back / Pause
local BTN_P1_X      = 6
local BTN_P1_Y      = 7
local BTN_P2_UP     = 8
local BTN_P2_DOWN   = 9
local BTN_P2_LEFT   = 10
local BTN_P2_RIGHT  = 11
local BTN_P2_A      = 12
local BTN_P2_B      = 13
local BTN_P2_X      = 14
local BTN_P2_Y      = 15

-- Screen dimensions
local EDGE_X_LEFT   = 0
local EDGE_X_RIGHT  = 240
local EDGE_Y_TOP    = 0
local EDGE_Y_BOTTOM = 136
local BOUNDARY_WIDTH = 10

-- Character dimensions (these scale linearly)
local FIXED_CHAR_WIDTH = 6
local FIXED_CHAR_HEIGHT = 6



-- [/TQ-Bundler: src.constants]

-- [TQ-Bundler: src.helpers]

-- ==========================================
-- HELPER FUNCTIONS
-- ==========================================


function print_centered_text(message, height, color, shadow, fixed, scale)
    if height == nil then
        height = math.floor(EDGE_Y_BOTTOM / 2)
    end
    if color == nil then
        color = WHITE
    end
    if shadow == nil then
        shadow = false
    end
    if fixed == nil then
        fixed = true
    end
    if scale == nil then
        scale = 1
    end
    local message_width = print(message, 0, -40, color, fixed, scale)
    local x_pos = ((EDGE_X_RIGHT - message_width) / 2) + 2
    if shadow then
        print(message, x_pos + 1, height + 1, color + 1, fixed, scale)
    end
    print(message, x_pos, height, color, fixed, scale)
end


-- [/TQ-Bundler: src.helpers]



-- ==========================================
-- FUNCTIONS
-- ==========================================

function INIT()
end -- INIT()


function INPUT()
end

function UPDATE()
end

function DRAW()
end


-- ==========================================
-- MAIN GAME LOOP
-- ==========================================

INIT()

function TIC()
    cls(BLACK)

    -- local ms = time()
    -- local timestamp = tstamp()

    local desc_col = {
        "Sec since start",
        "UNIX Timestamp",
    }
    local time_col = {
        ms = time(),
        timestamp = tstamp(),
    }

    local longest_str_width = 0
    local column_one_x = EDGE_X_LEFT + FIXED_CHAR_WIDTH
    for i, s in ipairs(desc_col) do
        -- print(s .. ": ", column_one_x, EDGE_Y_TOP + (i * FIXED_CHAR_WIDTH), WHITE, true, 1)
        local str_width = print(s .. ": ", column_one_x, EDGE_Y_TOP + (i * FIXED_CHAR_HEIGHT), WHITE, true, 1)
        if str_width > longest_str_width then
            longest_str_width = str_width
        end
    end

    local column_two_x = column_one_x + longest_str_width + FIXED_CHAR_WIDTH
    -- for i, s in ipairs(time_col) do
    --     print(tostring(time_col[i]) .. ": ", column_two_x, EDGE_Y_TOP + (i * FIXED_CHAR_WIDTH), WHITE, true, 1)
    -- end
    print(
        string.format("%-0.4f", time_col['ms']),
        column_two_x, EDGE_Y_TOP + FIXED_CHAR_HEIGHT, WHITE, true, 1
    )
    print(
        string.format("%-0.1f", time_col['timestamp']),
        column_two_x, EDGE_Y_TOP + 2*FIXED_CHAR_HEIGHT, WHITE, true, 1
    )

    print_centered_text("col 1 width = " .. tostring(column_one_x), EDGE_Y_BOTTOM - FIXED_CHAR_HEIGHT, BLUE_MED, false, true, 1)
    print_centered_text("col 2 width = " .. tostring(column_two_x), EDGE_Y_BOTTOM - (2*FIXED_CHAR_HEIGHT), BLUE_MED, false,
    true, 1)


    -- print(string.format("%20s: %100s", "Sec since start", tostring(ms)), EDGE_X_LEFT, EDGE_Y_TOP)
    -- print(string.format("%20s: %100s", "Sec since start", tostring(timestamp)), EDGE_X_LEFT, EDGE_Y_TOP)

    -- print(message, x_pos, height, color, fixed, scale)
    -- print_centered_text(message, height, color, shadow, fixed, scale)

    -- INPUT();

    -- UPDATE();

    -- DRAW()
end
