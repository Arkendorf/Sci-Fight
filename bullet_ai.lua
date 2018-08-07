local bullet_ai = {}

bullet_ai[1] = function(k, v, dt)
end

bullet_ai[2] = function(k, v, dt)
  local player = players[v.info]
  if not player then -- owner has left
    bullets[k] = nil
    return
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

  if v.collide and collision.bullet_and_cube(k, v, player) then -- return saber
    player.weapon.active = false
    bullets[k] = nil
    -- weapon animation
    char.weapon_anim(v.info, "base", 0)
    server:sendToAll("weaponanim", {index = v.info, anim = "base", speed = 0})
  end
end

bullet_ai[3] = function(k, v, dt)
  if not v.bounce_num then
    v.zV = v.zV - 3
    v.bounce_num = 0
  end
  if v.zV < 10 then
    v.zV = v.zV + 0.2
  elseif v.zV > 10 then
    v.zV = 10
  end
  if v.collide then
    v.xV = v.xV *0.7
    v.yV = v.yV *0.7
    v.zV = v.zV *0.7
    v.collide = false

    v.bounce_num = v.bounce_num + 1
    if v.bounce_num > 3 then
      bullet.explode(k, v)
    end
  end
end

bullet_ai[4] = function(k, v, dt)
  local target = {dist = math.huge}
  for l, w in pairs(players) do
    if l ~= v.parent then
      local l_x, l_y, l_z = v.x-w.x, v.y-w.y, v.z-w.z
      local dist = math.sqrt(l_x*l_x+l_y*l_y+l_z*l_z)
      if dist < target.dist then
        target = {dist = dist, num = l}
      end
    end
  end
  if target.num then
    player = players[target.num]
    local x1, y1, z1 = player.x+player.l/2, player.y+player.w/2, player.z+player.h/2
    local l_x, l_y, l_z = x1-v.x, y1-v.y, z1-v.z
    local speed = bullet_info[v.type].speed
    local xV = v.xV*0.9 + math.cos(math.atan2(math.sqrt(l_y*l_y+l_z*l_z), l_x))*speed*.1
    local yV = v.yV*0.9 + math.cos(math.atan2(math.sqrt(l_z*l_z+l_x*l_x), l_y))*speed*.1
    local zV = v.zV*0.9 + math.cos(math.atan2(math.sqrt(l_x*l_x+l_y*l_y), l_z))*speed*.1
    v.xV, v.yV, v.zV = xV, yV, zV
    v.angle = math.atan2(yV+zV, xV)
  end
end

bullet_ai[5] = function(k, v, dt)
  if not v.dmg then
    v.dmg = v.info
  end
end


return bullet_ai
