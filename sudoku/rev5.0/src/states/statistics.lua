-- ==========================================
-- STATE: STATISTICS
-- ==========================================

local MAX_PMEM_CHUNKS = 63

local lines = {}


-- Persistent memory has 255 slots. We want to save four pieces of data, so that
-- restricts us to 252 slots (63 chunks of 4 slots).

function loadHighScores()
    -- Don't sort here. Sorting happens when we want to print them.
    -- Convert game.play.date to a human-readable date after sort but before print.
    game.statistics = {}

    for idx = 0, MAX_PMEM_CHUNKS do
        local base = idx * 4
        local date = pmem(base + 0)
        if date ~= 0 then
            game.statistics[base] = {
                date       = date,
                difficulty = pmem(base + 1),
                timer      = pmem(base + 2),
                autonotes  = pmem(base + 3),
            }
        end
    end
end

function sortHighScores()
    -- Collect existing entries (0,4,8,...) into a dense list
    local list = {}
    for idx = 0, MAX_PMEM_CHUNKS do
        local base = idx * 4
        local d = game.statistics[base]
        if d then
            list[#list + 1] = d
        end
    end

    -- Sort by difficulty desc, then by time asc, then by autonotes asc.
    table.sort(list, function(a, b)
        if a.difficulty ~= b.difficulty then
            return a.difficulty > b.difficulty
        end
        if a.timer ~= b.timer then
            return a.timer < b.timer
        end
        if a.autonotes ~= b.autonotes then
            return a.autonotes < b.autonotes
        end
        -- optional tiebreaker so order is stable-ish
        return a.date > b.date
    end)

    -- Write back compacted into chunk keys 0,4,8,...
    game.statistics = {}
    for i = 1, #list do
        game.statistics[(i - 1) * 4] = list[i]
    end
end

local function saveCurrentScore()
    -- Always start from what is currently saved
    loadHighScores()

    -- Find next free chunk index in the CURRENT in-memory table
    local n = 0
    for idx = 0, MAX_PMEM_CHUNKS do
        if game.statistics[idx * 4] then n = n + 1 end
    end
    local base = n * 4
    if base > MAX_PMEM_CHUNKS * 4 then
        base = MAX_PMEM_CHUNKS * 4 -- will be trimmed after sort
    end

    -- Map difficulty string -> numeric rank for storage/sorting
    local diff = (game.play.difficulty == "Easy" and 0)
              or (game.play.difficulty == "Medium" and 1)
              or 2

    -- Add current result
    game.statistics[base] = {
        date       = game.play.date,
        difficulty = diff,
        timer      = game.play.timer:getSeconds(),
        autonotes  = game.play.autonotes,
    }

    -- Sort + compact keys to 0,4,8,...
    sortHighScores()

    -- Save the data.
    for i = 0, 255 do pmem(i, 0) end
    for idx = 0, MAX_PMEM_CHUNKS do
        local b = idx * 4
        local d = game.statistics[b]
        if d then
            pmem(b + 0, d.date)
            pmem(b + 1, d.difficulty)
            pmem(b + 2, d.timer)
            pmem(b + 3, d.autonotes)
        end
    end
end


function buildLines()
    -- Show only the saved/sorted entries (0,4,8,...,252)
    lines = {}
    for idx = 0, MAX_PMEM_CHUNKS do
        local k = idx * 4
        local d = game.statistics[k]
        if d then
            local dt_obj = unix_to_greg_utc(d.date)
            local dt_str = convert_datetime_obj_to_string(dt_obj)
            table.insert(lines, dt_str)

            local diff = (d.difficulty == 0 and "Easy")
                or (d.difficulty == 1 and "Medium")
                or (d.difficulty == 2 and "Hard")
            table.insert(lines, string.format("      Difficulty   %s", diff))

            local minutes = math.floor(d.timer / 60)
            local seconds = d.timer % 60
            table.insert(lines, string.format("      Clock         %02d:%02d", minutes, seconds))

            table.insert(lines, string.format("      Auto-Notes  %s", d.autonotes))
            table.insert(lines, "") -- blank spacer line
        end
    end
end


local function updateStatistics()
    if btnPressed(BTN_P1_A) or btnPressed(BTN_P1_B) then
        changeState(STATE.TITLE)
        return
    end
end


local function drawStatistics()
    cls(0)

    -- LAYOUT

    local header_y = EDGE_Y_TOP + Y_PADDING
    local line_h = FIXED_CHAR_HEIGHT + 1
    local view_top = header_y + FIXED_CHAR_HEIGHT + Y_PADDING
    local view_bottom = EDGE_Y_BOTTOM - 2 * Y_PADDING
    local visible_lines = math.max(1, math.floor((view_bottom - view_top) / line_h))

    -- INPUT
    local mouse_x, mouse_y, left_click, middle_click, right_click, scroll_x, scroll_y = mouse()
    local max_scroll = math.max(0, #lines - visible_lines)

    -- keyboard (hold+repeat)
    if btnp(BTN_P1_UP, 15, 3) then
        scroll = scroll - 1
    end
    if btnp(BTN_P1_DOWN, 15, 3) then
        scroll = scroll + 1
    end

    -- mouse wheel (usually +1/-1 per notch)
    if scroll_y ~= 0 then
        scroll = scroll - scroll_y
    end

    -- clamp
    scroll = math.max(0, math.min(max_scroll, scroll))

    drawCenteredText("STATISTICS", EDGE_Y_TOP + Y_PADDING, WHITE)

    -- draw visible slice
    for i = 0, visible_lines - 1 do
        local line = lines[scroll + 1 + i] -- Lua arrays are 1-based
        if not line then break end
        local y = view_top + i * line_h
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
    drawCenteredText("Press A or B to return", EDGE_Y_BOTTOM - Y_PADDING, GREEN_MED)
end
