local servergame = {}

servergame.load = function()
end

local server_hooks = {
  -- player sends position
  pos = function(data, client)
    local index = client:getIndex()
    -- players[index].x, players[index].y, players[index].z = data.x, data.y, data.z
    players[index].xV, players[index].yV, players[index].zV = data.xV, data.yV, data.zV
  end,
  use_ability = function(data, client)
    local index = client:getIndex()
    if char.use_ability(players[index], index, data.target, data.num) then -- only send info if ability is used
      local ability = players[index].abilities[data.num]
      server:sendToAll("ability_start", {index = index, num = data.num, delay = ability.delay, active = ability.active, energy = players[index].energy})
    end
  end,
  stop_ability = function(data, client)
    local index = client:getIndex()
    char.stop_ability(players[index], index, data.target, data.num)
    server:sendToAll("ability_end", {index = index, num = data.num, delay = players[index].abilities[data.num].delay, energy = players[index].energy})
  end,
  target = function(data, client)
    local index = client:getIndex()
    players[index].target = data
    server:sendToAllBut(client, "target", {index = index, target = data})
  end,
}

local win_score = 99

local menu_active = {false}

servergame.start = function(port)
  -- initialize server hooks
  for k, v in pairs(server_hooks) do
    server:on(k, v)
  end

  game.start()
  servergame.start_gui()
  menu_active[1] = false

  if mode == "pve" then
    enemy.new_wave()
  end
end

servergame.start_gui = function()
  local buttons = sidebar.new({{txt = "Settings", func = wipe.start, args = {settings.start, {state}}},
                               {txt ="Leave", func = wipe.start, args = {servermenu.leave}}})
  for i, v in ipairs(buttons) do
    v.active = {t = menu_active, i = 1}
  end
  gui.add(1, buttons)
end

servergame.update = function(dt)
  -- server pos
  char.input(dt)
  server:sendToAll("pos", {index = id, pos = {x = players[id].x, y = players[id].y, z = players[id].z, xV = players[id].xV, yV = players[id].yV, zV = players[id].zV}})
  server:sendToAll("target", {index = id, target = {x = players[id].target.x, y = players[id].target.y, z = players[id].target.z}})
  -- server's abilities
  game.update_abilities(servergame.update_ability, id, dt)
  -- game updating
  game.update(dt)
  -- server specific stuff
  -- update players
  char.serverupdate(dt)
  -- update bullets
  bullet.serverupdate(dt)

  for k, v in pairs(players) do
    if v.score >= win_score then
      server:sendToAll("gameover")
      wipe.start(servergame.start_end)
      break
    end
  end
end

servergame.draw = function()
  game.draw()
end

servergame.mousepressed = function(x, y, button)
  game.abilities("button", button, servergame.use_ability, id)

  if other_keys[6][1] == "button" and button == other_keys[6][2] then
    menu_active[1] = not menu_active[1]
  end
end

servergame.mousereleased = function(x, y, button)
  game.abilities("button", button, servergame.stop_ability)
end

servergame.keypressed = function(key)
  game.abilities("key", key, servergame.use_ability, id)

  if other_keys[6][1] == "key" and key == other_keys[6][2] then
    menu_active[1] = not menu_active[1]
  end
end

servergame.keyreleased = function(key)
  game.abilities("key", key, servergame.stop_ability)
end

servergame.use_ability = function(num, k)
  if char.use_ability(players[k], k, players[k].target, num) then
    local ability = players[k].abilities[num]
    server:sendToAll("ability_start", {index = k, num = num, delay = ability.delay, active = ability.active, energy = players[k].energy})
  end
end

servergame.update_ability = function(num, k, dt)
  char.update_ability(players[id], id, players[id].target, num, dt)
end

servergame.update_client_ability = function(num, k, dt)
  local stop = char.update_ability(players[k], k, players[k].target, num, dt)
  if stop then
    local ability = players[k].abilities[num]
    server:sendToPeer(server:getPeerByIndex(k), "ability_end", {index = k, num = num, delay = ability.delay, energy = players[k].energy})
  else
    server:sendToPeer(server:getPeerByIndex(k), "energy", {index = k, energy = players[k].energy})
  end
end

servergame.stop_ability = function(num)
  char.stop_ability(players[id], id, players[id].target, num)
  local ability = players[id].abilities[num]
  server:sendToAll("ability_end", {index = id, num = num, delay = ability.delay, energy = players[id].energy})
end

servergame.start_end = function()
  server:update()
  server:destroy()
  server = nil

  state = "endmenu"
  endmenu.start()
end

servergame.quit = function()
  server:sendToAll("disconnect")
  server:update()
  server:destroy()
  server = nil
end

return servergame
