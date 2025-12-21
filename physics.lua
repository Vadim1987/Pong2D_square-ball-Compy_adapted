-- physics.lua
-- Vector math and Collision detection

vec = { }
vec.__index = vec

-- Vector Library 

function V(x, y)
  return setmetatable({
    x = x,
    y = y
  }, vec)
end

function vec.__add(a, b)
  return V(a.x + b.x, a.y + b.y)
end

function vec.__sub(a, b)
  return V(a.x - b.x, a.y - b.y)
end

function vec.__mul(v, s)
  return V(v.x * s, v.y * s)
end

function dot(a, b)
  return a.x * b.x + a.y * b.y
end

--  Axis Configurations 

AXIS_X = {
  name = "x",
  ortho = "y",
  size = PADDLE.w,
  depth = PADDLE.h
}
AXIS_Y = {
  name = "y",
  ortho = "x",
  size = PADDLE.h,
  depth = PADDLE.w
}
AXES = {
  AXIS_X,
  AXIS_Y
}

--  Helpers

-- 1. Calculate time (t) and previous state

local function get_impact_data(ball, pad, axis, dt)
  local v_pad = V(pad.dx, pad.dy)
  local prev = V(pad.x, pad.y) - (v_pad * dt)
  local rv = (V(ball.dx, ball.dy) - v_pad)[axis.name]
  local offset = (0 < rv) and -BALL.size or axis.size
  local dist = prev[axis.name] + offset - ball[axis.name]
  return dist / rv, prev
end

-- 2. Check overlap

local function check_overlap(ball_pos, pad_prev, axis)
  local min = pad_prev[axis.ortho]
  local max = min + axis.depth
  return (min <= ball_pos + BALL.size) and (ball_pos <= max)
end

--  Main Solvers 

function solve_impact(ball, pad, axis, dt)
  local t, pad_prev = get_impact_data(ball, pad, axis, dt)
  if not (0 <= t and t <= dt) then
    return nil
  end
  local rel_vel = V(ball.dx, ball.dy) - V(pad.dx, pad.dy)
  local b_ortho = ball[axis.ortho] + rel_vel[axis.ortho] * t
  if not check_overlap(b_ortho, pad_prev, axis) then
    return nil
  end
  local n = (0 < rel_vel[axis.name]) and -1 or 1
  return t, (axis.name == "x" and n or 0), 
    (axis.name == "y" and n or 0)
end

function detect(ball, pad, dt)
  local best_t, best_nx, best_ny
  for _, axis in ipairs(AXES) do
    local t, nx, ny = solve_impact(ball, pad, axis, dt)
    if t and (not best_t or t < best_t) then
      best_t, best_nx, best_ny = t, nx, ny
    end
  end
  return best_t, best_nx, best_ny
end

function resolve(ball, pad, nx, ny)
  local v_ball, v_pad = V(ball.dx, ball.dy), V(pad.dx, pad.dy)
  local n = V(nx, ny)
  local vn = dot(v_ball - v_pad, n)
  if 0 <= vn then
    return 
  end
  local new_v = v_ball - (n * (2 * vn))
  ball.dx, ball.dy = new_v.x, new_v.y
end
