local sidebar = {}

local button = {w = 64, h = 48, border = 2}

sidebar.button_y = function(num, max)
  return (screen.h-max*(button.h+button.border))/2+(button.h+button.border)*(num-1)
end

sidebar.new = function(t)
  local buttons = {}
  for i, v in ipairs(t) do
    buttons[i] = {x = button.border, y = sidebar.button_y(i, #t), w = button.w, h = button.h, txt = v.txt, func = v.func, args = v.args, mat = v.mat}
  end
  return buttons
end

return sidebar
