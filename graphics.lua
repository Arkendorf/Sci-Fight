local graphics = {}

graphics.load = function()
  tile_img, tile_quad = graphics.load_tiles("tiles")

  char_img = love.graphics.newImage("char.png")
  shadow_img = love.graphics.newImage("shadow.png")
end

graphics.load_tiles = function(str)
  local img = {}
  local quad = {}
  local files = love.filesystem.getDirectoryItems(str)
  for i, v in ipairs(files) do
    local name = tonumber(string.sub(v, 1, -5))
    img[name] = love.graphics.newImage(str.."/"..v)
    quad[name] = graphics.spritesheet(img[name], tile_size, tile_size)
  end
  return img, quad
end


graphics.spritesheet = function(img, tw, th)
  local quads = {}
  for y = 0, math.ceil(img:getHeight()/th)-1 do
    for x = 0, math.ceil(img:getWidth()/tw)-1 do
      quads[#quads+1] = love.graphics.newQuad(x*tw, y * th, tw, th, img:getDimensions())
    end
  end
  return quads
end

graphics.bitmask_floor = function(x, y, z)
  local type = grid[z][y][x]
  local value = 1
  if y > 1 and grid[z][y-1][x] == type and (z == 1 or grid[z-1][y-1][x] == 0) then
    value = value + 1
  end
  if x > 1 and grid[z][y][x-1] == type and (z == 1 or grid[z-1][y][x-1] == 0) then
    value = value + 2
  end
  if x < #grid[z][y] and grid[z][y][x+1] == type and (z == 1 or grid[z-1][y][x+1] == 0) then
    value = value + 4
  end
  if y < #grid[z] and grid[z][y+1][x] == type and (z == 1 or grid[z-1][y+1][x] == 0) then
    value = value + 8
  end
  return value
end

graphics.bitmask_wall = function(x, y, z)
  local type = grid[z][y][x]
  local value = 1
  if z > 1 and grid[z-1][y][x] == type and (y == #grid[z] or grid[z-1][y+1][x] == 0) then
    value = value + 1
  end
  if x > 1 and grid[z][y][x-1] == type and (y == #grid[z] or grid[z][y+1][x-1] == 0) then
    value = value + 2
  end
  if x < #grid[z][y] and grid[z][y][x+1] == type and (y == #grid[z] or grid[z][y+1][x+1] == 0) then
    value = value + 4
  end
  if z < #grid and grid[z+1][y][x] == type and (y == #grid[z] or grid[z+1][y+1][x] == 0) then
    value = value + 8
  end
  return value
end

graphics.draw_queue = function(y)
  local current_queue = {}
  for i, v in ipairs(queue) do
    if not v.drawn and 1+math.floor((v.y+v.w)/tile_size) <= y then
      current_queue[#current_queue + 1] = v
      v.drawn = true
    end
  end
  if # current_queue > 0 then
    table.sort(current_queue, function(a, b) return a.y < b.y end)
    for i, v in ipairs(current_queue) do
      if v.quad then
        love.graphics.draw(v.img, v.quad, math.ceil(v.x), math.ceil(v.y+v.z))
      else
        love.graphics.draw(v.img, math.ceil(v.x), math.ceil(v.y+v.z))
      end
    end
  end
end

return graphics
