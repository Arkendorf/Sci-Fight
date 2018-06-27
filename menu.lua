clientmenu = require "clientmenu"
servermenu = require "servermenu"

local menu = {}

menu.load = function()
  clientmenu.load()
  servermenu.load()
end

menu.start = function()
  players = {}
  id = 0
end

menu.update = function(dt)
end

menu.draw = function()
end

menu.opening = function(a) -- find available space in list 'a'
  for i, v in ipairs(a) do
    if v == nil then
      return i
    end
  end
  return #a + 1
end

return menu
