map = require "map"
graphics = require "graphics"
player = require "player"
collision = require "collision"
shader = require "shader"

love.load = function()
  map.load()
  graphics.load()
  player.load()
end

love.update = function(dt)
  player.update(dt)

  queue = {}
  player.queue()
  map.update_mask()
end

love.draw = function()
  map.draw()
end

love.keypressed = function(key)
  player.keypressed(key)
end
