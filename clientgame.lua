local clientgame = {}

clientgame.load = function()
end

local client_hooks = {
  pos = function(data)
    players[data.index].x = data.pos.x
    players[data.index].y = data.pos.y
    players[data.index].z = data.pos.z
    players[data.index].xV = data.pos.xV
    players[data.index].yV = data.pos.yV
    players[data.index].zV = data.pos.zV
  end,
  bullet = function(data)
    bullets[data.k] = data.info
  end,
  ability_info = function(data)
    players[id].abilities[data.num].delay = data.delay
    players[id].abilities[data.num].active = data.active
  end,
}

clientgame.start = function(port)
  -- initialize client hooks
  for k,v in pairs(client_hooks) do
    client:on(k, v)
  end

  gui.clear()
end

clientgame.update = function(dt)
  -- client pos
  char.input(dt)
  client:send("pos", {x = players[id].x, y = players[id].y, z = players[id].z, xV = players[id].xV, yV = players[id].yV, zV = players[id].zV})
  --client's abilities
  if char.ability_check(players[id], id) then
    client:send("update_abilities", target)
  end
  -- game updating
  game.update(dt)
end

clientgame.draw = function()
  game.draw()
end

clientgame.mousepressed = function(x, y, button)
  game.abilities("button", button, clientgame.use_ability)
end

clientgame.mousereleased = function(x, y, button)
  game.abilities("button", button, clientgame.stop_ability)
end

clientgame.keypressed = function(key)
  game.abilities("key", key, clientgame.use_ability)
end

clientgame.keyreleased = function(key)
  game.abilities("key", key, clientgame.stop_ability)
end

clientgame.use_ability = function(num)
  client:send("use_ability", {target = target, num = num})
end

clientgame.stop_ability = function(num)
  client:send("stop_ability", num)
end

clientgame.quit = function()
  client:disconnectNow()
  client = nil
end

return clientgame
