--[[ CHECK FOR GAME STOPPAGES ]]--

function CHECK()

    -- Check if somebody's score == the WINNING_SCORE
    if paddle1:getScore() == WINNING_SCORE then
        GAME_OVER(paddle1)
    elseif paddle2:getScore() == WINNING_SCORE then
        GAME_OVER(paddle2)

    -- There's some sort of game stoppage (someone scored or the game is paused.)
    elseif
        paddle1:isInPlay() == false
        or paddle2:isInPlay() == false
    then
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
    -- Both players are ready but the ball has gone out of bounds.
    elseif
        paddle1:isInPlay() == true
        and paddle2:isInPlay() == true
    then

        if ball:isInPlay() == true then
            -- Ball is in play!
        else
            -- Ball is out of play! Increment score
            if (ball.x + ball.radius) < EDGE_X_LEFT then
                paddle2:incrementScore()
            elseif ball.x >= EDGE_X_RIGHT then
                paddle1:incrementScore()
            end

            paddle1:reset()
            paddle2:reset()
            ball:reset()
        end

    -- Everybody is playing, nothing new has happened.
    elseif
        paddle1:isInPlay() == true
        and paddle2:isInPlay() == true
        and ball:isInPlay() == true
    then
        -- Do nothing...for now.
    end
end -- CHECK()


function GAME_OVER(winning_paddle)
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
