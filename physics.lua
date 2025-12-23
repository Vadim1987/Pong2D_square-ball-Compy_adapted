-- physics.lua

-- 0. TOOLS (Getters)

function get_x_axis(obj)
  return obj.x, obj.w, obj.dx
end

function get_y_axis(obj)
  return obj.y, obj.h, obj.dy
end

-- HELPER: PREDICT

function predict(obj, getter, time_offset)
  local pos, size, vel = getter(obj)
  return pos + vel * time_offset, size, vel
end

-- STEP 1: START POSITIONS

function get_start_state(ball, pad, getter, dt)
  local b_pos, b_size, b_vel = predict(ball, getter, -dt)
  local p_pos, p_size, p_vel = predict(pad, getter, -dt)
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
function calc_axis_impact(ball, pad, getter, dt)
  local b_pos, b_size, b_vel, p_pos, p_size, p_vel = 
      get_start_state(ball, pad, getter, dt)
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

function verify_overlap(ball, pad, other_getter, time)
  local b_pos, b_size = predict(ball, other_getter, time)
  local p_pos, p_size = predict(pad, other_getter, time)
  return b_pos < p_pos + p_size and p_pos < b_pos + b_size
end

-- STEP 6: BOUNCE

function bounce(ball, pad, nx, ny)
  local rvx = ball.dx - pad.dx
  local rvy = ball.dy - pad.dy
  local dot = (rvx * nx) + (rvy * ny)
  ball.dx = ball.dx - (2 * dot * nx)
  ball.dy = ball.dy - (2 * dot * ny)
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
  local tx, vx = calc_axis_impact(ball, pad, get_x_axis, dt)
  if tx and not verify_overlap(ball, pad, get_y_axis, tx - dt)
       then
    tx = nil
  end
  local nx = tx and ((0 < vx) and -1 or 1) or 0
  local ty, vy = calc_axis_impact(ball, pad, get_y_axis, dt)
  if ty and not verify_overlap(ball, pad, get_x_axis, ty - dt)
       then
    ty = nil
  end
  local ny = ty and ((0 < vy) and -1 or 1) or 0
  return pick_earliest(tx, nx, ty, ny)
end
