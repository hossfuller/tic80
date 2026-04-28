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

-- Clock offsets
local EST_OFFSET_SECONDS    = -5 * 3600
local TEHRAN_OFFSET_SECONDS = (3 * 3600) + (30 * 60)


-- [/TQ-Bundler: src.constants]

-- [TQ-Bundler: src.helpers]

-- ==========================================
-- HELPER FUNCTIONS
-- ==========================================


function get_unix_timestamp()
    return math.tointeger(tstamp())
end


function convert_datetime_obj_to_string(datetime_obj)
    return string.format(
        "%04d-%02d-%02d %02d:%02d:%02d",
        datetime_obj.year,
        datetime_obj.month,
        datetime_obj.day,
        datetime_obj.hour,
        datetime_obj.min,
        datetime_obj.sec
    )
end



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

-- [TQ-Bundler: src.std_datetime]

-- ==========================================
-- STANDARD TIME FUNCTIONS
-- ==========================================

local mdays_common = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }

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

function greg_utc_to_other_timezone(ts, offset)
    return unix_to_greg_utc(ts + offset)
end


-- [/TQ-Bundler: src.std_datetime]

-- [TQ-Bundler: src.jalali_datetime]

-- ==========================================
-- JALALI TIME FUNCTIONS
-- ==========================================

local function greg_to_jalali(gy, gm, gd)
    local g_d_m = { 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334 }

    local jy
    if gy > 1600 then
        jy = 979
        gy = gy - 1600
    else
        jy = 0
        gy = gy - 621
    end

    local gy2 = (gm > 2) and (gy + 1) or gy

    local days =
        365 * gy
        + math.floor((gy2 + 3) / 4)
        - math.floor((gy2 + 99) / 100)
        + math.floor((gy2 + 399) / 400)
        - 80
        + gd
        + g_d_m[gm]

    jy = jy + 33 * math.floor(days / 12053)
    days = days % 12053

    jy = jy + 4 * math.floor(days / 1461)
    days = days % 1461

    if days > 365 then
        jy = jy + math.floor((days - 1) / 365)
        days = (days - 1) % 365
    end

    local jm, jd
    if days < 186 then
        jm = 1 + math.floor(days / 31)
        jd = 1 + (days % 31)
    else
        jm = 7 + math.floor((days - 186) / 30)
        jd = 1 + ((days - 186) % 30)
    end

    return jy, jm, jd
end

-- Public: Unix timestamp -> Jalali UTC date/time table
local function unix_to_jalali_utc(ts)
    local greg_datetime = unix_to_greg_utc(ts)
    local jy, jm, jd = greg_to_jalali(
        greg_datetime.year,
        greg_datetime.month,
        greg_datetime.day
    )
    return {
        year  = jy,
        month = jm,
        day   = jd,
        hour  = greg_datetime.hour,
        min   = greg_datetime.min,
        sec   = greg_datetime.sec,
    }
end

local function jalali_tehran_to_other_timezone(ts, offset)
    return unix_to_jalali_utc(ts + offset)
end


-- [/TQ-Bundler: src.jalali_datetime]

-- [TQ-Bundler: src.metric_datetime]

-- ==========================================
-- METRIC TIME FUNCTIONS
-- ==========================================


-- [/TQ-Bundler: src.metric_datetime]



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

    local datatime_headers = {
        "UNIX Timestamp",
        "UTC Standard",
        "UTC Jalali",
        " ",
        "Baltimore Time",
        "Mashhad Time",
    }

    local current_datetime         = get_unix_timestamp()
    local current_std_datetime     = unix_to_greg_utc(current_datetime)
    local current_balt_datetime    = greg_utc_to_est(current_datetime)
    local current_jalali_datetime  = unix_to_jalali_utc(current_datetime)
    local current_mashhad_datetime = unix_to_jalali_tehran(current_datetime)

    local datetime_data = {
        current_datetime,
        convert_datetime_obj_to_string(current_std_datetime),
        convert_datetime_obj_to_string(current_jalali_datetime),
        '',
        convert_datetime_obj_to_string(current_balt_datetime),
        convert_datetime_obj_to_string(current_mashhad_datetime),
    }

    local num = 0
    local column_one_x = EDGE_X_LEFT + X_PADDING
    for num, header in ipairs(datatime_headers) do

        -- print left column
        print(header, column_one_x, EDGE_Y_TOP + (num * Y_PADDING), WHITE, true, 1)

        -- print right column
        local y_pos = EDGE_Y_TOP + (num * Y_PADDING)
        local value_width = print(tostring(datetime_data[num]), 0, -100, WHITE, true, 1)
        local x_pos = EDGE_X_RIGHT - X_PADDING - value_width
        print(tostring(datetime_data[num]), x_pos, y_pos, WHITE, true, 1)
    end


    -- INPUT();

    -- UPDATE();

    -- DRAW()
end
