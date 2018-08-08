local abilities = {}

-- blaster abilities
abilities[1] = { -- blaster shot
press_func = function(player, index, target)
  local k = bullet.new(players[index], target, index, "laser")
  server:sendToAll("bullet", {info = bullets[k], k = k})
  -- weapon animation
  char.weapon_anim(index, "fire", 30)
  server:sendToAll("weaponanim", {index = index, anim = "fire", speed = 30})
  return false
end,
delay = 0.2,
energy = 5,
type = 2,
name = "Laser",
desc = "Standard blaster attack",
}

abilities[2] = { -- tri shot
press_func = function(player, index, target)
  local dif = {x = target.x-(player.x+player.l/2), y = target.y-(player.y+player.w/2), z = target.z-(player.z+player.h/2)}
  local base_angle = math.atan2(dif.y, dif.x)-math.rad(20)
  local mag = math.sqrt(dif.x*dif.x+dif.y*dif.y)
  for i = 1, 3 do
    local angle = base_angle+math.rad(10)*i
    local dir = game.target_pos(player, {x = math.cos(angle), y = math.sin(angle), z = dif.z/mag})
    local k = bullet.new(players[index], dir, index, "powerlaser")
    server:sendToAll("bullet", {info = bullets[k], k = k})
  end
  -- weapon animation
  char.weapon_anim(index, "fire", 30)
  server:sendToAll("weaponanim", {index = index, anim = "fire", speed = 30})
  return false
end,
delay = 3,
energy = 15,
type = 2,
name = "Tri-Shot",
desc = "Fire three high-damage lasers in an arc",
}

abilities[3] = {
press_func = function(player, index, target, num)
  player.abilities[num].info = 0
  return true
end,
update_func = function(player, index, target, num)
  player.abilities[num].info = player.abilities[num].info + global_dt*10
end,
stop_func = function(player, index, target, num)
  local k = bullet.new(players[index], target, index, "charge", player.abilities[num].info)
  server:sendToAll("bullet", {info = bullets[k], k = k})
  -- weapon animation
  char.weapon_anim(index, "fire", 30)
  server:sendToAll("weaponanim", {index = index, anim = "fire", speed = 30})
end,
delay = 2,
energy = 0.2,
type = 2,
name = "Charged Shot",
desc = "Fire a laser that becomes more powerful the longer it is held",
}

abilities[4] = {
press_func = function(player, index, target)
  local k = bullet.new(players[index], target, index, "pierce")
  server:sendToAll("bullet", {info = bullets[k], k = k})
  -- weapon animation
  char.weapon_anim(index, "fire", 30)
  server:sendToAll("weaponanim", {index = index, anim = "fire", speed = 30})
  return false
end,
delay = 8,
energy = 20,
type = 2,
name = "Piercing Laser",
desc = "Fire a laser that passes through floors and walls",
}


abilities[5] = { -- rapid reload
press_func = function(player, index, target)
  -- weapon animation
  char.weapon_anim(index, "reload", 30)
  server:sendToAll("weaponanim", {index = index, anim = "reload", speed = 30})
end,
delay = 7,
energy = -25,
type = 2,
name = "Reload",
desc = "Rapidly reload and gain a burst of energy",
}

local roll_speed = 12
abilities[6] = {
press_func = function(player, index, target)
  local dir = game.target_norm(player, target)
  local length = math.sqrt(dir.x*dir.x + dir.y*dir.y);
  player.xV = dir.x/length*roll_speed
  player.yV = dir.y/length*roll_speed
  server:sendToAll("v", {index = index, xV = player.xV, yV = player.yV})
  return false
end,
delay = 1.5,
energy = 5,
type = 2,
name = "Roll",
desc = "Dodge towards target",
}




-- saber abilities
 -- swing saber
local swing_range = 16
local swing_radius = 8
abilities[7] = {
press_func = function(player, index, target)
  local dir = game.target_norm(player, target)
  local bubble = game.target_pos(player, dir, swing_range)
  for k, v in pairs(players) do
    if k ~= index and char.damageable(k, index) and collision.sphere_and_cube(bubble, v, swing_radius) then
      local num = v.hp-weapons[player.weapon.type].dmg*10
      bullet.damage(v, num, index)
      server:sendToAll("hit", {index = k, num = num, parent = index})
    end
  end
  -- weapon animation
  char.weapon_anim(index, "swing", 30)
  server:sendToAll("weaponanim", {index = index, anim = "swing", speed = 30})
  return false
end,
delay = 0.2,
energy = 5,
type = 1,
name = "Swing Saber",
desc = "Standard saber attack",
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
  -- animation
  if player.weapon.anim == "block" and player.weapon.frame > 3 then
    char.weapon_anim(index, "block", 0)
    player.weapon.frame = 3
    server:sendToAll("weaponanim", {index = index, anim = "block", speed = 0, frame = 3})
  end
end
abilities[8] = {
press_func = function(player, index, target)
  char.weapon_anim(index, "block", 30)
  server:sendToAll("weaponanim", {index = index, anim = "block", speed = 30})
  deflect(player, index, target)
  return true
end,
update_func = deflect,
stop_func = function(player, index, target)
  char.weapon_anim(index, "block", 30)
  player.weapon.frame = 3
  server:sendToAll("weaponanim", {index = index, anim = "block", speed = 30, frame = 3})
end,
delay = 5,
energy = 0.3,
type = 1,
name = "Deflect",
desc = "Deflect incoming projectiles in the direction of the target",
}

abilities[9] = { -- throw saber
press_func = function(player, index, target)
  local k = bullet.new(players[index], target, index, "saber"..tostring(player.weapon.type), index)
  server:sendToAll("bullet", {info = bullets[k], k = k})
  player.weapon.active = true
  -- weapon animation
  char.weapon_anim(index, "thrown", 0)
  server:sendToAll("weaponanim", {index = index, anim = "thrown", speed = 0})
  return false
end,
delay = 4,
energy = 25,
type = 1,
name = "Throw Saber",
desc = "Throw your saber towards the target",
}

local spin_radius = 32
abilities[10] = {
press_func = function(player, index, target)
  local bubble = {x = player.x+player.l/2, y = player.y+player.w/2, z = player.z+player.h/2}
  for k, v in pairs(players) do
    if k ~= index and char.damageable(k, index) and  collision.sphere_and_cube(bubble, v, spin_radius) then
      local num = v.hp-weapons[player.weapon.type].dmg*10
      bullet.damage(v, num, index)
      server:sendToAll("hit", {index = k, num = num, parent = index})
    end
  end
  -- weapon animation
  char.weapon_anim(index, "spin", 30)
  server:sendToAll("weaponanim", {index = index, anim = "spin", speed = 30})
  return false
end,
delay = 4,
energy = 10,
type = 1,
name = "Spin",
desc = "Spin saber damaging all adjacent enemies",
}

local lunge_speed = 12
local lunge_range = 32
local lunge_radius = 20
abilities[11] = {
press_func = function(player, index, target)
  local x, y = 0, 0
  if math.abs(player.xV) < 0.1 and math.abs(player.yV) < 0.1 then
    local dir = game.target_norm(player, target)
    x = dir.x
    y = dir.y
  else
    x = player.xV
    y = player.yV
  end
  local length = math.sqrt(x*x + y*y);
  player.xV = x/length*lunge_speed
  player.yV = y/length*lunge_speed
  server:sendToAll("v", {index = index, xV = player.xV, yV = player.yV})

  local bubble = game.target_pos(player, {x = x, y = y, z = 0}, lunge_range)
  for k, v in pairs(players) do
    if k ~= index and char.damageable(k, index) and collision.sphere_and_cube(bubble, v, lunge_radius) then
      local num = v.hp-weapons[player.weapon.type].dmg*15
      bullet.damage(v, num, index)
      server:sendToAll("hit", {index = k, num = num, parent = index})
    end
  end
  return false
end,
delay = 4,
energy = 20,
type = 1,
name = "Lunge",
desc = "Start a forward damaging lunge",
}

abilities[12] = {
press_func = function(player, index, target)
  player.inv = 1
  -- weapon animation
  char.weapon_anim(index, "block", 30)
  server:sendToAll("weaponanim", {index = index, anim = "block", speed = 30})
  return false
end,
delay = 5,
energy = 20,
type = 1,
name = "Block",
desc = "Become temporarily invincible",
}



-- neutral abilities
local push_range = 36
local push_radius = 24
abilities[13] = {
press_func = function(player, index, target)
  local dir = game.target_norm(player, target)
  local bubble = game.target_pos(player, dir, push_range)
  local speed = 15
  for k, v in pairs(players) do
    if k ~= index and collision.sphere_and_cube(bubble, v, push_radius) then
      local x1, y1, z1 = v.x+v.l/2, v.y+v.w/2, v.z+v.h/2
      local l_x, l_y, l_z = x1-bubble.x, y1-bubble.y, z1-bubble.z
      v.xV = v.xV*0.1 + math.cos(math.atan2(math.sqrt(l_y*l_y+l_z*l_z), l_x))*speed
      v.yV = v.yV*0.1 + math.cos(math.atan2(math.sqrt(l_z*l_z+l_x*l_x), l_y))*speed
      v.zV = v.zV*0.1 + math.cos(math.atan2(math.sqrt(l_x*l_x+l_y*l_y), l_z))*speed
      server:sendToAll("v", {index = k, xV = v.xV, yV = v.yV, zV = v.zV})
    end
  end
end,
delay = 6,
energy = 15,
name = "Push",
desc = "Shove other players backwards",
}

abilities[14] = {
press_func = function(player, index, target)
  player.zV = -8
  server:sendToAll("v", {index = index, zV = player.zV})
  return false
end,
delay = 6,
energy = 15,
name = "Leap",
desc = "Burst of vertical momentum",
}

abilities[15] = {
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
name = "Speed",
desc = "Increases movement speed",
}

local freeze_range = 20
local freeze_radius = 24
abilities[16] = {
press_func = function(player, index, target)
  local dir = game.target_norm(player, target)
  local bubble = game.target_pos(player, dir, freeze_range)
  for k, v in pairs(bullets) do
    local p1, p2 = bullet.get_points(v, 1)
    if collision.line_and_sphere(p1, p2, bubble, freeze_radius) then
      v.freeze = 2
      server:sendToAll("bulletfreeze", {index = k, freeze = v.freeze})
    end
  end
  return false
end,
delay = 5,
energy = 15,
name = "Freeze",
desc = "Stop projectiles in target range in mid-air",
}

local heal = function(player, index, target, num)
  if player.hp < hp_max then
    player.hp = player.hp + 0.1*global_dt*60
  else
    player.hp = hp_max
    char.stop_ability(player, index, target, num)
    if index ~= 0 then
      server:sendToPeer(server:getPeerByIndex(index), "ability_info", {num = num, delay = player.abilities[num].delay, active = false})
    end
  end
  server:sendToAll("hp", {index = index, hp = player.hp})
  return true
end
abilities[17] = {
press_func = heal,
update_func = heal,
delay = 7,
energy = 0.2,
name = "Heal",
desc = "Slowly heal over time",
}

abilities[18] = {
press_func = function(player, index, target)
  local k = bullet.new(players[index], target, index, "grenade")
  server:sendToAll("bullet", {info = bullets[k], k = k})
  return false
end,
delay = 6,
energy = 10,
name = "Grenade",
desc = "Throw an explosive projectile",
}

abilities[19] = {
press_func = function(player, index, target)
  local k = bullet.new(players[index], target, index, "missile")
  server:sendToAll("bullet", {info = bullets[k], k = k})
  return false
end,
delay = 6,
energy = 20,
name = "Homing missile",
desc = "Fire a missile that locks on to enemies",
}



local flame_range = 18
local flame_radius = 12
local flame = function(player, index, target)
  local dir = game.target_norm(player, target)
  local bubble = game.target_pos(player, dir, flame_range)
  for k, v in pairs(players) do
    if k ~= index and char.damageable(k, index) and collision.sphere_and_cube(bubble, v, flame_radius) then
      local num = v.hp - 0.2*weapons[player.weapon.type].dmg -- bullet damage * weapon modifier
      v.killer = index
      v.hp = num
      server:sendToAll("hp", {index = k, hp = num})
    end
  end
  return true
end
abilities[20] = {
press_func = flame,
update_func = flame,
delay = 6,
energy = 0.4,
name = "Flamethrower",
desc = "Shoot out a jet of flame in the direction of the target",
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
abilities[21] = {
press_func = fly,
update_func = fly,
delay = 0.2,
energy = 0.4,
name = "Jetpack",
desc = "Fly upwards",
}

return abilities
