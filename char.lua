local char = {}

char.load = function()
end

char.input = function(dt)
  --input
  if love.keyboard.isDown("w") then
    players[id].yV = players[id].yV - dt * 60
  end
  if love.keyboard.isDown("s") then
    players[id].yV = players[id].yV + dt * 60
  end
  if love.keyboard.isDown("a") then
    players[id].xV = players[id].xV - dt * 60
  end
  if love.keyboard.isDown("d") then
    players[id].xV = players[id].xV + dt * 60
  end
  if love.keyboard.isDown("space") and not players[id].jump then
    players[id].zV = players[id].zV - dt * 60 * 5
    players[id].jump = true
  end
end

char.update = function(dt)
  for i, v in pairs(players) do
    -- disconnect animation
    if v.left then
      v.zV = v.zV - dt * 60
    end
    -- gravity
    if v.zV < 10 then
      v.zV = v.zV + dt * 60 * 0.2
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

    if v.left and v.y+v.z+v.l+v.h <= 0 then
      players[i] = nil
    end
  end
end

char.queue = function()
  for i, v in pairs(players) do
    queue[#queue + 1] = {img = player_img, x = v.x, y = v.y, z = v.z+v.l-v.h, w = v.w, h = v.h, l = v.l, shadow = true}
  end
end

return char
