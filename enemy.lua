local enemy = {}

local target_speed = 24

enemy.start = function()
  players[#players+1] = enemy.new({skin = 1, weapon = 1, abilities = {1}})

  for k, v in pairs(players) do
    if not v.canvas then
      v.canvas = love.graphics.newCanvas(88, 88)
    end
  end
end

enemy.new = function(loadout)
  local item = {name = "enemy", x = #grid[1][1]*tile_size*0.5-12, y = #grid[1]*tile_size*0.5-12, z = -24, l = 24, w = 24, h = 24, xV = 0, yV = 0, zV = 0,
                speed = .4, hp = 100, energy = 100, score = 0, jump = false, inv = 0, team = 0, killer = false, target = {x = 0, y = 0, z = 0, frame = 1},
                anim = "run", frame = 1, skin = loadout.skin, ai = true}
  item.weapon = {type = loadout.weapon, active = false, anim = "base", frame = 1, speed = 0}
  item.abilities = {}
  for i, v in ipairs(loadout.abilities) do
    item.abilities[i] = {type = v, active = false, delay = 0, info = nil}
  end
  return item
end

enemy.ai_melee = function(k, v, dt)
  local current = {dist = math.huge, index = 0}
  for l, w in pairs(players) do
    if not v.ai then
      local dist = pathfind.dist(v, w)
      if dist < current.dist then
        current.dist = dist
        current.index = l
      end
    end
  end
  local player = players[current.index]
  enemy.target_player(k, v, player, dt)

  if current.dist < tile_size then -- attack
  elseif enemy.new_path(v, player) then -- create new path
    v.path = pathfind.astar(enemy.to_node(v), enemy.to_node(player))
  end
  enemy.follow_path(v)
end

enemy.target_player = function(k, v, player, dt)
  v.target.dX, v.target.dY, v.target.dZ = player.x+player.l/2, player.y+player.w/2, player.z+player.h/2 -- target
  v.target.x = v.target.x + (v.target.dX-v.target.x) * dt * target_speed
  v.target.y = v.target.y + (v.target.dY-v.target.y) * dt * target_speed
  v.target.z = v.target.z + (v.target.dZ-v.target.z) * dt * target_speed
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

enemy.drift = function(speed, stop)
  return speed/(1-stop)
end

return enemy
