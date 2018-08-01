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
delay = 1,
energy = 0.2,
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

return abilities
