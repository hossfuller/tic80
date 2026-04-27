-- title:   Digi-TIC Clock
-- author:  Slyme
-- desc:    Digital clock-styled clock made for TIC-80
-- site:    https://slyme.xyz
-- license: MIT License
-- version: 1.0
-- script:  lua

function renderNumber(num, x, y, scale)
    scale = scale or 1
    spr(num, x, y, 0, scale)
    spr(num + 16, x, y + (8 * scale), 0, scale)
    return 9 * scale
end

function renderColon(tic, x, y, scale)
    scale = scale or 1
    spr(11 + (tic / 60 % 2), x, y, 0, scale)
    spr(27 + (tic / 60 % 2), x, y + (8 * scale), 0, scale)
    return 3 * scale
end

function renderPM(isPM, x, y, scale)
    scale = scale or 1
    local pmO = 0
    if isPM then pmO = 16 end
    spr(10 + pmO, x, y, 0, scale)
    return 9 * scale
end

local currentTime
local zoneOffset = -21600
local tic = 0

function renderClock(currentTime, t, x, y, scale)
    scale = scale or 1
    local cursor = x

    local currentHour = tostring(math.floor(currentTime / 3600 % 12))
    if currentHour == "0" then currentHour = 12 end
    if #currentHour < 2 then currentHour = "0" .. currentHour end
    for i = 1, #currentHour do
        cursor = cursor + renderNumber(tonumber(string.sub(currentHour, i, i)), cursor, y, scale)
    end

    cursor = cursor + renderColon(tic, cursor, y, scale)

    local currentMinute = tostring(math.floor(currentTime % 3600 / 60))
    if #currentMinute < 2 then currentMinute = "0" .. currentMinute end
    for i = 1, #currentMinute do
        cursor = cursor + renderNumber(tonumber(string.sub(currentMinute, i, i)), cursor, y, scale)
    end

    local isPM = currentTime > 43200
    renderPM(isPM, cursor, y, scale)
    return cursor, y + (16 * scale)
end

function math.clamp(v, min, max)
    if v > max then v = max end
    if v < min then v = min end
    return v
end

function redefineScale(scale)
    local clockLength, clockHeight = renderClock(tstamp() % 86400 + zoneOffset, 0, 0, 0, scale)
    local centerX = math.floor((240 - clockLength) / 2)
    local centerY = math.floor((136 - clockHeight) / 2)
    cls(0)
    return scale, centerX, centerY
end

local scale, centerX, centerY = redefineScale(3)

function TIC()
    cls(0)
    if btnp(2) then scale = math.clamp(scale - 1, 1, 4) end
    if btnp(3) then scale = math.clamp(scale + 1, 1, 4) end
    scale, centerX, centerY = redefineScale(scale)
    currentTime = tstamp() % 86400 + zoneOffset
    renderClock(currentTime, tic, centerX, centerY, scale)
    print("Digi-TIC Clock v1.0", 0, 0, 2)
    print("Current Scale: " .. tostring(scale), 0, 8, 2)
    tic = tic + 1
end
