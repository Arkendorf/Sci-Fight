local collision = {}

collision.grid = function(obj)
  for i = 0, 1 do
    for j = 0, 1 do
      for k = 0, 1 do
        local x = 1+math.floor((obj.x + obj.l*k) / tile_size)
        local y = 1+math.floor((obj.y + obj.w*j) / tile_size)
        local z = 1+math.floor((obj.z + obj.h*i) / tile_size)

        local x_new = 1+math.floor((obj.x + obj.xV + obj.l*k) / tile_size)
        if collision.in_bounds(x_new, y, z) and grid[z][y][x_new] > 0 and tiles[grid[z][y][x_new]] > 0 then
          if obj.xV > 0 then
            obj.x = (x_new-1)*tile_size - obj.l - 0.1
          elseif obj.xV < 0 then
            obj.x = x_new*tile_size
          end
          obj.xV = 0
        end

        local y_new = 1+math.floor((obj.y + obj.yV + obj.w*j) / tile_size)
        if collision.in_bounds(x, y_new, z) and grid[z][y_new][x] > 0 and tiles[grid[z][y_new][x]] > 0 then
          if obj.yV > 0 then
            obj.y = (y_new-1)*tile_size - obj.w - 0.1
          elseif obj.yV < 0 then
            obj.y = y_new*tile_size
          end
          obj.yV = 0
        end

        local z_new = 1+math.floor((obj.z + obj.zV + obj.h*i) / tile_size)
        if collision.in_bounds(x, y, z_new) and grid[z_new][y][x] > 0 and tiles[grid[z_new][y][x]] > 0 then
          if obj.zV > 0 then
            obj.z = (z_new-1)*tile_size - obj.h - 0.1
            obj.jump = false
          elseif obj.zV < 0 then
            obj.z = z_new*tile_size
          end
          obj.zV = 0
        end
      end
    end
  end
end

collision.in_bounds = function(x, y, z)
  return (x > 0 and x <= #grid[1][1] and y > 0 and y <= #grid[1] and z > 0 and z <= #grid)
end

return collision
