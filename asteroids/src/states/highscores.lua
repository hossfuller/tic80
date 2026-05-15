-- ==========================================
-- STATE: HIGH SCORES
-- ==========================================

-- Persistent memory has 255 slots. We want to save two pieces of data: the date
-- and the score. On top of that, we only want to save the top 10 scores. That
-- restricts us to just 20 slots (10 chunks of 2 slots). Since our counter
-- starts at 0, we set MAX_PMEM_CHUNKS equal to 9.
local MAX_PMEM_CHUNKS     = 9
local PMEM_CHUNK_ELEMENTS = 2

-- We'll store our high scores in this table.
local lines = {}

-- ==========================================
-- HIGH SCORE HELPERS
-- ==========================================

function loadHighScores()
    game.high_scores = {}

    for idx = 0, MAX_PMEM_CHUNKS do
        local base = idx * PMEM_CHUNK_ELEMENTS
        local date = pmem(base + 0)
        if date ~= 0 then
            game.high_scores[base] = {
                date  = date,
                score = pmem(base + 1),
            }
        end
    end
end

function sortHighScores()
    -- Collect existing entries (0,2,4,...) into a dense list
    local list = {}
    for idx = 0, MAX_PMEM_CHUNKS do
        local base = idx * PMEM_CHUNK_ELEMENTS
        local d = game.high_scores[base]
        if d then
            list[#list + 1] = d
        end
    end

    -- Sort by score...
    table.sort(list, function(a, b)
        if a.score ~= b.score then
            return a.score > b.score
        end
    end)

    -- Write back compacted into chunk keys 0,2,4,...
    game.high_scores = {}
    for i = 1, #list do
        game.high_scores[(i - 1) * PMEM_CHUNK_ELEMENTS] = list[i]
    end
end

function saveCurrentScore()
    -- Always start from what is currently saved
    loadHighScores()

    -- Find next free chunk index in the CURRENT in-memory table
    local n = 0
    for idx = 0, MAX_PMEM_CHUNKS do
        if game.high_scores[idx * PMEM_CHUNK_ELEMENTS] then
            n = n + 1
        end
    end
    local base = n * PMEM_CHUNK_ELEMENTS
    if base > MAX_PMEM_CHUNKS * PMEM_CHUNK_ELEMENTS then
        base = MAX_PMEM_CHUNKS * PMEM_CHUNK_ELEMENTS -- will be trimmed after sort
    end

    -- Add current result
    game.high_scores[base] = {
        date  = game.play.date,
        score = game.play.score,
    }

    -- Sort + compact keys to 0,4,8,...
    sortHighScores()

    -- -- Save the data.
    for i = 0, 255 do pmem(i, 0) end
    for idx = 0, MAX_PMEM_CHUNKS do
        local b = idx * PMEM_CHUNK_ELEMENTS
        local d = game.high_scores[b]
        if d then
            pmem(b + 0, d.date)
            pmem(b + 1, d.score)
        end
    end
end


function buildLines()
    -- Show only the saved/sorted entries (0,4,8,...,252)
    lines = {}
    for idx = 0, MAX_PMEM_CHUNKS do
        local k = idx * PMEM_CHUNK_ELEMENTS
        local d = game.high_scores[k]
        if d then
            local dt_obj = unix_to_greg_utc(d.date)
            local dt_str = convert_datetime_obj_to_string(dt_obj)
            table.insert(lines, dt_str .. "      " .. d.score)
        end
    end
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
        print(line, X_PADDING + 1, y + 1, BLACK) -- the shadow
        print(line, X_PADDING, y, WHITE)
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
    drawCenteredText("Press Z or X to return to start screen", EDGE_Y_BOTTOM - Y_PADDING, WHITE, false, 1, true, GRAY_MED)
end