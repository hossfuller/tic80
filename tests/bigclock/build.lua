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

-- Screen dimensions
local EDGE_X_LEFT            = 0
local EDGE_X_RIGHT           = 240
local EDGE_Y_TOP             = 0
local EDGE_Y_BOTTOM          = 136

-- Character dimensions (these scale linearly)
local FIXED_CHAR_WIDTH       = 6
local FIXED_CHAR_HEIGHT      = 6

local X_PADDING              = FIXED_CHAR_WIDTH + 2
local Y_PADDING              = FIXED_CHAR_HEIGHT + 2


-- function newTimer()
--     local self = {}

--     self.event = false
--     self.timeCount = false

--     local current = 0       -- time in the current frame
--     local last = self.current -- time in the last frame

--     self.count = function()
--         self.event = type(self.event) == "boolean" and self.event or false
--         current = not (self.timeCount) and time() or self.timeCount
--         last = self.event and last or current
--         return current - last --time interval
--     end

--     self.wait = function(starting, ending)
--         if not (starting) then return false end
--         ending = ending or math.huge
--         return self.count() >= math.abs(starting) and self.count() <= math.abs(ending)
--     end

--     self.waitFreq = function(frequency)
--         if frequency == 0 then return false end
--         return self.count() % (frequency * 2) > frequency
--     end

--     return self
-- end

-- local timer = newTimer()
-- local ticks = 0

-- local MOUSE_CLICKED = false
-- -- local MOUSE_PREV_CLICKED = false

-- local DISPLAY_MSG = false

-- function TIC()
--     cls(BLACK)

--     -- input
--     local mouse_x, mouse_y, left_click, middle_click, right_click, scroll_x, scroll_y = mouse()
--     timer.event = left_click




--     -- update
--     if left_click and MOUSE_CLICKED == false then
--         MOUSE_CLICKED = true
--         DISPLAY_MSG = true
--     end



--     -- draw
--     if DISPLAY_MSG then
--         print("Clicked!", 0, 0, WHITE)
--         print("Count: " .. tostring(ticks), 0, 10, WHITE)
--     end

--     ticks = ticks + 1
-- end

-- Timer variables
local timer_running = false
local start_time    = 0
local elapsed_time  = 0
local saved_time    = 0      -- stores time when paused

local max_min = 1
local max_sec = 59

function TIC()
    cls(BLACK)

    -- input
    local mouse_x, mouse_y, left_click, middle_click, right_click, scroll_x, scroll_y = mouse()

    -- update

    -- Start the timer
    if left_click and not timer_running then
        timer_running = true
        start_time    = time()
    end

    -- Stop the timer
    if right_click and timer_running then
        timer_running = false
        saved_time    = saved_time + (time() - start_time)
    end

    -- Reset the timer
    if middle_click and not timer_running then
        timer_running = false
        elapsed_time  = 0
        saved_time    = 0
    end

    if timer_running then
        elapsed_time = saved_time + (time() - start_time)
    else 
        elapsed_time = saved_time
    end


    
    -- Convert to minutes and seconds
    local total_sec = math.floor(elapsed_time / 1000)
    local minutes   = math.floor(total_sec / 60)
    local seconds   = total_sec % 60
    
    -- Cap at 99:59 to keep 2-digit format
    if minutes > max_min then
        minutes = max_min
        seconds = max_sec
    end
    

    -- draw
    print("Left click:   Start", EDGE_X_LEFT, EDGE_Y_TOP, ORANGE)
    print("Middle click: Reset", EDGE_X_LEFT, EDGE_Y_TOP + 2 * Y_PADDING, ORANGE)
    print("Right click:  Stop", EDGE_X_LEFT, EDGE_Y_TOP + Y_PADDING, ORANGE)

    print(
        string.format("%02d:%02d", minutes, seconds),
        EDGE_X_LEFT, 
        EDGE_Y_TOP + 4 * Y_PADDING, 
        WHITE, 
        true, 
        3, 
        false
    )
    if minutes == max_min and seconds == max_sec then
        print(
            "Clock is maxxed out! Middle click to reset!", 
            EDGE_X_LEFT, 
            EDGE_Y_BOTTOM - Y_PADDING, 
            RED
        )
    end
end