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
  end,
  update_ability = function(data, client)
    local index = client:getIndex()
    local stop = char.update_ability(players[index], index, data.target, data.num)
    if stop then
      local ability = players[index].abilities[data.num]
      server:sendToPeer(server:getPeerByIndex(index), "ability_info", {num = data.num, delay = ability.delay, active = ability.active, energy = players[index].energy})
    else
      server:sendToPeer(server:getPeerByIndex(index), "ability_info", {energy = players[index].energy})
    end
  end,
  stop_ability = function(data, client)
    local index = client:getIndex()
    char.stop_ability(players[index], index, data)
    server:sendToPeer(server:getPeerByIndex(index), "ability_info", {num = data, delay = players[index].abilities[data].delay, active = false})
  end,
}

local win_score = 1

servergame.start = function(port)
  -- initialize server hooks
  for k,v in pairs(server_hooks) do
    server:on(k, v)
  end

  gui.clear()
end

servergame.update = function(dt)
  -- server pos
  char.input(dt)
  server:sendToAll("pos", {index = id, pos = {x = players[id].x, y = players[id].y, z = players[id].z, xV = players[id].xV, yV = players[id].yV, zV = players[id].zV}})
  -- server's abilities
  game.update_abilities(servergame.update_ability)
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
  char.use_ability(players[id], id, target, num)
end

servergame.update_ability = function(num)
  char.update_ability(players[id], id, target, num)
end

servergame.stop_ability = function(num)
  char.stop_ability(players[id], id, num)
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
