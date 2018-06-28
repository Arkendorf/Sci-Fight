local wipe = {}

local x1 = 0
local x2 = 0

wipe.active = false
wipe.done = false

wipe.update = function(dt)
  x1 = graphics.zoom(wipe.active, x1, 0, screen.w, dt * 12)
  if x1 >= screen.w and not wipe.done then
    if wipe.args then
      wipe.func(unpack(wipe.args))
    else
      wipe.func()
    end
    wipe.done = true
  end
  x2 = graphics.zoom(wipe.done, x2, 0, screen.w, dt * 12)
  if x2 >= screen.w then
    wipe.active = false
    wipe.done = false
    x1 = 0
    x2 = 0
  end
end

wipe.draw = function()
  love.graphics.setColor(menu_color)
  love.graphics.rectangle("fill", x2, 0, x1-x2, screen.h)
  love.graphics.setColor(1, 1, 1)
end

wipe.start = function(func, args)
  wipe.active = true
  wipe.func = func
  wipe.args = args
end

return wipe
