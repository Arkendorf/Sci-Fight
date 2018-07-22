local bullet_ai = {}

bullet_ai[1] = function(k, v, dt)
  v.x = v.x + v.xV * dt * 60
  v.y = v.y + v.yV * dt * 60
  v.z = v.z + v.zV * dt * 60
end

bullet_ai[2] = function(k, v, dt)
  local player = players[v.info]
  if not v.ipos then
    v.ipos = {x = player.x+player.l/2, y = player.y+player.w/2, z = player.z+player.h/2}
  end
  if not v.ppos then
    v.ppos = {xV = v.xV, yV = v.yV, zV = v.zV}
  end
  local speed = bullet_info[v.type].speed

  if true then --check LoS
    local xV, yV, zV = v.xV, v.yV, v.zV
    if not v.turn then
      local l_x, l_y, l_z = v.x-v.ipos.x, v.y-v.ipos.y, v.z-v.ipos.z
      local dist = math.sqrt(l_x*l_x+l_y*l_y+l_z*l_z)
      if dist > tile_size * 5 then
        v.turn = true
      end
    else
      local x1, y1, z1 = player.x+player.l/2, player.y+player.w/2, player.z+player.h/2
      local l_x, l_y, l_z = x1-v.x, y1-v.y, z1-v.z
      xV = math.cos(math.atan2(math.sqrt(l_y*l_y+l_z*l_z), l_x))*speed
      yV = math.cos(math.atan2(math.sqrt(l_z*l_z+l_x*l_x), l_y))*speed
      zV = math.cos(math.atan2(math.sqrt(l_x*l_x+l_y*l_y), l_z))*speed
    end
    if v.xV ~= v.ppos.xV or v.yV ~= v.ppos.yV or v.zV ~= v.ppos.zV then -- collision has occurred
      v.turn = true
      v.xV, v.yV, v.zV = v.xV*0.9+xV*0.1, v.yV*0.9+yV*0.1, v.zV*0.9+zV*0.1
    else
      v.xV, v.yV, v.zV = xV, yV, zV
    end
  end

  if v.turn and collision.bullet_and_cube(k, v, player) then -- return saber
    player.weapon.active = false
    bullets[k] = nil
  end

  v.angle = v.angle + dt * 24 -- spin

  bullet_ai[1](k, v, dt)
end


return bullet_ai
