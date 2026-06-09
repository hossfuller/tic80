-- ==========================================
-- MISSIONS
-- ==========================================

local MISSION_TYPE = {
    CARGO                = "cargo",
    PASSENGER            = "passenger",
    CONTRABAND_CARGO     = "contraband_cargo",
    CONTRABAND_PASSENGER = "contraband_passenger",
}

local MISSION_STATUS = {
    AVAILABLE = "available",
    ACCEPTED  = "accepted",
    COMPLETED = "completed",
    FAILED    = "failed",
}

function generateMissionId(length)
    length = length or 6

    local chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    local id = ""

    for i = 1, length do
        local index = math.random(1, #chars)
        id = id .. string.sub(chars, index, index)
    end

    return id
end
