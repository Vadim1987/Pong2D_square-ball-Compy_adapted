-- strategy.lua
-- AI Logic and Input Handling

strategy = { }

-- 1. Hard AI 

function strategy.hard(pad, ball, dt)
  local pad_cy = pad.pos.y + pad.size.y / 2
  local ball_cy = ball.pos.y
  local diff = ball_cy - pad_cy
  if math.abs(diff) < GAME.ai_deadzone then
    pad.vel.y = 0
  else
    local dir = (0 < diff) and 1 or -1
    pad.vel.y = PADDLE.speed * dir
  end
end

-- 2. Easy AI (Slower reaction)

function strategy.easy(pad, ball, dt)
  strategy.hard(pad, ball, dt)
  pad.vel.y = pad.vel.y * 0.6
end

-- 3. Manual AI

function strategy.manual(pad, ball, dt)
  local is_down = love.keyboard.isDown
  local dx = get_key_direction(is_down, "right", "left")
  local dy = get_key_direction(is_down, "down", "up")
  pad.vel.x = PADDLE.speed * dx
  pad.vel.y = PADDLE.speed * dy
end
