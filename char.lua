local char = {}

local target_range = 48
local target_speed = 32
local shot_delay = 0.2

char.load = function()
end

char.input = function(dt)
  --input
  if love.keyboard.isDown("w") then
    players[id].yV = players[id].yV - 1
  end
  if love.keyboard.isDown("s") then
    players[id].yV = players[id].yV + 1
  end
  if love.keyboard.isDown("a") then
    players[id].xV = players[id].xV - 1
  end
  if love.keyboard.isDown("d") then
    players[id].xV = players[id].xV + 1
  end
  if love.keyboard.isDown("space") and not players[id].jump then
    players[id].zV = players[id].zV - 5
    players[id].jump = true
  end

  -- target
  local m_x, m_y = game.mouse_pos()
  local current = {k = nil, dist = target_range}
  for k, v in pairs(players) do
    if k ~= id then
      local x = v.x+v.l/2
      local y = v.y+v.z+v.w
      if math.sqrt((m_x-x)*(m_x-x)+(m_y-y)*(m_y-y)) < current.dist then
        current.k = k
      end
    end
  end
  if current.k then
    local v = players[current.k]
    target.dX, target.dY, target.dZ = v.x+v.l/2, v.y+v.w/2, v.z+v.h/2
  else
    local z = players[id].z+players[id].h/2
    target.dX, target.dY, target.dZ = m_x, m_y-z, z
  end
  target.x = target.x + (target.dX-target.x) * dt * target_speed
  target.y = target.y + (target.dY-target.y) * dt * target_speed
  target.z = target.z + (target.dZ-target.z) * dt * target_speed
end

char.update = function(dt)
  for k, v in pairs(players) do
    -- gravity
    if v.zV < 10 then
      v.zV = v.zV + 0.2
    elseif v.zV > 10 then
      v.zV = 10
    end

    -- collision
    collision.grid(v)

    -- movemwnt and friction
    v.x = v.x + v.xV * dt * 60
    v.xV = v.xV * 0.8

    v.y = v.y + v.yV * dt * 60
    v.yV = v.yV * 0.8

    v.z = v.z + v.zV * dt * 60

    -- attacking
    if v.delay > 0 then
      v.delay = v.delay - dt
    end
  end
end

char.fire = function(index, target)
  if players[index].delay <= 0 then
    players[index].delay = shot_delay
    return bullet.new(players[index], target, index)
  end
  return false
end

char.new = function()
  return {x = #grid[1][1]*tile_size*0.5, y = #grid[1]*tile_size*0.5, z = -tile_size, l = 24, w = 24, h = 24, xV = 0, yV = 0, zV = 0, jump = false, delay = 0}
end

char.queue = function()
  for i, v in pairs(players) do
    queue[#queue + 1] = {img = player_img, x = v.x, y = v.y, z = v.z, w = v.w, h = v.h, l = v.l, shadow = true}
  end
end

char.mousepressed = function(x, y, button)
end

return char
