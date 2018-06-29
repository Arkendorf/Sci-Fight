local bullet = {}

local laser_speed = 6

bullet.load = function()
  bullets = {}
end

bullet.update = function(dt)
  for i, v in pairs(bullets) do
    v.x = v.x + v.xV
    v.y = v.y + v.yV
    -- collide with players
    local hit = collision.line_player({x = v.x, y = v.y}, {x = v.xV, y = v.yV})
    if hit and hit ~= v.parent then
      -- damage stuff
      bullets[i] = nil
    end
    -- collide with borders (twice as large as map)
    if v.x > #grid[1][1]*tile_size*2 or v.x < -#grid[1][1]*tile_size or v.y > #grid[1]*tile_size*2 or v.y < -#grid[1]*tile_size then
      bullets[i] = nil
    end
  end
end

bullet.draw = function()
  for i, v in pairs(bullets) do
    love.graphics.setLineWidth(6)
    love.graphics.setColor(0, 1, 0)
    love.graphics.line(v.x, v.y, v.x+v.xV*4, v.y+v.yV*4)
    love.graphics.setLineWidth(2)
    love.graphics.setColor(1, 1, 1)
    love.graphics.line(v.x, v.y, v.x+v.xV*4, v.y+v.yV*4)
  end

  love.graphics.print(#bullets)
end

bullet.new = function(x1, y1, x2, y2)
  local angle = math.atan2(y2 - y1, x2 - x1)
  bullets[#bullets+1] = {x = x1, y = y1, xV = math.cos(angle)*laser_speed, yV = math.sin(angle)*laser_speed, angle = angle, parent = id}
end

return bullet
