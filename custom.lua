local custom = {}

local button = {w = 64, h = 48, border = 2}
local button2 = {w = 80, h = 32, border = 8}
local icon = {w = 32, h = 32, border = 2}
local current_loadout = 1
local current_slot = 0
local offsets = {skin = {x = 26, y = 7}, weapon = {x = 60, y = 7}, abilities = {{x = 60, y = 41}, {x = 94, y = 41}, {x = 128, y = 25}, {x = 162, y = 25}, {x = 196, y = 25}}}
local loadout_pos = {}
local option_pos = {}
local icons = {}

local custom_imgs = {}

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
    buttons[i] = {x = (screen.w-(button2.w+button2.border)*#loadouts+button2.border)/2+(i-1)*(button2.w+button2.border), y = (screen.h-256)/2, w = button2.w, h = button2.h, txt = "Loadout "..tostring(i), func = custom.set_current_loadout, args = {i}, mat = {func = custom.mat, args = {i}}}
  end
  gui.add(2, buttons)
  custom.set_current_loadout(current_loadout)
end

custom.load = function()
  loadouts = {}
  for i = 1, 3 do
    loadouts[i] = {skin = 1, weapon = 1, abilities = {7, 8, 13, 14, 15}}
  end
  loadout_pos = {x = (screen.w-256)/2, y = (screen.h-256)/2+button2.h+button.border, w = 256, h = 80}
  option_pos = {x = loadout_pos.x, y = loadout_pos.y+loadout_pos.h+button.border, w = loadout_pos.w, h = 256-loadout_pos.h-button2.h-button.border*2}

  custom_imgs.loadout = gui.new_img(4, loadout_pos.w, loadout_pos.h)
  custom_imgs.option = gui.new_img(5, option_pos.w, option_pos.h)
end

custom.update = function(dt)

end

custom.draw = function()
  love.graphics.draw(custom_imgs.loadout, loadout_pos.x, loadout_pos.y)
  love.graphics.draw(custom_imgs.option, option_pos.x, option_pos.y)

  custom.icon_background(loadout_pos.x+offsets.skin.x, loadout_pos.y+offsets.skin.y, 1, false)
  custom.draw_skin(loadouts[current_loadout].skin, loadout_pos.x+offsets.skin.x, loadout_pos.y+offsets.skin.y) -- skin
  custom.icon_background(loadout_pos.x+offsets.weapon.x, loadout_pos.y+offsets.weapon.y, 2, false)
  love.graphics.draw(weapon_icon[loadouts[current_loadout].weapon], loadout_pos.x+offsets.weapon.x, loadout_pos.y+offsets.weapon.y) -- weapon
  for i, v in ipairs(offsets.abilities) do -- abilities
    custom.icon_background(loadout_pos.x+v.x, loadout_pos.y+v.y, 3, false)
    love.graphics.draw(ability_icon[loadouts[current_loadout].abilities[i]], loadout_pos.x+v.x, loadout_pos.y+v.y)
  end
  for i, v in ipairs(icons) do
    if current_slot == "skin" then
      custom.icon_background(v.x, v.y, 1, loadouts[current_loadout].skin == v.num)
      custom.draw_skin(v.num, v.x, v.y) -- skin
    elseif current_slot == "weapon" then
      custom.icon_background(v.x, v.y, 2, loadouts[current_loadout].weapon == v.num)
      love.graphics.draw(weapon_icon[v.num], v.x, v.y)
    else
      custom.icon_background(v.x, v.y, 3, custom.ability_used(v.num))
      love.graphics.draw(ability_icon[v.num], v.x, v.y)
    end
  end
end

custom.icon_background = function(x, y, type, bool)
  if bool then
    love.graphics.draw(icon_img, icon_quad[type*2], x, y)
  else
    love.graphics.draw(icon_img, icon_quad[type*2-1], x, y)
  end
end

custom.draw_skin = function(skin, x, y)
  local offset = {x = 4, y = 12}
  local right_offset = {x = char_info[skin].base.armpos[1].right[1].x, y = char_info[skin].base.armpos[1].right[1].y}
  local left_offset = {x = char_info[skin].base.armpos[1].left[1].x, y = char_info[skin].base.armpos[1].left[1].y}
  char.draw_arm({x = x+offset.x+right_offset.x, y = y+offset.y+right_offset.y}, {x = x+offset.x+right_offset.x+1, y = y+offset.y+right_offset.y+10}, skin, true)
  char.draw_arm({x = x+offset.x+left_offset.x, y = y+offset.y+left_offset.y}, {x = x+offset.x+left_offset.x-1, y = y+offset.y+left_offset.y+10}, skin, true)
  love.graphics.draw(char_img[skin].base, char_quad[skin].base[1][1], x+offset.x, y+offset.y)
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
  -- skin
  buttons[#buttons+1] = {x = pos.x+offsets.skin.x, y = pos.y+offsets.skin.y, w = icon.w, h = icon.h*2+icon.border, txt = "Skin", func = custom.set_current_slot, args = {"skin"}, hide = true}
  local txt = skin_name[loadouts[current_loadout].skin]
  local w, h = gui.text_size(txt, 128)
  infoboxes[#infoboxes+1] = {x = pos.x+offsets.skin.x, y = pos.y+offsets.skin.y, w = w, h = h, hit = {w = icon.w, h = icon.h*2+icon.border}, txt = txt}
  -- weapon
  buttons[#buttons+1] = {x = pos.x+offsets.weapon.x, y = pos.y+offsets.weapon.y, w = icon.w*2+icon.border, h = icon.h, txt = "Weapon", func = custom.set_current_slot, args = {"weapon"}, hide = true}
  local txt = custom.weapon_info(loadouts[current_loadout].weapon)
  local w, h = gui.text_size(txt, 128)
  infoboxes[#infoboxes+1] = {x = pos.x+offsets.weapon.x, y = pos.y+offsets.weapon.y, w = w, h = h, hit = {w = icon.w*2+icon.border, h = icon.h}, txt = txt}
  -- abilities
  for i, v in ipairs(offsets.abilities) do
    buttons[#buttons+1]  = {x = pos.x+v.x, y = pos.y+v.y, w = icon.w, h = icon.h, txt = tostring(i), func = custom.set_current_slot, args = {i}, hide = true}
    txt = custom.ability_info(loadouts[current_loadout].abilities[i])
    local w, h = gui.text_size(txt, 128)
    infoboxes[#infoboxes+1] = {x = pos.x+v.x, y = pos.y+v.y, w = w, h = h, hit = {w = icon.w, h = icon.h}, txt = txt}
  end
  gui.add(3, buttons, {}, infoboxes)
end

custom.set_current_slot = function(type)
  current_slot = type
  icons = custom.get_icon_pos(type)
  local buttons = {}
  local infoboxes = {}
  for i, v in ipairs(icons) do
    if type == "skin" then
      buttons[#buttons+1] = {x = v.x, y = v.y, w = v.w, h = v.h, txt = tostring(v.num), func = custom.change_skin, args = {v.num}, hide = true}
      local txt = skin_name[v.num]
      local w, h = gui.text_size(txt, 128)
      infoboxes[#infoboxes+1] = {x = v.x, y = v.y, w = w, h = h, hit = {w = v.w, h = v.h}, txt = txt}
    elseif type == "weapon" then
      buttons[#buttons+1] = {x = v.x, y = v.y, w = v.w, h = v.h, txt = tostring(v.num), func = custom.change_weapon, args = {v.num}, hide = true}
      local txt = custom.weapon_info(v.num)
      local w, h = gui.text_size(txt, 128)
      infoboxes[#infoboxes+1] = {x = v.x, y = v.y, w = w, h = h, hit = {w = v.w, h = v.h}, txt = txt}
    else
      buttons[#buttons+1] = {x = v.x, y = v.y, w = v.w, h = v.h, txt = tostring(v.num), func = custom.change_ability, args = {v.num, type}, hide = true}
      local txt = custom.ability_info(v.num)
      local w, h = gui.text_size(txt, 128)
      infoboxes[#infoboxes+1] = {x = v.x, y = v.y, w = w, h = h, hit = {w = v.w, h = v.h}, txt = txt}
    end
  end
  gui.add(4, buttons, {}, infoboxes)
end

custom.get_icon_pos = function(type)
  local x = 0
  local y = 0
  local icons = {}
  if type == "skin" then
    for i, v in ipairs(char_img) do
      h = icon.h*2+icon.border
      icons[#icons+1] = {x = option_pos.x+x*(icon.w+icon.border)+icon.border+8, y = option_pos.y+y*(h+icon.border)+icon.border+5, w = icon.w, h = h, num = i}
      x = x + 1
      if x > 6 then
        x = 0
        y = y + 1
      end
    end
  elseif type == "weapon" then
    for i, v in ipairs(weapons) do
      w = icon.w*2+icon.border
      icons[#icons+1] = {x = option_pos.x+x*(w+icon.border)+icon.border+24, y = option_pos.y+y*(icon.h+icon.border)+icon.border+5, w = w, h = icon.h, num = i}
      x = x + 1
      if x > 2 then
        x = 0
        y = y + 1
      end
    end
  elseif type > 0 then
    for i, v in ipairs(abilities) do
      if (type > 2 and not v.type) or (type < 3 and v.type == weapons[loadouts[current_loadout].weapon].type) then
        icons[#icons+1] = {x = option_pos.x+x*(icon.w+icon.border)+icon.border+8, y = option_pos.y+y*(icon.h+icon.border)+icon.border+5, w = icon.w, h = icon.h, num = i}
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

custom.change_skin = function(skin)
  loadouts[current_loadout].skin = skin
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
  return weapons[num].desc.."\nModifier: x"..tostring(weapons[num].mod)
end

custom.mat = function(num)
  if current_loadout == num then
    return 2
  else
    return 1
  end
end

return custom
