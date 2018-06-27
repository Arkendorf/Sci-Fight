local clientmenu = {}

clientmenu.load = function()
end

local client_hooks = {
  -- when client connects to a server
  connect = function(data)
    client:send("playerinfo", {name = username[1]})
  end,
  -- update client with all relevant info from server
  allinfo = function(data)
    id = data.id
    players = data.players
  end,
  -- when a new player joins
  newplayer = function(data)
    players[data.index] = data.info
  end,
  -- when player leaves
  left = function(data)
    players[data] = nil
  end,
  -- when server leaves
  disconnect = function(data)
    client:disconnect()
    state = "mainmenu"
    mainmenu.start()
  end,
  -- when game starts
  startgame = function(data)
    state = "game"
  end,
}

clientmenu.start = function(ip, port)
  client = sock.newClient(ip, port)
  client:connect()
  gui.clear()

  -- initialize client hooks
  for k,v in pairs(client_hooks) do
    client:on(k, v)
  end

  menu.start()
end

clientmenu.update = function(dt)
end

clientmenu.draw = function()
  for i, v in pairs(players) do
    love.graphics.print(v.name, 2, i * 32)
  end
end

clientmenu.quit = function()
  client:disconnectNow()
end

return clientmenu
