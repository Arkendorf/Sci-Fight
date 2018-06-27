local mainmenu = {}

local prompts = {{num = 1, active = false, x = -128, y = 0, w = 64, port = "", button_x = -128}, {num = 2, active = false, x = -128, y = 0, w = 96, port = "", ip = "", button_x = -128}}
local button = {w = 64, h = 48, border = 2}
local textbox = {h = 16}

mainmenu.load = function()
  screen = {scale = 2, x = 0, y = 0}
  screen.w = love.graphics.getWidth() / screen.scale
  screen.h = love.graphics.getHeight() / screen.scale
  screen.canvas = love.graphics.newCanvas(screen.w, screen.h)

  textbox.border = (button.h-textbox.h*2)/3
  prompts[1].y = screen.h/2-button.h-button.border/2
  prompts[1].textboxes = {{x = {t = prompts[1], i = "x", o = textbox.border}, y = prompts[1].y+(button.h-textbox.h)/2, w = prompts[1].w-textbox.border*2, h = textbox.h, t = prompts[1], i = "port", sample = "Port"}}

  prompts[2].y = screen.h/2+button.border/2
  prompts[2].textboxes = {{x = {t = prompts[2], i = "x", o = textbox.border}, y = prompts[2].y+textbox.border, w = prompts[2].w-textbox.border*2, h = textbox.h, t = prompts[2], i = "ip", sample = "I.P. Address"},
                          {x = {t = prompts[2], i = "x", o = textbox.border}, y = prompts[2].y+textbox.border*2+textbox.h, w = prompts[2].w-textbox.border*2, h = textbox.h, t = prompts[2], i = "port", sample = "Port"}}

  gui.add(3, {{x = button.border, y = prompts[1].y, w = button.w, h = button.h, txt = "Host", func = mainmenu.prompt, args = {1}},
           {x = button.border, y = prompts[2].y, w = button.w, h = button.h, txt ="Join", func = mainmenu.prompt, args = {2}}}, {})
end

mainmenu.update = function(dt)
  for i, v in ipairs(prompts) do
    v.x = graphics.zoom(v.active, v.x, button.w+button.border-v.w, button.w+button.border*2, dt * 12)
    v.button_x = graphics.zoom(v.active, v.button_x, button.w+button.border-button.h, button.w+v.w+button.border*3, dt * 12)
    if v.x <= button.w+button.border-v.w and gui.menus[v.num] ~= nil then
      gui.remove(v.num)
    end
  end
end

mainmenu.draw = function()
  for i, v in ipairs(prompts) do
    if v.x > button.w+button.border-v.w then
      love.graphics.rectangle("line", v.x, v.y, v.w, button.h)
    end
  end
end

mainmenu.prompt = function(num)
  prompts[num].active = not prompts[num].active
  -- for i, v in ipairs(prompts) do
  --   if i ~= num then
  --     v.active = false
  --   end
  -- end
  if prompts[num].active then
    gui.add(prompts[num].num, {{x = {t = prompts[num], i = "button_x", o = 0}, y = prompts[num].y, w = button.h, h = button.h, txt = "Start", func = mainmenu.start, args = {num}}}, prompts[num].textboxes)
  end
end

mainmenu.start = function(num)
  if num == 1 then
    server = sock.newServer("*", tonumber(prompts[1].port))
    state = "server"
    gui.clear()
  else
    client = sock.newClient(prompts[1].ip, tonumber(prompts[1].port))
    state = "client"
    gui.clear()
  end
end

return mainmenu
