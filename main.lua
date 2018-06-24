map = require "map"
graphics = require "graphics"
player = require "player"
collision = require "collision"

love.load = function()
  map.load()
  graphics.load()
  player.load()
end

love.update = function(dt)
  player.update(dt)
end

love.draw = function()
  queue = {}
  player.draw()
  
  map.draw()
end

love.keypressed = function(key)
  player.keypressed(key)
end
