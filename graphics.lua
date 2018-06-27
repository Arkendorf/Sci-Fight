local graphics = {}

love.graphics.setDefaultFilter("nearest", "nearest")

graphics.load = function()
  screen = {scale = 2, x = 0, y = 0}
  screen.w = love.graphics.getWidth() / screen.scale
  screen.h = love.graphics.getHeight() / screen.scale
  screen.canvas = love.graphics.newCanvas(screen.w, screen.h)


  font = love.graphics.newImageFont("font.png",
  " abcdefghijklmnopqrstuvwxyz" ..
  "ABCDEFGHIJKLMNOPQRSTUVWXYZ0" ..
  "123456789.,!?-+/():;%&`'*#=[]\"", 1)
  love.graphics.setFont(font)

  love.graphics.setLineWidth(1)

  player_img = love.graphics.newImage("char.png")
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

graphics.draw = function(v, color)
  if color then
    love.graphics.setColor(color)
  elseif v.color then
    love.graphics.setColor(v.color)
  end
  if v.shader then
    love.graphics.setShader(shader[v.shader.type])
    for j, w in ipairs(v.shader.info) do
      shader[v.shader.type]:send(w[1], w[2])
    end
  end
  if v.quad then
    love.graphics.draw(v.img, v.quad, math.ceil(v.x), math.ceil(v.y+v.z))
  elseif v.shape then
    love.graphics[v.shape]("fill", math.ceil(v.x), math.ceil(v.y+v.z), v.a, v.b)
  else
    love.graphics.draw(v.img, math.ceil(v.x), math.ceil(v.y+v.z))
  end
  love.graphics.setShader()
  love.graphics.setColor(1, 1, 1)
end

graphics.zoom = function(bool, num, min, max, scalar)
  if max-num <= 1 then
    num = max
  elseif num-min <= 1 then
    num = min
  end
  if bool and num < max then
    if num + (max-num) * scalar > max then
      return max
    else
      return num + (max-num) * scalar
    end
  elseif not bool and num > min then
    return num + (min-num) * scalar
  else
    return num
  end
end

return graphics
