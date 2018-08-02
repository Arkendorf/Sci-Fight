local abilities = {}

-- blaster abilities

abilities[1] = { -- blaster shot
press_func = function(player, index, target)
  local k = bullet.new(players[index], target, index, 1)
  server:sendToAll("bullet", {info = bullets[k], k = k})
  return false
end,
delay = 0.2,
energy = 5,
type = 2,
desc = "Fire laser",
}

abilities[6] = { -- rapid reload
press_func = function() end,
delay = 7,
energy = -25,
type = 2,
desc = "Rapidly reload and gain a burst of energy",
}

abilities[7] = { -- tri shot
press_func = function(player, index, target)
  local dif = {x = target.x-(player.x+player.l/2), y = target.y-(player.y+player.w/2), z = target.z-(player.z+player.h/2)}
  local base_angle = math.atan2(dif.y, dif.x)-math.rad(20)
  local mag = math.sqrt(dif.x*dif.x+dif.y*dif.y)
  for i = 1, 3 do
    local angle = base_angle+math.rad(10)*i
    local dir = game.target_pos(player, {x = math.cos(angle), y = math.sin(angle), z = dif.z/mag})
    local k = bullet.new(players[index], dir, index, 3)
    server:sendToAll("bullet", {info = bullets[k], k = k})
  end
  return false
end,
delay = 3,
energy = 15,
type = 2,
desc = "Fire three high-damage lasers in an arc",
}



-- saber abilities
 -- swing saber
local swing_range = 16
local swing_radius = 8
abilities[5] = {
press_func = function(player, index, target)
  local dir = game.target_norm(player, target)
  local bubble = game.target_pos(player, dir, swing_range)
  for k, v in pairs(players) do
    if k ~= index and collision.sphere_and_cube(bubble, v, swing_radius) then
      local num = v.hp-weapons[player.weapon.type].dmg*10
      bullet.damage(v, num, index)
      server:sendToAll("hit", {index = k, num = num, parent = index})
    end
  end
end,
delay = 0.2,
energy = 5,
type = 1,
desc = "Swing saber",
}

-- laser deflect
local deflect_range = 8
local deflect_radius = 16
local deflect = function(player, index, target)
  local dir = game.target_norm(player, target)
  local bubble = game.target_pos(player, dir, deflect_range)
  for k, v in pairs(bullets) do
    local p1, p2 = bullet.get_points(v)
    if v.parent ~= index and collision.line_and_sphere(p1, p2, bubble, deflect_radius) then
      local mag = math.sqrt(v.xV*v.xV+v.yV*v.yV+v.zV*v.zV)
      v.xV, v.yV, v.zV = dir.x*mag, dir.y*mag, dir.z*mag
      v.angle = math.atan2(dir.y+dir.z, dir.x)
      v.parent = index
    end
    server:sendToAll("bulletupdate", {pos = {x = v.x, y = v.y, z = v.z, xV = v.xV, yV = v.yV, zV = v.zV, angle = v.angle}, index = k})
  end
  return true
end
abilities[2] = {
press_func = deflect,
update_func = deflect,
delay = 4,
energy = 0.3,
type = 1,
desc = "Deflect incoming projectiles in the direction of the mouse cursor",
}

abilities[3] = { -- throw saber
press_func = function(player, index, target)
  local k = bullet.new(players[index], target, index, 2, index)
  server:sendToAll("bullet", {info = bullets[k], k = k})
  player.weapon.active = true
  return false
end,
delay = 4,
energy = 25,
type = 1,
desc = "Throw saber",
}



-- neutral abilities

abilities[4] = { -- filler
press_func = function() end,
delay = 1,
energy = 0,
desc = "pls ignore",
}

abilities[8] = {
press_func = function(player, index, target)
  local k = bullet.new(players[index], target, index, 4)
  server:sendToAll("bullet", {info = bullets[k], k = k})
  return false
end,
delay = 6,
energy = 10,
desc = "Throw grenade",
}

abilities[9] = {
press_func = function(player, index, target)
  player.zV = -8
  server:sendToAll("v", {index = index, zV = player.zV})
  return false
end,
delay = 6,
energy = 15,
desc = "Super leap",
}

abilities[10] = {
press_func = function(player, index, target)
  player.speed = 2
  server:sendToAll("speed", {index = index, speed = player.speed})
  return true
end,
stop_func = function(player, index)
  player.speed = 1
  server:sendToAll("speed", {index = index, speed = player.speed})
end,
delay = 2,
energy = 0.3,
desc = "Super speed",
}

local fly = function(player, index, target)
  if player.zV > -5 then
    player.zV = player.zV - 0.3
  else
    player.zV = -5
  end
  server:sendToAll("v", {index = index, zV = player.zV})
  return true
end
abilities[11] = {
press_func = fly,
update_func = fly,
delay = 0.2,
energy = 0.4,
desc = "Jetpack",
}

local heal = function(player, index, target, dt)
  if player.hp < hp_max then
    if dt then
      player.hp = player.hp + 0.1*dt*60
    else
      player.hp = player.hp + 0.1
    end
  else
    player.hp = hp_max
  end
  server:sendToAll("hp", {index = index, hp = player.hp})
  return true
end
abilities[12] = {
press_func = heal,
update_func = heal,
delay = 7,
energy = 0.2,
desc = "Heal",
}

abilities[13] = {
press_func = function(player, index, target)
  local k = bullet.new(players[index], target, index, 5)
  server:sendToAll("bullet", {info = bullets[k], k = k})
  return false
end,
delay = 6,
energy = 20,
desc = "Fire homing missile",
}


return abilities
