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
    players[index].map = data.map
    server:sendToAll("ready", {index = index, ready = data.ready})
  end,
}

servermenu.start = function(port)
  server = sock.newServer("*", port, 12)

  -- initialize server hooks
  for k,v in pairs(server_hooks) do
    server:on(k, v)
  end

  menu.buttons = sidebar.new({{txt = "Players", func = menu.swap_mode, args = {1}},
                               {txt ="Loadout", func = menu.swap_mode, args = {2}},
                               {txt ="Map", func = menu.swap_mode, args = {3}},
                               {txt ="Leave", func = wipe.start, args = {servermenu.leave}}})
  menu.player_gui = {{x = (screen.w-64)/2, y = (screen.h+256)/2-32, w = 64, h = 32, txt = "Ready", func = servermenu.ready, args = {id}}}
  menu.start()
  menu.new_player(id, username[1])
end

servermenu.update = function(dt)
  local start = menu.update_list(dt)
  if start then
    servermenu.all_ready()
  end
  menu.update()
end

servermenu.draw = function()
  if menu.mode == 1 then
    menu.draw_list()
  else
    menu.draw()
  end
end

servermenu.all_ready = function()
  local map_num = mapselect.choose_map(players)
  new_players = servermenu.create_players(players)
  server:sendToAll("startgame", {players = new_players, map = map_num})
  wipe.start(servermenu.start_game, {map_num})
end

servermenu.start_game = function(map_num)
  map.set(map_num)
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
  players[id].map = mapselect.get_map()
  server:sendToAll("ready", {index = id, ready = players[id].ready})
end

servermenu.create_players = function(players)
  local new_players = {}
  for k, v in pairs(players) do
    if v.left then
      new_players[k] = nil
    else
      new_players[k] = char.new(v.name, v.loadout)
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
