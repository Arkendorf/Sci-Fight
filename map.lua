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


  -- shader stuff
  floor_canvas = love.graphics.newCanvas(#grid[1][1]*#grid[1], #grid+#grid[1])
  love.graphics.setCanvas(floor_canvas)
  for z = 1, #grid do
    for y = 1, #grid[1] do
      for x = 1, #grid[1][1] do
        if grid[z][y][x] > 0 then
          love.graphics.rectangle("fill", (x-1)+(z-1)*#grid[1], (y-1)+(z-1), 1, 1)
        end
      end
    end
  end
  love.graphics.setCanvas()
  shader.shadow:send("grid", floor_canvas)
  -- shader.shadow:send("grid_w", #grid[1])
  shader.shadow:send("grid_size", {tile_size*#grid[1][1]*#grid[1], tile_size*(#grid+#grid[1])})
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

  -- shadow
  love.graphics.setShader(shader.shadow)
  for z = 1+math.floor((char.z+char.h*0.5)/tile_size), #grid-1 do
    shader.shadow:send("coords", {char.x, char.y, z*tile_size})
    love.graphics.draw(shadow_img, char.x, char.y+z*tile_size)
  end
  love.graphics.setShader()

  love.graphics.draw(floor_canvas, 300, 200, 0, 4, 4)
  love.graphics.setColor(255, 0, 0)
  love.graphics.rectangle("fill", 300+(char.x+char.z*#grid[1][1])/(#grid[1][1]*#grid[1]*tile_size) *#grid[1][1]*#grid[1]*4, 200+(char.y)/(tile_size*(#grid+#grid[1])) *(#grid+#grid[1])*4, 4, 4)
  love.graphics.setColor(255, 255, 255)
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
