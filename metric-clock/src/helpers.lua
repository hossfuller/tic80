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
