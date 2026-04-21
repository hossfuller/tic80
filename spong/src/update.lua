--[[ UPDATE FUNCTIONS ]]--

function UPDATE()
    -- Get the ball moving after being out of play.
    if
        paddle1:isInPlay() 
        and paddle2:isInPlay()
        and ball:isInPlay() == false
    then
        ball:inPlay()
    end

    -- Keep the paddles on the screen
    paddle1:update()
    paddle2:update()

    -- Check for paddle/ball collision.
    ball:collision(paddle1)
    ball:collision(paddle2)
    ball:update()
end -- UPDATE()
