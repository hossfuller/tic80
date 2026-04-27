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

