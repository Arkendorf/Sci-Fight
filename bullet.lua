local bullet_ai = require "bullet_ai"

local bullet = {}

bullet.load = function()
  bullets = {}

  bullet_info = {}
  bullet_info[1] = {ai = 1, speed = 6, r = 0, persistant = true, img = 1, shadow = false}
  bullet_info[2] = {ai = 2, speed = 4, r = 16, persistant = true, img = 2, shadow = true}
end

bullet.update = function(dt)
  for k, v in pairs(bullets) do
    -- collide with map
    bullet.map_collide(k, v)
    -- collide with players
    bullet.player_collide(k, v)
    -- collide with borders (twice as large as map)
    if not collision.in_bounds((v.x/tile_size+#grid[1][1]/2)/2, (v.y/tile_size+#grid[1]/2)/2, (v.z/tile_size+#grid/2)/2) then
      bullets[k] = nil
    end
    --update
    bullet_ai[bullet_info[v.type].ai](k, v, dt)
  end
end

bullet.queue = function()
  for k, v in pairs(bullets) do
    queue[#queue + 1] = {img = bullet_img[bullet_info[v.type].img], x = v.x, y = v.y, z = v.z, h = 0, w = 0, l = 0, r = v.r/2, ox = 16, oy = 16, angle = v.angle, shadow = bullet_info[v.type].shadow}
  end
end

bullet.get_points = function(v, dt)
  return {x = v.x, y = v.y, z = v.z}, {x = v.x+v.xV*global_dt*60, y = v.y+v.yV*global_dt*60, z = v.z+v.zV*global_dt*60}
end

bullet.map_collide = function(k, v)
  p1, p2 = bullet.get_points(v)
  collide, face, frac = collision.line_and_map(p1, p2)
  if collide then
    if not v.persistant then
      bullet.destroy(k, v)
    elseif face then
      v.x = v.x + v.xV*frac
      v.y = v.y + v.yV*frac
      v.z = v.z + v.zV*frac
      bullet.reverse(v, face)
    end
  else
    v.collide = false
  end
end

bullet.player_collide = function(k, v)
  p1, p2 = bullet.get_points(v)
  for l, w in pairs(players) do
    if l ~= v.parent and collision.line_and_cube(p1, p2, w) then
      w.hp = w.hp - 1
      if w.hp <= 0 then
        char.death(w, players[v.parent])
      end
      if not v.persistant then
        bullet.destroy(k, v)
      end
      break
    end
  end
end

bullet.circle_collide = function(v, p, r)
  local p1, p2 = bullet.get_points(v)
  return collision.line_and_sphere(p1, p2, p, r)
end

bullet.destroy = function(k, v)
  bullets[k] = nil
end

bullet.reverse = function(v, face)
  if not v.collide then
    v.collide = true
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
end

bullet.new = function(p1, p2, parent, type, extra)
  local x1, y1, z1 = p1.x+p1.l/2, p1.y+p1.w/2, p1.z+p1.h/2
  local l_x, l_y, l_z = p2.x-x1, p2.y-y1, p2.z-z1
  local xV = math.cos(math.atan2(math.sqrt(l_y*l_y+l_z*l_z), l_x))
  local yV = math.cos(math.atan2(math.sqrt(l_z*l_z+l_x*l_x), l_y))
  local zV = math.cos(math.atan2(math.sqrt(l_x*l_x+l_y*l_y), l_z))
  local info = bullet_info[type]
  local spot = #bullets+1
  bullets[spot] = {x = x1, y = y1, z = z1, xV = xV*info.speed, yV = yV*info.speed, zV = zV*info.speed, angle = math.atan2(yV+zV, xV), r = info.r, parent = parent, persistant = info.persistant, type = type, info = extra}
  return spot
end

return bullet
