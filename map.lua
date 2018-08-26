local map = {}

tile_size = 32

map.load = function()
  -- maps must be within 100x100x100 for layering and shadows to work properly
  tiles = {[0] = 0, 1, 1, 1, 1, 1, 1, 1}

  prop_info = {}
  prop_info.console = {l = 4, w = 4, h = 1, img = "console", shadow = true}
  prop_info.runetop = {l = 4, w = 4, h = 1, img = "runetop", shadow = true}
  prop_info.timerods = {l = 2, w = 2, h = 3, img = "timerods", shadow = true}
  prop_info.railingright = {l = 1, w = 1, h = 1, img = "railingright"}

  map.set(1)
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
    for i, v in ipairs(props) do
      if prop_info[v.type].shadow then
        local cube = {x = v.x, y = v.y, z = v.z, l = prop_info[v.type].l, w = prop_info[v.type].w, h = prop_info[v.type].h}
        if collision.cube_and_cube(cube, {x = new_x, y = new_y, z = new_z, l = 1, w = 1, h = 1}) then
          return true
        end
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
  table.sort(props, function(a, b) return a.z > b.z end)

  -- shader stuff
  local x, y = #grid[1][1]*tile_size, (#grid+#grid[1])*tile_size

  layer_mask = love.graphics.newCanvas(x, y) -- create layer mask
  shader.layer:send("mask_size", {x, y})
  -- draw layer mask
  love.graphics.setCanvas(layer_mask)
  map.iterate(game.draw_layer_mask) -- draw tile layer mask
  game.draw_props("prop_layer_mask", layer_mask) -- draw prop layer mask
  shader.layer:send("mask", layer_mask)

  shadow_mask = love.graphics.newCanvas(x, y) -- create shadow mask
  shader.shadow:send("mask_size", {x, y})
  -- draw shadow mask
  love.graphics.setCanvas(shadow_mask)
  map.iterate(game.draw_shadow_mask) -- draw tile layer mask
  game.draw_props("prop_shadow_mask", layer_mask, true) -- draw prop layer mask
  shader.shadow:send("mask", shadow_mask)

  love.graphics.setColor(1, 1, 1) -- reset
  love.graphics.setShader()

  border_canvas = love.graphics.newCanvas(x, y) -- create canvas for borders (helps with perspective)
  love.graphics.setCanvas(border_canvas)
  love.graphics.clear()
  game.draw_prop_border(x, y) -- draw borders due to props
  love.graphics.setColor(0, 0, 0)
  game.draw_props("color") -- block out actual prop from borders
  love.graphics.setColor(1, 1, 1)
  shader.layer:send("xray_color", {0, 0, 0, 0})
  shader.layer:send("offset", {0, 0})
  map.iterate(game.draw_borders) -- draw borders due to tiles

  map_canvas = love.graphics.newCanvas(x, y) -- create canvas you actually see
  love.graphics.setCanvas(map_canvas)
  love.graphics.clear()
  map.iterate(game.draw_tiles) -- draw tiles
  love.graphics.setColor(0.2, 0.2, 0.3, 0.5)
  map.iterate(game.draw_tile_shadows) -- draw tile shadows
  love.graphics.setColor(1, 1, 1)
  game.draw_props("prop_layer", layer_mask) -- draw props
  love.graphics.setShader(shader.border) -- only draw borders, ignore blocks
  love.graphics.draw(border_canvas) -- draw borders
  love.graphics.setShader()

  love.graphics.setColor(1, 1, 1) -- reset
  love.graphics.setCanvas()
end

return map
