-- ==========================================
-- SUDOKU BUTTON DATA STRUCTURES
-- ==========================================

local function make_button(params)
    local g = {}

    g.TEXT         = params.TEXT         or "BUTTON"
    g.CLICKED      = params.CLICKED      or false
    g.PREV_CLICK   = params.PREV_CLICK   or false
    g.START_X      = params.START_X      or (EDGE_X_LEFT + X_PADDING)
    g.START_Y      = params.START_Y      or (EDGE_Y_TOP + Y_PADDING)
    g.END_X        = params.END_X        or (EDGE_X_RIGHT - FIXED_CHAR_WIDTH)
    g.CELL_WIDTH   = params.CELL_WIDTH   or (g.END_X - g.START_X)
    g.CELL_HEIGHT  = params.CELL_HEIGHT  or (FIXED_CHAR_HEIGHT + Y_PADDING)
    g.END_Y        = params.END_Y        or (g.START_Y + g.CELL_HEIGHT)
    g.TEXT_START_X = params.TEXT_START_X or (g.START_X + math.floor(X_PADDING / 2))
    g.TEXT_START_Y = params.TEXT_START_Y or (g.START_Y + math.floor(Y_PADDING / 2))
    g.BG_COLOR     = params.BG_COLOR     or YELLOW

    return g
end


local auto_note_btn = make_button({
    TEXT    = "AUTO-NOTE",
    START_X = notes.END_X + X_PADDING,
})
local undo_btn = make_button({
    TEXT    = "UNDO",
    START_X = notes.END_X + X_PADDING,
    START_Y = auto_note_btn.END_Y,
})
local clear_btn = make_button({
    TEXT    = "CLEAR",
    START_X = notes.END_X + X_PADDING,
    START_Y = undo_btn.END_Y,
})

local game_ctl_btn_width = math.floor((EDGE_X_RIGHT - FIXED_CHAR_WIDTH - notes.START_X) / 3)

local check_solution_btn = make_button({
    TEXT       = "CHECK",
    START_X    = notes.START_X,
    START_Y    = EDGE_Y_BOTTOM - (FIXED_CHAR_HEIGHT + (2 * Y_PADDING)),
    CELL_WIDTH = game_ctl_btn_width,
})
local new_puzzle_btn = make_button({
    TEXT       = "NEW",
    START_X    = check_solution_btn.START_X + check_solution_btn.CELL_WIDTH,   -- Chain from previous button
    START_Y    = check_solution_btn.START_Y,                                   -- Same row
    CELL_WIDTH = game_ctl_btn_width,
    BG_COLOR   = GREEN,
})
local exit_btn = make_button({
    TEXT       = "EXIT",
    START_X    = new_puzzle_btn.START_X + new_puzzle_btn.CELL_WIDTH,   -- Chain from previous button
    START_Y    = check_solution_btn.START_Y,                           -- Same row
    CELL_WIDTH = game_ctl_btn_width,
    BG_COLOR   = RED,
})

local puzzle_buttons = {
    auto_note_btn,
    undo_btn,
    clear_btn,
}
local game_ctl_buttons = {
    check_solution_btn,
    new_puzzle_btn,
    exit_btn,
}
