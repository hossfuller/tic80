--[[ Base Class: SballObj ]]--

SballObj = setmetatable({}, {__index = SpongObj})
SballObj.__index = SballObj

function SballObj:new(params)
    params = params or {}
    local obj = SpongObj.new(self, params)
    setmetatable(obj, self)

    -- SballObj-specific properties
    obj.radius = params.radius or BALL_RADIUS
    obj.touching_paddle = false
    obj.serve_direction_x = 1  -- serve the ball right
    obj.serve_direction_y = 1  -- serve the ball down

    return obj
end

function SballObj:draw()
    circ(self.x, self.y, self.radius, self.color)

    -- Draw the serve direction if the ball is out of play.
    if self:isInPlay() == false then
        local serve_dir_arrow_spr_id = 263
        local serve_dir_arrow_x = self.x - self.radius - 1
        local serve_dir_arrow_y = self.y + 1
        local serve_dir_arrow_flip = 0
        local serve_dir_arrow_rotate = 0

        if self.vx > 0 and self.vy < 0 then -- pointing right and up
            serve_dir_arrow_x = serve_dir_arrow_x + 1 
            serve_dir_arrow_y = serve_dir_arrow_y - 2*self.radius - 3
        elseif self.vx > 0 and self.vy > 0 then -- pointing right and down
            serve_dir_arrow_rotate = 2
        elseif self.vx < 0 and self.vy > 0 then -- pointing left and up
            serve_dir_arrow_x = serve_dir_arrow_x + 1 
            serve_dir_arrow_y = serve_dir_arrow_y - 2*self.radius - 3
        elseif self.vx < 0 and self.vy < 0 then -- pointing left and down
            -- serve_dir_arrow_x = serve_dir_arrow_x - self.radius
            serve_dir_arrow_rotate = 2
        end

        spr(
            serve_dir_arrow_spr_id, 
            serve_dir_arrow_x, 
            serve_dir_arrow_y, 
            0, -- colorkey
            1, -- scale
            serve_dir_arrow_flip, 
            serve_dir_arrow_rotate, 
            1, 1 -- width and height
        )
    end
end

function SballObj:getCollisionBox()
    return {
        top    = self.y - self.radius,
        bottom = self.y + self.radius,
        left   = self.x - self.radius,
        right  = self.x + self.radius,
    }
end

function SballObj:input()
    if (
        (CURRENT_SERVE_PLAYER == 1 and btnp(P1_RIGHT))
        or (CURRENT_SERVE_PLAYER == 2 and btnp(P2_RIGHT))
    ) then
        if self.serve_direction_y > 0 then
            self.serve_direction_y = -1 -- serve the ball up
            sfx(3)
        else
            self.serve_direction_y = 1 -- serve the ball down
            sfx(4)
        end
    end
end

function SballObj:preServe(paddle)
    local serving_x = EDGE_X_LEFT + PADDLE_WIDTH + self.radius + 2
    local serving_y = paddle.y + math.floor(paddle.height / 2)

    if paddle.player == 2 then
        serving_x = EDGE_X_RIGHT - PADDLE_WIDTH - self.radius - 3
    end

    self:reset(serving_x, serving_y)
end

function SballObj:reset(x, y)
    self.x = x or EDGE_X_LEFT + PADDLE_WIDTH + self.radius + 2
    self.y = y or math.floor(EDGE_Y_BOTTOM / 2)
    if CURRENT_SERVE_PLAYER == 2 then
        self.x = x or EDGE_X_RIGHT - PADDLE_WIDTH - self.radius - 3
    end

    if CURRENT_SERVE_PLAYER == 1 then
        self.serve_direction_x = 1
    else 
        self.serve_direction_x = -1
    end

    self.vx = self.serve_direction_x * GAME_SPEED
    self.vy = self.serve_direction_y * GAME_SPEED

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
    local ball_box   = self:getCollisionBox()
    local paddle_box = paddle:getCollisionBox()

    local is_colliding = ball_box['left'] < paddle_box['right']
        and ball_box['right'] > paddle_box['left']
        and ball_box['top'] < paddle_box['bottom']
        and ball_box['bottom'] > paddle_box['top']

    if is_colliding then
        if self:isTouchingPaddle() == false then
            sfx(1)
            self.vx = -self.vx

            -- Push the ball out of the paddle to prevent re-collision
            if paddle.player == 1 then
                self.x = paddle_box['right'] + self.radius + 1
            else
                self.x = paddle_box['left'] - self.radius - 1
            end

            self:touchingPaddle()
            paddle:incrementReturns()

            -- Speed up if that's where we're at.
            if (paddle:getReturns() > 0) and (paddle1:getReturns() % RETURN_THRESHOLD) == 0 then
                ball:speedUp()
                paddle:speedUp()
            end
        end
    else
        self:clearOfPaddle()
    end
end

function SballObj:clearOfPaddle()
    self.touching_paddle = false
end

function SballObj:touchingPaddle()
    self.touching_paddle = true
end

function SballObj:isTouchingPaddle()
    return self.touching_paddle
end