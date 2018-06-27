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
    wipe.start(clientmenu.leave)
  end,
  -- when game starts
  startgame = function(data)
    wipe.start(menu.start_game)
  end,
  -- if a player presses ready
  ready = function(data, client)
    players[data.index].ready = data.value
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

  gui.clear()
  gui.add(1, {{x = (screen.w)/2-65, y= screen.h-48, w = 64, h = 32, txt = "Leave", func = wipe.start, args = {clientmenu.leave}}, {x = (screen.w)/2+1, y= screen.h-48, w = 64, h = 32, txt = "Ready", func = clientmenu.ready, args = {id}}}, {})
end

clientmenu.update = function(dt)
  menu.update_list(dt)
end

clientmenu.draw = function()
  menu.draw_list()
end

clientmenu.leave = function()
  clientmenu.quit()
  state = "mainmenu"
  mainmenu.start()
end

clientmenu.ready = function()
  players[id].ready = not players[id].ready
  client:send("ready", players[id].ready)
end

clientmenu.quit = function()
  client:disconnectNow()
  client = nil
end

return clientmenu
