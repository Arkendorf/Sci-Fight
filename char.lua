local char = {}

local target_range = 32
local target_speed = 32
energy_max = 100
local energy_increase = 0.1
hp_max = 100

local tile_buffer = 8
local death_inv = 4

char.load = function()
end

char.input = function(dt)
  --input
  if love.keyboard.isDown("w") then
    players[id].yV = players[id].yV - .5 * players[id].speed
  end
  if love.keyboard.isDown("s") then
    players[id].yV = players[id].yV + 0.5 * players[id].speed
  end
  if love.keyboard.isDown("a") then
    players[id].xV = players[id].xV - 0.5 * players[id].speed
  end
  if love.keyboard.isDown("d") then
    players[id].xV = players[id].xV + 0.5 * players[id].speed
  end
  if love.keyboard.isDown("space") and not players[id].jump then
    players[id].zV = players[id].zV - 4
    players[id].jump = true
  end

  -- target
  local m_x, m_y = game.mouse_pos()
  local current = {k = nil, dist = target_range}
  for k, v in pairs(players) do
    if k ~= id and char.damageable(k, id) then
      local x = v.x+v.l/2
      local y = v.y+v.z+v.w
      if math.sqrt((m_x-x)*(m_x-x)+(m_y-y)*(m_y-y)) < current.dist then
        current.k = k
      end
    end
  end
  local target = players[id].target
  if current.k then
    local v = players[current.k]
    players[id].target.dX, target.dY, target.dZ = v.x+v.l/2, v.y+v.w/2, v.z+v.h/2
  else
    local z = players[id].z+players[id].h/2
    target.dX, target.dY, target.dZ = m_x, m_y-z, z
  end
  target.x = target.x + (target.dX-target.x) * dt * target_speed
  target.y = target.y + (target.dY-target.y) * dt * target_speed
  target.z = target.z + (target.dZ-target.z) * dt * target_speed
end

char.update = function(dt)
  for k, v in pairs(players) do
    -- gravity
    if v.zV < 10 then
      v.zV = v.zV + 0.2
    elseif v.zV > 10 then
      v.zV = 10
    end

    -- collision
    collision.grid(v)

    -- movement and friction
    v.x = v.x + v.xV * dt * 60
    v.xV = v.xV * 0.8

    v.y = v.y + v.yV * dt * 60
    v.yV = v.yV * 0.8

    v.z = v.z + v.zV * dt * 60

    --invulnerability
    if v.inv > 0 then
      v.inv = v.inv - dt
    end

    -- abilities
    for i, w in ipairs(v.abilities) do
      if w.delay > 0 then
        w.delay = w.delay - dt
      end
    end
    if v.energy < energy_max and not char.ability_check(v) then
      v.energy = v.energy + energy_increase*weapons[v.weapon.type].energy
    elseif v.energy > energy_max then
      v.energy = energy_max
    end

    -- animation
    v.weapon.frame = v.weapon.frame + v.weapon.speed*dt
    if v.weapon.frame > #weapon_quad[v.weapon.type][v.weapon.anim]+1 then
      if v.weapon.anim ~= "base" then
        v.weapon.anim = "base"
      end
      v.weapon.frame = 1
    end

    if v.hp <= 0 then -- death
      char.death(v)
    end
  end
end

char.serverupdate = function(dt)
  for k, v in pairs(players) do
    server:sendToAll("pos", {index = k, pos = {x = v.x, y = v.y, z = v.z, xV = v.xV, yV = v.yV, zV = v.zV}})
    if v.z > (#grid+tile_buffer)*tile_size then -- fall off reset
      v.hp = 0
      server:sendToAll("hp", {index = k, hp = 0})
    end
    if k ~= id then
      game.update_abilities(servergame.update_client_ability, k, dt)
    end
  end
end

char.use_ability = function(player, index, target, num)
  if player.abilities[num].delay <= 0 and player.energy >= abilities[player.abilities[num].type].energy and not (num < 3 and player.weapon.active) then
    player.abilities[num].active = abilities[player.abilities[num].type].press_func(player, index, target, num)
    if not player.abilities[num].active then -- initiate cooldown if ability isn't channelled
      player.abilities[num].delay = abilities[player.abilities[num].type].delay
      player.energy = player.energy - abilities[player.abilities[num].type].energy
    end
    if num < 3 then -- stop other weapon ability
      char.stop_ability(player, index, target, num-(num*2-3))
    end
  end
end

char.update_ability = function(player, index, target, num, dt)
  if player.abilities[num].active then
    if player.energy >= abilities[player.abilities[num].type].energy then
      if abilities[player.abilities[num].type].update_func then
        abilities[player.abilities[num].type].update_func(player, index, target, num)
      end
      player.energy = player.energy - abilities[player.abilities[num].type].energy * dt*60
    else
      char.stop_ability(player, index, target, num)
    end
  end
end

char.stop_ability = function(player, index, target, num)
  if player.abilities[num].active then
    if abilities[player.abilities[num].type].stop_func then
      abilities[player.abilities[num].type].stop_func(player, index, target, num)
    end
    player.abilities[num].active = false
    player.abilities[num].delay = abilities[player.abilities[num].type].delay-- initiate cooldown
  end
end

char.ability_check = function(player)
  for i, v in ipairs(player.abilities) do
    if v.active then
      return true
    end
  end
  return false
end

char.death = function(player)
  player.hp = hp_max
  player.x = #grid[1][1]*tile_size*0.5-player.l/2
  player.y = #grid[1]*tile_size*0.5-player.w/2
  player.z = -player.h
  if player.killer then
    players[player.killer].score = players[player.killer].score + 1
  end
  player.inv = death_inv
end

char.new = function(name, loadout, team)
  local item = {name = name, x = #grid[1][1]*tile_size*0.5, y = #grid[1]*tile_size*0.5, z = -24, l = 24, w = 24, h = 24, xV = 0, yV = 0, zV = 0,
                speed = 1, hp = hp_max, energy = energy_max, score = 0, jump = false, inv = 0, team = team, killer = false, target = {x = 0, y = 0, z = 0}}
  item.weapon = {type = loadout.weapon, active = false, anim = "base", frame = 1, speed = 0}
  item.abilities = {}
  for i, v in ipairs(loadout.abilities) do
    item.abilities[i] = {type = v, active = false, delay = 0, info = nil}
  end
  return item
end

char.damageable = function(k, l)
  return (players[k].inv <= 0 and (players[k].team <= 0 or players[k].team ~= players[l].team))
end

char.queue = function()
  for i, v in pairs(players) do
    -- char
    local flash = false
    if math.floor(math.sin(v.inv*14)+0.5) > 0 then
      flash = true
    end
    local border = false
    if v.team > 0 then
      border = team_colors[v.team]
    end
    queue[#queue + 1] = {img = player_img, x = v.x, y = v.y, z = v.z, w = v.w, h = v.h, l = v.l, shadow = true, flash = flash, border = border}

    -- weapon
    local dir = game.target_norm(v, v.target)
    local pos = game.target_pos(v, dir, (v.l+v.w)/2-8)
    local angle = math.atan2(dir.y+dir.z, dir.x)
    local sy = 1
    if pos.x < v.x+v.l/2 then
      sy = -1
    end
    queue[#queue + 1] = {img = weapon_img[v.weapon.type][v.weapon.anim], quad = weapon_quad[v.weapon.type][v.weapon.anim][math.floor(v.weapon.frame)], x = pos.x, y = pos.y, z = pos.z, angle = angle, w = 0, h = 0, l = 0, ox = 32, oy = 32, sx = 1, sy = sy}
  end
end

char.weapon_anim = function(k, anim, speed, reset)
  players[k].weapon.anim = anim
  players[k].weapon.frame = 1
  players[k].weapon.speed = speed
end

return char
