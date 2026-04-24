--[[ HELPERS ]]--

local function begin_round()
    -- after a point, nobody is ready
    paddle1:reset()
    paddle2:reset()
    ball:reset()
    winner_paddle = nil
    set_state(STATE.READY)
end

local function award_point_if_ball_out()
    if ball:isInPlay() then return false end

    if (ball.x + ball.radius) < EDGE_X_LEFT then
        paddle2:incrementScore()
    elseif ball.x >= EDGE_X_RIGHT then
        paddle1:incrementScore()
    else
        -- ball is "out of play" for some other reason; don't score
        return false
    end

    return true
end

local function check_for_winner()
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
