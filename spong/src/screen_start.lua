--[[ GAME START SCREEN FUNCTIONS ]]--


local start_title_y    = math.floor(EDGE_Y_BOTTOM * 0.25)
local start_subtitle_y = start_title_y + 35

local start_menu_option_x = math.floor(EDGE_X_RIGHT * 0.41)
local start_menu_option_y = start_subtitle_y + 20
local start_menu_space_y  = 10

local start_menu_options = {
    "New Game",
    "Options"
}
local start_menu_options_num = #start_menu_options

local start_menu_ball = {
    x = start_menu_option_x - 7,
    y = start_menu_option_y + 2,
    r = 2,
    cur = 1,
    sel = 0,
}

local function state_start_update()
    start_screen() -- your start screen already does input/update/draw
    -- your start_screen_update() currently sets CURRENT_GAME_MODE.
    -- Change that to:
    --   set_state(STATE.READY) for New Game
    --   set_state(STATE.OPTIONS) for Options
end

function start_screen()
    start_screen_input()
    start_screen_update()
    start_screen_draw()
end

function start_screen_input()
    if btnp(P1_UP) or btnp(P1_DOWN) then
        if start_menu_ball.cur == start_menu_options_num then
            start_menu_ball.cur = 1
            start_menu_ball.y   = start_menu_option_y + 2
        else
            start_menu_ball.cur = start_menu_ball.cur + 1
            start_menu_ball.y = start_menu_ball.y + start_menu_space_y
        end
    end
    if btnp(P1_LEFT) or btnp(P1_RIGHT) then
        start_menu_ball.sel = start_menu_ball.cur
    end
end

function start_screen_update()
    if start_menu_ball.sel == 1 then
        -- New Game
        INIT()
        begin_round() -- goes to READY
    elseif start_menu_ball.sel == 2 then
        set_state(STATE.OPTIONS)
    end
    start_menu_ball.sel = 0
end

function start_screen_draw()
    print_centered_text("SPONG", start_title_y, ORANGE, true, true, 6)
    print_centered_text("Son of PONG", start_subtitle_y, BLUE_DARK, true, true, 2)

    local current_start_menu_option_y = start_menu_option_y
    for index, start_option_text in ipairs(start_menu_options) do
        if index == start_menu_ball.cur then
            circ(start_menu_ball.x, start_menu_ball.y, start_menu_ball.r, WHITE)
        end
        print(start_option_text, start_menu_option_x, current_start_menu_option_y, GRAY_LITE)
        current_start_menu_option_y = current_start_menu_option_y + start_menu_space_y
    end

    local copyright_width = print("  2026 A. H. Fuller", 0, -10, GRAY_LITE)
    local x_pos = ((EDGE_X_RIGHT - copyright_width) / 2) + 2

    -- copyright sprite and message.
    spr(264, x_pos, EDGE_Y_BOTTOM - 8, 0, 1, 0, 0, 1, 1)
    print(" 2026 A. H. Fuller", x_pos + 8, EDGE_Y_BOTTOM - 7, GRAY_LITE)
end
