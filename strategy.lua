-- strategy.lua

strategy = { }

-- Hard AI
function strategy.hard(p, ball, dt)
  local cy = p.y + p.h / 2
  local by = ball.y + ball.w / 2
  local diff = by - cy
  local deadzone = GAME.ai_deadzone
  if math.abs(diff) < deadzone then
    p.dy = 0
  else
    local dir = (0 < diff) and 1 or -1
    p.dy = PADDLE.speed * dir
  end
end

-- Easy AI
function strategy.easy(p, ball, dt)
  strategy.hard(p, ball, dt)
  p.dy = p.dy * 0.6
end

-- Manual AI
function strategy.manual(p, ball, dt)
  local k = love.keyboard.isDown
  local dx = (k("right") and 1 or 0) - (k("left") and 1 or 0)
  local dy = (k("down")  and 1 or 0) - (k("up")   and 1 or 0)
  p.dx = PADDLE.speed * dx
  p.dy = PADDLE.speed * dy
end