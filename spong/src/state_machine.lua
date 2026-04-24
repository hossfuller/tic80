--[[ STATE MACHINE ]]--

local function state_ready_update()
    -- allow moving paddles and toggling serve direction
    paddle1:input()
    paddle2:input()
    ball:input()

    paddle1:update()
    paddle2:update()

    -- keep ball attached to serving paddle
    if CURRENT_SERVE_PLAYER == 1 then
        ball:preServe(paddle1)
    else
        ball:preServe(paddle2)
    end

    -- transition when both are ready
    if paddle1:isInPlay() and paddle2:isInPlay() then
        sfx(5)
        ball:inPlay()
        set_state(STATE.PLAY)
    end
end

local function state_ready_draw()
    DRAW()

    local ready_msg_height = math.floor(EDGE_Y_BOTTOM / 2) - 20
    print_centered_text("READY?", ready_msg_height, ORANGE, true, true, 3)
    print_centered_text("PRESS LEFT TO BEGIN", ready_msg_height + 30, BLUE_LITE, false, false, 1)
    print_centered_text("PRESS RIGHT TO CHANGE", ready_msg_height + 40, BLUE_LITE, false, false, 1)
    print_centered_text("SERVE DIRECTION", ready_msg_height + 47, BLUE_LITE, false, false, 1)
end

local function state_play_update()
    INPUT()
    UPDATE()

    -- scoring / round end
    if award_point_if_ball_out() then
        local w = check_for_winner()
        if w then
            winner_paddle = w
            set_state(STATE.GAMEOVER)
        else
            begin_round()
        end
    end
end

local function state_play_draw()
    DRAW()
end

local function state_gameover_update()
    -- no INPUT/UPDATE; only wait for A
    if winner_paddle and btnp(winner_paddle.aButton) then
        set_state(STATE.START)
        INIT()
    end
end

local function state_gameover_draw()
    DRAW()

    local winning_message = string.format("PLAYER %d WINS!", winner_paddle.player)
    print_centered_text(winning_message, EDGE_Y_BOTTOM / 2, ORANGE, true, false, 2)
    print_centered_text("PRESS A TO RETURN", EDGE_Y_BOTTOM / 2 + 20, BLUE_LITE)
    print_centered_text("TO START SCREEN", EDGE_Y_BOTTOM / 2 + 27, BLUE_LITE)
end
