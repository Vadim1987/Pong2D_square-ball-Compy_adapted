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
  local gap_front = function()
    return pos_b - (pos_a + size_a)
  end
  local gap_back = function()
    return (pos_b + size_b) - pos_a
  end
  return gap_front, gap_back
end

function select_gap(gap_front, gap_back, v_rel)
  if 0 < v_rel then
    return gap_front()
  elseif v_rel < 0 then
    return gap_back()
  end
  return nil
end

-- 2. TIME CALCULATION

function calc_time(dist, v, dt)
  if dist then
    local t = dist / v
    if t <= dt and -dt < t then
      return math.max(0, t)
    end
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

function bounce(ball, pad, n)
  local b, p = ball.vel, pad.vel
  local rvx = b.x - p.x
  local rvy = b.y - p.y
  local dot = (rvx * n.x) + (rvy * n.y)
  b.x = b.x - (2 * dot * n.x)
  b.y = b.y - (2 * dot * n.y)
end

-- Chooses the earliest collision from a list of candidates

coll = {
  x = { n = { y = 0 } },
  y = { n = { x = 0 } }
}

colls = {
  coll.x,
  coll.y
}

function resolve_collision(list)
  local earliest = nil
  for _, c in ipairs(list) do
    if c.t and (not earliest or c.t < earliest.t) then
      earliest = c
    end
  end
  if earliest then
    return earliest.t, earliest.n
  end
end

-- 5. COLLISION DETECTION

OTHER = {
  x = "y",
  y = "x"
}

function collide_side(ball, pad, axis, dt)
  local t, v = calc_axis_impact(ball, pad, axis, dt)
  if t and not verify_overlap(ball, pad, OTHER[axis], t) then
    t = nil
  end
  coll[axis].t = t
  coll[axis].n[axis] = tx and ((0 < vx) and -1 or 1) or 0
end

function detect(ball, pad, dt)
  collide_side(ball, pad, "x", dt)
  collide_side(ball, pad, "y", dt)
  return resolve_collision(colls)
end
