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
    -- collide with players
    if collision.line_and_map({x = v.x, y = v.y, z = v.z}, {x = v.x+v.xV, y = v.y+v.yV, z = v.z+v.zV}) then
      bullets[k] = nil
    end

    -- collide with borders (twice as large as map)
    if not collision.in_bounds((v.x/tile_size+#grid[1][1])/2, (v.y/tile_size+#grid[1])/2, (v.z/tile_size+#grid)/2) then
      bullets[k] = nil
    end
  end

end

bullet.draw = function()
  for k, v in pairs(bullets) do
    queue[#queue + 1] = {img = laser_img, x = v.x, y = v.y, z = v.z, h = 0, ox = 16, oy = 16, angle = v.angle, shadow = false}
  end
end

bullet.new = function(p1, p2)
  local x1, y1, z1 = p1.x+p1.l/2, p1.y+p1.w/2, p1.z+p1.h/2
  local l_x, l_y, l_z = p2.x-x1, p2.y-y1, p2.z-z1
  local ax = math.atan2(math.sqrt(l_y*l_y+l_z*l_z), l_x)
  local ay = math.atan2(math.sqrt(l_z*l_z+l_x*l_x), l_y)
  local az = math.atan2(math.sqrt(l_x*l_x+l_y*l_y), l_z)
  bullets[#bullets+1] = {x = x1, y = y1, z = z1, xV = math.cos(ax)*laser_speed, yV = math.cos(ay)*laser_speed, zV = math.cos(az)*laser_speed, angle = math.atan2(math.cos(ay)+math.cos(az),  math.cos(ax)), parent = id}
end

return bullet
