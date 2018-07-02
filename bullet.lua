local bullet = {}

local laser_speed = 6

bullet.load = function()
  bullets = {}
end

bullet.update = function(dt)
  for k, v in pairs(bullets) do
    v.x = v.x + v.xV * dt * 60
    v.y = v.y + v.yV * dt * 60
    v.z = v.z + v.zV * dt * 60
    -- collide with map
    local p1, p2 = {x = v.x, y = v.y, z = v.z}, {x = v.x+v.xV, y = v.y+v.yV, z = v.z+v.zV}
    if collision.line_and_map(p1, p2) then
      bullets[k] = nil
    end
    -- collide with players
    for l, w in pairs(players) do
      if l ~= v.parent and collision.line_and_cube(p1, p2, w) then
        -- damage
        bullets[k] = nil
        break
      end
    end
    -- collide with borders (twice as large as map)
    if not collision.in_bounds((v.x/tile_size+#grid[1][1]/2)/2, (v.y/tile_size+#grid[1]/2)/2, (v.z/tile_size+#grid/2)/2) then
      bullets[k] = nil
    end
  end

end

bullet.draw = function()
  for k, v in pairs(bullets) do
    queue[#queue + 1] = {img = laser_img, x = v.x, y = v.y, z = v.z, h = 0, ox = 16, oy = 16, angle = v.angle, shadow = false}
  end
end

bullet.new = function(p1, p2, parent)
  local x1, y1, z1 = p1.x+p1.l/2, p1.y+p1.w/2, p1.z+p1.h/2
  local l_x, l_y, l_z = p2.x-x1, p2.y-y1, p2.z-z1
  local xV = math.cos(math.atan2(math.sqrt(l_y*l_y+l_z*l_z), l_x))
  local yV = math.cos(math.atan2(math.sqrt(l_z*l_z+l_x*l_x), l_y))
  local zV = math.cos(math.atan2(math.sqrt(l_x*l_x+l_y*l_y), l_z))
  local spot = #bullets+1
  bullets[spot] = {x = x1, y = y1, z = z1, xV = xV*laser_speed, yV = yV*laser_speed, zV = zV*laser_speed, angle = math.atan2(yV+zV, xV), parent = parent}
  return spot
end

return bullet
