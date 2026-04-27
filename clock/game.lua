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
-- MAIN TIC FUNCTION
-- ==========================================

function INIT()
end -- INIT()

INIT()

function TIC()
    cls(BLACK)

    local unixTime = os.time()
    local specificTime = os.time({
        year = 1945,
        month = 6,
        day = 16,
        hour = 5,
        min = 29,
        sec = 21
    })


    INPUT();

    UPDATE();

    DRAW()
end

function INPUT()
end -- INPUT()

function UPDATE()
end -- UPDATE()

function DRAW()
    current_time_formatted = os.date("%Y-%m-%d %H:%M:%S", unixTime)
    print_centered_text(current_time_formatted, EDGE_Y_TOP, WHITE, true, true, 1)
end -- DRAW()

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

