--
-- Bundle file
-- Code changes will be overwritten
--

-- title:   Big Clock
-- author:  Adam Fuller <the.adam.fuller@gmail.com>
-- desc:    Test code for a big digital clock.
-- version: 0.1
-- script:  lua
-- input:   mouse

-- Colors
local BLACK      = 0
local PURPLE     = 1
local RED        = 2
local ORANGE     = 3
local YELLOW     = 4
local GREEN_LITE = 5
local GREEN_MED  = 6
local GREEN_DARK = 7
local BLUE_DARK  = 8
local BLUE_MED   = 9
local BLUE_LITE  = 10
local CYAN       = 11
local WHITE      = 12
local GRAY_LITE  = 13
local GRAY_MED   = 14
local GRAY_DARK  = 15


function newTimer()
    local self = {}

    self.event = false
    self.timeCount = false

    local current = 0       -- time in the current frame
    local last = self.current -- time in the last frame

    self.count = function()
        self.event = type(self.event) == "boolean" and self.event or false
        current = not (self.timeCount) and time() or self.timeCount
        last = self.event and last or current
        return current - last --time interval
    end

    self.wait = function(starting, ending)
        if not (starting) then return false end
        ending = ending or math.huge
        return self.count() >= math.abs(starting) and self.count() <= math.abs(ending)
    end

    self.waitFreq = function(frequency)
        if frequency == 0 then return false end
        return self.count() % (frequency * 2) > frequency
    end

    return self
end

local timer = newTimer()
local ticks = 0

local MOUSE_CLICKED = false
local MOUSE_PREV_CLICKED = false

local DISPLAY_MSG = false

function TIC()
    cls(BLACK)

    -- input
    local mouse_x, mouse_y, left_click, middle_click, right_click, scroll_x, scroll_y = mouse()





    -- update
    if left_click then
        MOUSE_CLICKED = true
    end

    if MOUSE_CLICKED and MOUSE_PREV_CLICKED == false then
        MOUSE_PREV_CLICKED = true
        DISPLAY_MSG = true
    end



    -- draw
    if DISPLAY_MSG then
        print("Clicked!", 0, 0, WHITE)
        print("Count: " .. tostring(ticks), 0, 10, WHITE)
    end

    ticks = ticks + 1
end

