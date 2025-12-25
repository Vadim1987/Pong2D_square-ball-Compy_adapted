-- physics.lua


-- 0. TOOLS

-- Projects object properties onto a specific axis ("x" or "y")

function get_projection(obj, axis)
  return obj.pos[axis], obj.size[axis], obj.vel[axis]
end

-- Extrapolates position forward in time

function extrapolate(obj, axis, dt)
  local pos, size, vel = get_projection(obj, axis)
  return pos + vel * dt, size, vel
end

-- 1. STATE & GAPS

function get_state(ball, pad, axis)
  local b_pos, b_size, b_vel = get_projection(ball, axis)
  local p_pos, p_size, p_vel = get_projection(pad, axis)
  return b_pos, b_size, b_vel, p_pos, p_size, p_vel
end

function get_gaps(pos_a, size_a, pos_b, size_b)
  return pos_b - (pos_a + size_a), (pos_b + size_b) - pos_a
end

function select_gap(gap_front, gap_back, v_rel)
  if 0 < v_rel then
    return gap_front
  end
  if v_rel < 0 then
    return gap_back
  end
  return nil
end

-- 2. TIME CALCULATION

function calc_time(dist, v, dt)
  if not dist then
    return nil
  end
  local t = dist / v
  if t <= dt and -dt < t then
    return math.max(0, t)
  end
  return nil
end

-- 3. AXIS LOGIC

function calc_axis_impact(ball, pad, axis, dt)
  local b_pos, b_sz, b_v, p_pos, p_sz, p_v = get_state(
    ball,
    pad,
    axis
  )
  local v_rel = b_v - p_v
  local gap_front, gap_back = get_gaps(b_pos, b_sz, p_pos, p_sz)
  local dist = select_gap(gap_front, gap_back, v_rel)
  return calc_time(dist, v_rel, dt), v_rel
end

function verify_overlap(ball, pad, axis, t)
  local b_pos, b_sz = extrapolate(ball, axis, t)
  local p_pos, p_sz = extrapolate(pad, axis, t)
  return b_pos < p_pos + p_sz and p_pos < b_pos + b_sz
end

-- 4. RESOLUTION

-- Reflects ball velocity based on paddle impact

function bounce(ball, pad, nx, ny)
  local b, p = ball.vel, pad.vel
  local rvx = b.x - p.x
  local rvy = b.y - p.y
  local dot = (rvx * nx) + (rvy * ny)
  b.x = b.x - (2 * dot * nx)
  b.y = b.y - (2 * dot * ny)
end

-- Compares impact times on X and Y axes to find the first coll
-- ision

function resolve_collision(t_x, n_x, t_y, n_y)
  if t_y and (not t_x or t_y < t_x) then
    return t_y, 0, n_y
  end
  if t_x then
    return t_x, n_x, 0
  end
end

-- 5. COLLISION DETECTION

function detect(ball, pad, dt)
  local tx, vx = calc_axis_impact(ball, pad, "x", dt)
  if tx and not verify_overlap(ball, pad, "y", tx) then
    tx = nil
  end
  local nx = tx and ((0 < vx) and -1 or 1) or 0
  local ty, vy = calc_axis_impact(ball, pad, "y", dt)
  if ty and not verify_overlap(ball, pad, "x", ty) then
    ty = nil
  end
  local ny = ty and ((0 < vy) and -1 or 1) or 0
  return resolve_collision(tx, nx, ty, ny)
end
