-- ==========================================
-- STATE: STATISTICS
-- ==========================================



-- Persistent memory has 255 slots. We want to save four pieces of data, so that
-- restricts us to 252 slots (63 chunks of 4 slots).
local function saveCurrentScore()
    -- Need to save the following:
    --  1. game.play.date - stored as the unix timestamp.
    --  2. game.play.difficulty - convert to an integer for storage.
    --  3. game.play.timer:getSeconds() - integer of total seconds.
    --  4. game.play.autonotes - already an integer.

    -- Process:
    -- 1. Load the high scores into a table.
    -- 2. Add this latest score to that table.
    -- 3. Sort the high scores table.
    -- 4. If there are more than 252 slots, lop off entries until there are only 252.
    -- 5. Save entire table over again.
end

local function loadHighScores()
    -- Don't sort here. Sorting happens when we want to print them.
    -- Convert game.play.date to a human-readable date after sort but before print.
end

local function sortHighScores()
    -- Sort by difficulty, then by time, then by autonotes.
end








local function updateStatistics()
    if btnPressed(BTN_P1_A) or btnPressed(BTN_P1_B) then
        changeState(STATE.TITLE)
    end

    -- Refresh high scores. Simply re-initializes the game.statistics data
    -- structure so the user will always see an updated high score table.
    loadHighScores()

    -- Sort (and save) the high scores.
    sortHighScores()
end

local function drawStatistics()
    cls(0)

    -- Title
    drawCenteredText("STATISTICS", 15, WHITE)

    -- Scores list
    local startY = 40
    local spacing = 15

    for i, entry in ipairs(game.statistics) do
        local y = startY + (i - 1) * spacing
        local rankText = string.format("%d.", i)
        local scoreText = string.format("%s %8d", entry.name, entry.score)

        print(rankText, 60, y, GREEN_MED)
        print(scoreText, 80, y, WHITE)
    end

    -- Instructions
    drawCenteredText("Press A or B to return", EDGE_Y_BOTTOM - 15, GREEN_MED)
end
