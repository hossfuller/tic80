-- ==========================================
-- SUDOKU BUTTON DATA STRUCTURES
-- ==========================================

local function make_button(overrides)
    local g = {
        TEXT       = "BUTTON",
        CLICKED    = false,
        PREV_CLICK = false,
        START_X    = EDGE_X_LEFT + X_PADDING,
        START_Y    = EDGE_Y_TOP + Y_PADDING,
    }

    for k, v in pairs(overrides or {}) do g[k] = v end

    g.END_X        = EDGE_X_RIGHT - FIXED_CHAR_WIDTH  -- All buttons end at same X
    g.CELL_WIDTH   = g.END_X - g.START_X
    g.CELL_HEIGHT  = FIXED_CHAR_HEIGHT + Y_PADDING
    g.END_Y        = g.START_Y + g.CELL_HEIGHT
    g.TEXT_START_X = g.START_X + math.floor(X_PADDING / 2)
    g.TEXT_START_Y = g.START_Y + math.floor(Y_PADDING / 2)

    return g
end


local auto_note_btn = make_button({
    TEXT = "Auto-Note",
    START_X = notes.END_X + X_PADDING,
})
local check_solution_btn = make_button({
    TEXT = "Check",
    START_X = notes.END_X + X_PADDING,
    START_Y = auto_note_btn.END_Y,
})
local clear_btn = make_button({
    TEXT = "Clear",
    START_X = notes.END_X + X_PADDING,
    START_Y = check_solution_btn.END_Y,
})

local puzzle_buttons = {
    auto_note_btn,
    check_solution_btn,
    clear_btn,
}