local gui = {}

gui.load = function()
  gui.clear()
end

gui.update = function(dt)
end

gui.draw = function()
  for i, v in pairs(gui.menus) do
    for j, w in ipairs(v.textboxes) do
      local x, y = gui.get_pos(w)
      love.graphics.rectangle("line", math.floor(x), math.floor(y), math.floor(w.w), math.floor(w.h))
      if string.len(w.t[w.i]) < 1 and w.sample then
        love.graphics.print(w.sample, math.floor(x+2), math.floor(y+(w.h-font:getHeight())/2))
      else
        love.graphics.print(w.t[w.i], math.floor(x+2), math.floor(y+(w.h-font:getHeight())/2))
      end
    end

    for j, w in ipairs(v.buttons) do
      local x, y = gui.get_pos(w)
      love.graphics.rectangle("line", math.floor(x), math.floor(y), math.floor(w.w), math.floor(w.h))
      love.graphics.print(w.txt, math.floor(x+(w.w-font:getWidth(w.txt))/2), math.floor(y+(w.h-font:getHeight())/2))
    end
  end
end

gui.add = function(num, buttons, textboxes)
  gui.menus[num] = {buttons = buttons, textboxes = textboxes}
end

gui.remove = function(num)
  gui.menus[num] = nil
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
        gui.current_box = {i, j}
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
    if font:getWidth(box.t[box.i]..text) <= box.w-4 then
      box.t[box.i] = box.t[box.i]..text
    end
  end
end

gui.get_pos = function(w)
  local x, y = 0, 0
  if type(w.x) == "number" then x = w.x else x = w.x.t[w.x.i]+w.x.o end
  if type(w.y) == "number" then y = w.y else y = w.y.t[w.y.i]+w.y.o end
  return x, y
end

return gui
