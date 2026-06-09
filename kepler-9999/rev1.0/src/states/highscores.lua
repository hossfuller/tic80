-- ==========================================
-- STATE: HIGH SCORES
-- ==========================================

-- Persistent memory has 255 slots.
MAX_HIGH_SCORES     = 19
PMEM_CHUNK_ELEMENTS = 5

-- We'll store our high scores in this table.
lines = {}

scroll = 0

-- ==========================================
-- HIGH SCORE HELPERS
-- ==========================================


function unixTimestampToDateString(timestamp)
    timestamp = timestamp or 0

    -- If timestamp is in milliseconds, convert to seconds.
    -- TIC-80 tstamp() is often millisecond-ish depending on usage.
    if timestamp > 100000000000 then
        timestamp = math.floor(timestamp / 1000)
    end

    local days = math.floor(timestamp / 86400)

    -- Civil date conversion from days since Unix epoch.
    -- Produces UTC date.
    local z = days + 719468
    local era

    if z >= 0 then
        era = math.floor(z / 146097)
    else
        era = math.floor((z - 146096) / 146097)
    end

    local doe = z - era * 146097
    local yoe = math.floor(
        (doe - math.floor(doe / 1460) + math.floor(doe / 36524) - math.floor(doe / 146096)) / 365
    )

    local year = yoe + era * 400
    local doy = doe - (365 * yoe + math.floor(yoe / 4) - math.floor(yoe / 100))
    local mp = math.floor((5 * doy + 2) / 153)

    local day = doy - math.floor((153 * mp + 2) / 5) + 1
    local month = mp + 3

    if mp >= 10 then
        month = mp - 9
    end

    if month <= 2 then
        year = year + 1
    end

    return string.format("%04d-%02d-%02d", year, month, day)
end

function makeHighScoreEntryFromShip(ship, death_timestamp)
    if not ship then
        return nil
    end

    death_timestamp = death_timestamp or getUnixTimestampSeconds()

    return {
        date   = math.floor(death_timestamp or 0),
        mass   = math.floor(ship:getMassDelivered() or 0),
        energy = math.floor(ship.engines.energy.mul or 1),
        life   = math.floor(ship.engines.life_support.mul or 1),
        shield = math.floor(ship.engines.shield.mul or 1),
    }
end

function loadHighScores()
    game.high_scores = {}

    for idx = 0, MAX_HIGH_SCORES do
        local base = idx * PMEM_CHUNK_ELEMENTS
        local date_timestamp = pmem(base + 0)

        if date_timestamp ~= 0 then
            game.high_scores[base] = {
                date   = date_timestamp,
                mass   = pmem(base + 1),
                energy = pmem(base + 2),
                life   = pmem(base + 3),
                shield = pmem(base + 4),
            }
        end
    end
end

function sortHighScores()
    local list = {}

    for _, d in pairs(game.high_scores) do
        if d and d.mass and d.mass > 0 then
            list[#list + 1] = d
        end
    end

    table.sort(list, function(a, b)
        if a.mass ~= b.mass then
            return a.mass > b.mass
        end

        if a.energy ~= b.energy then
            return a.energy > b.energy
        end

        if a.life ~= b.life then
            return a.life > b.life
        end

        if a.shield ~= b.shield then
            return a.shield > b.shield
        end

        return a.date > b.date
    end)

    game.high_scores = {}

    for i = 1, math.min(#list, MAX_HIGH_SCORES + 1) do
        game.high_scores[(i - 1) * PMEM_CHUNK_ELEMENTS] = list[i]
    end
end

function saveCurrentScore(ship)
    if not ship then
        return false
    end

    loadHighScores()

    local list = {}

    -- Pull saved scores into a compact list.
    for idx = 0, MAX_HIGH_SCORES do
        local base = idx * PMEM_CHUNK_ELEMENTS
        local d = game.high_scores[base]

        if d then
            list[#list + 1] = d
        end
    end

    -- Add current result.
    local current_entry = makeHighScoreEntryFromShip(ship, getUnixTimestampSeconds())

    if current_entry then
        list[#list + 1] = current_entry
    end

    -- Put list back into game.high_scores so sortHighScores() can sort it.
    game.high_scores = {}

    for i = 1, #list do
        game.high_scores[(i - 1) * PMEM_CHUNK_ELEMENTS] = list[i]
    end

    sortHighScores()

    -- Clear only the high-score pmem area.
    for idx = 0, MAX_HIGH_SCORES do
        local base = idx * PMEM_CHUNK_ELEMENTS
        pmem(base + 0, 0)
        pmem(base + 1, 0)
        pmem(base + 2, 0)
        pmem(base + 3, 0)
        pmem(base + 4, 0)
    end

    -- Save compacted/sorted high scores.
    for idx = 0, MAX_HIGH_SCORES do
        local base = idx * PMEM_CHUNK_ELEMENTS
        local d = game.high_scores[base]

        if d then
            pmem(base + 0, d.date or 0)
            pmem(base + 1, d.mass or 0)
            pmem(base + 2, d.energy or 1)
            pmem(base + 3, d.life or 1)
            pmem(base + 4, d.shield or 1) -- fixed: was incorrectly base + 3
        end
    end

    return true
end


function buildLines()
    lines = {}

    loadHighScores()
    sortHighScores()

    local score_count = 1

    for idx = 0, MAX_HIGH_SCORES do
        local k = idx * PMEM_CHUNK_ELEMENTS
        local d = game.high_scores[k]

        if d then
            local date_str = unixTimestampToDateString(d.date or 0)

            table.insert(
                lines,
                string.format("%2d", score_count) .. ". " ..
                date_str ..
                "  " .. string.format("%8d", d.mass or 0) ..
                "kg" ..
                "  E" .. tostring(d.energy or 1) ..
                " L" .. tostring(d.life or 1) ..
                " S" .. tostring(d.shield or 1)
            )

            score_count = score_count + 1
        end
    end

    if #lines <= 0 then
        table.insert(lines, "No high scores yet.")
    end
end

function enterHighScores()
    scroll = 0
    buildLines()
end

-- ==========================================
-- MAIN HIGH SCORE FUNCTIONS
-- ==========================================

function inputHighScores()
    if btnp(BTN_P1_A) or btnp(BTN_P1_B) then
        changeState(STATE.START)
    end
end

function updateHighScores()

end

function drawHighScores()
    cls(BLACK)

    -- LAYOUT
    local header_y = EDGE_Y_TOP + Y_PADDING
    local line_h = FIXED_CHAR_HEIGHT + 1
    local view_top = header_y + FIXED_CHAR_HEIGHT + 2 * Y_PADDING
    local view_bottom = EDGE_Y_BOTTOM - 2 * Y_PADDING
    local visible_lines = math.max(1, math.floor((view_bottom - view_top) / line_h))

    -- INPUT
    local max_scroll = math.max(0, #lines - visible_lines)

    -- keyboard (hold+repeat)
    if btnp(BTN_P1_UP, 15, 3) then
        scroll = scroll - 1
    end
    if btnp(BTN_P1_DOWN, 15, 3) then
        scroll = scroll + 1
    end

    -- clamp
    scroll = math.max(0, math.min(max_scroll, scroll))

    drawCenteredText("HIGH SCORES", EDGE_Y_TOP + Y_PADDING, ORANGE, nil, 3, nil, YELLOW)

    -- draw visible slice
    for i = 0, visible_lines - 1 do
        local line = lines[scroll + 1 + i] -- Lua arrays are 1-based
        if not line then break end
        local y = view_top + i * line_h
        print(line, X_PADDING + 1, y + 1, GRAY_MED, true) -- the shadow
        print(line, X_PADDING, y, WHITE, true)
    end

    -- Small scrollbar indicator
    if max_scroll > 0 then
        local bar_x = EDGE_X_RIGHT - 4
        rect(bar_x, view_top, 2, view_bottom - view_top, GRAY_DARK)
        local thumb_h = math.max(4, math.floor((view_bottom - view_top) * (visible_lines / #lines)))
        local thumb_y = view_top + math.floor((view_bottom - view_top - thumb_h) * (scroll / max_scroll))
        rect(bar_x, thumb_y, 2, thumb_h, GREEN_LITE)
    end

    -- Instructions
    drawCenteredText("Press Z to Return", EDGE_Y_BOTTOM - Y_PADDING, WHITE, false, 1, true, GRAY_MED)
end
