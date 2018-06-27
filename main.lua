mainmenu = require "mainmenu"
game = require "game"
gui = require "gui"
enet = require "enet"
sock = require "sock"

love.load = function()
  gui.load()

  mainmenu.load()
  game.load()

  state = "mainmenu"
end

love.update = function(dt)
  if state == "mainmenu" then
    mainmenu.update(dt)
  elseif state == "game" then
    game.update(dt)
  end
  gui.update(dt)
end

love.draw = function()
  love.graphics.setCanvas(screen.canvas)
  love.graphics.clear()
  if state == "mainmenu" then
    mainmenu.draw()
  elseif state == "game" then
    game.draw()
  end
  gui.draw()
  love.graphics.setCanvas()
  love.graphics.draw(screen.canvas, screen.x, screen.y, 0, screen.scale, screen.scale)
end

love.mousepressed = function(x, y, button)
  gui.mousepressed(x, y, button)
end

love.keypressed = function(key)
  gui.keypressed(key)
end

love.textinput = function(text)
  gui.textinput(text)
end
