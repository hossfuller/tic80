--[[ CHECK FOR GAME STOPPAGES ]]--

function CHECK()

    -- -- -- There's some sort of game stoppage (someone scored or the game is paused.)
    -- -- if paddle1:isInPlay() == false and paddle1:isInPlay() == false then
    -- --     print_centered_text("READY?", math.floor(EDGE_Y_BOTTOM/2), ORANGE, true, 3)

    -- -- elseif paddle1:isInPlay() == true and paddle1:isInPlay() == false then
    -- --     print_centered_text("READY?", math.floor(EDGE_Y_BOTTOM / 2), ORANGE, true, 3)
    -- --     print("YES!", EDGE_X_LEFT + 2, BOUNDARY_WIDTH + 2, ORANGE, true, 2)

    -- -- elseif paddle1:isInPlay() == false and paddle1:isInPlay() == true then
    -- --     print_centered_text("READY?", math.floor(EDGE_Y_BOTTOM / 2), ORANGE, true, 3)
    -- --     local p2_ready_width = print("YES!", EDGE_X_LEFT + 2, -20, ORANGE, true, 2)
    -- --     print("YES!", EDGE_X_RIGHT - p2_ready_width, BOUNDARY_WIDTH + 2, ORANGE, true, 2)

    -- --     -- The ball has gone out of play....
    -- -- elseif

    -- There's some sort of game stoppage (someone scored or the game is paused.)
    if
        paddle1:isInPlay() == false
        or paddle2:isInPlay() == false
    then
        print_centered_text("READY?", math.floor(EDGE_Y_BOTTOM/2), ORANGE, true, 3)

    -- Both players are ready but the ball has gone out of bounds.
    elseif
        paddle1:isInPlay() == true
        and paddle2:isInPlay() == true
    then
        
        if ball:isInPlay() == true then
            -- Ball is in play!

        else
            -- Ball is out of play!

    --     -- Increment score
    --     if (ball.x + ball.radius) < EDGE_X_LEFT then
    --         paddle2:incrementScore()
    --         -- paddle2:outOfPlay()

    --     elseif ball.x >= EDGE_X_RIGHT then
    --         paddle1:incrementScore()
    --         -- paddle1:outOfPlay()
    --     end

    --     -- Check if somebody's score == the WINNING_SCORE
    --     if paddle1:getScore() == WINNING_SCORE then
    --         GAME_OVER(paddle1)
    --     elseif paddle2:getScore() == WINNING_SCORE then
    --         GAME_OVER(paddle2)
    --     else
            paddle1:reset()
            paddle2:reset()
            ball:reset()
    --     end
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


-- function GAME_OVER(winning_paddle)
--     local winning_message = string.format("PLAYER [%d] WINS!", winning_paddle.player)
--     print_centered_text(winning_message, EDGE_Y_BOTTOM/2, ORANGE, true, 3)
-- end
