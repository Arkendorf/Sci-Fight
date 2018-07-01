local clientgame = {}

clientgame.load = function()
end

local client_hooks = {
  pos = function(data)
    players[data.index].x = data.pos.x
    players[data.index].y = data.pos.y
    players[data.index].z = data.pos.z
    players[data.index].xV = data.pos.xV
    players[data.index].yV = data.pos.yV
    players[data.index].zV = data.pos.zV
  end,
  bullet = function(data)
    bullets[#bullets+1] = data
  end
}

clientgame.start = function(port)
  -- initialize client hooks
  for k,v in pairs(client_hooks) do
    client:on(k, v)
  end

  gui.clear()
end

clientgame.update = function(dt)
  char.input(dt)
  client:send("pos", {x = players[id].x, y = players[id].y, z = players[id].z, xV = players[id].xV, yV = players[id].yV, zV = players[id].zV})
  game.update(dt)
end

clientgame.draw = function()
  game.draw()
end

clientgame.mousepressed = function(x, y, button)
  i = char.mousepressed(x, y, button)
  client:send("bullet", bullets[i])
end

clientgame.quit = function()
  client:disconnectNow()
  client = nil
end

return clientgame
