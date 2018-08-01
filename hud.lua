local hud = {}

local energy = energy_max
local hp = hp_max

local icon = {w = 32, h = 32, border = 2}
local bar = {w = 168, h = 6, border = 2}
local pos = {}

hud.load = function()
  pos = {x = icon.border, y = screen.h-icon.h-icon.border*2-bar.h*2-bar.border}
end

hud.update = function(dt)
  energy = energy + (players[id].energy-energy) * dt * 12
  hp = hp + (players[id].hp-hp) * dt * 12
end

hud.draw = function()
  love.graphics.setColor(1, 0, 0)
  love.graphics.rectangle("fill", pos.x, pos.y, math.floor(hp/hp_max*bar.w), bar.h)
  love.graphics.setColor(0, 1, 1)
  love.graphics.rectangle("fill", pos.x, pos.y+bar.h+bar.border, math.floor(energy/energy_max*bar.w), bar.h)
  love.graphics.setColor(1, 1, 1)
  for i, v in ipairs(players[id].abilities) do
    if v.delay > 0 or abilities[v.type].energy > players[id].energy or (i < 3 and players[id].weapon.active) then
      love.graphics.setShader(shader.greyscale)
    end
    local x, y = icon.border+(i-1)*(icon.w+icon.border), screen.h-(icon.h+icon.border)
    love.graphics.draw(ability_img[v.type], x, y)
    love.graphics.setShader()
    if v.delay > 0 then
      love.graphics.setColor(0, 0, 0, 0.4)
      love.graphics.circle("fill", x+16, y+16, 12)
      love.graphics.setColor(1, 1, 1)
      love.graphics.printf(math.floor(v.delay*10)/10, x, y+12, icon.w, "center")
    end
  end
end

return hud
