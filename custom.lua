local custom = {}

local button = {w = 64, h = 48, border = 2}
local button2 = {w = 82, h = 32, border = 4}
local icon = {w = 32, h = 32, border = 4}
local current_loadout = 1
local current_slot = {type = 0, num = 0}
local offsets = {weapon = {x = 35, y = 5}, abilities = {{x = 35, y = 43}, {x = 73, y = 43}, {x = 111, y = 25}, {x = 149, y = 25}, {x = 187, y = 25}}}
local loadout_pos = {}
local option_pos = {}
local icons = {}

custom.start = function()
  gui.clear()
  gui.add(1, {{x = button.border, y = mainmenu.button_y(1, 1), w = button.w, h = button.h, txt = "Done", func = wipe.start, args = {mainmenu.start}}}, {})

  local buttons = {}
  for i, v in ipairs(loadouts) do
    buttons[i] = {x = (screen.w-(button2.w+button2.border)*#loadouts+button2.border)/2+(i-1)*(button2.w+button2.border), y = (screen.h-256)/2, w = button2.w, h = button2.h, txt = "Loadout "..tostring(i), func = custom.set_current_loadout, args = {i}}
  end
  gui.add(2, buttons, {})
  custom.set_current_loadout(current_loadout)
end

custom.load = function()
  loadouts = {}
  for i = 1, 3 do
    loadouts[i] = {weapon = 1, abilities = {2, 3, 4, 4, 4}}
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
  for i, v in ipairs(offsets.abilities) do
    local img = ability_img[loadouts[current_loadout].abilities[i]]
    if img then
      love.graphics.draw(img, loadout_pos.x+v.x, loadout_pos.y+v.y)
    end
  end
  for i, v in ipairs(icons) do
    if current_slot.type == "weapon" then
      love.graphics.setColor(menu_color)
      love.graphics.rectangle("fill", v.x, v.y, v.w, v.h)
    elseif custom.ability_used(v.num) then
      love.graphics.setColor(0.6, 0.6, 0.6)
      love.graphics.draw(ability_img[v.num], v.x, v.y)
    else
      love.graphics.draw(ability_img[v.num], v.x, v.y)
    end
    love.graphics.setColor(1, 1, 1)
  end
end

custom.set_current_loadout = function(num)
  current_loadout = num
  gui.remove(3)
  current_slot.type = 0
  gui.remove(4)
  local pos = loadout_pos
  local buttons = {}
  buttons[1] = {x = pos.x+offsets.weapon.x, y = pos.y+offsets.weapon.y, w = 70, h = 32, txt = "Weapon", func = custom.set_current_slot, args = {"weapon"}}
  for i, v in ipairs(offsets.abilities) do
    buttons[i+1]  = {x = pos.x+v.x, y = pos.y+v.y, w = 32, h = 32, txt = tostring(i), func = custom.set_current_slot, args = {i}, hide = true}
  end
  gui.add(3, buttons, {})
end

custom.set_current_slot = function(type)
  current_slot.type = type
  current_slot.num = num
  icons = custom.get_icon_pos(type)
  local buttons = {}
  for i, v in ipairs(icons) do
    if type == "weapon" then
      buttons[#buttons+1] = {x = v.x, y = v.y, w= v.w, h = v.h, txt = tostring(v.num), func = custom.change_weapon, args = {v.num}, hide = true}
    else
      buttons[#buttons+1] = {x = v.x, y = v.y, w= v.w, h = v.h, txt = tostring(v.num), func = custom.change_ability, args = {v.num, type}, hide = true}
    end
  end

  gui.add(4, buttons, {})
end

custom.get_icon_pos = function(type)
  local x = 0
  local y = 0
  local icons = {}
  if type == "weapon" then
    for i, v in ipairs(weapons) do
      w = icon.w*2+icon.border
      icons[#icons+1] = {x = option_pos.x+x*(w+icon.border)+icon.border, y = option_pos.y+y*(icon.h+icon.border)+icon.border, w= w, h = icon.h, num = i}
      x = x + 1
      if x > 3 then
        x = 0
        y = y + 1
      end
    end
  elseif type > 0 then
    for i, v in ipairs(abilities) do
      if (type > 2 and not v.type) or (type < 3 and v.type == weapons[loadouts[current_loadout].weapon].type) then
        icons[#icons+1] = {x = option_pos.x+x*(icon.w+icon.border)+icon.border, y = option_pos.y+y*(icon.h+icon.border)+icon.border, w= icon.w, h = icon.h, num = i}
        x = x + 1
      end
      if x > 7 then
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
  loadouts[current_loadout].weapon = weapon
end

custom.get_loadout = function()
  return loadouts[current_loadout]
end

return custom
