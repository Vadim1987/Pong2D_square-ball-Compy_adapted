-- physics.lua

-- 0. TOOLS

-- Pre-allocated buffer for corners 

corner_buff = { }
for i = 1, 4 do
  corner_buff[i] = {
    x = 0,
    y = 0
  }
end

-- Projects object properties onto a specific axis ("x" or "y")

function get_projection(obj, axis)
  if obj.radius then
    return obj.pos[axis] - obj.radius, obj.radius * 2, obj.vel[
        axis]
  end
  return obj.pos[axis], obj.size[axis], obj.vel[axis]
end

-- Populates and returns the corner buffer

function get_corners(pad)
  local x, y = pad.pos.x, pad.pos.y
  local w, h = pad.size.x, pad.size.y
  corner_buff[1].x, corner_buff[1].y = x, y
  corner_buff[2].x, corner_buff[2].y = x + w, y
  corner_buff[3].x, corner_buff[3].y = x, y + h
  corner_buff[4].x, corner_buff[4].y = x + w, y + h
  return corner_buff
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

-- Solves linear equation: dist = v * t

function calc_time(dist, v, dt)
  if v == 0 then
    return nil
  end
  local t = dist / v
  return (0 <= t and t <= dt) and t or nil
end

-- Solves quadratic equation: a*t^2 + b*t + c = 0

function solve_quadratic(a, b, c, dt)
  if c <= 0 and b < 0 then
    return 0
  end
  if a == 0 then
    return nil
  end
  local d = b * b - 4 * a * c
  if d < 0 then
    return nil
  end
  local t = (-b - math.sqrt(d)) / (2 * a)
  return (0 <= t and t <= dt) and t or nil
end

-- Prepares coefficients for Circle vs Point collision

function calc_circ_time(ball, pad, cx, cy, dt)
  local rvx = ball.vel.x - pad.vel.x
  local rvy = ball.vel.y - pad.vel.y
  local dx = ball.pos.x - cx
  local dy = ball.pos.y - cy
  local a = rvx * rvx + rvy * rvy
  local b = 2 * (dx * rvx + dy * rvy)
  local c = (dx * dx + dy * dy) - ball.radius ^ 2
  return solve_quadratic(a, b, c, dt)
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
  local b_c = ball.pos[axis] + ball.vel[axis] * t
  local p_min = pad.pos[axis] + pad.vel[axis] * t
  local p_max = p_min + pad.size[axis]
   return b_c >= p_min and b_c <= p_max
end

-- 4. RESOLUTION

function bounce(ball, pad, n)
  local b, p = ball.vel, pad.vel
  local rvx = b.x - p.x
  local rvy = b.y - p.y
  local dot = (rvx * n.x) + (rvy * n.y)
  local vex = b.x - (2 * dot * n.x)
  local vey = b.y - (2 * dot * n.y)
  local k = GAME.elasticity
  local ik = 1 - k
  b.x = (vex * k) + (p.x * ik)
  b.y = (vey * k) + (p.y * ik)
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
  coll[axis].n[axis] = t and ((0 < v) and -1 or 1) or 0
end

corner_pool = { }
corner_idx = 1

for i = 1, 8 do
  corner_pool[i] = {
    t = nil,
    n = {
      x = 0,
      y = 0
    }
  }
end

function add_collision(t, nx, ny)
  if t then
    local c = corner_pool[corner_idx]
    corner_idx = corner_idx + 1
    local l = math.sqrt(nx * nx + ny * ny)
    if l == 0 then
      l = 1
    end
    c.t = t
    c.n.x = nx / l
    c.n.y = ny / l
    table.insert(colls, c)
  end
end

function collide_corner(ball, pad, corner, dt)
  local t = calc_circ_time(ball, pad, corner.x, corner.y, dt)
  if t then
    local bx = ball.pos.x + ball.vel.x * t
    local by = ball.pos.y + ball.vel.y * t
    local cx = corner.x + pad.vel.x * t
    local cy = corner.y + pad.vel.y * t
    add_collision(t, bx - cx, by - cy)
  end
end

function detect(ball, pad, dt)
  corner_idx = 1
  collide_side(ball, pad, "x", dt)
  collide_side(ball, pad, "y", dt)
  for _, c in ipairs(get_corners(pad)) do
    collide_corner(ball, pad, c, dt)
  end
  local t, n = resolve_collision(colls)
  for i = #colls, 3, -1 do
    colls[i] = nil
  end
  return t, n
end
