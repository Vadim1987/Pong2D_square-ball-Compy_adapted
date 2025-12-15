-- physics.lua

PhysicsLogic = { }

PhysicsMetatable = { __index = PhysicsLogic }
Physics = { }
setmetatable(Physics, PhysicsMetatable)

function PhysicsLogic.get_overlap(center_a, center_b, size_a, size_b)
  local half_size = (size_a + size_b) / 2
  local dist = math.abs(center_a - center_b)
  return half_size - dist
end

function PhysicsLogic.get_normal(ball, paddle)
  local ball_cx = ball.x + BALL_SIZE / 2
  local ball_cy = ball.y + BALL_SIZE / 2
  local pad_cx = paddle.x + PADDLE_WIDTH / 2
  local pad_cy = paddle.y + PADDLE_HEIGHT / 2
  local overlap_x = PhysicsLogic.get_overlap(ball_cx, pad_cx, BALL_SIZE, PADDLE_WIDTH)
  local overlap_y = PhysicsLogic.get_overlap(ball_cy, pad_cy, BALL_SIZE, PADDLE_HEIGHT)
  if overlap_x < overlap_y then
    return (ball_cx > pad_cx and 1 or -1), 0, overlap_x
  else
    return 0, (ball_cy > pad_cy and 1 or -1), overlap_y
  end
end

function PhysicsLogic.apply_bounce(ball, paddle, norm_x, norm_y)
  local rel_vx = ball.dx - paddle.dx
  local rel_vy = ball.dy - paddle.dy
  local dot_prod = rel_vx * norm_x + rel_vy * norm_y
  if dot_prod <= 0 then
    ball.dx = ball.dx - 2 * dot_prod * norm_x
    ball.dy = ball.dy - 2 * dot_prod * norm_y
    return true
  end
  return false
end

function PhysicsLogic.resolve_collision(ball, paddle, time, sync_fn)
  if not (ball.x < paddle.x + PADDLE_WIDTH and ball.x + BALL_SIZE > paddle.x and
          ball.y < paddle.y + PADDLE_HEIGHT and ball.y + BALL_SIZE > paddle.y) then
     return false 
  end
  local norm_x, norm_y, depth = PhysicsLogic.get_normal(ball, paddle)
  ball.x = ball.x + norm_x * depth
  ball.y = ball.y + norm_y * depth
  if PhysicsLogic.apply_bounce(ball, paddle, norm_x, norm_y) then
    sync_fn(ball, time)
    return true
  end
  return false
end
