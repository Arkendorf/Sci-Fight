local custom = {}

local button = {w = 64, h = 48, border = 2}
local button2 = {w = 84, h = 32, border = 2}
local icon = {w = 32, h = 32, border = 2}
local current_loadout = 1
local current_slot = 0
local offsets = {weapon = {x = 35, y = 5}, abilities = {{x = 35, y = 43}, {x = 73, y = 43}, {x = 111, y = 25}, {x = 149, y = 25}, {x = 187, y = 25}}}
local loadout_pos = {}
local option_pos = {}
local icons = {}

custom.start = function(buttons)
  gui.clear()
  if buttons then
    gui.add(1, buttons)
  else
    local buttons = sidebar.new({{txt = "Done", func = wipe.start, args = {mainmenu.start}}})
    gui.add(1, buttons)
  end

  local buttons = {}
  for i, v in ipairs(loadouts) do
    buttons[i] = {x = (screen.w-(button2.w+button2.border)*#loadouts+button2.border)/2+(i-1)*(button2.w+button2.border), y = (screen.h-256)/2, w = button2.w, h = button2.h, txt = "Loadout "..tostring(i), func = custom.set_current_loadout, args = {i}}
  end
  gui.add(2, buttons)
  custom.set_current_loadout(current_loadout)
end

custom.load = function()
  loadouts = {}
  for i = 1, 3 do
    loadouts[i] = {weapon = 1, abilities = {7, 8, 13, 14, 15}}
  end
  loadout_pos = {x = (screen.w-256)/2, y = (screen.h-256)/2+button2.h+button2.border, w = 256, h = 80}
  option_pos = {x = loadout_pos.x, y = loadout_pos.y+loadout_pos.h+button2.border, w = loadout_pos.w, h = 256-loadout_pos.h-button2.h-button2.border*2}
end

custom.update = function(dt)

end

custom.draw = function()
  love.graphics.setColor(menu_color)
  love.graphics.rectangle("fill", loadout_pos.x, loadout_pos.y, loadout_pos.w, loadout_pos.h)
  love.graphics.setColor(1, 1, 1)
  love.graphics.rectangle("fill", option_pos.x, option_pos.y, option_pos.w, option_pos.h)

  love.graphics.draw(weapon_img[loadouts[current_loadout].weapon], loadout_pos.x+offsets.weapon.x, loadout_pos.y+offsets.weapon.y)
  for i, v in ipairs(offsets.abilities) do
    love.graphics.draw(ability_img[loadouts[current_loadout].abilities[i]], loadout_pos.x+v.x, loadout_pos.y+v.y)
  end
  for i, v in ipairs(icons) do
    if current_slot == "weapon" then
      love.graphics.draw(weapon_img[v.num], v.x, v.y)
    elseif custom.ability_used(v.num) then
      love.graphics.setShader(shader.greyscale)
      love.graphics.draw(ability_img[v.num], v.x, v.y)
      love.graphics.setShader()
    else
      love.graphics.draw(ability_img[v.num], v.x, v.y)
    end
  end
end

custom.set_current_loadout = function(num)
  current_loadout = num
  icons = {}
  gui.remove(4)
  custom.update_loadout_gui()
end

custom.update_loadout_gui = function()
  gui.remove(3)
  local pos = loadout_pos
  local buttons = {}
  local infoboxes = {}
  buttons[1] = {x = pos.x+offsets.weapon.x, y = pos.y+offsets.weapon.y, w = 70, h = icon.h, txt = "Weapon", func = custom.set_current_slot, args = {"weapon"}, hide = true}
  local txt = custom.weapon_info(loadouts[current_loadout].weapon)
  infoboxes[#infoboxes+1] = {x = pos.x+offsets.weapon.x, y = pos.y+offsets.weapon.y, w = 70, h = icon.h, box = gui.text_size(txt, 128), txt = txt}
  for i, v in ipairs(offsets.abilities) do
    buttons[i+1]  = {x = pos.x+v.x, y = pos.y+v.y, w = icon.w, h = icon.h, txt = tostring(i), func = custom.set_current_slot, args = {i}, hide = true}
    txt = custom.ability_info(loadouts[current_loadout].abilities[i])
    infoboxes[#infoboxes+1] = {x = pos.x+v.x, y = pos.y+v.y, w = icon.w, h = icon.h, box = gui.text_size(txt, 128), txt = txt}
  end
  gui.add(3, buttons, {}, infoboxes)
end

custom.set_current_slot = function(type)
  current_slot = type
  icons = custom.get_icon_pos(type)
  local buttons = {}
  local infoboxes = {}
  for i, v in ipairs(icons) do
    if type == "weapon" then
      buttons[#buttons+1] = {x = v.x, y = v.y, w= v.w, h = v.h, txt = tostring(v.num), func = custom.change_weapon, args = {v.num}, hide = true}
      local txt = custom.weapon_info(v.num)
      infoboxes[#infoboxes+1] = {x = v.x, y = v.y, w= v.w, h = v.h, box = gui.text_size(txt, 128), txt = txt}
    else
      buttons[#buttons+1] = {x = v.x, y = v.y, w= v.w, h = v.h, txt = tostring(v.num), func = custom.change_ability, args = {v.num, type}, hide = true}
      local txt = custom.ability_info(v.num)
      infoboxes[#infoboxes+1] = {x = v.x, y = v.y, w= v.w, h = v.h, box = gui.text_size(txt, 128), txt = txt}
    end
  end
  gui.add(4, buttons, {}, infoboxes)
end

custom.get_icon_pos = function(type)
  local x = 0
  local y = 0
  local icons = {}
  if type == "weapon" then
    for i, v in ipairs(weapons) do
      w = 70
      icons[#icons+1] = {x = option_pos.x+x*(w+icon.border)+icon.border+18, y = option_pos.y+y*(icon.h+icon.border)+icon.border, w = w, h = icon.h, num = i}
      x = x + 1
      if x > 3 then
        x = 0
        y = y + 1
      end
    end
  elseif type > 0 then
    for i, v in ipairs(abilities) do
      if (type > 2 and not v.type) or (type < 3 and v.type == weapons[loadouts[current_loadout].weapon].type) then
        icons[#icons+1] = {x = option_pos.x+x*(icon.w+icon.border)+icon.border+8, y = option_pos.y+y*(icon.h+icon.border)+icon.border, w= icon.w, h = icon.h, num = i}
        x = x + 1
      end
      if x > 6 then
        x = 0
        y = y + 1
      end
    end
  end
  return icons
end

custom.change_ability = function(ability, slot)
  local used = custom.ability_used(ability)
  if not used then
    loadouts[current_loadout].abilities[slot] = ability
  else -- if ability is already slotted, switch
    local old = loadouts[current_loadout].abilities[slot]
    loadouts[current_loadout].abilities[slot] = ability
    loadouts[current_loadout].abilities[used] = old
  end
  custom.update_loadout_gui()
end

custom.ability_used = function(ability)
  for i, v in ipairs(loadouts[current_loadout].abilities) do -- no doubling abilities
    if v == ability then
      return i
    end
  end
  return false
end

custom.change_weapon = function(weapon)
  local old_type = weapons[loadouts[current_loadout].weapon].type  -- don't allow weapon to have abilities from another type of weapon
  local new_type = weapons[weapon].type
  local ability = 1
  if old_type ~= new_type then
    for i, v in ipairs(abilities) do
      if v.type and v.type == new_type then
        loadouts[current_loadout].abilities[ability] = i
        ability = ability + 1
      end
      if ability > 2 then
        break
      end
    end
  end
  loadouts[current_loadout].weapon = weapon
  custom.update_loadout_gui()
end

custom.get_loadout = function()
  return loadouts[current_loadout]
end

custom.ability_info = function(num)
  local str = abilities[num].name.."\n"..abilities[num].desc.."\nCooldown: "..tostring(abilities[num].delay).."s\nEnergy: "
  if abilities[num].update_func or abilities[num].stop_func then
    str = str..tostring(abilities[num].energy*60).."/s"
  else
    str = str..tostring(abilities[num].energy)
  end
  return str
end

custom.weapon_info = function(num)
  return weapons[num].desc.."\nDamage Modifier: x"..tostring(weapons[num].dmg).."\nEnergy Modifier: x"..tostring(weapons[num].energy)
end

return custom
