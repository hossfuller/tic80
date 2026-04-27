-- title:   Clock
-- author:  Adam Fuller <the.adam.fuller@gmail.com>
-- version: 0.1
-- script:  lua


-- ==========================================
-- INCLUDES
-- ==========================================

include "src.constants"
include "src.helpers"
include "src.std_dt"
include "src.jalali_dt"
include "src.metric_dt"


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
        -- " ",
        -- "Baltimore STD Time",
        -- "Mashhad STD Time",
        -- " ",
        -- "Baltimore Jal Time",
        -- "Mashhad Jal Time",
    }

    local cur_dt             = get_unix_timestamp()
    local cur_std_dt         = unix_to_greg_utc(cur_dt)
    local cur_jalali_dt      = unix_to_jalali_utc(cur_dt)
    -- local cur_balt_std_dt    = greg_utc_to_other_timezone(cur_dt, EST_OFFSET_SECONDS)
    -- local cur_mashhad_std_dt = greg_utc_to_other_timezone(cur_dt, TEHRAN_OFFSET_SECONDS)
    -- local cur_balt_jal_dt    = jalali_tehran_to_other_timezone(cur_dt, EST_OFFSET_SECONDS)
    -- local cur_mashhad_jal_dt = jalali_tehran_to_other_timezone(cur_dt, TEHRAN_OFFSET_SECONDS)

    local datetime_data = {
        cur_dt,
        convert_datetime_obj_to_string(cur_std_dt),
        convert_datetime_obj_to_string(cur_jalali_dt),
        -- '',
        -- convert_datetime_obj_to_string(cur_balt_std_dt),
        -- convert_datetime_obj_to_string(cur_mashhad_std_dt),
        -- '',
        -- convert_datetime_obj_to_string(cur_balt_jal_dt),
        -- convert_datetime_obj_to_string(cur_mashhad_jal_dt),
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
