clientmenu = require "clientmenu"
servermenu = require "servermenu"

local menu = {}

menu.load = function()
  clientmenu.load()
  servermenu.load()
end

menu.start = function()
  players = {}
  id = 0
end

menu.update = function(dt)
end

menu.draw = function()
end

menu.new_player = function(i, name)
  players[i] = {name = name, ready = false, x = -font:getWidth(name), left = false}
end

menu.update_list = function(dt)
  local start = true
  for k, v in pairs(players) do
    v.x = graphics.zoom(not v.left, v.x, -font:getWidth(v.name), (screen.w-192)/2+2, dt * 12)
    if v.left and v.x <= -font:getWidth(v.name) then
      players[k] = nil
    end
    if not v.ready then
      start = false
    end
  end
  return start
end

menu.draw_list = function()
  local x = (screen.w-192)/2
  local y = (screen.h-48-16*12)/2
  local i = 0
  for k, v in pairs(players) do
    love.graphics.print(v.name, v.x, y+i*16+4)
    if v.ready then
      love.graphics.print("Ready", x+190-font:getWidth("Ready"), y+i*16+4)
    end
    i = i + 1
  end
  for i = 0, 11 do
    love.graphics.rectangle("line", x, y+i*16, 192, 16)
  end
end

menu.start_game = function()
  for k, v in pairs(players) do
    if v.left then
      players[k] = nil
    end
    players[k] = {x = 64, y = 64, z = 0, l = 24, w = 24, h = 24, xV = 0, yV = 0, zV = 0, jump = false}
  end
  state = "game"
  gui.clear()
end

return menu
