local abilities = {}

abilities[1] = { -- blaster shot
press_func = function(player, index, target)
  local k = bullet.new(players[index], target, index, 1)
  server:sendToAll("bullet", {info = bullets[k], k = k})
  return false
end,
update_func = nil,
delay = 0.2,
energy = 5,
type = 2,
desc = "Fire laser",
}

-- laser deflect
local force_range = 8
local force_radius = 16
local deflect = function(player, index, target)
  local dir = game.target_norm(player, target)
  local bubble = {x = player.x+player.l/2+dir.x*force_range, y= player.y+player.w/2+dir.y*force_range, z = player.z+player.h/2+dir.z*force_range}
  for k, v in pairs(bullets) do
    local p1, p2 = bullet.get_points(v)
    if v.parent ~= index and collision.line_and_sphere(p1, p2, bubble, force_radius) then
      local mag = math.sqrt(v.xV*v.xV+v.yV*v.yV+v.zV*v.zV)
      v.xV, v.yV, v.zV = dir.x*mag, dir.y*mag, dir.z*mag
      v.angle = math.atan2(dir.y+dir.z, dir.x)
      v.parent = index
    end
    server:sendToAll("bulletupdate", {pos = {x = v.x, y = v.y, z = v.z, xV = v.xV, yV = v.yV, zV = v.zV}, index = k})
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
update_func = nil,
delay = 0.2,
energy = 25,
type = 1,
desc = "Throw saber",
}

abilities[4] = { -- filler
desc = "pls ignore",
}

return abilities
