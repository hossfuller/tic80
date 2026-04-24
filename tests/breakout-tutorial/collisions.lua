function collisions()
  playerWallCollision()
  ballWallCollision()
  ballGroundCollision()
  playerBallCollision()
  ballBrickCollision()
end

function playerWallCollision()
  if player.x < 0 then
    player.x = 0
  elseif player.x + player.width > 240 then
    player.x = 240 - player.width
  end
end

function ballWallCollision()
  if ball.y < 0 then
    -- top
    ball.speed.y = -ball.speed.y
  elseif ball.x < 0 then
    -- left
    ball.speed.x = -ball.speed.x
  elseif ball.x > 240 - ball.width then
    -- right
    ball.speed.x = -ball.speed.x
  end
end

function ballGroundCollision()
  if ball.y > 136 - ball.width then
    -- reset ball
    ball.deactive = true
    -- loss a life
    if lives > 0 then
      lives = lives - 1
    elseif lives == 0 then
      -- game over
      gameOver()
    end
  end
end

function playerBallCollision()
  if collide(player, ball) then
    ball.speed.y = -ball.speed.y
    ball.speed.x = ball.speed.x + 0.3 * player.speed.x
  end
end

function ballBrickCollision()
  for i, brick in pairs(bricks) do
    -- get parameters
    local x = bricks[i].x
    local y = bricks[i].y
    local w = bricks[i].width
    local h = bricks[i].height

    -- check collision
    if collide(ball, bricks[i]) then
      -- collide left or right side
      if y < ball.y and
          ball.y < y + h and
          ball.x < x or
          x + w < ball.x then
        ball.speed.x = -ball.speed.x
      end
      -- collide top or bottom side
      if ball.y < y or
          ball.y > y and
          x < ball.x and
          ball.x < x + w then
        ball.speed.y = -ball.speed.y
      end
      table.remove(bricks, i)
      score = score + 1
    end
  end
end

function collide(a, b)
  -- get parameters from a and b
  local ax = a.x
  local ay = a.y
  local aw = a.width
  local ah = a.height
  local bx = b.x
  local by = b.y
  local bw = b.width
  local bh = b.height

  -- check collision
  if ax < bx + bw and
      ax + aw > bx and
      ay < by + bh and
      ah + ay > by then
    -- collision
    return true
  end
  -- no collision
  return false
end
