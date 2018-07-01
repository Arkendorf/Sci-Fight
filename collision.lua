local collision = {}

collision.grid = function(obj)
  for i = 0, 1 do
    for j = 0, 1 do
      for k = 0, 1 do
        local x = collision.coord_to_tile(obj.x, obj.l, k)
        local y = collision.coord_to_tile(obj.y, obj.w, j)
        local z = collision.coord_to_tile(obj.z, obj.h, i)

        local z_new = collision.coord_to_tile(obj.z+obj.zV, obj.h, i)
        if collision.in_bounds(x, y, z_new) and grid[z_new][y][x] > 0 and tiles[grid[z_new][y][x]] == 1 then
          if obj.zV > 0 then
            obj.z = (z_new-1)*tile_size - obj.h
            obj.jump = false
          elseif obj.zV < 0 then
            obj.z = z_new*tile_size
          end
          obj.zV = 0
          -- recalculate z
          z = collision.coord_to_tile(obj.z, obj.h, i)
        end

        local x_new = collision.coord_to_tile(obj.x+obj.xV, obj.l, k)
        if collision.in_bounds(x_new, y, z) and grid[z][y][x_new] > 0 and tiles[grid[z][y][x_new]] == 1 then
          if obj.xV > 0 then
            obj.x = (x_new-1)*tile_size - obj.l
          elseif obj.xV < 0 then
            obj.x = x_new*tile_size
          end
          obj.xV = 0
          -- recalculate x
          x = collision.coord_to_tile(obj.x, obj.l, k)
        end

        local y_new = collision.coord_to_tile(obj.y+obj.yV, obj.w, j)
        if collision.in_bounds(x, y_new, z) and grid[z][y_new][x] > 0 and tiles[grid[z][y_new][x]] == 1 then
          if obj.yV > 0 then
            obj.y = (y_new-1)*tile_size - obj.w
          elseif obj.yV < 0 then
            obj.y = y_new*tile_size
          end
          obj.yV = 0
        end
      end
    end
  end
end

collision.coord_to_tile = function(x, w, k)
  if x+w*k > x+w*0.5 then
    return math.ceil((x+w*k)/tile_size)
  else
    return 1+math.floor((x+w*k)/tile_size)
  end
end

collision.in_bounds = function(x, y, z)
  return (x > 0 and x <= #grid[1][1] and y > 0 and y <= #grid[1] and z > 0 and z <= #grid)
end

collision.line_intersect = function(p1, p2, p3, p4)
  local s1 = {x = p2.x - p1.x, y = p2.y - p1.y}
  local s2 = {x = p4.x - p3.x, y = p4.y - p3.y}

  local denom = (-s2.x * s1.y + s1.x * s2.y)
  if denom ~= 0 then
    local s = (-s1.y * (p1.x - p3.x) + s1.x * (p1.y - p3.y)) / denom
    local t = ( s2.x * (p1.y - p3.y) - s2.y * (p1.x - p3.x)) / denom

    if s >= 0 and s <= 1 and t >= 0 and t <= 1 then
      local i = {x = p1.x + (t * s1.x), y = p1.y+ (t * s1.y)}
      return true, i
    end
  end

  return false
end

local corners = {{x = 0, y = 0}, {x = 1, y = 0}, {x = 1, y = 1}, {x = 0, y = 1}, {x = 0, y = 0}}
local faces = {{x = "x", y = "y", w = "l", h = "w"}, {x = "x", y = "z", w = "l", h = "h"}, {x = "z", y = "y", w = "h", h = "w"}}
collision.line_and_cube = function(p1, p2, c)
  local progress = 0
  for i, v in ipairs(faces) do
    for j = 1, #corners - 1 do
      if collision.line_intersect({x = p1[v.x], y = p1[v.y]}, {x = p2[v.x], y = p2[v.y]}, {x = c[v.x]+c[v.w]*corners[j].x, y = c[v.y]+c[v.h]*corners[j].y}, {x = c[v.x]+c[v.w]*corners[j+1].x, y = c[v.y]+c[v.h]*corners[j+1].y}) then
        progress = progress + 1
        break
      end
    end
    if progress > 1 then
      return true
    end
  end
  return false
end

collision.line_and_map = function(p1, p2)
  local x_min, x_max = 0, 0
  if p1.x < p2.x then
    x_min = 1+math.floor(p1.x/tile_size)
    x_max = 1+math.floor(p2.x/tile_size)
  else
    x_min = 1+math.floor(p2.x/tile_size)
    x_max = 1+math.floor(p1.x/tile_size)
  end
  local y_min, y_max = 0, 0
  if p1.y < p2.y then
    y_min = 1+math.floor(p1.y/tile_size)
    y_max = 1+math.floor(p2.y/tile_size)
  else
    y_min = 1+math.floor(p2.y/tile_size)
    y_max = 1+math.floor(p1.y/tile_size)
  end
  local z_min, z_max = 0, 0
  if p1.z < p2.z then
    z_min = 1+math.floor(p1.z/tile_size)
    z_max = 1+math.floor(p2.z/tile_size)
  else
    z_min = 1+math.floor(p2.z/tile_size)
    z_max = 1+math.floor(p1.z/tile_size)
  end
  for z = z_min, z_max do
    for y = y_min, y_max do
      for x = x_min, x_max do
        if collision.in_bounds(x, y, z) and grid[z][y][x] > 0 and tiles[grid[z][y][x]] == 1 then
          if collision.line_and_cube(p1, p2, {x = (x-1)*tile_size, y = (y-1)*tile_size, z = (z-1)*tile_size, l = tile_size, w = tile_size, h = tile_size}) then
            return true
          end
        end
      end
    end
  end
  return false
end

return collision
