map = require "map"
graphics = require "graphics"
char = require "char"
collision = require "collision"
shader = require "shader"
clientgame = require "clientgame"
servergame = require "servergame"
bullet = require "bullet"

local game = {}

game.load = function()
  map.load()
  char.load()
  bullet.load()
  clientgame.load()
  servergame.load()

  queue = {}
end

game.update = function(dt)
  -- normal updates
  char.update(dt)
  bullet.update(dt)
  -- create drawing queue
  queue = {}
  char.queue()
  -- update masks (e.g. layer and shadow)
  map.update_masks()
end

game.mousepressed = function(x, y, button)
  char.mousepressed(x, y, button)
end

game.draw = function()
  local offset = {math.floor(screen.w/2-players[id].x-players[id].l/2), math.floor(screen.h/2-players[id].y-players[id].z-players[id].w)}
  shader.shadow:send("offset", offset)
  shader.layer:send("offset", offset)
  love.graphics.push()
  love.graphics.translate(offset[1], offset[2])
  -- draw tiles
  map.draw()
  -- draw shadows
  game.draw_shadows()
  -- draw projectiles
  bullet.draw()
  -- draw objects
  game.draw_queue()

  local x, y = game.mouse_pos()
  love.graphics.circle("line", x, y, 12, 24)

  love.graphics.pop()
end

game.mouse_pos = function()
  return players[id].x+players[id].l/2+(love.mouse.getX())/screen.scale-screen.w/2, players[id].y+players[id].z+players[id].w+(love.mouse.getY())/screen.scale-screen.h/2
end

game.draw_queue = function()
  table.sort(queue, function(a, b) return a.y < b.y end)
  shader.layer:send("xray_color", {.5, .5, .5, .5})

  for i, v in ipairs(queue) do
    love.graphics.setShader(shader.layer)
    shader.layer:send("coords", {0, 1+math.floor((v.y)/tile_size), 2+math.floor((v.z+v.h)/tile_size)})
    graphics.draw(v)
    love.graphics.setShader()
  end
end

game.shadow = function(v)
  love.graphics.setShader(shader.shadow)
  for z_offset = 1+math.floor((v.z+v.h*0.5)/tile_size), #grid-1 do
    local diffuse = (z_offset*tile_size-(v.z+v.h))/tile_size/3
    local r = v.l/2
    shader.shadow:send("z", z_offset+1)
    love.graphics.setColor(0.2, 0.2, 0.3, 1-diffuse)
    love.graphics.circle("fill", math.ceil(v.x+v.l/2), math.ceil(v.y+v.w/2+z_offset*tile_size), r*(1+diffuse), 24)
  end
  love.graphics.setColor(1, 1, 1)
  love.graphics.setShader()
end

game.draw_shadows = function()
  map.iterate(game.draw_tile_shadows) -- draw tile shadows
  table.sort(queue, function(a, b) return a.z < b.z end)
  for i, v in ipairs(queue) do -- draw object shadows
    if v.shadow then
      game.shadow(v)
    end
  end
end

-- map functions
game.draw_tiles = function(x, y, z, tile)
  if tile > 0 then
    -- floor
    if not map.floor_block(x, y, z) then
      love.graphics.draw(tile_img[tile], tile_quad[tile][graphics.bitmask_floor(x, y, z)], (x-1)*tile_size, (y+z-2)*tile_size)
    end

    -- wall
    if not map.wall_block(x , y, z) then
      love.graphics.draw(tile_img[tile], tile_quad[tile][16+graphics.bitmask_wall(x, y, z)], (x-1)*tile_size, (y+z-1)*tile_size)
    end
  end
end

game.draw_tile_shadows = function(x, y, z, tile)
  if tile > 0 then
    local block, pos = map.vert_block(x, y, z)
    if block and not map.floor_block(x, y, z) then
      local diffuse = (z-pos-1)/3
      love.graphics.setColor(0.2, 0.2, 0.3, 1-diffuse)
      love.graphics.rectangle("fill", (x-1)*tile_size, (y+z-2)*tile_size, tile_size, tile_size)
    end
  end
end

game.draw_layer_mask = function(x, y, z, tile)
  if tile > 0 then
    love.graphics.setColor(0, 1.01 - 0.01*y, 1.01 - 0.01*z)
    if not map.floor_block(x, y, z) then
      love.graphics.rectangle("fill", (x-1)*tile_size, (y+z-2)*tile_size, tile_size, tile_size)
    end
    if not map.wall_block(x , y, z) then
      love.graphics.rectangle("fill", (x-1)*tile_size, (y+z-1)*tile_size, tile_size, tile_size)
    end
  end
end

game.draw_shadow_mask = function(x, y, z, tile)
  if tile > 0 then
    love.graphics.setColor(1.01 - 0.01*z, 0, 0)
    if not map.floor_block(x, y, z) and not map.vert_block(x, y, z) then
      love.graphics.rectangle("fill", (x-1)*tile_size, (y+z-2)*tile_size, tile_size, tile_size)
    end
  end
end

return game
