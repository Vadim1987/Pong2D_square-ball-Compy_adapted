-- main.lua
-- Entry point, State Management, and Game Loop

require("constants")
require("physics")
require("strategy")

audio = compy.audio
gfx = love.graphics
timer = love.timer

-- Game State 

GS = {
  init = false,
  mode = "start",
  input = "mouse",
  tf = nil
}

GS.assets = {
  canvas = nil,
  text_player = nil,
  text_opponent = nil,
  text_info = nil,
  text_mode = nil
}

GS.score = {
  player = 0,
  opponent = 0
}
GS.mouse = {
  x = 0,
  y = 0
}
GS.ai = strategy.hard

--  Entities 

GS.player = {
  x = 0,
  y = 0,
  dx = 0,
  dy = 0,
  w = PADDLE.w,
  h = PADDLE.h,
  limits = LIMITS.player
}

GS.opponent = {
  x = 0,
  y = 0,
  dx = 0,
  dy = 0,
  w = PADDLE.w,
  h = PADDLE.h,
  limits = LIMITS.opp
}

GS.ball = {
  x = 0,
  y = 0,
  dx = 0,
  dy = 0,
  w = BALL.size,
  h = BALL.size,
  sx = 0,
  sy = 0,
  st = 0
}

GS.paddles = {
  GS.player,
  GS.opponent
}

--  Helpers 

function update_scale()
  local w, h = gfx.getDimensions()
  local sx = w / GAME.width
  local sy = h / GAME.height
  GS.tf = love.math.newTransform():scale(sx, sy)
end

function sync_phys(now)
  local b = GS.ball
  b.sx, b.sy, b.st = b.x, b.y, now
end

function move_ball_time(t_target)
  local b = GS.ball
  local dt = t_target - b.st
  b.x = b.sx + b.dx * dt
  b.y = b.sy + b.dy * dt
end

function reset_ball_pos()
  local b = GS.ball
  b.x = LAYOUT.serve_off_x - (b.w / 2)
  b.y = (GAME.height - b.h) / 2
  b.dx, b.dy = 0, 0
end

function get_strat_name()
  local ai = GS.ai
  if ai == strategy.hard then
    return "1 Player (hard)"
  end
  if ai == strategy.easy then
    return "1 Player (easy)"
  end
  return "2 Players (keyboard)"
end

function update_ui()
  GS.assets.text_player:set(GS.score.player)
  GS.assets.text_opponent:set(GS.score.opponent)
  GS.assets.text_mode:set(get_strat_name())
end

function reset_round(now)
  GS.player.x = LIMITS.player.min
  GS.player.y = LAYOUT.pad_start_y
  GS.opponent.x = LIMITS.opp.max
  GS.opponent.y = LAYOUT.pad_start_y
  reset_ball_pos()
  sync_phys(now)
end

-- Init 

function init_canvas()
  local c = gfx.newCanvas(GAME.width, GAME.height)
  gfx.setCanvas(c)
  gfx.setColor(COLORS.fg)
  local cx = (GAME.width / 2) - (GRID.width / 2)
  local y = 0
  while y < GAME.height do
    gfx.rectangle("fill", cx, y, GRID.width, GRID.dash)
    y = y + GRID.dash + GRID.gap
  end
  gfx.setCanvas()
  return c
end

function init_assets()
  local f = gfx.getFont()
  GS.assets.text_info = gfx.newText(f, "Press Space to Start")
  GS.assets.text_player = gfx.newText(f, "0")
  GS.assets.text_opponent = gfx.newText(f, "0")
  GS.assets.text_mode = gfx.newText(f, "")
  GS.assets.canvas = init_canvas()
  update_ui()
end

function ensure_init()
  if GS.init then
    return 
  end
  update_scale()
  init_assets()
  reset_round(timer.getTime())
  GS.init = true
  love.mouse.setRelativeMode(true)
end

-- Logic 

function constrain(p)
  p.y = math.max(0, math.min(p.y, LIMITS.y_max))
  p.x = math.max(p.limits.min, math.min(p.x, p.limits.max))
end

function process_input(dt)
  local p = GS.player
  if GS.input == "mouse" then
    p.dx = GS.mouse.x / dt
    p.dy = GS.mouse.y / dt
    GS.mouse.x, GS.mouse.y = 0, 0
  else
    local k = love.keyboard.isDown
    local dy = (k("a") and 1 or 0) - (k("q") and 1 or 0)
    local dx = (k("d") and 1 or 0) - (k("s") and 1 or 0)
    p.dx = dx * PADDLE.speed
    p.dy = dy * PADDLE.speed
  end
end

function update_pads(dt)
  GS.player.dx, GS.player.dy = 0, 0
  process_input(dt)
  GS.ai(GS.opponent, GS.ball, dt)
  for _, p in ipairs(GS.paddles) do
    p.x = p.x + p.dx * dt
    p.y = p.y + p.dy * dt
    constrain(p)
  end
end

--  Physics Loop 

function find_collision(dt)
  local best = { time = nil }
  for _, p in ipairs(GS.paddles) do
    local t, nx, ny = detect(GS.ball, p, dt)
    if t and (not best.time or t < best.time) then
      best = {
        time = t,
        nx = nx,
        ny = ny,
        paddle = p
      }
    end
  end
  return best
end

function process_collision(col, t_sim)
  local t_imp = t_sim + col.time
  move_ball_time(t_imp)
  resolve(GS.ball, col.paddle, col.nx, col.ny)
  audio.shot()
  sync_phys(t_imp)
end

function check_bounds(now)
  local b = GS.ball
  local y_lim = GAME.height - b.h
  if b.y < 0 or b.y > y_lim then
    b.y = math.max(0, math.min(b.y, y_lim))
    b.dy = -b.dy 
    sync_phys(now)
    audio.knock()
  end
end

-- Scoring 

function handle_game_over()
  GS.mode = "over"
  GS.assets.text_info:set("Game Over")
  audio.gameover()
  love.mouse.setRelativeMode(false)
end

function process_win(win, now)
  GS.score[win] = GS.score[win] + 1
  update_ui()
  if GAME.score_win <= GS.score[win] then
    handle_game_over()
  else
    audio.win()
    reset_round(now)
  end
end

function check_score(now)
  local x = GS.ball.x
  local win = nil
  if x < 0 then
    win = "opponent"
  end
  if GAME.width < x then
    win = "player"
  end
  if win then
    process_win(win, now)
  end
end

function update_ball(dt, now)
  local t_sim = now - dt
  sync_phys(t_sim)
  local col = find_collision(dt)
  if col.time then
    process_collision(col, t_sim)
  end
  move_ball_time(now)
  check_bounds(now)
  check_score(now)
end

-- Controls 

actions = {
  start = { },
  play = { },
  over = { }
}

function actions.start.space()
  GS.mode = "play"
  love.mouse.setRelativeMode(true)
  reset_round(timer.getTime())
  audio.beep()
end

actions.start["e"] = function()
  local is_h = (GS.ai == strategy.hard)
  GS.ai = is_h and strategy.easy or strategy.hard
  GS.input = "mouse"
  update_ui()
  audio.toggle()
end

actions.start["1"] = actions.start["e"]

actions.start["2"] = function()
  GS.ai = strategy.manual
  GS.input = "keyboard"
  update_ui()
  audio.toggle()
end

function actions.play.r()
  GS.score.player = 0
  GS.score.opponent = 0
  update_ui()
  reset_round(timer.getTime())
  GS.mode = "start"
  GS.assets.text_info:set("Press Space to Start")
  love.mouse.setRelativeMode(false)
end

actions.over.space = actions.play.r

for k, v in pairs(actions) do
  v.escape = love.event.quit
end

-- Drawing

function draw_objs()
  gfx.draw(GS.assets.canvas, 0, 0)
  for _, p in ipairs(GS.paddles) do
    gfx.rectangle("fill", p.x, p.y, p.w, p.h)
  end
  local b = GS.ball
  gfx.rectangle("fill", b.x, b.y, b.w, b.h)
end

function draw_scores()
  local txt = GS.assets.text_player
  local wp = txt:getWidth()
  local cx = GAME.width / 2
  local y_off = GAME.score_off_y
  gfx.draw(txt, (cx - 60) - wp / 2, y_off)
  gfx.draw(GS.assets.text_opponent, cx + 40, y_off)
end

function draw_info()
  if GS.mode == "play" then
    return 
  end
  local ti = GS.assets.text_info
  local tm = GS.assets.text_mode
  local xi = (GAME.width - ti:getWidth()) / 2
  local yi = GAME.height * 0.4 - ti:getHeight() / 2
  gfx.draw(ti, xi, yi)
  local xm = (GAME.width - tm:getWidth()) / 2
  local ym = GAME.height * 0.6 - tm:getHeight() / 2
  gfx.draw(tm, xm, ym)
end

function draw_ui()
  draw_scores()
  draw_info()
end

-- Main Loop 

function love.update(dt)
  ensure_init()
  if GS.mode ~= "play" then
    return 
  end
  local now = timer.getTime()
  local sdt = dt * GAME.speed_scale
  update_pads(sdt)
  update_ball(sdt, now)
end

function love.draw()
  if not GS.init then
    return 
  end
  gfx.push()
  gfx.applyTransform(GS.tf)
  gfx.clear(COLORS.bg)
  gfx.setColor(COLORS.fg)
  draw_objs()
  draw_ui()
  gfx.pop()
end

function love.mousemoved(x, y, dx, dy)
  if GS.mode == "play" then
    GS.mouse.x = GS.mouse.x + dx
    GS.mouse.y = GS.mouse.y + dy
  end
end

function love.keypressed(k)
  local action = actions[GS.mode][k]
  if action then
    action()
  end
end

function love.resize(w, h)
  if GS.init then
    update_scale()
  end
end
