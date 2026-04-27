-- title:   Clock
-- author:  Adam Fuller <the.adam.fuller@gmail.com>
-- version: 0.1
-- script:  lua


-- ==========================================
-- INCLUDES
-- ==========================================

include "src.constants"
include "src.helpers"


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
