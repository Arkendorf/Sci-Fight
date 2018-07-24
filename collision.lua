local collision = {}

collision.grid = function(obj)
  for i = 0, 1 do
    for j = 0, 1 do
      for k = 0, 1 do
        local x = collision.coord_to_tile(obj.x, obj.l, k)
        local y = collision.coord_to_tile(obj.y, obj.w, j)
        local z = collision.coord_to_tile(obj.z, obj.h, i)

        local z_new = collision.coord_to_tile(obj.z+obj.zV*global_dt*60, obj.h, i)
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

        local x_new = collision.coord_to_tile(obj.x+obj.xV*global_dt*60, obj.l, k)
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

        local y_new = collision.coord_to_tile(obj.y+obj.yV*global_dt*60, obj.w, j)
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
      -- local i = {x = p1.x + (t * s1.x), y = p1.y+ (t * s1.y)}
      return true, t
    end
  end

  return false
end

collision.line_and_circle = function(p1, p2, p3, r)
  local d = {x = p2.x-p1.x, y = p2.y-p1.y}
  local f = {x = p1.x-p3.x, y = p1.y-p3.y}
  local a = d.x*d.x + d.y*d.y
  local b = 2*(f.x*d.x+f.y*d.y)
  local c = f.x*f.x + f.y*f.y - r*r ;
  local  disc = b*b-4*a*c;
  if disc >= 0 then
    disc = math.sqrt(disc)
    local t1 = (-b - disc)/(2*a)
    local t2 = (-b + disc)/(2*a)
    if (( t1 >= 0 and t1 <= 1 ) or ( t2 >= 0 and t2 <= 1 )) then
      return true
    end
  end
  return false
end

collision.circle_and_square = function(p, c, r)
  local dist = {}
  dist.x = math.abs(p.x - c.x-c.w/2)
  dist.y = math.abs(p.y - c.y-c.h/2)

  if (dist.x > c.w/2 + r) or (dist.y > c.h/2 + r) then
    return false
  end
  if (dist.x <= c.w/2) or (dist.y <= c.h/2) then
    return true
  end

  corner_dist = (dist.x - c.w/2)*(dist.x - c.w/2) + (dist.y - c.h/2)*(dist.y - c.h/2)
  return (corner_dist <= r*r)
end

collision.line_and_sphere = function(p1, p2, p3, r)
  local d = {x = p2.x-p1.x, y = p2.y-p1.y, z = p2.z-p1.z}
  local f = {x = p1.x-p3.x, y = p1.y-p3.y, z = p1.z-p3.z}
  local a = d.x*d.x + d.y*d.y + d.z*d.z
  local b = 2*(f.x*d.x + f.y*d.y + f.z*d.z)
  local c = f.x*f.x + f.y*f.y + f.z*f.z - r*r
  local  disc = b*b-4*a*c
  if disc >= 0 then
    disc = math.sqrt(disc)
    local t1 = (-b - disc)/(2*a)
    local t2 = (-b + disc)/(2*a)
    if (( t1 >= 0 and t1 <= 1 ) or ( t2 >= 0 and t2 <= 1 )) then
      return true
    end
  end
  return false
end

local corners = {{x = 0, y = 0}, {x = 1, y = 0}, {x = 1, y = 1}, {x = 0, y = 1}, {x = 0, y = 0}}
collision.line_and_square = function(p1, p2, c)
  for j = 1, #corners - 1 do
    if collision.line_intersect(p1, p2, {x = c.x+c.w*corners[j].x, y = c.y+c.h*corners[j].y}, {x = c.x+c.w*corners[j+1].x, y = c.y+c.h*corners[j+1].y}) then
      return true
    end
  end
  return false
end

local faces = {{x = "x", y = "y", z = "z", w = "l", h = "w"}, {x = "x", y = "z", z = "y", w = "l", h = "h"}, {x = "z", y = "y", z = "x", w = "h", h = "w"}}
collision.line_and_cube = function(p1, p2, c)
  local progress = 0
  for i, v in ipairs(faces) do
    if collision.line_and_square({x = p1[v.x], y = p1[v.y]}, {x = p2[v.x], y = p2[v.y]}, {x = c[v.x], y = c[v.y], w = c[v.w], h = c[v.h]}) then
      progress = progress + 1
    end
  end
  if progress > 1 then
    return true
  else
    return false
  end
end

collision.sphere_and_cube = function(p, c, r)
  local progress = 0
  for i, v in ipairs(faces) do
    for j = 1, #corners - 1 do
      if collision.circle_and_square({x = p[v.x], y = p[v.y]}, {x = c[v.x], y = c[v.y], w = c[v.w], h = c[v.h]}, r[v.r]) then
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

collision.sphere_and_sphere = function(p1, p2, r1, r2)
  local x, y, z = p2.x-p1.x, p2.y-p1.y, p2.z-p1.z
  local dist = math.sqrt(x*x+y*y+z*z)
  return dist < r1+r2
end

collision.line_and_tile = function(p1, p2, t)
  local progress = 0
  local face_collide = {false, false, false}
  for i, v in ipairs(faces) do
    for j = 1, #corners - 1 do
      if collision.line_intersect({x = p1[v.x], y = p1[v.y]}, {x = p2[v.x], y = p2[v.y]}, {x = c[v.x]+c[v.w]*corners[j].x, y = c[v.y]+c[v.h]*corners[j].y}, {x = c[v.x]+c[v.w]*corners[j+1].x, y = c[v.y]+c[v.h]*corners[j+1].y}) then
        progress = progress + 1
        face_collide[i] = true
        break
      end
    end
  end
  if progress > 1 then
    return true, collision.face(face_collide)
  else
    return false
  end
end

collision.bullet_and_cube = function(k, v, c)
  p1, p2 = bullet.get_points(v)
  return collision.line_and_cube(p1, p2, c)
end

collision.line_and_map = function(p1, p2)
  local x_min = 1+math.floor(math.min(p1.x, p2.x)/tile_size)
  local x_max = 1+math.floor(math.max(p1.x, p2.x)/tile_size)
  local y_min = 1+math.floor(math.min(p1.y, p2.y)/tile_size)
  local y_max = 1+math.floor(math.max(p1.y, p2.y)/tile_size)
  local z_min = 1+math.floor(math.min(p1.z, p2.z)/tile_size)
  local z_max = 1+math.floor(math.max(p1.z, p2.z)/tile_size)

  local face = {x = 0, y = 0, z = 0}
  local frac = 1
  local hits = {}
  for z = z_min, z_max do
    for y = y_min, y_max do
      for x = x_min, x_max do
        if collision.in_bounds(x, y, z) and tiles[grid[z][y][x]] == 1 then
          local cube = {x = (x-1)*tile_size, y = (y-1)*tile_size, z = (z-1)*tile_size, l = tile_size, w = tile_size, h = tile_size}
          if collision.line_and_cube(p1, p2, cube) then
            hits[#hits+1] = {x = x, y = y, z = z}
            local new_face, new_frac = collision.find_face(p1, p2, cube)
            if new_face then
              for k, v in pairs(new_face) do
                if v > 0 then
                  face[k] = 1
                end
              end
              if new_frac < frac then
                frac = new_frac
              end
            end
          end
        end
      end
    end
  end
  if face.x+face.y+face.z > 1 then
    blah = hits
  end
  if face.x > 0 or face.y > 0 or face.z > 0 then
    return face, frac
  else
    return false
  end
end

collision.find_face = function(p1, p2, t)
  for i, v in ipairs(faces) do
    for j = 1, #corners - 1 do
      local corner1 = corners[j]
      local corner2 = corners[j+1]
      local x_offset = corner2.y-corner1.y
      local y_offset = corner1.x-corner2.x
      if x_offset * (p2[v.x]-p1[v.x]) < 0 or y_offset * (p2[v.y]-p1[v.y]) < 0 then -- make sure edge is in LoS
        local tile = collision.get_tile({[v.x] = 1+math.floor(t[v.x]/tile_size)+x_offset, [v.y] = 1+math.floor(t[v.y]/tile_size)+y_offset, [v.z] = 1+math.floor(t[v.z]/tile_size)})
        if tiles[tile] == 0 then --no adjacent tile to edge
          local collide, frac = collision.line_intersect({x = p1[v.x], y = p1[v.y]}, {x = p2[v.x], y = p2[v.y]}, {x = t[v.x]+tile_size*corner1.x, y = t[v.y]+tile_size*corner1.y}, {x = t[v.x]+tile_size*corner2.x, y = t[v.y]+tile_size*corner2.y})
          if collide then
            return {[v.x] = math.abs(x_offset), [v.y] = math.abs(y_offset)}, frac
          end
        end
      end
    end
  end
  return false
end

collision.get_tile = function(coords)
  if collision.in_bounds(coords.x, coords.y, coords.z) then
    return grid[coords.z][coords.y][coords.x]
  else
    return 0
  end
end

return collision
