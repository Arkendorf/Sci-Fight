local map = {}

map.load = function()
  grid = {
    {{1, 1, 0, 0, 1},
     {0, 0, 0, 0, 0},
     {1, 0, 0, 0, 0},
     {0, 0, 0, 0, 0},
     {0, 0, 0, 1, 0}},

    {{1, 1, 1, 1, 1},
     {0, 0, 1, 0, 1},
     {1, 1, 0, 0, 0},
     {0, 0, 0, 0, 0},
     {0, 0, 0, 1, 1}},

    {{1, 1, 1, 1, 1},
     {1, 1, 1, 1, 1},
     {1, 1, 1, 1, 1},
     {1, 1, 1, 1, 1},
     {1, 0, 0, 1, 1}},

    {{1, 1, 1, 1, 1},
     {1, 1, 1, 1, 1},
     {1, 1, 1, 1, 1},
     {1, 1, 1, 1, 1},
     {1, 1, 1, 1, 1}}
        }

  tiles = {1}
  tile_size = 32


  -- shader stuff
  local x, y = #grid[1][1]*tile_size, (#grid+#grid[1])*tile_size
  shadow_mask = love.graphics.newCanvas(x, y)
  shader.shadow:send("mask_size", {x, y})
end

map.update_mask = function()
  -- draw shadow mask for shader
  love.graphics.setCanvas(shadow_mask)
  for z = 1, #grid do -- draw tiles
    love.graphics.setColor(1.01 - 0.01*z, 0, 0)
    for y = 1, #grid[1] do
      for x = 1, #grid[1][1] do
        if grid[z][y][x] > 0 then
          if not map.floor_block(x, y, z) then
            love.graphics.rectangle("fill", (x-1)*tile_size, (y+z-2)*tile_size, tile_size, tile_size)
          end
        end
      end
    end
  end
  love.graphics.setColor(0, 0, 0)
  for i, v in ipairs(queue) do -- remove objects from mask
    graphics.draw(v)
  end
  love.graphics.setColor(1, 1, 1)
  love.graphics.setCanvas()
  shader.shadow:send("mask", shadow_mask)
end

map.draw = function()
  -- items and map
  graphics.draw_queue(0)
  for y, _ in ipairs(grid[1]) do
    for z, _ in ipairs(grid) do
      for x, tile in ipairs(grid[z][y]) do
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
    end
    graphics.draw_queue(y)
  end
  graphics.draw_queue(math.huge)
  -- shadows
  for i, v in ipairs(queue) do
    graphics.shadow(v)
  end
end

map.wall_block = function(x, y, z)
  for i = z, 1, -1 do
    if ((y+(z-i)+1 <= #grid[1] and grid[i][y+(z-i)+1][x] > 0)) then
      return true
    end
  end
  return false
end

map.floor_block = function(x, y, z)
  if z > 1 then
    for i = z-1, 1, -1 do
      if ((y+(z-i) <= #grid[1] and grid[i][y+(z-i)][x] > 0)) or ((y+(z-i-1) <= #grid[1] and grid[i][y+(z-i-1)][x] > 0)) then
        return true
      end
    end
  end
  return false
end

return map
