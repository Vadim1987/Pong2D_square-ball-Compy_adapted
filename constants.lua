-- constants.lua
COLORS = {
  bg = {0, 0, 0},
  fg = {1, 1, 1}
}

GAME = {
  width = 640,
  height = 480,
  speed_scale = 1.5,
  score_win = 10,
  score_off_y = 20,
  ai_deadzone = 4
}

GRID = {
  width = 4,
  dash = 10,
  gap = 20
}

PADDLE = {
  w = 10,
  h = 60,
  speed = 180,
  off_x = 0
}

BALL = {
  size = 10,
  sx = 360, 
  sy = 180
}

-- Calculations (local scope now)
gh = GAME.height
pw = PADDLE.w
ph = PADDLE.h
gw = GAME.width
pox = PADDLE.off_x

LAYOUT = {
  pad_start_y = (gh - ph) / 2,
  serve_off_x = gw / 6
}

LIMITS = {
  player = { 
    min = pox, 
    max = (gw / 4) - pw 
  },
  opp = { 
    min = gw - (gw / 4), 
    max = (gw - pox) - pw 
  },
  y_max = gh - ph
}