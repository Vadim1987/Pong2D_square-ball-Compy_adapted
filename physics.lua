-- physics.lua

PHYS_ZERO_PADDLE = {
  dx = 0,
  dy = 0,
  x = 0, 
  y = 0  
}

function phys_dot(ax, ay, bx, by)
  return ax * bx + ay * by
end

function phys_reflect(ball, paddle, nx, ny)
  local rvx = ball.dx - paddle.dx
  local rvy = ball.dy - paddle.dy
  local vn = phys_dot(rvx, rvy, nx, ny)
  if vn >= 0 then
    return false
  end
  ball.dx = ball.dx - 2 * vn * nx
  ball.dy = ball.dy - 2 * vn * ny
  return true
end

function phys_hit_paddle_x(ball, paddle, psx, psy, dt)
  local rvx = ball.dx - paddle.dx
  if rvx == 0 then
    return nil
  end
  local px = psx
  if rvx > 0 then
    px = px - BALL_SIZE
  else
    px = px + PADDLE_WIDTH
  end
  local t = (px - ball.x) / rvx
  if t < 0 or t > dt then
    return nil
  end
  local y_at_t = ball.y + (ball.dy - paddle.dy) * t
  if y_at_t + BALL_SIZE < psy or
     psy + PADDLE_HEIGHT < y_at_t then
    return nil
  end
  local nx = (rvx > 0) and -1 or 1
  return t, nx, 0
end

function phys_hit_paddle_y(ball, paddle, psx, psy, dt)
  local rvy = ball.dy - paddle.dy
  if rvy == 0 then
    return nil
  end
  local py = psy
  if rvy > 0 then
    py = py - BALL_SIZE
  else
    py = py + PADDLE_HEIGHT
  end
  local t = (py - ball.y) / rvy
  if t < 0 or t > dt then
    return nil
  end
  local x_at_t = ball.x + (ball.dx - paddle.dx) * t
  if x_at_t + BALL_SIZE < psx or
     psx + PADDLE_WIDTH < x_at_t then
    return nil
  end
  local ny = (rvy > 0) and -1 or 1
  return t, 0, ny
end

function phys_hit_paddle(ball, paddle, dt)
  local psx = paddle.x - paddle.dx * dt
  local psy = paddle.y - paddle.dy * dt
  local tx, nx, ny = phys_hit_paddle_x(
    ball,
    paddle,
    psx,
    psy,
    dt
  )
  local ty, mx, my = phys_hit_paddle_y(
    ball,
    paddle,
    psx,
    psy,
    dt
  )
  if not tx then
    return ty, mx, my
  end
  if not ty or tx < ty then
    return tx, nx, ny
  end
  return ty, mx, my
end

function phys_ball_wall_y(ball, y, ny)
  ball.y = y
  return phys_reflect(ball, PHYS_ZERO_PADDLE, 0, ny)
end
