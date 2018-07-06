local bullet_ai = {}

bullet_ai[1] = function(k, v, dt)
  v.x = v.x + v.xV * dt * 60
  v.y = v.y + v.yV * dt * 60
  v.z = v.z + v.zV * dt * 60
end

bullet_ai[2] = function(k, v, dt)
  if not v.t then
    v.t = 0
  else
    v.t = v.t + dt
  end
  local target = players[v.info]
  local speed = 0.1


  local x1, y1, z1 = target.x+target.l/2, target.y+target.w/2, target.z+target.h/2
  local l_x, l_y, l_z = x1-v.x, y1-v.y, z1-v.z
  v.xV = v.xV + math.cos(math.atan2(math.sqrt(l_y*l_y+l_z*l_z), l_x))*speed
  v.yV = v.yV + math.cos(math.atan2(math.sqrt(l_z*l_z+l_x*l_x), l_y))*speed
  v.zV = v.zV + math.cos(math.atan2(math.sqrt(l_x*l_x+l_y*l_y), l_z))*speed

  if v.t > 0.4 and bullet.cube_collide(k, v, target) then
    target.weapon.active = false
    bullets[k] = nil
  end

  v.angle = v.angle + dt * 12

  bullet_ai[1](k, v, dt)
end


return bullet_ai
