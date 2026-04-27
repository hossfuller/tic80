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

-- Character dimensions (these scale linearly)
local FIXED_CHAR_WIDTH  = 6
local FIXED_CHAR_HEIGHT = 6

-- Screen dimensions
local EDGE_X_LEFT   = 0
local EDGE_X_RIGHT  = 240
local EDGE_Y_TOP    = 0
local EDGE_Y_BOTTOM = 136
local X_PADDING     = FIXED_CHAR_WIDTH
local Y_PADDING     = FIXED_CHAR_HEIGHT



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

-- [TQ-Bundler: src.timecalc]

-- ==========================================
-- TIME CALCULATION FUNCTIONS
-- ==========================================

-- local epoch = {
--     year = 1970,
--     month = 1,
--     day = 1
-- }

-- local days_per_month = {
--     31,
--     28,
--     31,
--     30,
--     31,
--     30,
--     31,
--     31,
--     30,
--     31,
--     30,
--     31,
-- }

function get_unix_timestamp()
    return math.tointeger(tstamp())
end

-- function get_std_num_of_days_since_epoch(timestamp)
--     return timestamp / 86400
-- end

-- -- function get_std_num_of_years_since_epoch(timestamp)
-- --     local num_days = get_std_num_of_days_since_epoch(timestamp)
-- --     local num_years = 0
-- --     local leftover_days = 0
-- --     for i = 0, num_days do
-- --         if (num_years % 4) == 0 then
-- --             if (num_days % 366) == 0 then
-- --                 num_years = num_years + 1
-- --                 leftover_days = 0
-- --             end
-- --         else
-- --             if (num_days % 365) == 0 then
-- --                 num_years = num_years + 1
-- --                 leftover_days = 0
-- --             end
-- --         end
-- --         leftover_days = leftover_days + 1
-- --     end
-- --     return {num_years = num_years, leftover_days = leftover_days}
-- -- end

-- -- function get_std_month(timestamp)
-- --     years = get_std_num_of_years_since_epoch(timestamp)
-- --     if (years['leftover_days'] > )
-- -- end

-- -- function get_std_year(timestamp)

-- -- end


-- -- function get_std_date(timestamp)
-- --     years = get_std_num_of_years_since_epoch(timestamp)



-- --     return {
-- --         year = epoch['year'] + years['num_years']
-- --     }
-- -- end



-- Pure Lua: Unix timestamp -> UTC calendar date/time
-- Works for integer seconds, including negative timestamps.

local function is_leap(y)
    return (y % 4 == 0) and ((y % 100 ~= 0) or (y % 400 == 0))
end

local mdays_common = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }

local function days_in_month(y, m)
    if m == 2 and is_leap(y) then return 29 end
    return mdays_common[m]
end

local function unix_to_utc(ts)
    -- split into days since epoch and seconds-of-day
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

    -- convert day offset to Y-M-D by walking years then months
    local y    = 1970
    if days >= 0 then
        while true do
            local diy = is_leap(y) and 366 or 365
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
            local diy = is_leap(y) and 366 or 365
            days = days + diy
        end
    end

    local m = 1
    while true do
        local dim = days_in_month(y, m)
        if days >= dim then
            days = days - dim
            m = m + 1
        else
            break
        end
    end

    local d = days + 1 -- days is 0-based within month

    return {
        year = y,
        month = m,
        day = d,
        hour = hour,
        min = min,
        sec = sec
    }
end



-- [/TQ-Bundler: src.timecalc]



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
    cls(PURPLE)

    local desc_col = {
        "UNIX Timestamp",
        "Standard Date",
    }
    local time_col = {
        get_unix_timestamp(),
    }
    current_std_date = unix_to_utc(time_col[1])
    table.insert(time_col, string.format(
        "%04d-%02d-%02d %02d:%02d:%02d",
        current_std_date.year,
        current_std_date.month,
        current_std_date.day,
        current_std_date.hour,
        current_std_date.min,
        current_std_date.sec
    ))

    local longest_str_width = 0
    local column_one_x = EDGE_X_LEFT + X_PADDING
    for i, s in ipairs(desc_col) do
        local str_width = print(s .. ": ", column_one_x, EDGE_Y_TOP + (i * Y_PADDING), WHITE, true, 1)
        if str_width > longest_str_width then
            longest_str_width = str_width
        end
    end


    -- local column_two_x = column_one_x + longest_str_width + FIXED_CHAR_WIDTH
    local key_count = 0
    for k, v in pairs(time_col) do
        key_count = key_count + 1
        local date_string_length = print(string.format("%s", v), 0, -100)

        print_centered_text(date_string_length, EDGE_Y_BOTTOM - (key_count * Y_PADDING), WHITE, true, true, 1)

        -- local x_pos = EDGE_X_RIGHT - date_string_length - X_PADDING
        local x_pos = longest_str_width + X_PADDING

        print(
            string.format("%-s", v),
            x_pos, EDGE_Y_TOP + (key_count * Y_PADDING), WHITE, true, 1
        )
    end

    -- INPUT();

    -- UPDATE();

    -- DRAW()
end
