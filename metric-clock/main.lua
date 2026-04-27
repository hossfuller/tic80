-- title:   Clock
-- author:  Adam Fuller <the.adam.fuller@gmail.com>
-- version: 0.1
-- script:  lua


-- ==========================================
-- INCLUDES
-- ==========================================

include "src.constants"
include "src.helpers"
include "src.timecalc"


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
