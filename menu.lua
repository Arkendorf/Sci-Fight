clientmenu = require "clientmenu"
servermenu = require "servermenu"

local menu = {}

team_colors = {
  {1, 0, 0},
  {0, 0, 1},
  {0, 1, 0},
  {1, 1, 0},
  {1, 0, 1},
  {0, 1, 1},
}

menu.mode = 1
menu.buttons = {}
menu.player_gui = {}
menu.team_select = false

local menu_imgs = {}

menu.load = function()
  clientmenu.load()
  servermenu.load()

  menu_imgs.back = gui.new_img(5, 256, 192)
end

menu.start = function()
  players = {}
  id = 0
  menu.mode = 1
  menu.start_gui()
end

menu.start_gui = function()
  gui.clear()
  gui.add(1, menu.buttons)
  gui.add(2, menu.player_gui)
end

menu.new_player = function(i, name)
  players[i] = {name = name, ready = false, x = -font:getWidth(name), y = i * 16, left = false, team = 0}
end

menu.update_list = function(dt)
  local start = true
  local i = 0
  for k, v in pairs(players) do
    v.x = graphics.zoom(not v.left, v.x, -font:getWidth(v.name), (screen.w-256)/2+2, dt * 12)
    v.y = v.y + (i*16-v.y) * dt * 12
    if v.left and v.x <= -font:getWidth(v.name)+1 then
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
  elseif menu.mode == 3 then
    mapselect.update(dt)
  end
end

menu.draw_list = function()
  local x = (screen.w-256)/2
  local y = (screen.h-256)/2
  love.graphics.draw(menu_imgs.back, x, y)
  local i = 0
  for k, v in pairs(players) do
    if menu.team_select ~= k then
      if v.team > 0 then
        love.graphics.setColor(team_colors[v.team])
      end
      love.graphics.print(v.name, v.x+5, y+v.y+5)
      love.graphics.setColor(1, 1, 1)
    end
    if v.ready then
      love.graphics.print("Ready", x+251-font:getWidth("Ready"), y+i*16+5)
    end
    i = i + 1
  end
end

menu.draw = function()
  if menu.mode == 2 then
    custom.draw()
  elseif menu.mode == 3 then
    mapselect.draw()
  end
end

menu.swap_mode = function(num)
  if menu.mode ~= num and not players[id].ready then
    wipe.start(menu.mode_start[num])
  end
end

menu.mode_start = {}
menu.mode_start[1] = function()
  menu.mode = 1
  menu.start_gui()
end

menu.mode_start[2] = function()
  menu.mode = 2
  custom.start(menu.buttons)
end

menu.mode_start[3] = function()
  menu.mode = 3
  mapselect.start(menu.buttons)
end

menu.mat = function(num)
  if num == menu.mode then
    return 2
  elseif players[id] and players[id].ready then
    return 3
  else
    return 1
  end
end

menu.readymat = function()
  if not players[id] then
    return 3
  elseif players[id] and players[id].ready then
    return 2
  else
    return 1
  end
end


return menu
