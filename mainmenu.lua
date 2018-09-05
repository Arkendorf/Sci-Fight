local mainmenu = {}

local prompts = {{num = 1, active = false, x = 0, y = 0, w = 96, port = "25565", button_x = -128}, {num = 2, active = false, x = 0, y = 0, w = 96, port = "25565", ip = "localhost", button_x = -128}}
local button = {w = 64, h = 48, border = 2}
local textbox = {h = 16}
local button_num = 4

mainmenu.load = function()
  button.x, button.y = (screen.w-(button.w+button.border)*5)/2, (screen.h-button.h+32)/2

  textbox.border = (button.h-textbox.h*2)/3

  prompts[1].x = (screen.w-96-button.h-button.border)/2
  prompts[1].y = button.y+button.h+button.border
  prompts[1].textboxes = {{x = {t = prompts[1], i = "x"}, y = prompts[1].y+(button.h-textbox.h)/2, w = prompts[1].w, h = textbox.h, t = prompts[1], i = "port", sample = "Port", active = {t = prompts[1], i = "active"}}}

  prompts[2].x = (screen.w-96-button.h-button.border)/2
  prompts[2].y = button.y+button.h+button.border
  prompts[2].textboxes = {{x = {t = prompts[2], i = "x"}, y = prompts[2].y+textbox.border, w = prompts[2].w, h = textbox.h, t = prompts[2], i = "ip", sample = "I.P. Address", active = {t = prompts[2], i = "active"}},
                          {x = {t = prompts[2], i = "x"}, y = prompts[2].y+textbox.border*2+textbox.h, w = prompts[2].w, h = textbox.h, t = prompts[2], i = "port", sample = "Port", active = {t = prompts[2], i = "active"}}}

  menu_color = {0, 0, 0}
  text_color = {86/255, 81/255, 116/255}
end

mainmenu.start = function()
  state = "mainmenu"
  gui.clear()
  local buttons = {{txt = "Host",    x = button.x,                            y = button.y, w = button.w, h = button.h, func = mainmenu.prompt, args = {1}, mat = {func = mainmenu.mat, args = {1}}},
                   {txt ="Join",     x = button.x+(button.w+button.border),   y = button.y, w = button.w, h = button.h, func = mainmenu.prompt, args = {2}, mat = {func = mainmenu.mat, args = {2}}},
                   {txt ="Loadouts", x = button.x+(button.w+button.border)*2, y = button.y, w = button.w, h = button.h, func = wipe.start, args = {mainmenu.custom_start}},
                   {txt ="Settings", x = button.x+(button.w+button.border)*3, y = button.y, w = button.w, h = button.h, func = wipe.start, args = {mainmenu.settings_start}},
                   {txt ="Quit",     x = button.x+(button.w+button.border)*4, y = button.y, w = button.w, h = button.h, func = function() love.event.quit() end, args = {}}}
  gui.add(3, buttons)

  for i, v in ipairs(prompts) do
    v.active = false
    gui.add(v.num, {{x = v.x+v.w/2+button.border+button.h, y = v.y, w = button.h, h = button.h, txt = "Start", func = wipe.start, args = {mainmenu.prompt_start[i]}, active = {t = v, i = "active"}}}, v.textboxes)
  end
end

mainmenu.update = function(dt)
end

mainmenu.draw = function()
  love.graphics.draw(logo_img, math.floor((screen.w-467)/2), 16)
end

mainmenu.prompt = function(num)
  if prompts[num].active then
    prompts[num].active = false
  else
    prompts[num].active = true
    for i, v in ipairs(prompts) do
      if i ~= num then
        v.active = false
      end
    end
  end
end

mainmenu.prompt_start = {}
mainmenu.prompt_start[1] = function()
  state = "servermenu"
  servermenu.start(tonumber(prompts[1].port))
end

mainmenu.prompt_start[2] = function()
  state = "clientmenu"
  clientmenu.start(prompts[2].ip, tonumber(prompts[2].port))
end

mainmenu.custom_start = function()
  state = "custom"
  custom.start()
end

mainmenu.settings_start = function()
  state = "settings"
  settings.start()
end

mainmenu.mat = function(num)
  if prompts[num].active then
    return 2
  else
    return 1
  end
end

mainmenu.get_connection_info = function()
  return prompts[1].port, prompts[2].ip, prompts[2].port
end

mainmenu.set_connection_info = function(port1, ip, port2)
  prompts[1].port = port1
  prompts[2].ip = ip
  prompts[2].port = port2
end

return mainmenu
