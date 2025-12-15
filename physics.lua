-- physics.lua
Physics = { }

-- 1. Helper: Математика (Local + Compact)
function get_axis_overlap(c1, size1, c2, size2)
  local limit = (size1 + size2) / 2
  return limit - math.abs(c1 - c2)
end

function apply_bounce(ball, paddle, nx, ny)
  local rvx, rvy = ball.dx - paddle.dx, ball.dy - paddle.dy
  local dot = (rvx * nx) + (rvy * ny)
  if dot > 0 then 
    return false 
  end
  local impulse = -2 * dot
  ball.dx, ball.dy = ball.dx + (impulse * nx), ball.dy + (impulse * ny)
  return true
end

function get_collision_data(ball, paddle)
  local bx, by = ball.x + BALL_SIZE/2, ball.y + BALL_SIZE/2
  local px, py = paddle.x + PADDLE_WIDTH/2, paddle.y + PADDLE_HEIGHT/2
  local ox = get_axis_overlap(bx, BALL_SIZE, px, PADDLE_WIDTH)
  local oy = get_axis_overlap(by, BALL_SIZE, py, PADDLE_HEIGHT)
  if ox <= 0 or oy <= 0 then 
    return nil 
  end
  if ox < oy then 
    return (px < bx and 1 or -1), 0, ox 
  end
  return 0, (py < by and 1 or -1), oy
end

function Physics.resolve_collision(ball, paddle)
  local nx, ny, depth = get_collision_data(ball, paddle)
  if not nx then 
    return false 
  end
  ball.x = ball.x + (nx * depth)
  ball.y = ball.y + (ny * depth)
  return apply_bounce(ball, paddle, nx, ny)
end
local function get_collision_data(ball, paddle)
  local bx, by = ball.x + BALL_SIZE / 2, ball.y + BALL_SIZE / 2
  local px, py = paddle.x + PADDLE_WIDTH / 2, paddle.y + 
      PADDLE_HEIGHT / 2
  local ox = get_axis_overlap(bx, BALL_SIZE, px, PADDLE_WIDTH)
  local oy = get_axis_overlap(by, BALL_SIZE, py, PADDLE_HEIGHT)
  if ox <= 0 or oy <= 0 then
    return nil
  end
  if ox < oy then
    return (px < bx and 1 or -1), 0, ox
  end
  return 0, (py < by and 1 or -1), oy
end