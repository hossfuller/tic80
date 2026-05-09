-- TimerObj object module
TimerObj = {}
TimerObj.__index = TimerObj

-- Creates a new TimerObj instance
function TimerObj.new()
    local self = setmetatable({}, TimerObj)
    self.running       = false
    self.start_time    = 0
    self.saved_time    = 0
    self.elapsed_time  = 0
    self.max_mininutes = 99
    self.max_seconds   = 59
    return self
end

-- Starts the timer
function TimerObj:start()
    if not self.running then
        self.running    = true
        self.start_time = time()
    end
end

-- Pauses the timer
function TimerObj:stop()
    if self.running then
        self.saved_time = self.saved_time + (time() - self.start_time)
        self.running    = false
    end
end

-- Resets timer to 00:00
function TimerObj:reset()
    self.running      = false
    self.start_time   = 0
    self.saved_time   = 0
    self.elapsed_time = 0
end

-- Updates elapsed time (call each frame)
function TimerObj:update()
    if self.running then
        self.elapsed_time = self.saved_time + (time() - self.start_time)
    else
        self.elapsed_time = self.saved_time
    end
end

-- Returns total elapsed seconds
function TimerObj:getSeconds()
    return math.floor(self.elapsed_time / 1000)
end

-- Returns total elapsed minutes
function TimerObj:getMinutes()
    return math.floor(self:getSeconds() / 60)
end

-- Returns time as "MM:SS" string
function TimerObj:getFormatted()
    local totalSeconds = self:getSeconds()
    local minutes      = math.floor(totalSeconds / 60)
    local seconds      = totalSeconds % 60

    if minutes > self.max_mininutes then
        minutes = self.max_mininutes
        seconds = self.max_seconds
    end

    return string.format("%02d:%02d", minutes, seconds)
end

-- Returns true if timer is active
function TimerObj:isRunning()
    return self.running
end