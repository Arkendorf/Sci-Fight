local map = {}

tile_size = 32

map.load = function()
  -- maps must be within 100x100x100 for layering and shadows to work properly
  tiles = {[0] = 0, 1, 1, 1, 1, 1, 1, 1}

  prop_info = {}
  prop_info[1] = {l = 2, w = 2, h = 2, img = 1}

  map.set(1)
end

map.update_masks = function()
end

map.draw = function()
  -- map
  love.graphics.draw(map_canvas)
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

map.column = function(x, y, z)
  local new_ox = -1
  local new_oy = -1
  for new_z = 1, z do
    new_x = x-(z-new_z+1)
    new_y = y-(z-new_z+1)
    if new_x >= 1 and new_x <= #grid[1][1] and new_y >= 1 and new_y <= #grid[1] then
      if grid[new_z][new_y][new_x] > 0 then
        return true
      end
    end
  end
  return false
end

map.in_bounds = function(x, y, z)
  return (x >= 1 and x <= #grid[1][1] and y >= 1 and y <= #grid[1] and z >= 1 and z <= #grid)
end

map.set = function(num)
  grid = maps[num].grid
  props = maps[num].props

  -- shader stuff
  local x, y = #grid[1][1]*tile_size, (#grid+#grid[1])*tile_size

  layer_mask = love.graphics.newCanvas(x, y)
  shader.layer:send("mask_size", {x, y})
  -- draw layer mask
  love.graphics.setCanvas(layer_mask)
  map.iterate(game.draw_layer_mask)
  game.draw_props("prop_layer_mask", layer_mask)
  shader.layer:send("mask", layer_mask)

  shadow_mask = love.graphics.newCanvas(x, y)
  shader.shadow:send("mask_size", {x, y})
  -- draw shadow mask
  love.graphics.setCanvas(shadow_mask)
  map.iterate(game.draw_shadow_mask)
  game.draw_props("prop_shadow_mask", layer_mask)
  shader.shadow:send("mask", shadow_mask)

  love.graphics.setShader()

  map_canvas = love.graphics.newCanvas(x, y)
  love.graphics.setCanvas(map_canvas)
  love.graphics.clear()
  map.iterate(game.draw_tiles)
  map.iterate(game.draw_tile_shadows) -- draw tile shadows
  game.draw_props("prop_layer", layer_mask)

  -- reset
  love.graphics.setColor(1, 1, 1)
  love.graphics.setCanvas()
end

return map
