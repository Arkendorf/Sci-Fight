local hud = {}

local energy = energy_max
local hp = hp_max

hud.update = function(dt)
  energy = energy + (players[id].energy-energy) * dt * 12
  hp = hp + (players[id].hp-hp) * dt * 12
end

hud.draw = function()
  love.graphics.setColor(1, 0, 0)
  love.graphics.rectangle("fill", 4, 4, math.floor(hp/hp_max*256), 8)
  love.graphics.setColor(0, 1, 1)
  love.graphics.rectangle("fill", 4, 16, math.floor(energy/energy_max*256), 8)
  love.graphics.setColor(1, 1, 1)
end

return hud
