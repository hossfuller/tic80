--
-- Bundle file
-- Code changes will be overwritten
--

-- title:   SPong (Son of Pong)
-- author:  Adam Fuller <the.adam.fuller@gmail.com>
-- version: 0.2
-- script:  lua


--[[ INCLUDES ]]--
-- [TQ-Bundler: src.constants]

--[[ CONSTANTS ]] --

-- Colors
BLACK             = 0
PURPLE            = 1
RED               = 2
ORANGE            = 3
YELLOW            = 4
GREEN_LITE        = 5
GREEN_MED         = 6
GREEN_DARK        = 7
BLUE_DARK         = 8
BLUE_MED          = 9
BLUE_LITE         = 10
CYAN              = 11
WHITE             = 12
GRAY_LITE         = 13
GRAY_MED          = 14
GRAY_DARK         = 15

-- Controls
P1_UP             = 0
P1_DOWN           = 1
P1_LEFT           = 2
P1_RIGHT          = 3
P2_UP             = 8
P2_DOWN           = 9
P2_LEFT           = 10
P2_RIGHT          = 11

-- Screen Edges
HUD_WIDTH     = 10
EDGE_X_LEFT   = 0   + HUD_WIDTH
EDGE_X_RIGHT  = 239 - HUD_WIDTH
EDGE_Y_TOP    = 0
EDGE_Y_BOTTOM = 135

-- Moving Parts Contraints
PADDLE_WIDTH   = 4
PADDLE_HEIGHT  = 24
BALL_RADIUS    = 10
BOUNDARY_WIDTH = 2

-- Game Configuration
READY_LIGHT_RADIUS = 4
GAME_SPEED         = 1
WINNING_SCORE      = 2
SHOW_NUM_RETURNS   = true
ALWAYS_SHOW_SCORE  = true


-- [/TQ-Bundler: src.constants]

-- [TQ-Bundler: src.classes.SpongObj]

--[[ Base Class: SpongObj ]]--

SpongObj = {}
SpongObj.__index = SpongObj

function SpongObj:new(params)
    params = params or {}
    local obj = {
        x       = params.x or 0,
        y       = params.y or 0,
        vx      = params.vx or GAME_SPEED,
        vy      = params.vy or GAME_SPEED,
        width   = params.width or PADDLE_WIDTH,
        height  = params.height or PADDLE_HEIGHT,
        color   = params.color or WHITE,
        play_on = false,
    }
    setmetatable(obj, self)

    return obj
end

function SpongObj:draw()
    rect(self.x, self.y, self.width, self.height, self.color)
end

function SpongObj:getCollisionBox()
    return {
        top    = self.y,
        bottom = self.y + self.height,
        left   = self.x,
        right  = self.x + self.width
    }
end

function SpongObj:reset(x, y)
    print("This method hasn't been implemented", EDGE_X_LEFT, EDGE_Y_BOTTOM/2, RED)
end

function SpongObj:inPlay()
    self.play_on = true
end

function SpongObj:outOfPlay()
    self.play_on = false
end

function SpongObj:isInPlay()
    return self.play_on
end


-- [/TQ-Bundler: src.classes.SpongObj]

-- [TQ-Bundler: src.classes.SpaddleObj]

--[[ Base Class: SpaddleObj ]]--

SpaddleObj = setmetatable({}, {__index = SpongObj})
SpaddleObj.__index = SpaddleObj

function SpaddleObj:new(params)
    params = params or {}
    local obj = SpongObj.new(self, params)
    setmetatable(obj, self)
    -- SpaddleObj-specific properties
    obj.player = params.player or 1

    -- controls
    obj.upButton    = P1_UP
    obj.downButton  = P1_DOWN
    obj.leftButton  = P1_LEFT
    obj.rightButton = P1_RIGHT
    if obj.player == 2 then
        obj.upButton    = P2_UP
        obj.downButton  = P2_DOWN
        obj.leftButton  = P2_LEFT
        obj.rightButton = P2_RIGHT
    end

    obj.score   = 0
    obj.returns = 0

    return obj
end

function SpaddleObj:input()
    if btn(self.upButton) then
        self.y = math.floor(self.y - self.vy)
    end
    if btn(self.downButton) then
        self.y = math.ceil(self.y + self.vy)
    end
    -- Pressing left indicates that we're ready to play!
    if btn(self.leftButton) and self:isInPlay() == false then
        self:inPlay()
    end
end

function SpaddleObj:update()
    if self.x < EDGE_X_LEFT then
        self.x = EDGE_X_LEFT
    elseif self.x > (EDGE_X_RIGHT - self.width) then
        self.x = math.floor(EDGE_X_RIGHT - self.width)
    end
    if self.y < (EDGE_Y_TOP + 1) then
        self.y = EDGE_Y_TOP + 1
    elseif self.y > (EDGE_Y_BOTTOM - self.height) then
        self.y = math.floor(EDGE_Y_BOTTOM - self.height)
    end
end

function SpaddleObj:reset(x, y)
    self.x = x or EDGE_X_LEFT
    self.y = y or math.floor((EDGE_Y_BOTTOM - self.height) / 2)
    if self.player == 2 then
        self.x = x or EDGE_X_RIGHT - self.width
    end

    self:resetReturns()

    self:outOfPlay()
end

function SpaddleObj:getReturns()
    return self.returns
end

function SpaddleObj:incrementReturns()
    self.returns = self.returns + 1
end

function SpaddleObj:resetReturns()
    self.returns = 0
end

function SpaddleObj:getScore()
    return self.score
end

function SpaddleObj:incrementScore()
    self.score = self.score + 1
end

function SpaddleObj:resetScore()
    self.score = 0
end


-- [/TQ-Bundler: src.classes.SpaddleObj]

-- [TQ-Bundler: src.classes.SballObj]

--[[ Base Class: SballObj ]]--

SballObj = setmetatable({}, {__index = SpongObj})
SballObj.__index = SballObj

function SballObj:new(params)
    params = params or {}
    local obj = SpongObj.new(self, params)
    setmetatable(obj, self)

    -- SballObj-specific properties
    obj.radius = params.radius or BALL_RADIUS

    return obj
end

function SballObj:draw()
    circ(self.x, self.y, self.radius, self.color)
end

function SballObj:getCollisionBox()
    return {
        top    = self.y - self.radius,
        bottom = self.y + self.radius,
        left   = self.x - self.radius,
        right  = self.x + self.radius,
    }
end

function SballObj:reset(x, y)
    self.x      = x or math.floor(EDGE_X_RIGHT/2)
    self.y      = y or math.floor(EDGE_Y_BOTTOM/2)

    -- Get the ball moving in a random direction.
    local ball_direction_x = (math.random() < 0.5) and 1 or -1
    local ball_direction_y = (math.random() < 0.5) and 1 or -1
    self.vx = ball_direction_x * GAME_SPEED
    self.vy = ball_direction_y * GAME_SPEED

    self:outOfPlay()
end

function SballObj:update()
    if self:isInPlay() then
        self.x = self.x + self.vx
        self.y = self.y + self.vy
    end

    if (self.x + 3*self.radius) < EDGE_X_LEFT or (self.x - 3*self.radius) > EDGE_X_RIGHT then
        sfx(2)
        self:outOfPlay()
    end

    if self.y < (EDGE_Y_TOP + self.radius + 1) then
        sfx(0)
        self.y = EDGE_Y_TOP + self.radius + 1
        self.vy = - self.vy
    elseif self.y > (EDGE_Y_BOTTOM - (self.radius)) then
        sfx(0)
        self.y = math.floor(EDGE_Y_BOTTOM - self.radius)
        self.vy = - self.vy
    end
end

function SballObj:collision(paddle)
    ball_box   = self:getCollisionBox()
    paddle_box = paddle:getCollisionBox()

    if
        ball_box['left'] < paddle_box['right']
        and ball_box['right'] > paddle_box['left']
        and ball_box['top'] < paddle_box['bottom']
        and ball_box['bottom'] > paddle_box['top']
    then
        sfx(1)
        self.vx = -self.vx
        paddle:incrementReturns()
    end
end


-- [/TQ-Bundler: src.classes.SballObj]

-- [TQ-Bundler: src.input]

--[[ INPUT FUNCTIONS ]]--

function INPUT()
    paddle1:input()
    paddle2:input()
end -- INPUT()


-- [/TQ-Bundler: src.input]

-- [TQ-Bundler: src.update]

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


-- [/TQ-Bundler: src.update]

-- [TQ-Bundler: src.draw]

--[[ DRAW FUNCTIONS ]]--

function DRAW()
    cls(BLACK)

    -- Draw the court, which is stationary.
    drawCourt()

    -- draw the HUD for each user.
    -- drawHud(paddle1, ball:isInPlay())
    -- drawHud(paddle2, ball:isInPlay())

    spr(257, 10, 10, 0, 0, 0, 0, 2, 4)

    -- -- Draw score and other situational information
    -- -- if ALWAYS_SHOW_SCORE or (
    -- --     paddle1:isInPlay() == false
    -- --     or paddle1:isInPlay() == false
    -- --     or ball:isInPlay() == false
    -- -- ) then
    -- --     drawScoreBug()
    -- -- end
    -- drawScoreBug()

    -- -- Draw the moving elements.
    -- paddle1:draw()
    -- paddle2:draw()
    -- ball:draw()

    -- print_centered_text("P1.x = " .. paddle1.x, 20)
    -- print_centered_text("P1.y = " .. paddle1.y, 30)
    -- print_centered_text("P1.player = " .. paddle1.player, 40)
    -- print_centered_text("P1.isInPlay() = " .. tostring(paddle1:isInPlay()), 50)

    -- print_centered_text("P2.x = " .. paddle2.x, 70)
    -- print_centered_text("P2.y = " .. paddle2.y, 80)
    -- print_centered_text("P2.player = " .. paddle2.player, 90)
    -- print_centered_text("P2.isInPlay() = " .. tostring(paddle2:isInPlay()), 100)

    -- print_centered_text("Ball.isInPlay() = " .. tostring(ball:isInPlay()), 120)
end -- DRAW()

function drawHud(paddle, ball_status)
    local x_pos = EDGE_X_LEFT - HUD_WIDTH

    local red_light_spr_id    = 1
    local yellow_light_spr_id = 3
    local green_light_spr_id  = 5
    local status_light_spr_id = 0

    -- local red_light    = spr(1, 2, 3, 0, scale, flip, rotate, w, h)
    -- local yellow_light = spr(3, 2, 3, 0, scale, flip, rotate, w, h)
    -- local green_light  = spr(5, 2, 3, 0, scale, flip, rotate, w, h)

    if paddle.player == 2 then
        x_pos = EDGE_X_RIGHT
    end
    -- rect(x_pos, EDGE_Y_TOP, HUD_WIDTH, EDGE_Y_BOTTOM + 1, GRAY_LITE)

    if paddle:isInPlay() == false then
        status_light_spr_id = red_light_spr_id
        print("Player " .. paddle.player .. " is not ready.")
    elseif paddle:isInPlay() == true and ball_status == false then
        status_light_spr_id = yellow_light_spr_id
        print("Player " .. paddle.player .. " is ready.")
    elseif paddle:isInPlay() == true and ball_status == true then
        status_light_spr_id = green_light_spr_id
        print("Game on!")
    end
    -- spr(status_light_spr_id, x_pos, EDGE_Y_TOP, 0, 0, 0, 0, 2, 4)
    spr(status_light_spr_id, 10, 10, 0, 0, 0, 0, 2, 4)


end

function drawCourt()
    -- Net
    for _i=EDGE_Y_TOP+2,EDGE_Y_BOTTOM,8 do
        rect(EDGE_X_RIGHT/2, _i, BOUNDARY_WIDTH, 4, GREEN_LITE)
    end
    -- Court boundaries
    line(EDGE_X_LEFT, EDGE_Y_TOP, EDGE_X_RIGHT - 1, EDGE_Y_TOP, YELLOW)
    line(EDGE_X_LEFT, EDGE_Y_BOTTOM, EDGE_X_RIGHT - 1, EDGE_Y_BOTTOM, YELLOW)
end

-- function drawScoreBug()
--     local score_line = string.format("%d - %d", paddle1:getScore(), paddle2:getScore())
--     print_centered_text(score_line, BOUNDARY_WIDTH + 2, BLUE_LITE, true, 2)

--     if SHOW_NUM_RETURNS then
--         local returns_line = string.format("%d   %d", paddle1:getReturns(), paddle2:getReturns())
--         print_centered_text(returns_line, EDGE_Y_BOTTOM - 9, GRAY_LITE, true, 1)
--     end
-- end

function print_centered_text(message, height, color, shadow, scale)
    if height == nil then
        height = math.floor(EDGE_Y_BOTTOM/2)
    end
    if color == nil then
        color = WHITE
    end
    if shadow == nil then
        shadow = false
    end
    if scale == nil then
        scale = 1
    end
    local message_width = print(message, 0, -40, color, true, scale)
    local x_pos = ((EDGE_X_RIGHT - message_width) / 2) + 2
    if shadow then
        print(message, x_pos + 1, height + 1, color + 1, true, scale)
    end
    print(message, x_pos, height, color, true, scale)
end


-- [/TQ-Bundler: src.draw]

-- [TQ-Bundler: src.check]

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


-- [/TQ-Bundler: src.check]

--[[ INITIALIZATION ]]--

-- Create objects
paddle1 = SpaddleObj:new({player = 1})
paddle2 = SpaddleObj:new({player = 2})
ball    = SballObj:new()

-- TODO: How do I automatically change the keymapping upon loading?
function BOOT()
end

function INIT()
    paddle1:reset()
    paddle2:reset()
    ball:reset()
end

INIT()


--[[ GAME LOOP ]]--

function TIC()
    --[[ CHECK FOR USER INPUT ]]--
    INPUT()

    --[[ UPDATE GAME DATA ]]--
    UPDATE()

    --[[ DRAW GAME GRAPHICS ]]--
    DRAW()

    --[[ CHECK FOR GAME STOPPAGES ]]--
    CHECK()
end --TIC

-- <SPRITES>
-- 001:00ffffff0feeeeeefeeefffefeef222ffef22222fef22222fef22222feef222f
-- 002:f0000000ef000000eef00000eef00000fef00000fef00000fef00000eef00000
-- 003:00ffffff0feeeeeefeeefffefeefdddffefdddddfefdddddfefdddddfeefdddf
-- 004:f0000000ef000000eef00000eef00000fef00000fef00000fef00000eef00000
-- 005:00ffffff0feeeeeefeeefffefeefdddffefdddddfefdddddfefdddddfeefdddf
-- 006:f0000000ef000000eef00000eef00000fef00000fef00000fef00000eef00000
-- 017:feeefffefeeeeeeefeeefffefeefdddffefdddddfefdddddfefdddddfeefdddf
-- 018:eef00000eef00000eef00000eef00000fef00000fef00000fef00000eef00000
-- 019:feeefffefeeeeeeefeeefffefeef444ffef44444fef44444fef44444feef444f
-- 020:eef00000eef00000eef00000eef00000fef00000fef00000fef00000eef00000
-- 021:feeefffefeeeeeeefeeefffefeefdddffefdddddfefdddddfefdddddfeefdddf
-- 022:eef00000eef00000eef00000eef00000fef00000fef00000fef00000eef00000
-- 033:feeefffefeeeeeeefeeefffefeefdddffefdddddfefdddddfefdddddfeefdddf
-- 034:eef00000eef00000eef00000eef00000fef00000fef00000fef00000eef00000
-- 035:feeefffefeeeeeeefeeefffefeefdddffefdddddfefdddddfefdddddfeefdddf
-- 036:eef00000eef00000eef00000eef00000fef00000fef00000fef00000eef00000
-- 037:feeefffefeeeeeeefeeefffefeef666ffef66666fef66666fef66666feef666f
-- 038:eef00000eef00000eef00000eef00000fef00000fef00000fef00000eef00000
-- 049:feeefffe0feeeeee00ffffff0000000000000000000000000000000000000000
-- 050:eef00000ef000000f00000000000000000000000000000000000000000000000
-- 051:feeefffe0feeeeee00ffffff0000000000000000000000000000000000000000
-- 052:eef00000ef000000f00000000000000000000000000000000000000000000000
-- 053:feeefffe0feeeeee00ffffff0000000000000000000000000000000000000000
-- 054:eef00000ef000000f00000000000000000000000000000000000000000000000
-- </SPRITES>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:00000000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000404000000000
-- 001:00000000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f00020a000000000
-- 002:04f004c0049004600430f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400100000000000
-- </SFX>

-- <TRACKS>
-- 000:100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </TRACKS>

-- <PALETTE>
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

