local mapselect = {}

mapselect.load = function()
  local files = love.filesystem.getDirectoryItems("maps")
  maps = {}
  for i, v in ipairs(files) do
    maps[i] = {name = string.sub(v, -1, -4), grid = love.filesystem.load("maps/"..v)()}
  end
end

mapselect.start = function()
end

mapselect.update = function(dt)
end

mapselect.draw = function(dt)
end

return mapselect
