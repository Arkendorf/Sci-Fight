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
    char.use_ability(players[index], index, data.target, data.num)
    local ability = players[index].abilities[data.num]
    server:sendToPeer(server:getPeerByIndex(index), "ability_info", {num = data.num, delay = ability.delay, active = ability.active, energy = players[index].energy})
    if ability.active then
      players[index].target = data.target
    end
  end,
  update_ability = function(data, client)
    local index = client:getIndex()
    players[index].target = data.target
  end,
  stop_ability = function(data, client)
    local index = client:getIndex()
    char.stop_ability(players[index], index, data.target, data.num)
    server:sendToPeer(server:getPeerByIndex(index), "ability_info", {num = data.num, delay = players[index].abilities[data.num].delay, active = false})
  end,
  target = function(data, client)
    local index = client:getIndex()
    players[index].target = data
    server:sendToAllBut(client, "target", {index = index, target = data})
  end,
}

local win_score = 1

servergame.start = function(port)
  -- initialize server hooks
  for k,v in pairs(server_hooks) do
    server:on(k, v)
  end

  gui.clear()
  bullets = {}
end

servergame.update = function(dt)
  -- server pos
  char.input(dt)
  server:sendToAll("pos", {index = id, pos = {x = players[id].x, y = players[id].y, z = players[id].z, xV = players[id].xV, yV = players[id].yV, zV = players[id].zV}})
  server:sendToAll("target", {index = id, target = players[id].target})
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
      server:sendToAll("gameover", players)
      wipe.start(servergame.start_end)
      break
    end
  end
end

servergame.draw = function()
  game.draw()
end

servergame.mousepressed = function(x, y, button)
  game.abilities("button", button, servergame.use_ability)
end

servergame.mousereleased = function(x, y, button)
  game.abilities("button", button, servergame.stop_ability)
end

servergame.keypressed = function(key)
  game.abilities("key", key, servergame.use_ability)
end

servergame.keyreleased = function(key)
  game.abilities("key", key, servergame.stop_ability)
end

servergame.use_ability = function(num)
  char.use_ability(players[id], id, players[id].target, num)
end

servergame.update_ability = function(num, k, dt)
  char.update_ability(players[id], id, players[id].target, num, dt)
end

servergame.update_client_ability = function(num, k, dt)
  local stop = char.update_ability(players[k], k, players[k].target, num, dt)
  if stop then
    local ability = players[k].abilities[num]
    server:sendToPeer(server:getPeerByIndex(k), "ability_info", {num = num, delay = ability.delay, active = ability.active, energy = players[k].energy})
  else
    server:sendToPeer(server:getPeerByIndex(k), "ability_info", {energy = players[k].energy})
  end
end

servergame.stop_ability = function(num)
  char.stop_ability(players[id], id, players[id].target, num)
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
