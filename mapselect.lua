local mapselect = {}

local icon = {w = 82, h = 40, border = 2}
local option_pos = {}
local icons = {}
local current = 1

mapselect.load = function()
  local files = love.filesystem.getDirectoryItems("maps")
  maps = {}
  for i, v in ipairs(files) do
    maps[i] = {name = string.sub(v, 1, -5), grid = love.filesystem.load("maps/"..v)()}
  end

  option_pos = {x = (screen.w-256)/2, y = (screen.h-256)/2+66, w = 256, h = 190}
end

mapselect.start = function(buttons)
  gui.clear()
  gui.add(1, buttons, {}, {})
  icons = mapselect.get_icon_pos()
  local buttons = {}
  local infoboxes = {}
  for i, v in ipairs(icons) do
    buttons[i] = {x = v.x, y = v.y, w= v.w, h = v.h, txt = tostring(v.num), func = mapselect.change_map, args = {v.num}, hide = true}
    local txt =  maps[v.num].name
    infoboxes[i] = {x = v.x, y = v.y, w= v.w, h = v.h, box = gui.text_size(txt, 128), txt = txt}
  end
  gui.add(2, buttons, {}, infoboxes)
end

mapselect.update = function(dt)
end

mapselect.draw = function(dt)
  love.graphics.setColor(menu_color)
  love.graphics.rectangle("fill", option_pos.x, option_pos.y-66, option_pos.w, 64)
  love.graphics.setColor(1, 1, 1)
  love.graphics.printf("Map Vote:\n"..maps[current].name, option_pos.x, option_pos.y-42, option_pos.w, "center")
  love.graphics.rectangle("fill", option_pos.x, option_pos.y, option_pos.w, option_pos.h)
  for i, v in ipairs(icons) do
    if current == i then
      love.graphics.draw(map_icon[maps[current].name], v.x, v.y)
    else
      love.graphics.setShader(shader.greyscale)
      love.graphics.draw(map_icon[maps[current].name], v.x, v.y)
      love.graphics.setShader()
    end
  end
end

mapselect.get_icon_pos = function()
  local x = 0
  local y = 0
  local icons = {}
  for i, v in ipairs(maps) do
    icons[i] = {x = option_pos.x+x*(icon.w+icon.border)+icon.border, y = option_pos.y+y*(icon.h+icon.border)+icon.border, w= icon.w, h = icon.h, num = i}
    x = x + 1
    if x > 2 then
      x = 0
      y = y + 1
    end
  end
  return icons
end

mapselect.change_map = function(num)
  current = num
end

mapselect.get_map = function()
  return current
end

mapselect.choose_map = function(players)
  local choices = {}
  for k, v in pairs(players) do
    if v.map then
      choices[#choices+1] = v.map
    end
  end
  return choices[math.random(1, #choices)]
end

return mapselect
