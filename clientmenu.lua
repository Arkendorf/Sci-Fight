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
    if state == "clientmenu" then
      players[data].left = true
    else
      players[data] = nil
    end
  end,
  -- when server leaves
  disconnect = function(data)
    wipe.start(clientmenu.leave)
  end,
  -- when game starts
  startgame = function(data)
    new_players = data.players
    wipe.start(clientmenu.start_game, {data.map})
  end,
  -- if a player presses ready
  ready = function(data)
    players[data.index].ready = data.ready
  end,
  -- team change
  team = function(data)
    players[data.index].team = data.team
  end,
  explosion = function(data)
    bullet.explode_particle(data.pos, data.r)
  end
}

clientmenu.start = function(ip, port)
  client = sock.newClient(ip, port)
  client:connect()
  gui.clear()

  -- initialize client hooks
  for k,v in pairs(client_hooks) do
    client:on(k, v)
  end

  menu.buttons = sidebar.new({{txt = "Players", func = menu.swap_mode, args = {1}, mat = {func = menu.mat, args = {1}}},
                               {txt ="Loadout", func = menu.swap_mode, args = {2}, mat = {func = menu.mat, args = {2}}},
                               {txt ="Map", func = menu.swap_mode, args = {3}, mat = {func = menu.mat, args = {3}}},
                               {txt ="Leave", func = wipe.start, args = {clientmenu.leave}}})
  menu.player_gui = {{x = (screen.w-64)/2, y = (screen.h+256)/2-32, w = 64, h = 32, txt = "Ready", func = clientmenu.ready, args = {id}, mat = {func = menu.readymat, args = {}}}}
  menu.start()
end

clientmenu.update = function(dt)
  menu.update_list(dt)
  menu.update()
end

clientmenu.draw = function()
  if menu.mode == 1 then
    menu.draw_list()
  else
    menu.draw()
  end
end

clientmenu.leave = function()
  clientmenu.quit()
  state = "mainmenu"
  mainmenu.start()
end

clientmenu.ready = function()
  players[id].ready = not players[id].ready
  client:send("ready", {ready = players[id].ready, loadout = custom.get_loadout(), map = mapselect.get_map()})
end

clientmenu.start_game = function(map_num)
  map.set(map_num)
  players = new_players
  state = "clientgame"
  clientgame.start()
end

clientmenu.quit = function()
  client:disconnectNow()
  client = nil
end

return clientmenu
