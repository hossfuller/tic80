-- ==========================================
-- MISSION OBJECT
-- ==========================================

Mission = {}
Mission.__index = Mission

function Mission:new(params)
    params = params or {}

    local self = setmetatable({}, Mission)

    self.id = params.id or generateMissionId(params.id_length or 6)

    -- Origin and destination can be SpaceDock or SpaceStation objects.
    self.source      = params.source      or nil
    self.destination = params.destination or nil

    self.type   = params.type   or MISSION_TYPE.CARGO
    self.status = params.status or MISSION_STATUS.IN_PROGRESS

    self.deadline = params.deadline or nil

    -- Passenger bookkeeping.
    self.passengers = {
        total       = 0,
        transported = params.passengers_transported or 0,
        active      = params.passengers_active or 0,
    }

    -- Mass bookkeeping.
    self.mass = {
        total       = 0,
        transported = params.mass_transported or 0,
        active      = params.mass_active or 0,
    }

    if self:isPassengerMission() then
        self.passengers.total = math.floor(params.passengers_total or params.passengers or 1)
        if self.passengers.total < 0 then
            self.passengers.total = 0
        end

        self.mass.total = self.passengers.total * PASSENGER_TOTAL_MASS

        -- For passenger missions, active mass is derived from active passengers.
        self.passengers.active = math.floor(self.passengers.active or 0)
        if self.passengers.active < 0 then
            self.passengers.active = 0
        elseif self.passengers.active > self.passengers.total then
            self.passengers.active = self.passengers.total
        end

        self.mass.active = self.passengers.active * PASSENGER_TOTAL_MASS
    else
        self.passengers.total = 0
        self.passengers.transported = 0
        self.passengers.active = 0

        self.mass.total = math.floor(params.mass_total or params.mass or 0)
        if self.mass.total < 0 then
            self.mass.total = 0
        end

        if self.mass.active < 0 then
            self.mass.active = 0
        elseif self.mass.active > self.mass.total then
            self.mass.active = self.mass.total
        end
    end

    -- Clamp transported values.
    self:clampProgress()

    return self
end

-- ==========================================
-- MISSION HELPERS
-- ==========================================

function Mission:isCargoMission()
    return self.type == MISSION_TYPE.CARGO or
        self.type == MISSION_TYPE.CONTRABAND_CARGO
end

function Mission:isPassengerMission()
    return self.type == MISSION_TYPE.PASSENGER or
        self.type == MISSION_TYPE.CONTRABAND_PASSENGER
end

function Mission:isContrabandMission()
    return self.type == MISSION_TYPE.CONTRABAND_CARGO or
        self.type == MISSION_TYPE.CONTRABAND_PASSENGER
end

function Mission:clampProgress()
    if self:isPassengerMission() then
        self.passengers.total       = math.max(0, math.floor(self.passengers.total or 0))
        self.passengers.transported = math.max(
            0,
            math.min(
                math.floor(self.passengers.transported or 0),
                self.passengers.total
            )
        )
        self.passengers.active      = math.max(
            0,
            math.min(
                math.floor(self.passengers.active or 0),
                self.passengers.total - self.passengers.transported
            )
        )

        self.mass.total             = self.passengers.total * PASSENGER_TOTAL_MASS
        self.mass.transported       = self.passengers.transported * PASSENGER_TOTAL_MASS
        self.mass.active            = self.passengers.active * PASSENGER_TOTAL_MASS
    else
        self.passengers.total       = 0
        self.passengers.transported = 0
        self.passengers.active      = 0

        self.mass.total             = math.max(0, math.floor(self.mass.total or 0))
        self.mass.transported       = math.max(
            0,
            math.min(
                math.floor(self.mass.transported or 0),
                self.mass.total
            )
        )
        self.mass.active            = math.max(
            0,
            math.min(
                math.floor(self.mass.active or 0),
                self.mass.total - self.mass.transported
            )
        )
    end
end

function Mission:getTypeLabel()
    if self.type == MISSION_TYPE.CARGO then
        return "Cargo"
    elseif self.type == MISSION_TYPE.PASSENGER then
        return "Passenger"
    elseif self.type == MISSION_TYPE.CONTRABAND_CARGO then
        return "Contraband Cargo"
    elseif self.type == MISSION_TYPE.CONTRABAND_PASSENGER then
        return "Contraband Passenger"
    end

    return tostring(self.type)
end

function Mission:getShortTypeLabel()
    if self.type == MISSION_TYPE.CARGO then
        return "Cargo"
    elseif self.type == MISSION_TYPE.PASSENGER then
        return "Passengers"
    elseif self.type == MISSION_TYPE.CONTRABAND_CARGO then
        return "Contra Cargo"
    elseif self.type == MISSION_TYPE.CONTRABAND_PASSENGER then
        return "Contra Pass."
    end

    return tostring(self.type)
end

function Mission:getStatusLabel()
    if self.status == MISSION_STATUS.IN_PROGRESS then
        return "In Progress"
    elseif self.status == MISSION_STATUS.COMPLETED then
        return "Completed"
    elseif self.status == MISSION_STATUS.FAILED then
        return "Failed"
    end

    return tostring(self.status)
end

function Mission:getProgressText()
    if self:isPassengerMission() then
        return tostring(self.passengers.transported) ..
            "/" ..
            tostring(self.passengers.total) ..
            " pax"
    end

    return tostring(math.floor(self.mass.transported)) ..
        "/" ..
        tostring(math.floor(self.mass.total)) ..
        " kg"
end

-- ==========================================
-- MISSION STATUS
-- ==========================================

function Mission:isInProgress()
    return self.status == MISSION_STATUS.IN_PROGRESS
end

function Mission:isCompleted()
    return self.status == MISSION_STATUS.COMPLETED
end

function Mission:isFailed()
    return self.status == MISSION_STATUS.FAILED
end

function Mission:isTerminal()
    return self:isCompleted() or self:isFailed()
end

function Mission:canAct()
    return self:isInProgress()
end

function Mission:fail()
    if self:isTerminal() then
        return false
    end

    self.status = MISSION_STATUS.FAILED

    -- Mission cargo/passengers are no longer considered recoverable.
    self.mass.active = 0
    self.passengers.active = 0

    return true
end

function Mission:canComplete()
    if self.status ~= MISSION_STATUS.IN_PROGRESS then
        return false
    end

    if self:isPassengerMission() then
        return self.passengers.transported >= self.passengers.total
    end

    return self.mass.transported >= self.mass.total
end

function Mission:complete()
    if not self:canComplete() then
        return false
    end

    self.status = MISSION_STATUS.COMPLETED

    self.mass.active = 0
    self.passengers.active = 0

    return true
end

function Mission:onShipDestroyed()
    if self:isTerminal() then
        return false
    end

    if (self.mass.active or 0) > 0 then
        return self:fail()
    end

    return false
end

-- ==========================================
-- MISSION WITH DEADLINE
-- ==========================================

function Mission:hasDeadline()
    return self.deadline ~= nil
end

function Mission:isExpired(current_timestamp)
    if not self.deadline then
        return false
    end

    current_timestamp = current_timestamp or os.time()

    return current_timestamp >= self.deadline
end

function Mission:updateDeadline(current_timestamp)
    if self:isTerminal() then
        return false
    end

    if self:isExpired(current_timestamp) then
        return self:fail()
    end

    return false
end

-- ==========================================
-- MISSION MASS/PASSENGER TRANSFER
-- ==========================================

function Mission:getRemainingPassengerCount()
    if not self:isPassengerMission() then
        return 0
    end

    return math.max(
        0,
        self.passengers.total -
        self.passengers.transported -
        self.passengers.active
    )
end

function Mission:getRemainingMass()
    if self:isPassengerMission() then
        return self:getRemainingPassengerCount() * PASSENGER_TOTAL_MASS
    end

    return math.max(
        0,
        self.mass.total -
        self.mass.transported -
        self.mass.active
    )
end

function Mission:loadPassengers(count)
    if not self:canAct() then
        return 0
    end

    if not self:isPassengerMission() then
        return 0
    end

    count = math.floor(count or 0)
    if count <= 0 then
        return 0
    end

    local loaded = math.min(count, self:getRemainingPassengerCount())

    self.passengers.active = self.passengers.active + loaded
    self.mass.active = self.passengers.active * PASSENGER_TOTAL_MASS

    self:clampProgress()

    return loaded
end

function Mission:loadMass(amount)
    if not self:canAct() then
        return 0
    end

    if not self:isCargoMission() then
        return 0
    end

    amount = math.floor(amount or 0)
    if amount <= 0 then
        return 0
    end

    local loaded = math.min(amount, self:getRemainingMass())

    self.mass.active = self.mass.active + loaded

    self:clampProgress()

    return loaded
end

function Mission:deliverPassengers(count)
    if not self:canAct() then
        return 0
    end

    if not self:isPassengerMission() then
        return 0
    end

    count = math.floor(count or 0)
    if count <= 0 then
        return 0
    end

    local delivered = math.min(count, self.passengers.active)

    self.passengers.active = self.passengers.active - delivered
    self.passengers.transported = self.passengers.transported + delivered

    self:clampProgress()

    if self:canComplete() then
        self:complete()
    end

    return delivered
end

function Mission:deliverMass(amount)
    if not self:canAct() then
        return 0
    end

    if not self:isCargoMission() then
        return 0
    end

    amount = math.floor(amount or 0)
    if amount <= 0 then
        return 0
    end

    local delivered = math.min(amount, self.mass.active)

    self.mass.active = self.mass.active - delivered
    self.mass.transported = self.mass.transported + delivered

    self:clampProgress()

    if self:canComplete() then
        self:complete()
    end

    return delivered
end

