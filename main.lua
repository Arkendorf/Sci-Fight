mainmenu = require "mainmenu"
game = require "game"
gui = require "gui"
enet = require "enet"
sock = require "sock"
menu = require "menu"
wipe = require "wipe"
sidebar = require "sidebar"
custom = require "custom"
mapselect = require "mapselect"
abilities = require "abilities"
weapons = require "weapons"

love.load = function()
  graphics.load()
  gui.load()

  mapselect.load()
  mainmenu.load()
  menu.load()
  game.load()
  custom.load()


  state = "mainmenu"
  mainmenu.start()
  global_dt = 0
end

love.update = function(dt)
  global_dt = dt
  if server then
    server:update()
  end
  if client then
    client:update()
  end
  if state == "mainmenu" then
    mainmenu.update(dt)
  elseif state == "clientmenu" then
    clientmenu.update(dt)
  elseif state == "servermenu" then
    servermenu.update(dt)
  elseif state == "clientgame" then
    clientgame.update(dt)
  elseif state == "servergame" then
    servergame.update(dt)
  elseif state == "custom" then
    custom.update(dt)
  end
  gui.update(dt)
  wipe.update(dt)
end

love.draw = function()
  love.graphics.setCanvas(screen.canvas)
  love.graphics.clear()
  if state == "mainmenu" then
    mainmenu.draw()
  elseif state == "clientmenu" then
    clientmenu.draw()
  elseif state == "servermenu" then
    servermenu.draw()
  elseif state == "clientgame" then
    clientgame.draw()
  elseif state == "servergame" then
    servergame.draw()
  elseif state == "custom" then
    custom.draw()
  end
  gui.draw()
  wipe.draw()
  love.graphics.setCanvas()
  love.graphics.draw(screen.canvas, screen.x, screen.y, 0, screen.scale, screen.scale)

  love.graphics.print(love.timer.getFPS(), 0, 0, 0, 2, 2)
end

love.mousepressed = function(x, y, button)
  if state == "servergame" then
    servergame.mousepressed(x, y, button)
  elseif state == "clientgame" then
    clientgame.mousepressed(x, y, button)
  end
  gui.mousepressed(x, y, button)
end

love.mousereleased = function(x, y, button)
  if state == "servergame" then
    servergame.mousereleased(x, y, button)
  elseif state == "clientgame" then
    clientgame.mousereleased(x, y, button)
  end
end

love.keypressed = function(key)
  if state == "servergame" then
    servergame.keypressed(key)
  elseif state == "clientgame" then
    clientgame.keypressed(key)
  end
  gui.keypressed(key)
end

love.keyreleased = function(key)
  if state == "servergame" then
    servergame.keyreleased(key)
  elseif state == "clientgame" then
    clientgame.keyreleased(key)
  end
end

love.textinput = function(text)
  gui.textinput(text)
end

love.quit = function()
  if state == "clientmenu" then
    clientmenu.quit()
  elseif state == "servermenu" then
    servermenu.quit()
  elseif state == "clientgame" then
    clientgame.quit()
  elseif state == "servergame" then
    servergame.quit()
  end
end
