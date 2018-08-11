love.keyboard.setKeyRepeat(true)
local gui = {}

local gui_imgs = {}

gui.load = function()
  gui.clear()
end

gui.update = function(dt)
  if gui.current_box then
    gui.current_box.flash = gui.current_box.flash + dt
  end
  local m_x, m_y = love.mouse.getPosition()
  for i, v in pairs(gui.menus) do
    for j, w in ipairs(v.infoboxes) do
      if not w.a then
        w.a = 0
      end
      local w_x, w_y = gui.get_pos(w)
      if m_x >= screen.x+w_x*screen.scale and m_x <= screen.x+(w_x+w.hit.w)*screen.scale and m_y >= screen.y+w_y*screen.scale and m_y <= screen.y+(w_y+w.hit.h)*screen.scale then
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
end

gui.draw = function()
  for i, v in pairs(gui.menus) do
    for j, w in ipairs(v.textboxes) do
      if not w.hide then
        local x, y = gui.get_pos(w)
        love.graphics.draw(gui_imgs[6][tostring(w.w).."x"..tostring(w.h)], math.floor(x), math.floor(y))

        local string = ""
        if gui.current_box and gui.current_box[1] == i and gui.current_box[2] == j then
          string = w.t[w.i]
          if math.floor(math.sin(gui.current_box.flash*4)+0.5) == 0 then
            string = string.."_"
          end
        elseif string.len(w.t[w.i]) < 1 and w.sample then
          string = w.sample
        else
          string = w.t[w.i]
        end
        love.graphics.print(string, math.floor(x+5), math.floor(y+(w.h-font:getHeight())/2)+1)
      end
    end

    for j, w in ipairs(v.buttons) do
      if not w.hide then
        local x, y = gui.get_pos(w)
        local mat = 1
        if w.mat then
          mat = w.mat.func(unpack(w.mat.args))
        end
        love.graphics.draw(gui_imgs[mat][tostring(w.w).."x"..tostring(w.h)], math.floor(x), math.floor(y))

        love.graphics.setColor(1, 1, 1)
        love.graphics.print(w.txt, math.floor(x+(w.w-font:getWidth(w.txt))/2), math.floor(y+(w.h-font:getHeight())/2))
      end
    end

    for j, w in ipairs(v.infoboxes) do
      local m_x, m_y = love.mouse.getPosition()
      local x, y = m_x/screen.scale-screen.x+6, m_y/screen.scale-screen.y+6
      love.graphics.setColor(1, 1, 1, w.a)
      love.graphics.draw(gui_imgs[6][tostring(w.w).."x"..tostring(w.h)], math.floor(x), math.floor(y))
      love.graphics.printf(w.txt, math.floor(x+5), math.floor(y+5), math.floor(w.w))
    end
  end
end

gui.add = function(num, buttons, textboxes, infoboxes)
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
  gui.menus[num] = {buttons = b, textboxes = t, infoboxes = i}
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
  gui.current_box = nil
end

gui.mousepressed = function(x, y, button)
  local button_pressed = false
  local box_clicked = false
  for i, v in pairs(gui.menus) do
    if not button_pressed then
      for j, w in ipairs(v.buttons) do
        local w_x, w_y = gui.get_pos(w)
        if x >= screen.x+w_x*screen.scale and x <= screen.x+(w_x+w.w)*screen.scale and y >= screen.y+w_y*screen.scale and y <= screen.y+(w_y+w.h)*screen.scale then
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

    for j, w in ipairs(v.textboxes) do
      local w_x, w_y = gui.get_pos(w)
      if x >= screen.x+w_x*screen.scale and x <= screen.x+(w_x+w.w)*screen.scale and y >= screen.y+w_y*screen.scale and y <= screen.y+(w_y+w.h)*screen.scale then
        gui.current_box = {i, j, flash = 0}
        box_clicked = true
      end
    end
  end
  if not box_clicked then
    gui.current_box = nil
  end
end

gui.keypressed = function(key)
  if gui.current_box and key == "backspace" then
    local box = gui.menus[gui.current_box[1]].textboxes[gui.current_box[2]]
    box.t[box.i] = string.sub(box.t[box.i], 1, -2)
  end
end

gui.textinput = function(text)
  if gui.current_box then
    local box = gui.menus[gui.current_box[1]].textboxes[gui.current_box[2]]
    if font:getWidth(box.t[box.i]..text) <= box.w-10 then
      box.t[box.i] = box.t[box.i]..text
    end
  end
end

gui.get_pos = function(w)
  local x, y = 0, 0
  if type(w.x) == "number" then x = w.x else x = w.x.t[w.x.i] end
  if type(w.y) == "number" then y = w.y else y = w.y.t[w.y.i] end
  return x, y
end

gui.text_size = function(txt, limit)
  local w, wrap = font:getWrap(txt, limit)
  return w+10, #wrap*font:getHeight()+10
end

gui.add_imgs = function(list, mat)
  for i, v in ipairs(list) do
    if not gui_imgs[mat] then gui_imgs[mat] = {} end
    local str = tostring(v.w).."x"..tostring(v.h)
    if not gui_imgs[mat][str] then
      gui_imgs[mat][str] = gui.new_img(mat, v.w, v.h)
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

return gui
