local servermenu = {}

servermenu.load = function()
end

local server_hooks = {
  -- if a player connects
  playerinfo = function(data, client)
    local index = client:getIndex()
    players[index] = {name = data.name}
    server:sendToPeer(server:getPeerByIndex(index), "allinfo", {id = index, players = players})
    server:sendToAllBut(client, "newplayer", {info = players[index], index = index})
  end,
  -- if a player disconnects
  disconnect = function(data, client)
    local index = client:getIndex()
    players[index] = nil
    server:sendToAll("left", index)
  end,
}

servermenu.start = function(port)
  server = sock.newServer("*", port)
  gui.clear()
  gui.add(1, {{x= 100, y= 100, w = 64, h = 64, txt = "ready", func = wipe.start, args = {servermenu.start_game}}}, {})

  -- initialize server hooks
  for k,v in pairs(server_hooks) do
    server:on(k, v)
  end

  menu.start()
  players[0] = {name = username[1]}
end

servermenu.update = function(dt)
end

servermenu.draw = function()
  for i, v in pairs(players) do
    love.graphics.print(v.name, 2, i * 32)
  end
end

servermenu.start_game = function()
  server:sendToAll("startgame")
  state = "game"
  gui.clear()
end

servermenu.quit = function()
  server:sendToAll("disconnect")
  server:update()
end

return servermenu
