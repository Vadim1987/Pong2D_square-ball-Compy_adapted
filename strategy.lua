-- strategy.lua
strategy = { }

-- fast AI (hard)
function strategy.hard(S, dt)
  local b = S.ball
  local p = S.opp
  local y_diff = (b.y + BALL_SIZE / 2) - 
    (p.y + PADDLE_HEIGHT / 2)
  local dy = (AI_DEADZONE < math.abs(y_diff))
       and (0 < y_diff and 1 or -1) * PADDLE_SPEED or 0
  p.dx = 0
  p.dy = dy
  apply_velocity(p, dt)
  clamp_paddle(p, false)
end

-- slow AI (easy)
function strategy.easy(S, dt)
  local b = S.ball
  local p = S.opp
  local y_diff = (b.y + BALL_SIZE / 2) - 
    (p.y + PADDLE_HEIGHT / 2)
  local dy = (AI_DEADZONE < math.abs(y_diff))
       and (0 < y_diff and 1 or -1) * (PADDLE_SPEED * 0.6) or 0
  p.dx = 0
  p.dy = dy
  apply_velocity(p, dt)
  clamp_paddle(p, false)
end

-- Manual (second player)
function strategy.manual(S, dt)
  local tx = 0
  local ty = 0
  for key, dir in pairs(INPUT_P2) do
    if love.keyboard.isDown(key) then
      tx = tx + dir.x
      ty = ty + dir.y
    end
  end
  S.opp.dx = tx * PADDLE_SPEED
  S.opp.dy = ty * PADDLE_SPEED
  apply_velocity(S.opp, dt)
  clamp_paddle(S.opp, false)
end
