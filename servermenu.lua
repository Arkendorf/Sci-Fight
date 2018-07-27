local servermenu = {}

servermenu.load = function()
end

local server_hooks = {
  -- if a player connects
  playerinfo = function(data, client)
    if state == "servermenu" then
      local index = client:getIndex()
      menu.new_player(index, data.name)
      server:sendToPeer(server:getPeerByIndex(index), "allinfo", {id = index, players = players})
      server:sendToAllBut(client, "newplayer", {info = players[index], index = index})
    end
  end,
  -- if a player disconnects
  disconnect = function(data, client)
    local index = client:getIndex()
    if players[index] then
      if state == "servermenu" then
        players[index].left = true
      else
        players[index] = nil
      end
      server:sendToAll("left", index)
    end
  end,
  -- if a player presses ready
  ready = function(data, client)
    local index = client:getIndex()
    players[index].ready = data.ready
    players[index].loadout = data.loadout
    server:sendToAll("ready", {index = index, ready = data.ready})
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
    servermenu.all_ready()
  end
end

servermenu.draw = function()
  menu.draw_list()
end

servermenu.all_ready = function()
  new_players = servermenu.create_players()
  server:sendToAll("updatedplayers", new_players)

  server:sendToAll("startgame")
  wipe.start(servermenu.start_game, {"server"})
end

servermenu.start_game = function()
  players = new_players
  state = "servergame"
  servergame.start()
end

servermenu.leave = function()
  servermenu.quit()
  state = "mainmenu"
  mainmenu.start()
end

servermenu.ready = function()
  players[id].ready = not players[id].ready
  players[id].loadout = custom.get_loadout()
  server:sendToAll("ready", {index = id, ready = players[id].ready})
end

servermenu.create_players = function()
  local new_players = {}
  for k, v in pairs(players) do
    if v.left then
      new_players[k] = nil
    else
      new_players[k] = char.new(v.loadout)
    end
  end
  return new_players
end

servermenu.quit = function()
  server:sendToAll("disconnect")
  server:update()
  server:destroy()
  server = nil
end

return servermenu
