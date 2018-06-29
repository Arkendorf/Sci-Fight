mainmenu = require "mainmenu"
game = require "game"
gui = require "gui"
enet = require "enet"
sock = require "sock"
menu = require "menu"
wipe = require "wipe"

love.load = function()
  graphics.load()
  gui.load()

  mainmenu.load()
  menu.load()
  game.load()

  state = "mainmenu"
  mainmenu.start()
end

love.update = function(dt)
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
  end
  gui.update(dt)
  if server then
    server:update()
  end
  if client then
    client:update()
  end
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
  end
  gui.draw()
  wipe.draw()
  love.graphics.setCanvas()
  love.graphics.draw(screen.canvas, screen.x, screen.y, 0, screen.scale, screen.scale)

  love.graphics.print(love.timer.getFPS(), 0, 0, 0, 2, 2)
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
