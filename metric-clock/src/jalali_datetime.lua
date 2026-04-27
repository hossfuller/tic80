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

function unix_to_jalali_utc(ts)
    return jalali_tehran_to_other_timezone(ts, TEHRAN_OFFSET_SECONDS)
end
