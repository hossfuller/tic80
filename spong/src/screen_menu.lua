--[[ GAME MENU SCREEN FUNCTIONS ]] --


local menu_title_y       = 0
local menu_menu_option_x = 20
local menu_menu_option_y = menu_title_y + 20
local menu_menu_space_y  = 8

local menu_menu_options = {
    "< Back to Main Menu",
    "Player who serves first",
    "Winning Score",
    "Starting game speed",
    "Enable speed boost",
    "Speed boost multiplier",
    "Returns before speed boost",
    "Display number of returns",
}
local menu_menu_options_num = #menu_menu_options

local menu_menu_ball = {
    x = menu_menu_option_x - 7,
    y = menu_menu_option_y + 2,
    r = 2,
    cur = 1,
    sel = 0,
    inc = false,
    dec = false,
}


function menu_screen()
    menu_screen_input()
    menu_screen_update()
    menu_screen_draw()
end

function menu_screen_input()
    if btnp(P1_UP) then
        if menu_menu_ball.cur == 1 then
            menu_menu_ball.cur = menu_menu_options_num
        else
            menu_menu_ball.cur = menu_menu_ball.cur - 1
        end
        menu_menu_ball.y = (menu_menu_option_y + 2) + ((menu_menu_ball.cur - 1) * menu_menu_space_y)
    end
    if btnp(P1_DOWN) then
        if menu_menu_ball.cur == menu_menu_options_num then
            menu_menu_ball.cur = 1
        else
            menu_menu_ball.cur = menu_menu_ball.cur + 1
        end
        menu_menu_ball.y = (menu_menu_option_y + 2) + ((menu_menu_ball.cur - 1) * menu_menu_space_y)
    end
    if btnp(P1_LEFT) then
        menu_menu_ball.sel = menu_menu_ball.cur
        menu_menu_ball.inc = false
        menu_menu_ball.dec = true
    end
    if btnp(P1_RIGHT) then
        menu_menu_ball.sel = menu_menu_ball.cur
        menu_menu_ball.inc = true
        menu_menu_ball.dec = false
    end
end

function menu_screen_update()
    local winning_score_limit    = 100
    local game_speed_limit       = 10
    local return_threshold_limit = 100

    local multiplier = 1
    if menu_menu_ball.dec == true and menu_menu_ball.inc == false then
       multiplier = -1
    end

    if menu_menu_ball.sel == 1 then
        CURRENT_GAME_MODE = 'start'

    elseif menu_menu_ball.sel == 2 then
        CURRENT_SERVE_PLAYER = 1
        if multiplier > 0 then
            CURRENT_SERVE_PLAYER = 2
        end
    elseif menu_menu_ball.sel == 3 then
        WINNING_SCORE = WINNING_SCORE + (1 * multiplier)
        if WINNING_SCORE < 1 then
            WINNING_SCORE = 1
        elseif WINNING_SCORE > winning_score_limit then
            WINNING_SCORE = winning_score_limit
        end
    elseif menu_menu_ball.sel == 4 then
        GAME_SPEED = GAME_SPEED + (1 * multiplier)
        if GAME_SPEED > game_speed_limit then
            GAME_SPEED = game_speed_limit
        elseif GAME_SPEED < 1 then
            GAME_SPEED = 1
        end
    elseif menu_menu_ball.sel == 5 then
        if ENABLE_SPEED_BOOST == true then
            ENABLE_SPEED_BOOST = false
        else
            ENABLE_SPEED_BOOST = true
        end
    elseif menu_menu_ball.sel == 6 then
        SPEED_BOOSTER = SPEED_BOOSTER + (0.05 * multiplier)
        if SPEED_BOOSTER > 1.01 then
            SPEED_BOOSTER = 1.0
        elseif SPEED_BOOSTER < 0.05 then
            SPEED_BOOSTER = 0.05
        end
    elseif menu_menu_ball.sel == 7 then
        RETURN_THRESHOLD = RETURN_THRESHOLD + (1 * multiplier)
        if RETURN_THRESHOLD > return_threshold_limit then
            RETURN_THRESHOLD = return_threshold_limit
        elseif RETURN_THRESHOLD < 1 then
            RETURN_THRESHOLD = 1
        end
    elseif menu_menu_ball.sel == 8 then
        if SHOW_NUM_RETURNS == true then
            SHOW_NUM_RETURNS = false
        else
            SHOW_NUM_RETURNS = true
        end
    end

    menu_menu_ball.sel = 0
    menu_menu_ball.inc = false
    menu_menu_ball.dec = false
end

function menu_screen_draw()
    print_centered_text("OPTIONS", menu_title_y, ORANGE, true, true, 2)

    -- Get longest option length first.
    local longest_option_width = 0
    for index, menu_option_text in ipairs(menu_menu_options) do
        longest_option_width = print(menu_option_text, 0, -10)
    end
    longest_option_width = longest_option_width + 30

    local current_menu_menu_option_y = menu_menu_option_y
    for index, menu_option_text in ipairs(menu_menu_options) do
        if index == menu_menu_ball.cur then
            circ(menu_menu_ball.x, menu_menu_ball.y, menu_menu_ball.r, WHITE)
        end
        print(menu_option_text, menu_menu_option_x, current_menu_menu_option_y, GRAY_LITE)
        print(
            menu_screen_get_option_value(index),
            longest_option_width + (2 * menu_menu_space_y),
            current_menu_menu_option_y,
            GRAY_LITE,
            true
        )
        current_menu_menu_option_y = current_menu_menu_option_y + menu_menu_space_y
    end
end

function menu_screen_get_option_value(index)
    local return_string = " "
    local true_string   = string.format("%5s", "TRUE")
    local false_string  = string.format("%5s", "FALSE")

    if index == 2 then
        return_string = string.format("%5d", tostring(CURRENT_SERVE_PLAYER))
    elseif index == 3 then
        return_string = string.format("%5d", tostring(WINNING_SCORE))
    elseif index == 4 then
        return_string = string.format("%5d", tostring(GAME_SPEED))
    elseif index == 5 then
        if ENABLE_SPEED_BOOST == true then
            return_string = true_string
        else
            return_string = false_string
        end
    elseif index == 6 then
        return_string = string.format(" %0.2f", tostring(SPEED_BOOSTER))
    elseif index == 7 then
        return_string = string.format("%5d", tostring(RETURN_THRESHOLD))
    elseif index == 8 then
        if SHOW_NUM_RETURNS == true then
            return_string = true_string
        else
            return_string = false_string
        end
    end
    return return_string
end
