love.keyboard.setKeyRepeat(true)
local gui = {}

local gui_imgs = {}

gui.load = function()
  gui.clear()
end

gui.update = function(dt)
  local m_x, m_y = love.mouse.getPosition()
  for i, v in pairs(gui.menus) do
    for j, w in ipairs(v.buttons) do
      gui.active_update(w, dt)
    end
    for j, w in ipairs(v.textboxes) do
      gui.active_update(w, dt)
    end
    for j, w in ipairs(v.infoboxes) do
      if not w.a then
        w.a = 0
      end
      local w_x, w_y = gui.get_pos(w)
      if m_x >= screen.x+w_x*screen.scale and m_x <= screen.x+(w_x+w.hit.w)*screen.scale and m_y >= screen.y+w_y*screen.scale and m_y <= screen.y+(w_y+w.hit.h)*screen.scale and gui.in_range(m_x, m_y, w.range) then
        if w.a < 1 then
          w.a = w.a + dt * 4
        else
          w.a = 1
        end
      else
        if w.a > 0 then
          w.a = w.a - dt * 4
        else
          w.a = 0
        end
      end
    end
  end
  if gui.current_item and gui.current_item.type == 1 then
    gui.current_item.flash = gui.current_item.flash + dt
  elseif gui.current_item and gui.current_item.type == 2 then
    local scroll = gui.menus[gui.current_item[1]].scrolls[gui.current_item[2]]

    scroll.pos = (m_y/screen.scale-screen.x)-scroll.y-gui.current_item.offset
    if scroll.pos < 0 then
       scroll.pos = 0
    end
    if scroll.pos > scroll.h-scroll.grab_h then
      scroll.pos = scroll.h-scroll.grab_h
    end
    local value = scroll.pos*scroll.range/(scroll.h-scroll.grab_h)*scroll.scale
    if scroll.range == 0 then
      value = 0
    end
    if type(scroll.value) == "number" then
      scroll.value = value
    else
      scroll.value.t[scroll.value.i] = value
    end
    if not love.mouse.isDown(1) then
      gui.current_item  = nil
    end
  end
end

gui.draw = function()
  for i, v in pairs(gui.menus) do
    for j, w in ipairs(v.textboxes) do
      if not w.hide then
        local x, y = gui.get_pos(w)
        if w.a then
          love.graphics.setColor(1, 1, 1, w.a)
        end
        love.graphics.draw(gui_imgs[6][tostring(w.w).."x"..tostring(w.h)], math.floor(x), math.floor(y))

        local string = ""
        if gui.current_item and gui.current_item.type == 1 and gui.current_item[1] == i and gui.current_item[2] == j then
          string = w.t[w.i]
          if math.floor(math.sin(gui.current_item.flash*4)+0.5) == 0 then
            string = string.."_"
          end
        elseif string.len(w.t[w.i]) < 1 and w.sample then
          string = w.sample
        else
          string = w.t[w.i]
        end
        love.graphics.print(string, math.floor(x+5), math.floor(y+(w.h-font:getHeight())/2)+1)
      end
      love.graphics.setColor(1, 1, 1)
    end

    for j, w in ipairs(v.buttons) do
      if not w.hide then
        local x, y = gui.get_pos(w)
        local mat = 1
        if w.mat then
          mat = w.mat.func(unpack(w.mat.args))
        end
        if w.a then
          love.graphics.setColor(1, 1, 1, w.a)
        end
        if w.range then
          shader.range:send("range", {w.range.x+5, w.range.y+5, w.range.w-10, w.range.h-10})
          love.graphics.setShader(shader.range)
        end
        love.graphics.draw(gui_imgs[mat][tostring(w.w).."x"..tostring(w.h)], math.floor(x), math.floor(y))
        if type(w.txt) == "string" then
          love.graphics.print(w.txt, math.floor(x+(w.w-font:getWidth(w.txt))/2), math.floor(y+(w.h-font:getHeight())/2))
        else
          local txt = w.txt.func(unpack(w.txt.args))
          love.graphics.print(txt, math.floor(x+(w.w-font:getWidth(txt))/2), math.floor(y+(w.h-font:getHeight())/2))
        end
        love.graphics.setShader()
        love.graphics.setColor(1, 1, 1)
      end
    end

    for j, w in ipairs(v.scrolls) do
      love.graphics.setColor(1, 1, 1)
      love.graphics.rectangle("fill", w.x, w.y+w.pos, w.grab_w, w.grab_h)
    end

    for j, w in ipairs(v.infoboxes) do
      local m_x, m_y = love.mouse.getPosition()
      local x, y = m_x/screen.scale-screen.x+6, m_y/screen.scale-screen.y+6
      love.graphics.setColor(1, 1, 1, w.a)
      love.graphics.draw(gui_imgs[6][tostring(w.w).."x"..tostring(w.h)], math.floor(x), math.floor(y))
      love.graphics.printf(w.txt, math.floor(x+5), math.floor(y+4), math.floor(w.w))
    end
  end
end

gui.add = function(num, buttons, textboxes, infoboxes, scrolls)
  local b = {}
  if buttons then
    b = buttons
    gui.add_imgs(buttons, 1)
    gui.add_imgs(buttons, 2)
    gui.add_imgs(buttons, 3)
  end
  local t = {}
  if textboxes then
    t = textboxes
    gui.add_imgs(textboxes, 6)
  end
  local i = {}
  if infoboxes then
    i = infoboxes
    gui.add_imgs(infoboxes, 6)
  end
  local s = {}
  if scrolls then
    s = scrolls
    gui.scroll_setup(scrolls)
  end
  gui.menus[num] = {buttons = b, textboxes = t, infoboxes = i, scrolls = s}
end

gui.remove = function(num)
  gui.menus[num] = nil
end

gui.exists = function(num)
  if gui.menus[num] then
    return true
  else
    return false
  end
end

gui.clear = function()
  gui.menus = {}
  gui.current_item = nil
end

gui.mousepressed = function(x, y, button)
  if button == 1 then
    local button_pressed = false
    local box_clicked = false
    for i, v in pairs(gui.menus) do
      if not button_pressed then
        for j, w in ipairs(v.buttons) do
          if not w.active or w.active.t[w.active.i] then
            local w_x, w_y = gui.get_pos(w)
            if x >= screen.x+w_x*screen.scale and x <= screen.x+(w_x+w.w)*screen.scale and y >= screen.y+w_y*screen.scale and y <= screen.y+(w_y+w.h)*screen.scale and gui.in_range(x, y, w.range) then
              if w.args then
                w.func(unpack(w.args))
              else
                w.func()
              end
              button_pressed = true
              break
            end
          end
        end
      end

      for j, w in ipairs(v.textboxes) do
        if not w.active or w.active.t[w.active.i] then
          local w_x, w_y = gui.get_pos(w)
          if x >= screen.x+w_x*screen.scale and x <= screen.x+(w_x+w.w)*screen.scale and y >= screen.y+w_y*screen.scale and y <= screen.y+(w_y+w.h)*screen.scale then
            gui.current_item = {type = 1, i, j, flash = 0}
            box_clicked = true
          end
        end
      end

      for j, w in ipairs(v.scrolls) do
        local w_x, w_y = gui.get_pos(w)
        if x >= screen.x+w_x*screen.scale and x <= screen.x+(w_x+w.grab_w)*screen.scale and y >= screen.y+(w_y+w.pos)*screen.scale and y <= screen.y+(w_y+w.grab_h+w.pos)*screen.scale then
          gui.current_item = {type = 2, i, j, offset = (y/screen.scale-screen.y)-w_y-w.pos}
          box_clicked = true
        end
      end
    end
    if not box_clicked then
      gui.current_item = nil
    end
  end
end

gui.keypressed = function(key)
  if gui.current_item and key == "backspace" then
    local box = gui.menus[gui.current_item[1]].textboxes[gui.current_item[2]]
    if not box.active or box.active.t[box.active.i] then
      box.t[box.i] = string.sub(box.t[box.i], 1, -2)
    end
  end
end

gui.textinput = function(text)
  if gui.current_item then
    local box = gui.menus[gui.current_item[1]].textboxes[gui.current_item[2]]
    if not box.active or box.active.t[box.active.i] then
      if font:getWidth(box.t[box.i]..text) <= box.w-10 then
        box.t[box.i] = box.t[box.i]..text
      end
    end
  end
end

gui.get_pos = function(w)
  local x, y = 0, 0
  if type(w.x) == "number" then
    x = w.x
  else
    x = w.x.t[w.x.i]
    if w.x.o then
      x = x + w.x.o
    end
  end
  if type(w.y) == "number" then
    y = w.y
  else
    y = w.y.t[w.y.i]
    if w.y.o then
      y = y + w.y.o
    end
  end
  return x, y
end

gui.text_size = function(txt, limit)
  local w, wrap = font:getWrap(txt, limit)
  if #wrap > 1 then
    return w+10, #wrap*font:getHeight()+8
  else
    return w+10, #wrap*font:getHeight()
  end
end

gui.add_imgs = function(list, mat)
  for i, v in ipairs(list) do
    if not v.hide then
      if not gui_imgs[mat] then gui_imgs[mat] = {} end
      local str = tostring(v.w).."x"..tostring(v.h)
      if not gui_imgs[mat][str] then
        gui_imgs[mat][str] = gui.new_img(mat, v.w, v.h)
      end
    end
  end
end

gui.new_img = function(mat, w, h)
  local w = math.ceil(w/16)
  local h = math.ceil(h/16)
  local canvas = love.graphics.newCanvas(w*16, h*16)
  love.graphics.setCanvas(canvas)
  love.graphics.clear()
  for x = 0, w-1 do
    for y = 0, h-1 do
      love.graphics.draw(mat_img[mat], mat_quad[gui.bitmask(x, y, w-1, h-1)], x*16, y*16)
    end
  end
  love.graphics.setCanvas()
  return canvas
end

gui.bitmask = function(x, y, w, h)
  local value = 1
  if x > 0 then
    value = value + 2
  end
  if x < w then
    value = value + 4
  end
  if y > 0 then
    value = value + 1
  end
  if y < h then
    value = value + 8
  end
  return value
end

gui.scroll_setup = function(scrolls)
  for i, v in ipairs(scrolls) do
    if not v.scale then
      v.scale = 1
    end
    v.range = math.abs(v.max-v.min)
    v.grab_h = v.h/(v.range+1)
    if v.range == 0 then
      v.pos = 0
    else
      if type(v.value) == "number" then
        v.pos = v.value/v.range*(v.h-v.grab_h)
      else
        v.pos = v.value.t[v.value.i]/v.range*(v.h-v.grab_h)
      end
    end
  end
end

gui.in_range = function(mx, my, range)
  if range then
    return (mx/screen.scale-screen.x >= range.x and mx/screen.scale-screen.x <= range.x+range.w and my/screen.scale-screen.y >= range.y and my/screen.scale-screen.y <= range.y+range.h)
  else
    return true
  end
end

gui.active_update = function(w, dt)
  if w.active then
    if not w.a then
      w.a = 0
    end
    if w.active.t[w.active.i] and w.a < 1 then
      w.a = w.a + dt * 4
      if w.a > 1 then
        w.a = 1
      end
    end
    if not w.active.t[w.active.i] and w.a > 0 then
      w.a = w.a - dt * 4
      if w.a < 0 then
        w.a = 0
      end
    end
  end
end

return gui
