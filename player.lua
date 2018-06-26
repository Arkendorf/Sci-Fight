local player = {}

player.load = function()
  char = {x = 64, y = 64, z = 0, l = 24, w = 24, h = 24, xV = 0, yV = 0, zV = 0, jump = false}
end

player.update = function(dt)
  --input
  if love.keyboard.isDown("w") then
    char.yV = char.yV - dt * 60
  end
  if love.keyboard.isDown("s") then
    char.yV = char.yV + dt * 60
  end
  if love.keyboard.isDown("a") then
    char.xV = char.xV - dt * 60
  end
  if love.keyboard.isDown("d") then
    char.xV = char.xV + dt * 60
  end
  if love.keyboard.isDown("space") and not char.jump then
    char.zV = char.zV - dt * 60 * 5
    char.jump = true
  end
  --gravity
  if char.zV < 10 then
    char.zV = char.zV + dt * 60 * 0.2
  elseif char.zV > 10 then
    char.zV = 10
  end

  -- collision
  collision.grid(char)

  -- movemwnt and friction
  char.x = char.x + char.xV
  char.xV = char.xV * 0.8

  char.y = char.y + char.yV
  char.yV = char.yV * 0.8

  char.z = char.z + char.zV
end

player.queue = function()
  queue[#queue + 1] = {img = char_img, x = char.x, y = char.y, z = char.z+char.l-char.h, w = char.w, h = char.h, l = char.l}
end

player.keypressed = function(key)
end

return player
