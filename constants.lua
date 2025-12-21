-- constants.lua
-- Configuration and Layout

COLORS = {
  bg = {
    0,
    0,
    0
  },
  fg = {
    1,
    1,
    1
  }
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

-- Dynamic geometry of the game field

LAYOUT = {
  pad_start_y = (GAME.height - PADDLE.h) / 2,
  serve_off_x = GAME.width / 6
}

LIMITS = {
  player = {
    min = PADDLE.off_x,
    max = (GAME.width / 4) - PADDLE.w
  },
  opp = {
    min = GAME.width - (GAME.width / 4),
    max = (GAME.width - PADDLE.off_x) - PADDLE.w
  },
  y_max = GAME.height - PADDLE.h
}
