-- physics.lua

-- 1. Helper: Extract state (pos, size, vel) for a specific axis

function get_axis_state(obj, ax, dt)
  local is_x = (ax == "x")
  local vel = is_x and obj.dx or obj.dy
  local sz = is_x and obj.w or obj.h
  return obj[ax] - vel * dt, sz, vel
end

-- 2. Logic: Calculate distance to impact (Gap)

function get_impact_dist(b_pos, b_sz, p_pos, p_sz, v_rel)
  if 0 < v_rel then
    return p_pos - (b_pos + b_sz)
  end
  if v_rel < 0 then
    return (p_pos + p_sz) - b_pos
  end
  return nil
end

-- 3. Logic: Calculate Time of Impact (TOI)

function calc_time(dist, v_rel, dt)
  if not dist then
    return nil
  end
  local t = dist / v_rel
  return (0 <= t and t <= dt) and t or nil
end

-- 4. Logic: Verify overlap on the orthogonal axis

function verify_orth(ball, pad, orth, t, dt)
  local b_pos, b_sz, b_v = get_axis_state(ball, orth, dt)
  local p_pos, p_sz, p_v = get_axis_state(pad, orth, dt)
  local b_fut, p_fut = b_pos + b_v * t, p_pos + p_v * t
  return b_fut < p_fut + p_sz and p_fut < b_fut + b_sz
end

-- 5a. Helper: Calculate potential Time & Velocity on main axis

function calc_axis_impact(ball, pad, ax, dt)
  local b_pos, b_sz, b_v = get_axis_state(ball, ax, dt)
  local p_pos, p_sz, p_v = get_axis_state(pad, ax, dt)
  local v_rel = b_v - p_v
  local dist = get_impact_dist(b_pos, b_sz, p_pos, p_sz, v_rel)
  return calc_time(dist, v_rel, dt), v_rel
end

-- 5b. Coordinator: Verify collision on specific Axis

function check_axis(ball, pad, ax, orth, dt)
  local t, v_rel = calc_axis_impact(ball, pad, ax, dt)
  if t and verify_orth(ball, pad, orth, t, dt) then
    return t, (0 < v_rel and -1 or 1)
  end
end

-- 6a. Helper: Pick the earliest collision (Winner takes all)

function pick_earliest(tx, nx, ty, ny)
  if ty and (not tx or ty < tx) then
    return ty, 0, ny
  end
  if tx then
    return tx, nx, 0
  end
end

-- 6b. Main Detect Function

function detect(ball, pad, dt)
  local tx, nx = check_axis(ball, pad, "x", "y", dt)
  local ty, ny = check_axis(ball, pad, "y", "x", dt)
  return pick_earliest(tx, nx, ty, ny)
end

-- Resolve Bounce

function resolve(ball, pad, nx, ny)
  if nx ~= 0 then
    ball.dx = (2 * pad.dx) - ball.dx
  end
  if ny ~= 0 then
    ball.dy = (2 * pad.dy) - ball.dy
  end
end
