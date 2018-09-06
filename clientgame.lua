local clientgame = {}

clientgame.load = function()
end

local client_hooks = {
  pos = function(data)
    players[data.index].x, players[data.index].y, players[data.index].z = data.pos.x, data.pos.y, data.pos.z
    if data.index ~= id then
      players[data.index].xV, players[data.index].yV, players[data.index].zV = data.pos.xV, data.pos.yV, data.pos.zV
    end
  end,
  v = function(data)
    if data.xV then
      players[data.index].xV = data.xV
    end
    if data.yV then
      players[data.index].yV = data.yV
    end
    if data.zV then
      players[data.index].zV = data.zV
    end
  end,
  speed = function(data)
    players[data.index].speed = data.speed
  end,
  bullet = function(data)
    bullet.new(players[data.index], data.target, data.index, data.type, data.extra)
  end,
  bulletkill = function(data)
    bullets[data] = nil
  end,
  bulletupdate = function(data)
    if data.spark then
      bullet.spark(bullets[data.index], {x = bullets[data.index].xV, y = bullets[data.index].yV, z = bullets[data.index].zV}, bullet_info[bullets[data.index].type].color)
    end
    if bullets[data.index] then
      bullets[data.index].x, bullets[data.index].y, bullets[data.index].z = data.pos.x, data.pos.y, data.pos.z
      bullets[data.index].xV, bullets[data.index].yV, bullets[data.index].zV = data.pos.xV, data.pos.yV, data.pos.zV
      bullets[data.index].angle = data.pos.angle
    end
  end,
  bulletfreeze = function(data)
    if bullets[data.index] then
      bullets[data.index].freeze = data.freeze
    end
  end,
  ability_start = function(data)
    local ability = players[data.index].abilities[data.num]
    ability.active = data.active
    ability.delay = data.delay
    players[data.index].energy = data.energy
    if not data.active and abilities[ability.type].particle_func then
      abilities[ability.type].particle_func(players[data.index], data.index, players[data.index].target)
    end
  end,
  ability_end = function(data)
    players[data.index].abilities[data.num].active = false
    players[data.index].abilities[data.num].delay = data.delay
    players[data.index].energy = data.energy
  end,
  energy = function(data)
    players[data.index].energy = data.energy
  end,
  hit = function(data)
    bullet.damage(players[data.index], data.num, data.parent, data.dir, data.color)
  end,
  gameover = function(data)
    wipe.start(clientgame.start_end)
  end,
  hp = function(data)
    players[data.index].hp = data.hp
  end,
  target = function(data)
    players[data.index].target = data.target
  end,
  weaponanim = function(data)
    char.weapon_anim(data.index, data.anim, data.speed)
    if data.frame then
      players[data.index].weapon.frame = data.frame
    end
  end,
}

local menu_active = {false}

clientgame.start = function(port)
  -- initialize client hooks
  for k,v in pairs(client_hooks) do
    client:on(k, v)
  end

  game.start()
  clientgame.start_gui()
  menu_active[1] = false
end

clientgame.start_gui = function()
  local buttons = sidebar.new({{txt = "Settings", func = wipe.start, args = {settings.start, {state}}},
                               {txt ="Leave", func = wipe.start, args = {clientmenu.leave}}})
  for i, v in ipairs(buttons) do
    v.active = {t = menu_active, i = 1}
  end
  gui.add(1, buttons)
end

clientgame.update = function(dt)
  -- client pos
  char.input(dt)
  client:send("pos", {x = players[id].x, y = players[id].y, z = players[id].z, xV = players[id].xV, yV = players[id].yV, zV = players[id].zV})
  client:send("target", {x = players[id].target.x, y = players[id].target.y, z = players[id].target.z})
  -- game updating
  game.update(dt)
end

clientgame.draw = function()
  game.draw()
end

clientgame.mousepressed = function(x, y, button)
  game.abilities("button", button, clientgame.use_ability)

  if other_keys[6][1] == "button" and button == other_keys[6][2] then
    menu_active[1] = not menu_active[1]
  end
end

clientgame.mousereleased = function(x, y, button)
  game.abilities("button", button, clientgame.stop_ability)
end

clientgame.keypressed = function(key)
  game.abilities("key", key, clientgame.use_ability)

  if other_keys[6][1] == "key" and key == other_keys[6][2] then
    menu_active[1] = not menu_active[1]
  end
end

clientgame.keyreleased = function(key)
  game.abilities("key", key, clientgame.stop_ability)
end

clientgame.use_ability = function(num)
  client:send("use_ability", {target = players[id].target, num = num})
end

clientgame.stop_ability = function(num)
  client:send("stop_ability", {target = players[id].target, num = num})
end

clientgame.start_end = function()
  client:disconnectNow()
  client = nil

  state = "endmenu"
  endmenu.start()
end

clientgame.quit = function()
  client:disconnectNow()
  client = nil
end

return clientgame
