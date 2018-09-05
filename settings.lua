local settings = {}

local setting_imgs = {}
local submenu = 1
local scroll = {0}
local pos = {x = 0, y = 0, w = 256, h = 192}
local current_control = false

local control_button = {w = 64, h = 32, border = 2}
local name_box = {w = 96, h = 16, border = 2}
local button = {w = 64, h = 32, border = 2}

local submenu_gui = {{}, {}}
local submenu_h = {0, 0}

settings.load = function()
  username = {"Placeholder"}

  ability_keys = {{"button", 1, "Weapon Ability 1"}, {"button", 2, "Weapon Ability 2"}, {"key", "capslock", "Ability 1"}, {"key", "lshift", "Ability 2"}, {"key", "lctrl", "Ability 3"}}
  movement_keys = {{"key", "w", "Move Forward"}, {"key", "a", "Move Left"}, {"key", "s", "Move Backward"}, {"key", "d", "Move Right"}, {"key", "space", "Jump"}}

  pos.x, pos.y = (screen.w-256)/2, (screen.h-256)/2

  -- set up general gui
  submenu_gui[1] = {{}, {}, {}}
  submenu_h[1] = 0
  submenu_gui[1][2][1] = {x = pos.x+pos.w-15-name_box.w, y = {t = scroll, i = 1, o = pos.y+6}, w = name_box.w, h = name_box.h, t = username, i = 1, sample = "Username", range = pos}
  submenu_gui[1][1][1] = {txt = {func = settings.screen_string, args = {}}, x = pos.x+pos.w-15-button.w, y = {t = scroll, i = 1, o = pos.y+6+name_box.h+name_box.border}, w = button.w, h = button.h, func = settings.screen_type, args = {}, range = pos}

  -- set up controls gui
  submenu_gui[2] = {{}, {}, {}}
  for i, v in ipairs(movement_keys) do
    submenu_gui[2][1][i] = {txt = {func = settings.control_string, args = {i}}, x = pos.x+pos.w-15-control_button.w, y = {t = scroll, i = 1, o = pos.y+(control_button.h+control_button.border)*(i-1)+6}, w = control_button.w, h = control_button.h, func = settings.change_control, args = {i}, range = pos}
  end
  for i, v in ipairs(ability_keys) do
    submenu_gui[2][1][i+5] = {txt = {func = settings.control_string, args = {i+5}}, x = pos.x+pos.w-15-control_button.w, y = {t = scroll, i = 1, o = pos.y+(control_button.h+control_button.border)*(i+4)+6}, w = control_button.w, h = control_button.h, func = settings.change_control, args = {i+5}, range = pos}
  end
  submenu_h[2] = 10*(control_button.h+control_button.border)

  setting_imgs.back = gui.new_img(5, pos.w, pos.h)
  setting_canvas = love.graphics.newCanvas(pos.w-10, pos.h-10)
end

settings.start = function()
  gui.clear()
  local buttons = sidebar.new({{txt = "General", func = settings.change_submenu, args = {1}, mat = {func = settings.mat, args = {1}}},
                               {txt ="Controls", func = settings.change_submenu, args = {2}, mat = {func = settings.mat, args = {2}}},
                               {txt ="Leave", func = wipe.start, args = {settings.leave}}})
  gui.add(1, buttons)
  settings.set_submenu(1)
end

settings.update = function(dt)
end

settings.draw = function(dt)
  love.graphics.setCanvas(setting_canvas)
  love.graphics.clear()
  if submenu == 1 then
    love.graphics.print("Username:", 2, 5+scroll[1])
    love.graphics.print("Screen Mode:", 2, 28+scroll[1])
  elseif submenu == 2 then
    for i, v in ipairs(movement_keys) do
      love.graphics.print(v[3]..":", 2, (control_button.h+control_button.border)*(i-1)+12+scroll[1])
    end
    for i, v in ipairs(ability_keys) do
      love.graphics.print(v[3]..":", 2, (control_button.h+control_button.border)*(i+4)+12+scroll[1])
    end
  end
  love.graphics.setCanvas(screen.canvas)
  love.graphics.draw(setting_imgs.back, pos.x, pos.y)
  love.graphics.draw(setting_canvas, pos.x+5, pos.y+5)
end

settings.change_submenu = function(num)
  if submenu ~= num then
    wipe.start(settings.set_submenu, {num})
  end
end

settings.set_submenu = function(num)
  submenu = num
  gui.remove(2)
  local scrolls = {{x = pos.x+pos.w-12, y = pos.y+7, h = pos.h-14, grab_w = 6, value = {t = scroll, i = 1}, min = 0, max = math.max(1, submenu_h[num]/(pos.h-14))-1, scale = -pos.h+18}}
  local buttons, textboxes, infoboxes = unpack(submenu_gui[num])
  gui.add(2, buttons, textboxes, infoboxes, scrolls)
  scroll[1] = 0
end

settings.control_string = function(num)
  local table = movement_keys
  local num2 = num
  if num > #movement_keys then
    table = ability_keys
    num2 = num - #movement_keys
  end
  if current_control and current_control == num then
    return "[---]"
  elseif table[num2][1] == "button" then
    return "Mouse "..string.upper(tostring(table[num2][2]))
  else
    return string.upper(tostring(table[num2][2]))
  end
end

settings.change_control = function(num)
  if not current_control then
    current_control = num
  end
end

settings.screen_string = function()
  if love.window.getFullscreen() then
    return "Fullscreen"
  else
    return "Windowed"
  end
end

settings.screen_type = function()
  love.window.setFullscreen(not love.window.getFullscreen())
  background.res_change()
  settings.start()
end

settings.mat = function(num)
  if num == submenu then
    return 2
  else
    return 1
  end
end

settings.mousepressed = function(x, y, button)
  if current_control then
    local table = movement_keys
    if current_control > #movement_keys then
      table = ability_keys
      current_control = current_control - #movement_keys
    end
    table[current_control][1] = "button"
    table[current_control][2] = button
    current_control = false
  end
end

settings.keypressed = function(key)
  if current_control then
    local table = movement_keys
    if current_control > #movement_keys then
      table = ability_keys
      current_control = current_control - #movement_keys
    end
    table[current_control][1] = "key"
    table[current_control][2] = key
    current_control = false
  end
end

settings.leave = function()
  state = "mainmenu"
  mainmenu.start()
end

return settings
