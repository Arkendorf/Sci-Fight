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
endmenu = require "endmenu"
background = require "background"
settings = require "settings"

love.load = function()
  math.randomseed(os.time())
  graphics.load()
  gui.load()
  background.load()

  mapselect.load()
  mainmenu.load()
  menu.load()
  game.load()
  custom.load()
  endmenu.load()
  settings.load()


  state = "mainmenu"
  mainmenu.start()
  global_dt = 0

  -- load saved data
  load_data()
end

love.update = function(dt)
  global_dt = dt
  if server then
    server:update()
  end
  if client then
    client:update()
  end
  background.update(dt)
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
  elseif state == "endmenu" then
    endmenu.update(dt)
  elseif state == "settings" then
    settings.update(dt)
  end
  gui.update(dt)
  wipe.update(dt)
end

love.draw = function()
  love.graphics.setCanvas(screen.canvas)
  love.graphics.clear()
  background.draw()
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
  elseif state == "endmenu" then
    endmenu.draw()
  elseif state == "settings" then
    settings.draw()
  end
  gui.draw()
  wipe.draw()
  love.graphics.setCanvas()
  love.graphics.draw(screen.canvas, screen.x, screen.y, 0, screen.scale, screen.scale)

  love.graphics.print(love.timer.getFPS(), 0, 0, 0, 2, 2)
end

love.mousepressed = function(x, y, button)
  if state == "servermenu" then
    servermenu.mousepressed(x, y, button)
  elseif state == "servergame" then
    servergame.mousepressed(x, y, button)
  elseif state == "clientgame" then
    clientgame.mousepressed(x, y, button)
  elseif state == "settings" then
    settings.mousepressed(x, y, button)
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
  elseif state == "settings" then
    settings.keypressed(key)
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
  save()
end

save = function()
  local str = ""
  -- abilities
  for i, v in ipairs(loadouts) do
    str = str..tostring(v.skin).."\r\n"
    str = str..tostring(v.weapon).."\r\n"
    for j, w in ipairs(v.abilities) do
      str = str..tostring(w).."\r\n"
    end
  end
  -- server / client connection info
  local port1, ip, port2 = mainmenu.get_connection_info()
  str = str..port1.."\r\n"..ip.."\r\n"..port2.."\r\n"
  -- username
  str = str..username[1].."\r\n"
  -- window settings
  str = str..tostring(love.window.getFullscreen()).."\r\n"
  str = str..tostring(screen.scale).."\r\n"
  str = str..tostring(love.graphics.getWidth()).."\r\n"
  str = str..tostring(love.graphics.getHeight()).."\r\n"
  -- controls
  for i, v in ipairs(movement_keys) do
    str = str..tostring(string.sub(v[1], 1, 3))..tostring(v[2]).."\r\n"
  end
  for i, v in ipairs(ability_keys) do
    str = str..tostring(string.sub(v[1], 1, 3))..tostring(v[2]).."\r\n"
  end

  love.filesystem.write("save.txt", str)
end

load_data = function()
  if love.filesystem.getInfo("save.txt") then
    local save_info = {}
    for line in love.filesystem.lines("save.txt") do
      save_info[#save_info+1] = line
    end
    -- load abilities
    for i, v in ipairs(loadouts) do
      v.skin = tonumber(save_info[(i-1)*7+1])
      v.weapon = tonumber(save_info[(i-1)*7+2])
      for j, w in ipairs(v.abilities) do
        v.abilities[j] = tonumber(save_info[(i-1)*7+2+j])
      end
    end
    -- server / client connection info
    local port1, ip, port2 = mainmenu.get_connection_info()
    mainmenu.set_connection_info(save_info[22], save_info[23], save_info[24])
    -- username
    username[1] = save_info[25]
    --controls
    for i, v in ipairs(movement_keys) do
      local info = save_info[29+i]
      if string.sub(info, 1, 3) == "but" then
        v[1] = "button"
      else
        v[1] = "key"
      end
      v[2] = string.sub(info, 4, -1)
    end
    for i, v in ipairs(ability_keys) do
      local info = save_info[29+i]
      if string.sub(info, 1, 3) == "but" then
        v[1] = "button"
      else
        v[1] = "key"
      end
      v[2] = string.sub(info, 4, -1)
    end
  end
end

load_window = function()
  if love.filesystem.getInfo("save.txt") then
    local save_info = {}
    for line in love.filesystem.lines("save.txt") do
      save_info[#save_info+1] = line
    end
    love.window.setMode(save_info[28], save_info[29], {resizable = true})
    if save_info[26] == "true" then
      love.window.setFullscreen(true)
    else
      love.window.setFullscreen(false)
    end
    screen = {scale = tonumber(save_info[27]), x = 0, y = 0}
  end
end
