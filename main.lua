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
  -- normal updates
  player.update(dt)

  -- create drawing queue
  queue = {}
  player.queue()

  -- update masks (e.g. layer and shadow)
  map.update_masks()
end

love.draw = function()
  map.draw()
  graphics.draw_queue()
  graphics.draw_shadow_layer()
end

love.keypressed = function(key)
  player.keypressed(key)
end
