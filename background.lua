local background = {}

local stars = {}

local t = 0

background.load = function()
  background.canvas = love.graphics.newCanvas(screen.w, screen.h)
  background.fodder = love.graphics.newCanvas(screen.w, screen.h)
  love.graphics.setCanvas(background.canvas)
  love.graphics.clear()
  shader.background:send("color1", {21/255, 10/255, 51/255, 1})
  shader.background:send("color2", {86/255, 52/255, 127/255, 1})
  love.graphics.setShader(shader.background)
  love.graphics.draw(background.fodder)
  love.graphics.setShader()
  love.graphics.setCanvas()

  stars = {}
  local distance = 32
  local star_num = (screen.w*screen.h)/(distance*distance)
  for i = 1, star_num do
    stars[#stars+1] = {x = math.random(0, screen.w), y = math.random(0, screen.h), type = math.random(1, #star_quad), a = 1, a_offset = math.random(0, 2*math.pi)}
  end
end

background.update = function(dt)
  t = t + dt
  for i, v in ipairs(stars) do
    v.a = 1+math.sin(t+v.a_offset)*.5
  end
  local w, h = love.graphics.getDimensions()
  if w ~= screen.w*screen.scale or h ~= screen.h*screen.scale then
    background.res_change()
  end
end

background.draw = function()
  love.graphics.draw(background.canvas)
  for i, v in ipairs(stars) do
    love.graphics.setColor(1, 1, 1, v.a)
    love.graphics.draw(star_img, star_quad[v.type], v.x, v.y, 0, 1, 1, 4, 4)
    love.graphics.setColor(1, 1, 1)
  end
end

background.res_change = function()
  screen.w = love.graphics.getWidth() / screen.scale
  screen.h = love.graphics.getHeight() / screen.scale
  screen.canvas = love.graphics.newCanvas(screen.w, screen.h)
  background.load()
  settings.load()
  mainmenu.load()
end

return background
