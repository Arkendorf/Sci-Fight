local servermenu = {}

servermenu.load = function()
end

local server_hooks = {
  -- if a player connects
  playerinfo = function(data, client)
    local index = client:getIndex()
    menu.new_player(index, data.name)
    server:sendToPeer(server:getPeerByIndex(index), "allinfo", {id = index, players = players})
    server:sendToAllBut(client, "newplayer", {info = players[index], index = index})
  end,
  -- if a player disconnects
  disconnect = function(data, client)
    local index = client:getIndex()
    players[index].left = true
    server:sendToAll("left", index)
  end,
  -- if a player presses ready
  ready = function(data, client)
    local index = client:getIndex()
    players[index].ready = data
    server:sendToAll("ready", {index = index, value = data})
  end,
}

servermenu.start = function(port)
  server = sock.newServer("*", port, 12)

  -- initialize server hooks
  for k,v in pairs(server_hooks) do
    server:on(k, v)
  end

  menu.start()
  menu.new_player(id, username[1])

  gui.clear()
  gui.add(1, {{x = (screen.w)/2-65, y= screen.h-48, w = 64, h = 32, txt = "Leave", func = wipe.start, args = {servermenu.leave}}, {x = (screen.w)/2+1, y= screen.h-48, w = 64, h = 32, txt = "Ready", func = servermenu.ready, args = {id}}}, {})
end

servermenu.update = function(dt)
  local start = menu.update_list(dt)
  if start then
    servermenu.start_game()
  end
end

servermenu.draw = function()
  menu.draw_list()
end

servermenu.start_game = function()
  server:sendToAll("startgame")
  wipe.start(menu.start_game)
end

servermenu.leave = function()
  servermenu.quit()
  state = "mainmenu"
  mainmenu.start()
end

servermenu.ready = function()
  players[id].ready = not players[id].ready
  server:sendToAll("ready", {index = id, value = players[id].ready})
end

servermenu.quit = function()
  server:sendToAll("disconnect")
  server:update()
  server:destroy()
  server = nil
end

return servermenu
