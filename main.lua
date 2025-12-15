-- main.lua

require "constants"
require "strategy"
require "physics"

sfx = compy.audio
gfx = love.graphics

-- virtual game space
VIRTUAL_W = 640
VIRTUAL_H = 480

MOUSE_SENSITIVITY = 1

-- runtime variables
view_tf = nil
screen_w, screen_h = 0, 0
paddle_max_y = 0
ball_max_y = 0

inited = false
mouse_enabled = false
time_t = 0 

-- game state
S = { }

S.player = { 
  x = PADDLE_OFFSET_X, 
  y = 0,
  dx = 0,
  dy = 0 
}
S.opp = { 
  x = 0, 
  y = 0, 
  dx = 0,
  dy = 0 
}
S.ball = {
  x = 0,
  y = 0,
  x0 = 0,
  y0 = 0,
  t0 = 0,
  dx = BALL_SPEED_X,
  dy = BALL_SPEED_Y
}
S.score = {
  player = 0,
  opp = 0
}
S.state = "start"

S.strategy = { 
  fn = nil, 
  text = nil 
}

DIR_UP = {
  x = 0,  
  y = -1
}
DIR_DOWN = {
  x = 0,  
  y = 1
}
DIR_LEFT  = {
x = -1, 
y = 0
}
DIR_RIGHT = {
x = 1,  
y = 0
}

INPUT_P1 = { 
w = DIR_UP, 
s = DIR_DOWN, 
a = DIR_LEFT, 
d = DIR_RIGHT 
}

INPUT_P2 = { 
up = DIR_UP, 
down = DIR_DOWN, 
left = DIR_LEFT, 
right = DIR_RIGHT 
}

-- ui resources
font = nil
texts = { }
center_canvas = nil

-- screen helpers
function update_view_transform(w, h)
  screen_w = w
  screen_h = h
  local sx = w / VIRTUAL_W
  local sy = h / VIRTUAL_H
  view_tf = love.math.newTransform()
  view_tf:scale(sx, sy)
end

function cache_dims()
  local w = gfx.getWidth()
  local h = gfx.getHeight()
  update_view_transform(w, h)
end

function layout()
  S.player.x = PADDLE_OFFSET_X
  S.player.y = (VIRTUAL_H - PADDLE_HEIGHT) / 2
  S.opp.x = (VIRTUAL_W - PADDLE_OFFSET_X) - PADDLE_WIDTH
  S.opp.y = (VIRTUAL_H - PADDLE_HEIGHT) / 2
end

-- text helpers
function set_text(name, str)
  local old = texts[name]
  if old then 
    old:release() 
  end
  texts[name] = gfx.newText(font, str)
end

function rebuild_score_texts()
  set_text("score_l", tostring(S.score.player))
  set_text("score_r", tostring(S.score.opp))
end

function rebuild_opp_texts()
  set_text("easy", "1 Player (easy)")
  set_text("hard", "1 Player (hard)")
  set_text("manual", "2 Players (keyboard)")
end

-- canvas 
function draw_center_line()
  local x = VIRTUAL_W / 2 - 2
  local step = BALL_SIZE * 2
  local y = 0
  while y < VIRTUAL_H do
    gfx.rectangle("fill", x, y, 4, BALL_SIZE)
    y = y + step
  end
end

function build_center_canvas()
  if center_canvas then 
    center_canvas:release() 
  end
  center_canvas = gfx.newCanvas(VIRTUAL_W, VIRTUAL_H)
  gfx.setCanvas(center_canvas)
  gfx.clear(0, 0, 0, 0)
  gfx.setColor(COLOR_FG)
  draw_center_line()
  gfx.setCanvas()
end

-- initialization
function build_static_texts()
  font = gfx.getFont()
  set_text("start", 
  "Press Space to Start"
)
  set_text("gameover", 
  "Game Over"
)
  rebuild_opp_texts()
  rebuild_score_texts()
end

function set_strategy(name)
  S.strategy.fn = strategy[name]
  S.strategy.text = texts[name]
end

function do_init()
  cache_dims()
  layout()
  reset_ball(love.timer.getTime())
  build_center_canvas()
  build_static_texts()
  time_t = love.timer.getTime()
  inited = true
  set_strategy("hard")
end

-- paddle and ball movement
function apply_velocity(p, dt)
  p.x = p.x + p.dx * dt
  p.y = p.y + p.dy * dt
end

function clamp_paddle(p, is_left)
  local max_y = VIRTUAL_H - PADDLE_HEIGHT
  p.y = math.min(math.max(p.y, 0), max_y)
  local limit = VIRTUAL_W / 2
  local min_x = is_left and 0 or limit
  local max_x = is_left and (limit - PADDLE_WIDTH) or 
  (VIRTUAL_W - PADDLE_WIDTH)
  p.x = math.min(math.max(p.x, min_x), max_x)
end

function check_scored(bx)
  if bx < 0 then 
    return "opp" 
  end
  if VIRTUAL_W < bx + BALL_SIZE then 
    return "player" 
  end
  return nil
end

function sync_ball_state(b, t)
  b.x0, b.y0, b.t0 = b.x, b.y, t
end

function move_ball(b, t) 
  local time_elapsed = t - b.t0
  b.x = b.x0 + b.dx * time_elapsed
  b.y = b.y0 + b.dy * time_elapsed
  if b.y < 0 then
    b.y, b.dy = 0, -b.dy
    sync_ball_state(b, t) 
  end
  if VIRTUAL_H < b.y + BALL_SIZE then
    b.y, b.dy = VIRTUAL_H - BALL_SIZE, -b.dy
    sync_ball_state(b, t) 
  end
end

function scored(side)
  local s = S.score
  s[side] = s[side] + 1
  rebuild_score_texts()
  if WIN_SCORE <= s[side] then
    S.state = "gameover"
    love.mouse.setRelativeMode(false)
    sfx.gameover()
    return true
  end
  sfx.win()
  return false
end

function reset_ball(t) 
  local b = S.ball
  local target_x = VIRTUAL_W / 3
  b.x = target_x - BALL_SIZE / 2
  b.y = (VIRTUAL_H - BALL_SIZE) / 2
  b.dx, b.dy = 0, 0
  sync_ball_state(b, t) 
end

-- control and update
key_actions = { 
  start = { }, 
  play = { }, 
  gameover = { } 
}

function key_actions.start.space()
  S.state = "play"
  love.mouse.setRelativeMode(true)
  reset_ball(love.timer.getTime()) 
  sfx.beep()
end

function key_actions.start.e()
  set_strategy("easy"); 
  sfx.toggle()
end

function key_actions.start.h()
  set_strategy("hard"); 
  sfx.toggle()
end

key_actions.start["1"] = function()
  if S.strategy.fn ~= strategy.easy then 
    set_strategy("hard") 
  end
  sfx.toggle()
end

key_actions.start["2"] = function()
  set_strategy("manual")
  sfx.toggle()
end

function key_actions.play.r()
  S.score.player = 0
  S.score.opp = 0
  rebuild_score_texts()
  layout()
  reset_ball(love.timer.getTime())
  S.state = "start"
  love.mouse.setRelativeMode(false)
end
key_actions.gameover.space = key_actions.play.r
for name in pairs(key_actions) do
  key_actions[name].escape = love.event.quit
end

function love.keypressed(k)
  local action = key_actions[S.state][k]
  if action then action() end
end

function update_player(dt)
  local tx, ty = 0, 0
  for key, dir in pairs(INPUT_P1) do
    if love.keyboard.isDown(key) then 
      tx, ty = tx + dir.x, ty + dir.y 
    end
  end
  S.player.dx, S.player.dy = tx * PADDLE_SPEED, ty * PADDLE_SPEED
  apply_velocity(S.player, dt)
  clamp_paddle(S.player, true)
end

function love.mousemoved(x, y, dx, dy)
  if S.state ~= "play" then 
    return 
  end
  S.player.dy = dy * MOUSE_SENSITIVITY / love.timer.getDelta()
  S.player.y = S.player.y + dy * MOUSE_SENSITIVITY
  clamp_paddle(S.player, true) 
end

-- main step/update
function try_hit(ball, paddle, t)
  if Physics.resolve_collision(ball, paddle) then
    sync_ball_state(ball, t) 
    return true
  end
  return false
end

function step_ball(b, t)
  move_ball(b, t)
  local hit_p = try_hit(b, S.player, t)
  local hit_o = try_hit(b, S.opp, t)
  if hit_p or hit_o then 
    sfx.shot() 
  end
end

function handle_score(t)
  local side = check_scored(S.ball.x)
  if side then
    scored(side)
    reset_ball(t)
    return true
  end
  return false
end

function step_game(dt, t) 
  if S.state ~= "play" then 
    return 
  end
  update_player(dt)
  S.strategy.fn(S, dt)
  step_ball(S.ball, t)
  handle_score(t) 
end

function love.update(dt)
  if not inited then 
    do_init() 
  end 
  if S.state ~= "play" then 
    return 
  end
  update_player(dt)
  S.strategy.fn(S, dt)
  step_ball(S.ball, love.timer.getTime())
  handle_score(love.timer.getTime()) 
end

-- drawing
function draw_bg()
  gfx.clear(COLOR_BG)
  gfx.setColor(COLOR_FG)
end

function draw_paddle(p)
  gfx.rectangle("fill", p.x, p.y, PADDLE_WIDTH, PADDLE_HEIGHT)
end

function draw_ball(b)
  gfx.rectangle("fill", b.x, b.y, BALL_SIZE, BALL_SIZE)
end

function draw_scores()
  gfx.draw(texts.score_l, VIRTUAL_W / 2 - 60, SCORE_OFFSET_Y)
  gfx.draw(texts.score_r, VIRTUAL_W / 2 + 40, SCORE_OFFSET_Y)
end

function draw_centered(text_obj, percent_y)
  if text_obj then
    local y = percent_y * VIRTUAL_H - text_obj:getHeight() / 2
    local x = (VIRTUAL_W - text_obj:getWidth()) / 2
    gfx.draw(text_obj, x, y)
  end
end

function draw_state_texts(s)
  draw_centered(texts[s], 0.4)
  if s == "start" then
    draw_centered(S.strategy.text, 0.6)
  end
end

function love.draw()
  draw_bg()
  gfx.push()
  gfx.applyTransform(view_tf)
  gfx.draw(center_canvas)
  draw_paddle(S.player)
  draw_paddle(S.opp)
  draw_ball(S.ball)
  draw_scores()
  draw_state_texts(S.state)
  gfx.pop()
end

function love.resize(w, h)
  update_view_transform(w, h)
  build_center_canvas()
end
