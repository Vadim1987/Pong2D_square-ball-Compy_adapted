-- physics.lua

-- 0. TOOLS

-- Pre-allocated buffers

V_REL = {
  x = 0,
  y = 0
}
D_VEC = {
  x = 0,
  y = 0
}

CORNER_BUFF = { }
for i = 1, 4 do
  CORNER_BUFF[i] = {
    x = 0,
    y = 0
  }
end

-- Helpers

function get_corners(pad)
  local x, y = pad.pos.x, pad.pos.y
  local w, h = pad.size.x, pad.size.y
  CORNER_BUFF[1].x, CORNER_BUFF[1].y = x, y
  CORNER_BUFF[2].x, CORNER_BUFF[2].y = x + w, y
  CORNER_BUFF[3].x, CORNER_BUFF[3].y = x, y + h
  CORNER_BUFF[4].x, CORNER_BUFF[4].y = x + w, y + h
  return CORNER_BUFF
end

-- Converts vector to Unit Vector (Length = 1)

function normalize(x, y)
  local l = math.sqrt(x * x + y * y)
  return x / l, y / l
end

-- Calculates wall distance 

function get_dist(ball, pad, axis, v)
  local pos_b = ball.pos[axis]
  local pos_p = pad.pos[axis]
  local size_p = pad.size[axis]
  local s = (0 < v) and -1 or 1
  local edge = (0 < v) and pos_p or (pos_p + size_p)
  return (edge + s * ball.radius) - pos_b
end

-- 1. TIME CALCULATION

-- Solves linear intersection (Wall/SIde)

function calc_time(dist, v, dt)
  local t = dist / v
  return (0 <= t and t <= dt) and t or nil
end

-- Solves geometry intersection (Corner)

function calc_circ_time(dx, dy, v, r)
  local v2 = v.x * v.x + v.y * v.y
  local perp = v.x * dy - v.y * dx
  local r2v2 = r * r * v2
  if r2v2 < perp * perp then
    return nil
  end
  local proj = dx * v.x + dy * v.y
  local disc = r2v2 - perp * perp
  if disc < 0 then
    return nil
  end
  return (proj - math.sqrt(disc)) / v2
end

-- 2. AXIS LOGIC

-- Checks if Ball Center lies within Paddle bounds.

function check_center(ball, pad, axis, t)
  local ortho = (axis == "x") and "y" or "x"
  local b_proj = ball.pos[ortho] + ball.vel[ortho] * t
  local p_proj = pad.pos[ortho] + pad.vel[ortho] * t
  if p_proj <= b_proj and b_proj <= p_proj + pad.size[ortho]
       then
    coll[axis].t = t
    coll[axis].n[axis] = (0 < ball.vel[axis] - pad.vel[axis])
         and -1 or 1
    coll[axis].n[ortho] = 0
  end
end

-- 3. RESOLUTION

function bounce(ball, pad, norm)
  local b_vel, p_vel = ball.vel, pad.vel
  local rvx = b_vel.x - p_vel.x
  local rvy = b_vel.y - p_vel.y
  local dot = (rvx * norm.x) + (rvy * norm.y)
  local k = GAME.elasticity
  local ik = 1 - k
  ball.vel.x = (rvx - 2 * dot * norm.x) * k + p_vel.x * ik
  ball.vel.y = (rvy - 2 * dot * norm.y) * k + p_vel.y * ik
end

-- Collision candidates

coll = {
  x = { },
  y = { },
  c = { }
}
coll.x.n = {
  x = 0,
  y = 0
}
coll.y.n = {
  x = 0,
  y = 0
}
coll.c.n = {
  x = 0,
  y = 0
}

colls = {
  coll.x,
  coll.y,
  coll.c
}

function resolve_collision(candidates)
  local best = nil
  for _, c in ipairs(candidates) do
    if c.t and (not best or c.t < best.t) then
      best = c
    end
  end
  return best and best.t, best and best.n
end

-- 4. COLLISION DETECTION

function collide_side(ball, pad, axis, dt)
  local v = ball.vel[axis] - pad.vel[axis]
  local dist = get_dist(ball, pad, axis, v)
  local t = calc_time(dist, v, dt)
  if t then
    check_center(ball, pad, axis, t)
  end
end

function add_corner_hit(t, nx, ny)
  if not coll.c.t or t < coll.c.t then
    coll.c.t = t
    coll.c.n.x, coll.c.n.y = normalize(nx, ny)
  end
end

function collide_corner(ball, pad, corner, dt)
  D_VEC.x = corner.x - ball.pos.x
  D_VEC.y = corner.y - ball.pos.y
  local t = calc_circ_time(D_VEC.x, D_VEC.y, V_REL, ball.radius)
  if t and 0 <= t and t <= dt then
    local bx = ball.pos.x + V_REL.x * t
    local by = ball.pos.y + V_REL.y * t
    add_corner_hit(t, bx - corner.x, by - corner.y)
  end
end

function detect(ball, pad, dt)
  coll.x.t, coll.y.t, coll.c.t = nil, nil, nil
  collide_side(ball, pad, "x", dt)
  collide_side(ball, pad, "y", dt)
  V_REL.x = ball.vel.x - pad.vel.x
  V_REL.y = ball.vel.y - pad.vel.y
  for _, corner in ipairs(get_corners(pad)) do
    collide_corner(ball, pad, corner, dt)
  end
  return resolve_collision(colls)
end
