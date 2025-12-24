-- physics.lua

-- 0. TOOLS

function get_axis(obj, axis)
  return obj.pos[axis], obj.size[axis], obj.vel[axis]
end

-- HELPER: PREDICT

function predict(obj, getter, axis, time_offset)
  local pos, size, vel = getter(obj, axis)
  return pos + vel * time_offset, size, vel
end

-- STEP 1: START POSITIONS

function get_start_state(ball, pad, getter, axis, dt)
  local b_pos, b_size, b_vel = getter(ball, axis)
  local p_pos, p_size, p_vel = getter(pad, axis)
  return b_pos, b_size, b_vel, p_pos, p_size, p_vel
end

-- STEP 2: MEASURE GAPS

function get_gaps(pos_a, size_a, pos_b, size_b)
  return pos_b - (pos_a + size_a), (pos_b + size_b) - pos_a
end

-- STEP 3: CALCULATE TIME

function select_gap(gap_front, gap_back, velocity)
  if 0 < velocity then
    return gap_front
  end
  if velocity < 0 then
    return gap_back
  end
  return nil
end

function calc_time(distance, velocity, dt)
  if not distance then
    return nil
  end
  local time = distance / velocity
  return (0 <= time and time <= dt) and time or nil
end

-- STEP 4: CALCULATE AXIS IMPACT

function calc_axis_impact(ball, pad, getter, axis, dt)
  local b_pos, b_size, b_vel, p_pos, p_size, p_vel = 
      get_start_state(ball, pad, getter, axis, dt)
  local v_rel = b_vel - p_vel
  local gap_front, gap_back = get_gaps(
    b_pos,
    b_size,
    p_pos,
    p_size
  )
  local dist = select_gap(gap_front, gap_back, v_rel)
  return calc_time(dist, v_rel, dt), v_rel
end

-- STEP 5: VERIFY OVERLAP

function verify_overlap(ball, pad, getter, axis, time)
  local b_pos, b_size = predict(ball, getter, axis, time)
  local p_pos, p_size = predict(pad, getter, axis, time)
  return b_pos < p_pos + p_size and p_pos < b_pos + b_size
end

-- STEP 6: BOUNCE

function bounce(ball, pad, nx, ny)
  local rvx = ball.vel.x - pad.vel.x
  local rvy = ball.vel.y - pad.vel.y
  local dot = (rvx * nx) + (rvy * ny)
  ball.vel.x = ball.vel.x - (2 * dot * nx)
  ball.vel.y = ball.vel.y - (2 * dot * ny)
end

-- FINAL: PICK WINNER

function pick_earliest(tx, nx, ty, ny)
  if ty and (not tx or ty < tx) then
    return ty, 0, ny
  end
  if tx then
    return tx, nx, 0
  end
end

-- MAIN DETECT PIPELINE

function detect(ball, pad, dt)
  local tx, vx = calc_axis_impact(ball, pad, get_axis, "x", dt)
  if tx and not verify_overlap(ball, pad, get_axis, "y", tx)
       then
    tx = nil
  end
  local nx = tx and ((0 < vx) and -1 or 1) or 0
  local ty, vy = calc_axis_impact(ball, pad, get_axis, "y", dt)
  if ty and not verify_overlap(ball, pad, get_axis, "x", ty)
       then
    ty = nil
  end
  local ny = ty and ((0 < vy) and -1 or 1) or 0
  return pick_earliest(tx, nx, ty, ny)
end
