local map = {}

map.load = function()
  grid = {
    {{1, 1, 0, 0, 1},
     {0, 0, 0, 0, 0},
     {1, 0, 0, 0, 0},
     {0, 0, 0, 0, 0},
     {0, 0, 0, 0, 0}},

    {{1, 1, 1, 1, 1},
     {0, 0, 1, 0, 1},
     {1, 1, 0, 0, 0},
     {0, 0, 0, 0, 0},
     {0, 0, 0, 1, 0}},

    {{1, 1, 1, 1, 1},
     {1, 1, 1, 1, 1},
     {1, 1, 1, 1, 1},
     {1, 1, 1, 1, 1},
     {1, 1, 1, 1, 1}}
        }

  tiles = {1}
  tile_size = 32
end


map.draw = function()

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
