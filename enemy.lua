local enemy = {}

local target_speed = 24

enemy.start = function()
  enemies = {}

  enemies[1] = char.new("Enemy", {skin = 1, weapon = 1, abilities = {1}}, 0)
  -- enemies[1].speed = .3

  for k, v in pairs(enemies) do
    v.canvas = love.graphics.newCanvas(88, 88)
  end
end

enemy.update = function(dt)
  for k, v in pairs(enemies) do
    char.update_char(k, v, dt)
  end
end

enemy.serverupdate = function(dt)
  for k, v in pairs(enemies) do
    local current = {dist = math.huge, index = 0}
    for l, w in pairs(players) do
      local dist = pathfind.dist(v, w)
      if dist < current.dist then
        current.dist = dist
        current.index = l
      end
    end
    local player = players[current.index]
    v.target.dX, v.target.dY, v.target.dZ = player.x+player.l/2, player.y+player.w/2, player.z+player.h/2 -- target
    v.target.x = v.target.x + (v.target.dX-v.target.x) * dt * target_speed
    v.target.y = v.target.y + (v.target.dY-v.target.y) * dt * target_speed
    v.target.z = v.target.z + (v.target.dZ-v.target.z) * dt * target_speed

    if current.dist < tile_size then -- attack
    elseif enemy.new_path(v, player) then -- create new path
      v.path = pathfind.astar(enemy.to_node(v), enemy.to_node(player))
    end
    enemy.follow_path(v)
  end
end

enemy.new_path = function(v, player)
  return ((not v.path or #v.path < 1 -- path is complete or non-existant
  or enemy.to_node(v).z-v.path[1].z > 1 -- can't make a jump
  or pathfind.dist(v.path[#v.path], enemy.to_node(player))*tile_size > tile_size) -- player has moved away from old path
  and not v.jump) -- only path when enemy is on the ground (prevents excessive jumping)
end

enemy.follow_path = function(v)
  if v.path and #v.path > 0 then
    local p = enemy.to_node(v)
    if pathfind.dist(p, v.path[1]) > 1/4 then
      if v.path[1].action == "jump" then
        if not v.jump then
          v.zV = v.zV - 4
          v.jump = true
        end
      end
      local x, y = (v.path[1].x-p.x), (v.path[1].y-p.y)
      if math.sqrt(x*x+y*y) > 1/4 then
        local angle = math.atan2(y, x)
        v.xV = v.xV + v.speed * math.cos(angle)
        v.yV = v.yV + v.speed * math.sin(angle)
      end
    else
      table.remove(v.path, 1)
    end
  end
end

enemy.to_node = function(v)
  return {x = 1+(v.x+v.l/2)/tile_size, y = 1+(v.y+v.w/2)/tile_size, z = 1+(v.z+v.h)/tile_size}
end

enemy.queue = function()
  for i, v in pairs(enemies) do
    local dir = game.target_norm(v, v.target)

    love.graphics.setCanvas(v.canvas)
    love.graphics.clear()
    char.draw_char(v)
    love.graphics.setCanvas()

    queue[#queue + 1] = {img = v.canvas, x = v.x, y = v.y, z = v.z, w = v.w, h = v.h, l = v.l, shadow = true, ox = 32, oy = 24}
  end
end

enemy.drift = function(speed, stop)
  return speed/(1-stop)
end

return enemy
