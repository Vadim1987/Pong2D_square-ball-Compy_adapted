-- strategy.lua
-- opponent behavior module

strategy = { }

-- fast AI (hard)
function strategy.hard(S, dt)
  local b, p = S.ball, S.opp
  local y_diff = (b.y + BALL_SIZE/2) - (p.y + PADDLE_HEIGHT/2)
  local dy = (math.abs(y_diff) > AI_DEADZONE) and 
    (y_diff > 0 and 1 or -1) * PADDLE_SPEED or 0
  move_paddle(p, 0, dy, dt, false)
end

-- slow AI (easy)
function strategy.easy(S, dt)
  local b, p = S.ball, S.opp
  local y_diff = (b.y + BALL_SIZE/2) - (p.y + PADDLE_HEIGHT/2)
  local dy = (math.abs(y_diff) > AI_DEADZONE) and 
    (y_diff > 0 and 1 or -1) * (PADDLE_SPEED * 0.6) or 0
  move_paddle(p, 0, dy, dt, false)
end

-- Manual (second player): 2D enabled
function strategy.manual(S, dt)
  local tx, ty = 0, 0
  for key, dir in pairs(INPUT_P2) do
    if love.keyboard.isDown(key) then
      tx = tx + dir.x
      ty = ty + dir.y
    end
  end
  move_paddle(S.opp, tx * PADDLE_SPEED, ty * PADDLE_SPEED, dt, false)
end