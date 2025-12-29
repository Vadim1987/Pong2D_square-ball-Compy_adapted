-- constants.lua
-- Configuration and Layout

COLORS = {
  bg = Color[Color.black],
  fg = Color[Color.white + Color.bright]
}

GAME = {
  width = 640,
  height = 480,
  speed_scale = 1.5,
  score_win = 10,
  score_off_y = 20,
  ai_deadzone = 4,
  elasticity = 0.8
}

GRID = {
  width = 4,
  dash = 10,
  gap = 20
}

PADDLE = {
  size = {
    x = 10,
    y = 60
  },
  speed = 180,
  off_x = 0
}

BALL = { radius = 10 }

-- Dynamic geometry

LAYOUT = {
  pad_start_y = (GAME.height - PADDLE.size.y) / 2,
  serve_pos_player = {
    x = GAME.width / 6,
    y = GAME.height / 2
  }
}

LAYOUT.serve_pos_opp = {
  x = (GAME.width - LAYOUT.serve_pos_player.x),
  y = LAYOUT.serve_pos_player.y
}

LIMITS = {
  player = {
    min = PADDLE.off_x,
    max = (GAME.width / 4) - PADDLE.size.x
  },
  opp = {
    min = GAME.width - (GAME.width / 4),
    max = (GAME.width - PADDLE.off_x) - PADDLE.size.x
  },
  y_max = GAME.height - PADDLE.size.y
}
