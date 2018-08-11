local graphics = {}

love.graphics.setDefaultFilter("nearest", "nearest")

graphics.load = function()
  love.window.setMode(1000, 600)
  screen = {scale = 2, x = 0, y = 0}
  screen.w = love.graphics.getWidth() / screen.scale
  screen.h = love.graphics.getHeight() / screen.scale
  screen.canvas = love.graphics.newCanvas(screen.w, screen.h)

  font = love.graphics.newImageFont("font.png",
  " abcdefghijklmnopqrstuvwxyz" ..
  "ABCDEFGHIJKLMNOPQRSTUVWXYZ0" ..
  "123456789.,!?-+/():;%&`'*#=[]\"_", 1)
  love.graphics.setFont(font)

  love.graphics.setLineWidth(1)
  love.graphics.setLineStyle("rough")

  mat_img = graphics.load_folder("art/gui/materials")
  mat_quad = graphics.load_quad(mat_img[1], 16, 16)

  -- load tile images
  tile_img = graphics.load_folder("art/tiles")
  tile_quad = graphics.load_tile_quad(tile_size)

  local img, quad = graphics.load_folder("art/bullets", 32, 32)
  bullet_img = img
  bullet_quad = quad

  ability_icon = graphics.load_folder("art/abilityicons")
  weapon_icon = graphics.load_folder("art/weaponicons")
  map_icon = graphics.load_folder("art/mapicons")

  weapon_img, weapon_quad, weapon_info = graphics.load_doublefolder("art/weaponimgs", 64, 64)
  char_img, char_quad, char_info = graphics.load_doublefolder("art/charimgs", 24, 48, graphics.load_face_quad)
end

graphics.load_doublefolder = function(str, tw, th, quadfunc)
  local img = {}
  local quad = {}
  local info = {}
  local files = love.filesystem.getDirectoryItems(str)
  for i, v in ipairs(files) do
    img[tonumber(v)], quad[tonumber(v)], info[tonumber(v)] = graphics.load_folder(str.."/"..v, tw, th, quadfunc)
  end
  return img, quad, info
end

graphics.load_folder = function(str, tw, th, quadfunc)
  local img = {}
  local quad = {}
  local info = {}
  local files = love.filesystem.getDirectoryItems(str)
  for i, v in ipairs(files) do
    if string.sub(v, -4, -1) == ".png" then
      local name = string.sub(v, 1, -5)
      if tonumber(name) then
        name = tonumber(name)
      end
      img[name] = love.graphics.newImage(str.."/"..v)
      if tx or th then
        if not quadfunc then
          quadfunc = graphics.load_quad
        end
        quad[name] = quadfunc(img[name], tw, th)
      end
      local info_name = str.."/"..name.."_info.txt"
      if love.filesystem.getInfo(info_name) then
        info[name] = love.filesystem.load(info_name)()
      end
    end
  end
  return img, quad, info
end

graphics.load_quad = function(img, tw, th)
  local quad = {}
  local iw, ih = img:getDimensions()
  for h = 0, math.floor(ih/th)-1 do
    for w = 0, math.floor(iw/tw)-1 do
      quad[#quad+1] = love.graphics.newQuad(w*tw, h*th, tw, th, iw, ih)
    end
  end
  return quad
end

graphics.load_face_quad = function(img, tw, th)
  local quad = {}
  local iw, ih = img:getDimensions()
  for h = 0, 3 do
    quad[h+1] = {}
    for w = 0, math.floor(iw/tw)-1 do
      quad[h+1][w+1] = love.graphics.newQuad(w*tw, h*th, tw, th, iw, ih)
    end
  end
  return quad
end

graphics.load_tile_quad = function(t)
  local x, y = tile_img[1]:getDimensions()
  local tile = {{{}, {}, {}, {}}, {{}, {}, {}, {}}}
  for i = 0, 1 do
    for j = 0, 4 do
      tile[i+1][1][j+1] = love.graphics.newQuad(j*t, t*i, t/2, t/2, x, y)
      tile[i+1][2][j+1] = love.graphics.newQuad(t/2+j*t, t*i, t/2, t/2, x, y)
      tile[i+1][3][j+1] = love.graphics.newQuad(j*t, t*i+t/2, t/2, t/2, x, y)
      tile[i+1][4][j+1] = love.graphics.newQuad(t/2+j*t, t*i+t/2, t/2, t/2, x, y)
    end
  end
  return tile
end

graphics.draw_floor = function(x, y, z, tile)
  for w = 0, 1 do
    for h = 0, 1 do
      local corner = w+h*2+1
      local type = graphics.bitmask_floor(x, y, z, w, h, tile)
      love.graphics.draw(tile_img[tile], tile_quad[1][corner][type], (x-1+w/2)*tile_size, (y+z-2+h/2)*tile_size)
    end
  end
end

graphics.bitmask_floor = function(x, y, z, w, h, tile)
  -- determine value
  local value = 3
  local right = (w > 0 and x < #grid[1][1])
  local left = (w < 1 and x > 1)
  local down = (h > 0 and y < #grid[1])
  local up = (h < 1 and y > 1)
  local side_type = 4
  -- direct sides
  if (right and graphics.match(x+1, y, z, tile)) or (left and graphics.match(x-1, y, z, tile)) then
    value = value + 2
  else -- for resolving type conflict
    side_type = 5
  end
  if (down and graphics.match(x, y+1, z, tile)) or (up and graphics.match(x, y-1, z, tile)) then
    value = value + 2
  end
  -- diagonals
  if (right and down and graphics.match(x+1, y+1, z, tile)) or (right and up and graphics.match(x+1, y-1, z, tile)) or (left and up and graphics.match(x-1, y-1, z, tile)) or (left and down and graphics.match(x-1, y+1, z, tile)) then
    value = value + 1
  end

  -- translate value
  if value < 5 then
    return 2
  elseif value < 7 then
    return side_type
  elseif value < 8 then
    return 1
  else
    return 3
  end
end

graphics.match = function(x, y, z, tile)
  return (grid[z][y][x] == tile and (z == 1 or grid[z-1][y][x] == 0))
end

graphics.draw_wall = function(x, y, z, tile)
  for w = 0, 1 do
    for h = 0, 1 do
      local corner = w+h*2+1
      local type = graphics.bitmask_wall(x, y, z, w, h, tile)
      love.graphics.draw(tile_img[tile], tile_quad[2][corner][type], (x-1+w/2)*tile_size, (y+z-1+h/2)*tile_size)
    end
  end
end

graphics.bitmask_wall = function(x, y, z, w, h, tile)
  -- determine value
  local value = 3
  local right = (w > 0 and x < #grid[1][1])
  local left = (w < 1 and x > 1)
  local down = (h > 0 and z < #grid)
  local up = (h < 1 and z > 1)
  local side_type = 4
  -- direct sides
  if (right and graphics.match_wall(x+1, y, z, tile)) or (left and graphics.match_wall(x-1, y, z, tile)) then
    value = value + 2
  else -- for resolving type conflict
    side_type = 5
  end
  if (down and graphics.match_wall(x, y, z+1, tile)) or (up and graphics.match_wall(x, y, z-1, tile)) then
    value = value + 2
  end
  -- diagonals
  if (right and down and graphics.match_wall(x+1, y, z+1, tile)) or (right and up and graphics.match_wall(x+1, y, z-1, tile)) or (left and up and graphics.match_wall(x-1, y, z-1, tile)) or (left and down and graphics.match_wall(x-1, y, z+1, tile)) then
    value = value + 1
  end

  -- translate value
  if value < 5 then
    return 2
  elseif value < 7 then
    return side_type
  elseif value < 8 then
    return 1
  else
    return 3
  end
end

graphics.match_wall = function(x, y, z, tile)
  return (grid[z][y][x] == tile and (y == #grid[1] or grid[z][y+1][x] == 0))
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
  local angle = 0
  if v.angle then
    angle = v.angle
  end
  local ox, oy = 0, 0
  if v.ox or v.oy then
    ox, oy = v.ox, v.oy
  end
  local sx, sy = 1, 1
  if v.sx or v.sy then
    sx, sy = v.sx, v.sy
  end
  if v.quad then
    love.graphics.draw(v.img, v.quad, math.floor(v.x), math.floor(v.y+v.z), angle, sx, sy, ox, oy)
  elseif v.shape then
    love.graphics[v.shape]("fill", math.floor(v.x), math.floor(v.y+v.z), v.a, v.b)
  else
    love.graphics.draw(v.img, math.floor(v.x), math.floor(v.y+v.z), angle, sx, sy, ox, oy)
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

graphics.draw_border = function(v)
  love.graphics.setShader(shader.color)
  love.graphics.setColor(v.border)
  for i = -1, 1, 2 do
    for j = -1, 1, 2 do
      if v.quad then
        love.graphics.draw(v.img, v.quad, math.floor(v.x+j), math.floor(v.y+i))
      else
        love.graphics.draw(v.img, math.floor(v.x+j), math.floor(v.y+i))
      end
    end
  end
  love.graphics.setColor(1, 1, 1)
  love.graphics.setShader()
end


return graphics
