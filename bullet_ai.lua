local bullet_ai = {}

bullet_ai[1] = function(k, v, dt)
end

bullet_ai[2] = function(k, v, dt)
  local player = players[v.info]
  if not player then -- owner has left
    bullets[k] = nil
  end
  v.parent = v.info -- in case it's reflected
  if not v.start then
    v.start = {x = player.x+player.l/2, y = player.y+player.w/2, z = player.z+player.h/2}
  end

  if not v.collide then
    local l_x, l_y, l_z = v.x-v.start.x, v.y-v.start.y, v.z-v.start.z
    local dist = math.sqrt(l_x*l_x+l_y*l_y+l_z*l_z)
    if dist > tile_size * 6 then
      v.collide = true
    end
  else
    local x1, y1, z1 = player.x+player.l/2, player.y+player.w/2, player.z+player.h/2
    local l_x, l_y, l_z = x1-v.x, y1-v.y, z1-v.z
    local speed = bullet_info[v.type].speed
    local xV = v.xV*0.9 + math.cos(math.atan2(math.sqrt(l_y*l_y+l_z*l_z), l_x))*speed*.1
    local yV = v.yV*0.9 + math.cos(math.atan2(math.sqrt(l_z*l_z+l_x*l_x), l_y))*speed*.1
    local zV = v.zV*0.9 + math.cos(math.atan2(math.sqrt(l_x*l_x+l_y*l_y), l_z))*speed*.1
    v.xV, v.yV, v.zV = xV, yV, zV
  end

  if not v.rangle then
    v.rangle = v.angle
  else
    v.rangle = v.rangle + dt * 24 -- spin
    v.angle = v.rangle
  end

  if v.collide and collision.bullet_and_cube(k, v, player) then -- return saber
    player.weapon.active = false
    bullets[k] = nil
  end
end


return bullet_ai
