local char = {}

local target_range = 24
local target_speed = 32
energy_max = 100
local energy_increase = 0.1
hp_max = 100

local tile_buffer = 8
local death_inv = 1

skin_name = {
  "Trooper",
  "Shadow Trooper",
  "Bounty Hunter I",
  "Bounty Hunter II",
  "Master",
  "Dark Lord",
  "Knight I",
  "Knight II"
}

char.load = function()
end

char.input = function(dt)
  --input
  local add = {x = 0, y = 0}
  if love.keyboard.isDown("w") then
    add.y = add.y - 1
  end
  if love.keyboard.isDown("s") then
    add.y = add.y + 1
  end
  if love.keyboard.isDown("a") then
    add.x = add.x - 1
  end
  if love.keyboard.isDown("d") then
    add.x = add.x + 1
  end
  local norm = math.sqrt(add.x*add.x+add.y*add.y)
  if norm > 0 then -- don't divide by zero!
    local mag = .5 * players[id].speed
    players[id].xV = players[id].xV + add.x/norm*mag
    players[id].yV = players[id].yV + add.y/norm*mag
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
    -- animate target
    if players[id].target.frame < 4 then
      players[id].target.frame = players[id].target.frame+dt*30
      if players[id].target.frame > 4 then
        players[id].target.frame = 4
      end
    end
  else
    local z = players[id].z+players[id].h/2
    target.dX, target.dY, target.dZ = m_x, m_y-z, z
    if players[id].target.frame > 1 then
      players[id].target.frame = players[id].target.frame-dt*30
      if players[id].target.frame < 1 then
        players[id].target.frame = 1
      end
    end
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

    -- particles
    local speed = math.sqrt(v.xV*v.xV+v.yV*v.yV)
    local pos = {x = 1+math.floor((v.x+v.l/2)/tile_size), y = 1+math.floor((v.y+v.w/2)/tile_size), z = 1+math.floor((v.z+v.h+math.min(math.abs(v.zV), tile_size/2))/tile_size)}
    if map.in_bounds(pos.x, pos.y, pos.z) and tiles[grid[pos.z][pos.y][pos.x]].solid then
      if math.random(1, 16) < speed then
        local vX, vY = math.random(-v.l/2, v.l/2), math.random(-v.w/2, v.w/2)
        particle.new(v.x+v.l/2+vX, v.y+v.w/2+vY, v.z+v.h, vX/40, vY/40, 0, "dust")
      end
      if math.abs(v.zV) > 1 then
        char.jump_particle(v)
      end
    end

    -- collision
    collision.map(v)

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
      if w.active and abilities[w.type].particle_func then
        abilities[w.type].particle_func(v, k, v.target)
      end
    end
    if v.energy < energy_max and not char.ability_check(v) then
      v.energy = v.energy + energy_increase
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

    if math.abs(v.xV) > 0.1 or math.abs(v.yV) > 0.1 then
      v.anim = "run"
    else
      v.anim = "base"
    end
    v.frame = v.frame + (math.abs(v.xV)+math.abs(v.yV))*6*dt
    if v.frame > #char_quad[v.skin][v.anim][1]+1 then
      v.frame = 1
    end

    if v.hp <= 0 then -- death
      char.death(v)
    end
  end
end

char.serverupdate = function(dt)
  for k, v in pairs(players) do
    server:sendToAll("pos", {index = k, pos = {x = v.x, y = v.y, z = v.z, xV = v.xV, yV = v.yV, zV = v.zV}})
    if v.inv <= 0 and v.tile_damage then -- damaging tiles
      local num = v.hp - 25
      bullet.damage(v, num)
      server:sendToAll("hit", {index = k, num = num})
      v.tile_damage = false
    end
    if v.z > (#grid+tile_buffer)*tile_size then -- fall off reset
      v.hp = 0
      server:sendToAll("hp", {index = k, hp = 0})
    end
    if k ~= id then
      game.update_abilities(servergame.update_client_ability, k, dt)
    end
  end
end

char.jump_particle = function(v)
  local freq = math.ceil(math.abs(v.zV))
  for i = 1, freq do
    local vX, vY = math.random(-v.l/2, v.l/2), math.random(-v.w/2, v.w/2)
    particle.new(v.x+v.l/2+vX, v.y+v.w/2+vY, v.z+v.h, vX*freq/40, vY*freq/40, 0, "dust")
  end
end

char.use_ability = function(player, index, target, num)
  local cost = abilities[player.abilities[num].type].energy*weapons[player.weapon.type].mod
  if player.abilities[num].delay <= 0 and player.energy >= cost and not (num < 3 and player.weapon.active) then
    player.abilities[num].active = abilities[player.abilities[num].type].press_func(player, index, target, num)
    if not player.abilities[num].active then -- initiate cooldown if ability isn't channelled
      player.abilities[num].delay = abilities[player.abilities[num].type].delay
      player.energy = player.energy - cost
      if abilities[player.abilities[num].type].particle_func then
        abilities[player.abilities[num].type].particle_func(player, index, target)
      end
    end
    if num < 3 then -- stop other weapon ability
      char.stop_ability(player, index, target, num-(num*2-3))
    end
    return true
  end
  return false
end

char.update_ability = function(player, index, target, num, dt)
  if player.abilities[num].active then
    local cost = abilities[player.abilities[num].type].energy*weapons[player.weapon.type].mod*dt*60
    if player.energy >= cost then
      if abilities[player.abilities[num].type].update_func then
        abilities[player.abilities[num].type].update_func(player, index, target, num)
      end
      player.energy = player.energy - cost
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
  player.energy = energy_max
  player.x = #grid[1][1]*tile_size*0.5-player.l/2
  player.y = #grid[1]*tile_size*0.5-player.w/2
  player.z = -player.h
  if player.killer then
    players[player.killer].score = players[player.killer].score + 1
  end
  player.inv = death_inv
end

char.new = function(name, loadout, team)
  local item = {name = name, x = #grid[1][1]*tile_size*0.5-12, y = #grid[1]*tile_size*0.5-12, z = -24, l = 24, w = 24, h = 24, xV = 0, yV = 0, zV = 0,
                speed = 1, hp = hp_max, energy = energy_max, score = 0, jump = false, inv = 0, team = team, killer = false, target = {x = 0, y = 0, z = 0, frame = 1},
                anim = "run", frame = 1, skin = loadout.skin}
  item.weapon = {type = loadout.weapon, active = false, anim = "base", frame = 1, speed = 0}
  item.abilities = {}
  for i, v in ipairs(loadout.abilities) do
    item.abilities[i] = {type = v, active = false, delay = 0, info = nil}
  end
  return item
end

char.damageable = function(k, l)
  return (k ~= l and players[k].inv <= 0 and (players[k].team <= 0 or players[k].team ~= players[l].team))
end

char.queue = function()
  for i, v in pairs(players) do
    local dir = game.target_norm(v, v.target)

    love.graphics.setCanvas(v.canvas)
    love.graphics.clear()
    char.draw_char(v)
    love.graphics.setCanvas()

    queue[#queue + 1] = {img = v.canvas, x = v.x, y = v.y, z = v.z, w = v.w, h = v.h, l = v.l, shadow = true, ox = 32, oy = 24}
  end
end

char.get_weapon_pos = function(v)
  return game.target_norm(v, v.target, (v.l+v.w)/2-12)
end

char.draw_char = function(v)
  -- weapon pos
  local dir = char.get_weapon_pos(v)
  local weapon_pos = {x = math.floor(dir.x)+44, y = math.floor(dir.y+dir.z)+44}
  local angle = math.atan2(dir.y+dir.z, dir.x)
  local sy = 1
  if dir.x < 0 then
    sy = -1
  end

  -- face
  local face = 1
  if math.abs(dir.x) > math.abs(dir.y) and dir.x > 0 then
    face = 2
  elseif math.abs(dir.x) > math.abs(dir.y) then
    face = 4
  elseif dir.y < 0 then
    face = 3
  end

  -- arm pos
  local weapon_offset = {x = (weapon_info[v.weapon.type][v.weapon.anim].handlepos[math.floor(v.weapon.frame)].x-32)*sy, y = (weapon_info[v.weapon.type][v.weapon.anim].handlepos[math.floor(v.weapon.frame)].y-32)*sy}
  local hand_pos = {x = weapon_pos.x+weapon_offset.x*math.cos(angle)-weapon_offset.y*math.sin(angle), y = weapon_pos.y+weapon_offset.x*math.sin(angle)+weapon_offset.y*math.cos(angle)}
  local right_pos = {x = 32+char_info[v.skin][v.anim].armpos[face].right[math.floor(v.frame)].x, y = 24+char_info[v.skin][v.anim].armpos[face].right[math.floor(v.frame)].y}
  local left_pos = {x = 32+char_info[v.skin][v.anim].armpos[face].left[math.floor(v.frame)].x, y = 24+char_info[v.skin][v.anim].armpos[face].left[math.floor(v.frame)].y}

  -- draw everything
  if face == 1 then
    char.draw_body(v, face)
    love.graphics.draw(weapon_img[v.weapon.type][v.weapon.anim], weapon_quad[v.weapon.type][v.weapon.anim][math.floor(v.weapon.frame)], weapon_pos.x, weapon_pos.y, angle, 1, sy, 32, 32)
  end
  char.draw_arm(left_pos, hand_pos, v.skin)
  if face == 2 or face == 4 then
    char.draw_body(v, face)
    love.graphics.draw(weapon_img[v.weapon.type][v.weapon.anim], weapon_quad[v.weapon.type][v.weapon.anim][math.floor(v.weapon.frame)], weapon_pos.x, weapon_pos.y, angle, 1, sy, 32, 32)
  end
  char.draw_arm(right_pos, hand_pos, v.skin)
  if face == 3 then
    love.graphics.draw(weapon_img[v.weapon.type][v.weapon.anim], weapon_quad[v.weapon.type][v.weapon.anim][math.floor(v.weapon.frame)], weapon_pos.x, weapon_pos.y, angle, 1, sy, 32, 32)
    char.draw_body(v, face)
  end
end

char.draw_body = function(v, face)
  if v.team > 0 then
    graphics.draw_outline({img = char_img[v.skin][v.anim], quad = char_quad[v.skin][v.anim][face][math.floor(v.frame)], x = 32, y = 24, border = team_colors[v.team]})
  end
  if math.floor(math.sin(v.inv*14)+0.5) > 0 then
    love.graphics.setShader(shader.color)
  end
  love.graphics.draw(char_img[v.skin][v.anim], char_quad[v.skin][v.anim][face][math.floor(v.frame)], 32, 24)
  love.graphics.setShader()
end

char.draw_arm = function(p1, p2, skin, disp)
  love.graphics.setLineWidth(4)
  love.graphics.setColor(0, 0, 0)
  love.graphics.line(p1.x, p1.y, p2.x, p2.y)
  love.graphics.setLineWidth(2)
  love.graphics.setColor(char_info[skin].base.armcolor)
  if disp then
    love.graphics.line(p1.x, p1.y, p2.x, p2.y-1)
  else
    love.graphics.line(p1.x, p1.y, p2.x, p2.y)
  end
  love.graphics.setColor(1, 1, 1)
end


char.weapon_anim = function(k, anim, speed, reset)
  players[k].weapon.anim = anim
  players[k].weapon.frame = 1
  players[k].weapon.speed = speed
end

return char
