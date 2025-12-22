-- physics.lua
-- Physics logic based on Time of Impact (TOI)

-- physics.lua

physics = { }

-- Helper: Get size based on axis

function physics.get_size(obj, axis)
  if axis == "x" then
    return obj.w
  end
  return obj.h
end

-- Step 1: Position at the start of the frame

function physics.get_start_pos(val, vel, dt)
  return val - vel * dt
end

-- Step 2: Distance between edges (The "Gap")

function physics.get_gap(b_pos, b_size, p_pos, p_size, v_rel)
  if 0 < v_rel then
    return p_pos - (b_pos + b_size)
  end
  if v_rel < 0 then
    return (p_pos + p_size) - b_pos
  end
  return nil
end

-- Step 3: Calculate Time of Impact (TOI)

function physics.calc_time(gap, v_rel, dt)
  if not gap then
    return nil
  end
  local t = gap / v_rel
  if 0 <= t and t <= dt then
    return t
  end
  return nil
end

-- Step 4: Project position to future time 't'

function physics.project_pos(start, vel, t)
  return start + vel * t
end

-- Helper: Simple AABB Overlap check

function physics.is_overlap(pos1, size1, pos2, size2)
  return pos1 < pos2 + size2 and pos2 < pos1 + size1
end

-- Step 5 (Part A): Solve time for one specific axis

function physics.solve_axis_time(ball, pad, axis, dt)
  local bv, pv = ball["d" .. axis], pad["d" .. axis]
  local v_rel = bv - pv
  local b_s = physics.get_start_pos(ball[axis], bv, dt)
  local p_s = physics.get_start_pos(pad[axis], pv, dt)
  local p_size = physics.get_size(pad, axis)
  local gap = physics.get_gap(b_s, ball.w, p_s, p_size, v_rel)
  return physics.calc_time(gap, v_rel, dt), v_rel
end

-- Step 5 (Part B): Verify collision on the OTHER axis

function physics.verify_impact(ball, pad, axis, t, dt)
  local ortho = (axis == "x") and "y" or "x"
  local bv, pv = ball["d" .. ortho], pad["d" .. ortho]
  local b_fut = physics.project_pos(
    ball[ortho] - bv * dt,
    bv,
    t
  )
  local p_fut = physics.project_pos(pad[ortho] - pv * dt, pv, t)
  local size_o = physics.get_size(pad, ortho)
  return physics.is_overlap(b_fut, ball.w, p_fut, size_o)
end

-- Orchestrator: Check specific axis

function physics.check_axis(ball, pad, axis, dt)
  local t, v_rel = physics.solve_axis_time(ball, pad, axis, dt)
  if t and physics.verify_impact(ball, pad, axis, t, dt) then
    local normal = (0 < v_rel) and -1 or 1
    return t, normal
  end
  return nil
end

-- Main detection loop
-- Selects the earliest collision (Winner Takes All pattern)

function detect(ball, pad, dt)
  local tx, nx = physics.check_axis(ball, pad, "x", dt)
  local ty, ny = physics.check_axis(ball, pad, "y", dt)
  local t, final_nx, final_ny = tx, nx, 0
  if ty and (not t or ty < t) then
    t, final_nx, final_ny = ty, 0, ny
  end
  if t then
    return t, final_nx, final_ny
  end
  return nil
end

-- Step 6: Resolve bounce

-- V_new = 2 * V_wall - V_ball

function resolve(ball, pad, nx, ny)
  if nx ~= 0 then
    ball.dx = 2 * pad.dx - ball.dx
  end
  if ny ~= 0 then
    ball.dy = 2 * pad.dy - ball.dy
  end
end
