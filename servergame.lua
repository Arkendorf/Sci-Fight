local servergame = {}

servergame.load = function()
end

local server_hooks = {
  -- player sends position
  pos = function(data, client)
    local index = client:getIndex()
    players[index].x = data.x
    players[index].y = data.y
    players[index].z = data.z
    players[index].xV = data.xV
    players[index].yV = data.yV
    players[index].zV = data.zV
    server:sendToAllBut(client, "pos", {index = index, pos = data})
  end,
  bullet = function(data, client)
    local index = client:getIndex()
    bullets[#bullets+1] = data
    server:sendToAllBut(client, "bullet", data)
  end
}

servergame.start = function(port)
  -- initialize server hooks
  for k,v in pairs(server_hooks) do
    server:on(k, v)
  end

  gui.clear()
end

servergame.update = function(dt)
  char.input(dt)
  server:sendToAll("pos", {index = id, pos = {x = players[id].x, y = players[id].y, z = players[id].z, xV = players[id].xV, yV = players[id].yV, zV = players[id].zV}})
  game.update(dt)
end

servergame.draw = function()
  game.draw()
end

servergame.mousepressed = function(x, y, button)
  i = char.mousepressed(x, y, button)
  server:sendToAll("bullet", bullets[i])
end

servergame.quit = function()
  server:sendToAll("disconnect")
  server:update()
  server:destroy()
  server = nil
end

return servergame
