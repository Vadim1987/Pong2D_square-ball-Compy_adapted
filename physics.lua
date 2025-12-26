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
  local gap_front_fn = function()
    return pos_b - (pos_a + size_a)
  end
  local gap_back_fn = function()
    return (pos_b + size_b) - pos_a
  end
  return gap_front_fn, gap_back_fn
end

function select_gap(gap_front_fn, gap_back_fn, v_rel)
  if 0 < v_rel then
    return gap_front_fn()
  end
  if v_rel < 0 then
    return gap_back_fn()
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

function bounce(ball, pad, nx, ny)
  local b, p = ball.vel, pad.vel
  local rvx = b.x - p.x
  local rvy = b.y - p.y
  local dot = (rvx * nx) + (rvy * ny)
  b.x = b.x - (2 * dot * nx)
  b.y = b.y - (2 * dot * ny)
end

-- Chooses the earliest collision from a list of candidates

coll_x = { ny = 0 }
coll_y = { nx = 0 }
colls = {
  coll_x,
  coll_y
}

function resolve_collision(list)
  local earliest = nil
  for i = 1, #list do
    local c = list[i]
    if c.t and (not earliest or c.t < earliest.t) then
      earliest = c
    end
  end
  if earliest then
    return earliest.t, earliest.nx, earliest.ny
  end
end

-- 5. COLLISION DETECTION

function detect(ball, pad, dt)
  local tx, vx = calc_axis_impact(ball, pad, "x", dt)
  if tx and not verify_overlap(ball, pad, "y", tx) then
    tx = nil
  end
  coll_x.t = tx
  coll_x.nx = tx and ((0 < vx) and -1 or 1) or 0
  local ty, vy = calc_axis_impact(ball, pad, "y", dt)
  if ty and not verify_overlap(ball, pad, "x", ty) then
    ty = nil
  end
  coll_y.t = ty
  coll_y.ny = ty and ((0 < vy) and -1 or 1) or 0
  return resolve_collision(colls)
end
