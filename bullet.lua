local bullet_ai = require "bullet_ai"

local bullet = {}

local tile_buffer = 12
local inv_time = 0.4

bullet.load = function()
  bullets = {}

  bullet_info = {}
  bullet_info.laser = {ai = 1, speed = 6, r = 0, dmg = 10, img = "laser", flare = true, color = {0, 1, 0}}
  bullet_info.powerlaser = {ai = 1, speed = 6, r = 0, dmg = 20, img = "laser", flare = true, color = {0, 1, 0}}
  bullet_info.charge = {ai = 5, speed = 6.3, r = 0, dmg = 10, img = "charge", explosion = {dmg = 0, r = 24}, flare = true, color = {0, 1, 1}}
  bullet_info.pierce = {ai = 1, speed = 7, r = 0, dmg = 25, img = "pierce", pierce = true, flare = true, color = {1, 0, 0}}
  bullet_info.missile = {ai = 4, speed = 2.2, r = 12, dmg = 0, img = "missile", shadow = true, explosion = {dmg = 20, r = 32}, particle = "jet"}
  bullet_info.grenade = {ai = 3, speed = 3, r = 12, dmg = 0, persistant = true, img = "grenade", shadow = true, explosion = {dmg = 30, r = 64}}
  bullet_info.saber1 = {ai = 2, speed = 4, r = 16, dmg = 25, persistant = true, img = "saber1", shadow = true, anim_speed = 30, color = weapons[1].color}
  bullet_info.saber2 = {ai = 2, speed = 4, r = 16, dmg = 25, persistant = true, img = "saber2", shadow = true, anim_speed = 30, color = weapons[2].color}
  bullet_info.saber3 = {ai = 2, speed = 4, r = 16, dmg = 25, persistant = true, img = "saber3", shadow = true, anim_speed = 30, color = weapons[3].color}
  bullet_info.saber4 = {ai = 2, speed = 4, r = 16, dmg = 25, persistant = true, img = "saber4", shadow = true, anim_speed = 30, color = weapons[4].color}
end

bullet.update = function(dt)
  for k, v in pairs(bullets) do
    if v.freeze <= 0 then
      -- collide with map
      if not bullet_info[v.type].pierce then
        bullet.map_collide(k, v)
      end
      -- collide with borders
      bullet.bound_collide(k, v)
      -- update pos
      v.x = v.x + v.xV * dt * 60
      v.y = v.y + v.yV * dt * 60
      v.z = v.z + v.zV * dt * 60
    else
      v.freeze = v.freeze - dt
    end
    -- animation
    if bullet_info[v.type].anim_speed then
      v.frame = v.frame+dt*bullet_info[v.type].anim_speed
      if v.frame > #bullet_quad[bullet_info[v.type].img]+1 then
        v.frame = 1
      end
    end

    if bullet_info[v.type].particle then
      particle.new(v.x, v.y, v.z, -v.xV+math.random()-.5, -v.yV+math.random()-.5, -v.zV+math.random()-.5, bullet_info[v.type].particle)
    end
  end
end

bullet.serverupdate = function(dt)
  for k, v in pairs(bullets) do
    if v.freeze <= 0 then
      if v.explode then
        bullet.explode(k, v)
      end
      -- collide with players
      bullet.player_collide(k, v)
      -- update velocity
      bullet_ai[bullet_info[v.type].ai](k, v, dt)
      -- send update info
      if bullets[k] then
        if not v.old or v.x ~= v.old.x or v.y ~= v.old.y or v.z ~= v.old.z or v.xV ~= v.old.xV or v.yV ~= v.old.yV or v.zV ~= v.old.yV or v.angle ~= v.old.angle then
          server:sendToAll("bulletupdate", {index = k, pos = {x = v.x, y = v.y, z = v.z, xV = v.xV, yV = v.yV, zV = v.zV, angle = v.angle}})
          v.old = {x = v.x, y = v.y, z = v.z, xV = v.xV, yV = v.yV, zV = v.zV, angle = v.angle}
        end
      else -- delete bullet
        server:sendToAll("bulletkill", k)
      end
    end
  end
end

bullet.queue = function()
  for k, v in pairs(bullets) do
    queue[#queue + 1] = {img = bullet_img[bullet_info[v.type].img], quad = bullet_quad[bullet_info[v.type].img][math.floor(v.frame)], x = v.x, y = v.y, z = v.z, h = 0, w = 0, l = 0, r = bullet_info[v.type].r/2, ox = 16, oy = 16, angle = v.angle, shadow = bullet_info[v.type].shadow}
  end
end

bullet.get_points = function(v, dt)
  if not dt then
    dt = global_dt
  end
  return {x = v.x, y = v.y, z = v.z}, {x = v.x+v.xV*dt*60, y = v.y+v.yV*dt*60, z = v.z+v.zV*dt*60}
end

bullet.map_collide = function(k, v)
  for i = 1, 3 do -- one for each face
    local p1, p2 = bullet.get_points(v)
    local face, frac = collision.line_and_map(p1, p2)
    if face then
      v.collide = face
      v.x, v.y, v.z = v.x+v.xV*frac, v.y+v.yV*frac, v.z+v.zV*frac
      bullet.spark(v, {x = v.xV, y = v.yV, z = v.zV}, bullet_info[v.type].color)
      if bullet_info[v.type].explosion and not bullet_info[v.type].persistant and server then
        v.explode = true
        break
      elseif bullet.destroy(k, v, face) then
        break
      end
    end
  end
end

bullet.player_collide = function(k, v) -- only server should do this
  local p1, p2 = bullet.get_points(v)
  for l, w in pairs(players) do
    if l ~= v.parent and char.damageable(l, v.parent) and collision.line_and_cube(p1, p2, w) then
      if bullet_info[v.type].explosion then
        bullet.explode(k, v)
      elseif bullet_info[v.type].dmg > 0 then
        local num = w.hp - bullet_info[v.type].dmg*weapons[players[v.parent].weapon.type].mod -- bullet damage * weapon modifier
        local dir, color = {x = v.xV, y = v.yV, z = v.zV}, bullet_info[v.type].color
        bullet.damage(w, num, v.parent, dir, color)
        server:sendToAll("hit", {index = l, num = num, parent = v.parent, dir = dir, color = color})
      end
      bullet.destroy(k, v, {x = 0, y = 0, z = 0})
      break
    end
  end
end

bullet.damage = function(player, num, parent, dir, color)
  player.hp = num
  player.inv = inv_time
  if parent then
    player.killer = parent
    bullet.spark(player, dir, color)
  end
  -- knock back player
  if dir then
    local norm = math.sqrt(dir.x*dir.x+dir.y*dir.y+dir.z*dir.z)
    player.xV = player.xV + dir.x/norm
    player.yV = player.yV + dir.y/norm
    player.zV = player.zV + dir.z/norm
  end
  -- blood particle
  for i = 1, 3 do
    local dir = {x = math.random()-.5, y = math.random()-.5}
    local norm = math.sqrt(dir.x*dir.x+dir.y*dir.y)
    local mag = 3
    particle.new(player.x+player.l/2, player.y+player.w/2, player.z+player.h/2, dir.x/norm*mag, dir.y/norm*mag, 0, "blood")
  end
  if player.hp <= 0 then
    char.death(player)
  end
end

bullet.explode = function(k, v)
  local info = bullet_info[v.type].explosion
  local dmg = info.dmg
  if v.dmg then
    dmg = v.dmg
  end
  for l, w in pairs(players) do
    if l ~= v.parent and char.damageable(l, v.parent) and collision.sphere_and_cube(v, w, info.r) and not collision.line_and_map(v, {x = w.x+w.l/2, y = w.y+w.w/2, z = w.z+w.h/2}) then
      local num = w.hp - dmg*weapons[players[v.parent].weapon.type].mod -- bullet damage * weapon modifier
      bullet.damage(w, num, v.parent)
      server:sendToAll("hit", {index = l, num = num, parent = v.parent})
    end
  end
  bullet.explode_particle(v, info.r)
  server:sendToAll("explosion", {pos = {x = v.x, y = v.y, z = v.z}, r = info.r})
  bullets[k] = nil
end

bullet.explode_particle = function(v, r)
  for i = 1, math.floor(r*r/128) do
    dir = {x = math.random()-.5, y = math.random()-.5, z = math.random()-.5}
    local norm = math.sqrt(dir.x*dir.x+dir.y*dir.y+dir.z*dir.z)
    local mag = r/12
    particle.new(v.x, v.y, v.z, dir.x/norm*mag, dir.y/norm*mag, dir.z/norm*mag, "explosion")
  end
  game.screenshake = r/160
end

bullet.bound_collide = function(k, v)
  if v.z < -tile_buffer*tile_size or v.z > (#grid+tile_buffer)*tile_size
  or v.y < -tile_buffer*tile_size or v.y > (#grid[1]+tile_buffer)*tile_size
  or v.x < -tile_buffer*tile_size or v.x > (#grid[1][1]+tile_buffer)*tile_size then
    bullet.destroy(k, v)
  end
end

bullet.destroy = function(k, v, face)
  if not bullet_info[v.type].persistant then
    bullets[k] = nil
    return true
  elseif face then
    bullet.reverse(v, face)
  end
  return false
end

bullet.reverse = function(v, face)
  local x_angle = math.atan2(math.sqrt(v.yV*v.yV+v.zV*v.zV), v.xV)
  local xV = math.cos((math.pi-x_angle)*face.x+x_angle*(1-face.x))

  local y_angle = math.atan2(math.sqrt(v.zV*v.zV+v.xV*v.xV), v.yV)
  local yV = math.cos((math.pi-y_angle)*face.y+y_angle*(1-face.y))

  local z_angle = math.atan2(math.sqrt(v.xV*v.xV+v.yV*v.yV), v.zV)
  local zV = math.cos((math.pi-z_angle)*face.z+z_angle*(1-face.z))

  local mag = math.sqrt(v.xV*v.xV+v.yV*v.yV+v.zV*v.zV)
  v.xV, v.yV, v.zV = xV*mag, yV*mag, zV*mag
  v.angle = math.atan2(yV+zV, xV)
end

bullet.new = function(p1, p2, parent, type, extra)
  local x1, y1, z1 = p1.x+p1.l/2, p1.y+p1.w/2, p1.z+p1.h/2
  local l_x, l_y, l_z = p2.x-x1, p2.y-y1, p2.z-z1
  local xV = math.cos(math.atan2(math.sqrt(l_y*l_y+l_z*l_z), l_x))
  local yV = math.cos(math.atan2(math.sqrt(l_z*l_z+l_x*l_x), l_y))
  local zV = math.cos(math.atan2(math.sqrt(l_x*l_x+l_y*l_y), l_z))
  local info = bullet_info[type]
  local spot = #bullets+1
  local weapon_pos = char.get_weapon_pos(players[parent])
  bullets[spot] = {x = x1+weapon_pos.x, y = y1+weapon_pos.y, z = z1+weapon_pos.z, xV = xV*info.speed, yV = yV*info.speed, zV = zV*info.speed, angle = math.atan2(yV+zV, xV), parent = parent, type = type, info = extra, freeze = 0, frame = 1}
  if info.flare then
    particle.new(x1+weapon_pos.x+xV*12, y1+weapon_pos.y+yV*12, z1+weapon_pos.z+zV*12-8, xV/100, yV/100, zV/100, "flare", players[parent], info.color)
  end
  return spot
end

bullet.spark = function(v, dir, color)
  local x, y, z = v.x, v.y, v.z
  if v.l and v.w and v.h then
    x, y, z = v.x+v.l/2, v.y+v.w/2, v.z+v.h/2
  end
  if dir then
    for j = 1, 3 do -- effect
      particle.new(x, y, z, math.random(-dir.x, 0)+(math.random()-.5)*2, math.random(-dir.y, 0)+(math.random()-.5)*2, math.random(-dir.z, 0)+(math.random()-.5)*2, "spark", {xV = 0, yV = 0, zV = 0}, color)
    end
  end
end

return bullet
