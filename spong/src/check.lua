--[[ CHECK FOR GAME STOPPAGES ]]--

function CHECK()
    -- Check to see if we've got a winner.
    local winner = check_for_winner()
    if winner then
        GAME_OVER(winner)
        return
    end

    -- No winner, but there's some sort of game stoppage (someone scored or the
    -- game is paused.)
    if paddle1:isInPlay() == false or paddle2:isInPlay() == false then
        local ready_msg_height = math.floor(EDGE_Y_BOTTOM / 2) - 20
        print_centered_text("READY?", ready_msg_height, ORANGE, true, true, 3)
        print_centered_text("PRESS LEFT TO BEGIN", ready_msg_height + 30, BLUE_LITE, false, false, 1)
        print_centered_text("PRESS RIGHT TO CHANGE", ready_msg_height + 40, BLUE_LITE, false, false, 1)
        print_centered_text("SERVE DIRECTION", ready_msg_height + 47, BLUE_LITE, false, false, 1)

        -- Serving player can move up and down with the ball with this wrapper
        -- method for ball:reset().
        if CURRENT_SERVE_PLAYER == 1 then
            ball:preServe(paddle1)
        else
            ball:preServe(paddle2)
        end

        return

    -- Both players are ready but check if the ball has gone out of bounds.
    elseif
        paddle1:isInPlay() == true
        and paddle2:isInPlay() == true
        and ball:isInPlay() == false
    then
        if (ball.x + ball.radius) < EDGE_X_LEFT then
            paddle2:incrementScore()
        elseif ball.x >= EDGE_X_RIGHT then
            paddle1:incrementScore()
        end

        paddle1:reset()
        paddle2:reset()
        ball:reset()
        return
    end
end -- CHECK()

function check_for_winner()
    local score_one  = paddle1:getScore()
    local score_two  = paddle2:getScore()
    local max_score  = math.max(score_one, score_two)
    local diff_score = math.abs(score_one - score_two)

    if WIN_BY_TWO then
        if max_score >= WINNING_SCORE and diff_score >= 2 then
            return (score_one > score_two) and paddle1 or paddle2
        end
    else
        if score_one >= WINNING_SCORE then return paddle1 end
        if score_two >= WINNING_SCORE then return paddle2 end
    end

    return nil
end

function GAME_OVER()
    local winning_paddle = check_for_winner()

    local winning_message = string.format("PLAYER %d WINS!", winning_paddle.player)
    print_centered_text(winning_message, EDGE_Y_BOTTOM/2, ORANGE, true, false, 2)
    print_centered_text("PRESS A TO RETURN", EDGE_Y_BOTTOM/2 + 20, BLUE_LITE)
    print_centered_text("TO START SCREEN", EDGE_Y_BOTTOM/2 + 27, BLUE_LITE)

    CURRENT_GAME_MODE = 'over'

    -- If we're on the game-over screen, wait for A and do nothing else.
    if btnp(winning_paddle.aButton) then
        CURRENT_GAME_MODE = 'start'
        INIT() -- optional reset
    end
end
