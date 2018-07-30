local clientgame = {}

clientgame.load = function()
end

local client_hooks = {
  pos = function(data)
    players[data.index].x, players[data.index].y, players[data.index].z = data.pos.x, data.pos.y, data.pos.z
    if data.index ~= id then
      players[data.index].xV, players[data.index].yV, players[data.index].zV = data.pos.xV, data.pos.yV, data.pos.zV
    end
    players[data.index].jump = data.pos.jump
  end,
  bullet = function(data)
    bullets[data.k] = data.info
  end,
  bulletupdate = function(data)
    bullets[data.index].x, bullets[data.index].y, bullets[data.index].z = data.pos.x, data.pos.y, data.pos.z
    bullets[data.index].xV, bullets[data.index].yV, bullets[data.index].zV = data.pos.xV, data.pos.yV, data.pos.zV
    bullets[data.index].angle = data.pos.angle
  end,
  ability_info = function(data)
    if data.num then
      players[id].abilities[data.num].delay = data.delay
      players[id].abilities[data.num].active = data.active
    end
    if data.energy then
      players[id].energy = data.energy
    end
  end,
  hit = function(data)
    bullet.damage(players[data.index], data.num, data.parent)
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
  game.update_abilities(clientgame.update_ability)
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

clientgame.update_ability = function(num)
  client:send("update_ability", {target = target, num = num})
end

clientgame.stop_ability = function(num)
  client:send("stop_ability", num)
end

clientgame.quit = function()
  client:disconnectNow()
  client = nil
end

return clientgame
