-- physics.lua

vec = { }
vec.__index = vec

-- Vectors
function V(x, y)
  return setmetatable({x = x, y = y}, vec)
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

AXES = {
  {
  "x", 
  "y", 
  PADDLE.w, 
  PADDLE.h
},
  {
  "y", 
  "x", 
  PADDLE.h, 
  PADDLE.w
}
}

function solve(b, p, p_old, dt, ax, ay, size_m, size_o)
  local rv = V(b.dx, b.dy) - V(p.dx, p.dy)
  if rv[ax] == 0 then 
    return nil 
  end
  local off = (rv[ax] > 0) and -BALL.size or size_m
  local t = (p_old[ax] + off - b[ax]) / rv[ax]
  if t < 0 or t > dt 
   then return nil 
  end
  local op = b[ay] + rv[ay] * t
  if op + BALL.size < p_old[ay] or 
     p_old[ay] + size_o < op then
    return nil 
  end
  local n = (rv[ax] > 0) and -1 or 1
  return t, (ax=="x" and n or 0), (ax=="y" and n or 0)
end

function detect(b, p, dt)
  local v_p = V(p.dx, p.dy)
  local pos_old = V(p.x, p.y) - (v_p * dt)
  local best_t, best_nx, best_ny 
  for _, c in ipairs(AXES) do
    local ax, ay, sz_m, sz_o = c[1], c[2], c[3], c[4]
    local t, nx, ny = solve(b, p, pos_old, dt, ax, ay, sz_m, sz_o)
    if t and (not best_t or t < best_t) then
      best_t, best_nx, best_ny = t, nx, ny
    end
  end
  return best_t, best_nx, best_ny
end

function resolve(b, p, nx, ny)
  local v_b, v_p = V(b.dx, b.dy), V(p.dx, p.dy)
  local n, rel = V(nx, ny), v_b - v_p
  local vn = dot(rel, n)
   if vn >= 0 then 
    return 
  end
  local new_v = v_b - (n * (2 * vn))
  b.dx, b.dy = new_v.x, new_v.y
end