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

collision.line_player = function(p1, p2)
  for k, v in pairs(players) do
    if collision.line_intersect(p1, p2, {x = v.x, y = v.y+v.z}, {x = v.x+v.l, y = v.y+v.z})
    or collision.line_intersect(p1, p2, {x = v.x+v.l, y = v.y+v.z}, {x = v.x+v.l, y = v.y+v.z+v.w+v.h})
    or collision.line_intersect(p1, p2, {x = v.x+v.l, y = v.y+v.z+v.w+v.h}, {x = v.x, y = v.y+v.z+v.w+v.h})
    or collision.line_intersect(p1, p2, {x = v.x, y = v.y+v.z+v.w+v.h}, {x = v.x, y = v.y+v.z}) then
      return k
    end
  end
  return false
end

collision.line_and_cube = function(p1, p2, p3, l, w, h)
  local continue = false
  for i = 0, 1 do
    for j = 0, 1 do
      if collision.line_intersect(p1, p2, {x = p3.x+l*j, y = p3.y+w*i}, {x = p3.x+l*collision.loop(j+1, 0, 1), y = p3.y+w*collision.loop(i+1, 0, 1)}) then
        continue = true
      end
    end
  end
  if not continue then return false end
  continue = false
  local new_p = collision.swap(p3, "x", "z")
  for i = 0, 1 do
    for j = 0, 1 do
      if collision.line_intersect(collision.swap(p1, "x", "z"), collision.swap(p2, "x", "z"), {x = new_p.x+l*j, y = new_p.y+h*i}, {x = new_p.x+l*collision.loop(j+1, 0, 1), y = new_p.y+h*collision.loop(i+1, 0, 1)}) then
        continue = true
      end
    end
  end
  if not continue then return false end
  continue = false
  local new_p = collision.swap(p3, "z", "y")
  for i = 0, 1 do
    for j = 0, 1 do
      if collision.line_intersect(collision.swap(p1, "z", "y"), collision.swap(p2, "z", "y"), {x = new_p.x+h*j, y = new_p.y+w*i}, {x = new_p.x+h*collision.loop(j+1, 0, 1), y = new_p.y+w*collision.loop(i+1, 0, 1)}) then
        continue = true
      end
    end
  end
  return continue
end

collision.line_and_map = function(p1, p2)
end

return collision
