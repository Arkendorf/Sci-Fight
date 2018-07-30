clientmenu = require "clientmenu"
servermenu = require "servermenu"

local menu = {}

menu.mode = 1
menu.buttons = {}
menu.player_gui = {}

menu.load = function()
  clientmenu.load()
  servermenu.load()
end

menu.start = function()
  players = {}
  id = 0
  menu.mode = 1
  menu.start_gui()
end

menu.start_gui = function()
  gui.clear()
  gui.add(1, menu.buttons, {})
  gui.add(2, menu.player_gui, {})
end

menu.update = function(dt)
end

menu.draw = function()
end

menu.new_player = function(i, name)
  players[i] = {name = name, ready = false, x = -font:getWidth(name), y = i * 16, left = false}
end

menu.update_list = function(dt)
  local start = true
  local i = 0
  for k, v in pairs(players) do
    v.x = graphics.zoom(not v.left, v.x, -font:getWidth(v.name), (screen.w-256)/2+2, dt * 12)
    v.y = v.y + (i*16-v.y) * dt * 12
    if v.left and v.x <= -font:getWidth(v.name) then
      players[k] = nil
    end
    if not v.ready then
      start = false
    end
    i = i + 1
  end
  return start
end

menu.update = function(dt)
  if menu.mode == 2 then
    custom.update(dt)
  end
end

menu.draw_list = function()
  local x = (screen.w-256)/2
  local y = (screen.h-256)/2
  for i = 0, 11 do
    love.graphics.setColor(menu_color)
    love.graphics.rectangle("line", x, y+i*16, 256, 16)
    love.graphics.setColor(1, 1, 1)
  end
  local i = 0
  for k, v in pairs(players) do
    love.graphics.print(v.name, v.x, y+v.y+4)
    if v.ready then
      love.graphics.print("Ready", x+254-font:getWidth("Ready"), y+i*16+4)
    end
    i = i + 1
  end
end

menu.draw = function()
  if menu.mode == 2 then
    custom.draw()
  end
end

menu.swap_mode = function(num)
  if menu.mode ~= num and not players[id].ready then
    if num == 1 then
      wipe.start(menu.start_default)
    elseif num == 2 then
      wipe.start(menu.start_custom)
    end
  end
end

menu.start_default = function()
  menu.mode = 1
  menu.start_gui()
end

menu.start_custom = function()
  menu.mode = 2
  custom.start(menu.buttons)
end

return menu
