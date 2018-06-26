local graphics = {}

love.graphics.setDefaultFilter("nearest", "nearest")
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
  if #current_queue > 0 then
    table.sort(current_queue, function(a, b) return a.y < b.y end)
    for i, v in ipairs(current_queue) do
      graphics.draw(v)
    end
  end
end

graphics.draw = function(v)
  if v.color then
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

graphics.shadow = function(v)
  love.graphics.setShader(shader.shadow)
  for z_offset = 1+math.floor((v.z+v.h*0.5)/tile_size), #grid-1 do
    local diffuse = (z_offset*tile_size-(v.z+v.h))/tile_size*0.3
    local r = v.l/2
    shader.shadow:send("z", z_offset+1)
    love.graphics.setColor(0.4, 0.4, 0.4, 1-diffuse)
    love.graphics.circle("fill", v.x+v.l/2, v.y+v.w/2+z_offset*tile_size, r*(1+diffuse), 24)
  end
  love.graphics.setColor(1, 1, 1)
  love.graphics.setShader()
end

return graphics
