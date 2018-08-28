local mapselect = {}

local icon = {w = 76, h = 56, border = 2}
local option_pos = {}
local icons = {}
local current = 1
local option_scroll = {0}
local mapselect_imgs = {}

map_name = {
  "Time Machine Interior",
  "Time Machine Interior",
  "Time Machine Interior",
}

mapselect.load = function()
  local files = love.filesystem.getDirectoryItems("maps")
  maps = {}
  for i, v in ipairs(files) do
    local grid, props = love.filesystem.load("maps/"..v)()
    maps[i] = {grid = grid, props = props}
  end

  option_pos = {x = (screen.w-256)/2, y = (screen.h-256)/2+66, w = 256, h = 192}

  mapselect_imgs.header = gui.new_img(1, option_pos.w, 64)
  mapselect_imgs.option = gui.new_img(5, option_pos.w, option_pos.h)
end

mapselect.start = function(buttons)
  gui.clear()
  gui.add(1, buttons, {}, {})
  icons = mapselect.get_icon_pos()
  local buttons = {}
  local infoboxes = {}
  for i, v in ipairs(icons) do
    buttons[i] = {x = v.x, y = v.y, w= v.w, h = v.h, txt = tostring(v.num), func = mapselect.change_map, args = {v.num}, hide = true}
    local txt =  map_name[v.num]
    local w, h = gui.text_size(txt, 128)
    infoboxes[i] = {x = v.x, y = v.y, w= w, h = h, hit = {w = v.w, h = v.h}, txt = txt}
  end
  scroll = {{x = option_pos.x+option_pos.w-12, y = option_pos.y+7, h = option_pos.h-14, grab_w = 6, value = {t = option_scroll, i = 1}, min = 0, max = math.max(1, math.ceil(#icons/7)*icon.h/(option_pos.h-18))-1, scale = -option_pos.h+18}}
  gui.add(2, buttons, {}, infoboxes, scroll)
end

mapselect.update = function(dt)
end

mapselect.draw = function(dt)
  love.graphics.draw(mapselect_imgs.header, option_pos.x, option_pos.y-66)
  love.graphics.draw(mapselect_imgs.option, option_pos.x, option_pos.y)
  love.graphics.printf("Map Vote:\n"..map_name[current], option_pos.x, option_pos.y-42, option_pos.w, "center")
  for i, v in ipairs(icons) do
    custom.icon_background(v.x, v.y, 4, current == i)
    love.graphics.draw(map_icon[current], v.x, v.y)
  end
end

mapselect.get_icon_pos = function()
  local x = 0
  local y = 0
  local icons = {}
  for i, v in ipairs(maps) do
    icons[i] = {x = option_pos.x+x*(icon.w+icon.border)+icon.border+6, y = option_pos.y+y*(icon.h+icon.border)+icon.border+5, w= icon.w, h = icon.h, num = i}
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
