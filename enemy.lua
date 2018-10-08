local enemy = {}

enemy.start = function()
  enemies = {}

  enemies[1] = char.new("Enemy", {skin = 1, weapon = 1, abilities = {1}}, 0)

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
    -- if current.dist < tile_size then -- attack
    -- elseif not v.path or #v.path < 1 or pathfind.dist(v.path[#v.path], players[current.index]) > tile_size then -- find new path
    --   local goal = players[current.index]
    --   v.path = pathfind.astar({x = v.x+v.l/2, y = v.y+v.w/2, z = v.z+v.h}, {x = goal.x+goal.l/2, y = goal.y+goal.w/2, z = goal.z+goal.h})
    -- end
    enemy.follow_path(v)

    if love.keyboard.isDown("f") then
      local goal = players[0]
      v.path = pathfind.astar(enemy.to_node(v), enemy.to_node(goal))
    elseif love.keyboard.isDown("r") then
      char.death(v, 0)
    end
  end
end

enemy.follow_path = function(v)
  if v.path and #v.path > 0 then
    local p = enemy.to_node(v)
    local dist = pathfind.dist(p, v.path[1])*tile_size
    if dist > tile_size/4 then
      local angle = math.atan2((v.path[1].y-p.y), (v.path[1].x-p.x))
      v.xV = v.xV + v.speed * math.cos(angle)
      v.yV = v.yV + v.speed * math.sin(angle)
      if v.path[1].action == "jump" then
        if not v.jump then
          v.zV = v.zV - 4
          v.jump = true
        end
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
