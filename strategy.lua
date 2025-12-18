-- strategy.lua
-- opponent behavior module

strategy = { }

-- fast AI (hard)
function strategy.hard(S, dt)
  local c = S.opp.y + PADDLE_HEIGHT / 2
  local by = S.ball.y + BALL_SIZE / 2
  local d = by - c
  if math.abs(d) < AI_DEADZONE then
    S.opp.dy = 0
  else
    local dir = (0 < d) and 1 or -1
    move_paddle(S.opp, 0, dir, dt)
  end
end

-- slow AI (easy)
function strategy.easy(S, dt)
  local c = S.opp.y + PADDLE_HEIGHT / 2
  local by = S.ball.y + BALL_SIZE / 2
  local d = by - c
  if math.abs(d) < AI_DEADZONE then
    S.opp.dy = 0
  else
    local dir = (0 < d) and 1 or -1
    move_paddle(S.opp, 0, dir, dt)
  end
end

-- Manual (second player)
function strategy.manual(S, dt)
  local dx, dy = 0, 0
  if love.keyboard.isDown("left") then
    dx = -1
  elseif love.keyboard.isDown("right") then
    dx = 1
  end
  if love.keyboard.isDown("up") then
    dy = -1
  elseif love.keyboard.isDown("down") then
    dy = 1
  end
  move_paddle_xy(S.opp, dx, dy, dt)
end