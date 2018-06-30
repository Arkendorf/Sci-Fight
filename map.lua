local map = {}

tile_size = 32

map.load = function()
  -- maps must be within 100x100x100 for layering and shadows to work properly
  grid = love.filesystem.load("maps/time_machine.txt")()
  tiles = {1, 1, 1}

  -- shader stuff
  local x, y = #grid[1][1]*tile_size, (#grid+#grid[1])*tile_size
  shadow_mask = love.graphics.newCanvas(x, y)
  shader.shadow:send("mask_size", {x, y})

  layer_mask = love.graphics.newCanvas(x, y)
  shader.layer:send("mask_size", {x, y})

  shadow_canvas = love.graphics.newCanvas(x, y)
end

map.update_masks = function()
  -- draw layer mask
  love.graphics.setCanvas(layer_mask)
  map.iterate(game.draw_layer_mask)
  shader.layer:send("mask", layer_mask)


  -- draw shadow mask
  love.graphics.setCanvas(shadow_mask)
  map.iterate(game.draw_shadow_mask)
  shader.shadow:send("mask", shadow_mask)

  -- reset
  love.graphics.setColor(1, 1, 1)
  love.graphics.setCanvas()
end

map.draw = function()
  -- map
  map.iterate(game.draw_tiles)
end

map.wall_block = function(x, y, z)
  for i = z, 1, -1 do
    if (y+(z-i)+1 <= #grid[1] and grid[i][y+(z-i)+1][x] > 0) or (i < z and y+(z-i) <= #grid[1] and grid[i][y+(z-i)][x] > 0) then
      return true
    end
  end
  return false
end

map.floor_block = function(x, y, z)
  if z > 1 then
    for i = z-1, 1, -1 do
      if (y+(z-i) <= #grid[1] and grid[i][y+(z-i)][x] > 0) or (y+(z-i)-1 <= #grid[1] and grid[i][y+(z-i)-1][x] > 0) then
        return true
      end
    end
  end
  return false
end

map.vert_block = function(x, y, z)
  if z > 2 then
    for i = z-2, 1, -1 do
      if grid[i][y][x] > 0 then
        return true, i
      end
    end
  end
  return false
end

map.iterate = function(func)
  for z, _ in ipairs(grid) do
    for y, _ in ipairs(grid[1]) do
      for x, tile in ipairs(grid[z][y]) do
        func(x, y, z, tile)
      end
    end
  end
end

return map
