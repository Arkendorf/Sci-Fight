map = require "map"
graphics = require "graphics"
char = require "char"
collision = require "collision"
shader = require "shader"
clientgame = require "clientgame"
servergame = require "servergame"
bullet = require "bullet"
particle = require "particle"
hud = require "hud"

local game = {}

game.screenshake = 0

game.load = function()
  map.load()
  char.load()
  bullet.load()
  particle.load()
  clientgame.load()
  servergame.load()
  hud.load()

  queue = {}

  ability_keys = {{"button", 1}, {"button", 2}, {"key", "lshift"}, {"key", "lctrl"}, {"key", "lalt"}}
end

game.start = function()
  gui.clear()
  bullets = {}
  particles = {}
  for k, v in pairs(players) do
    v.canvas = love.graphics.newCanvas(88, 88)
  end
end

game.update = function(dt)
  -- normal updates
  char.update(dt)
  bullet.update(dt)
  particle.update(dt)
  hud.update(dt)
  -- create drawing queue
  queue = {}
  char.queue()
  bullet.queue()
  particle.queue()

  if game.screenshake > 0 then
    game.screenshake = game.screenshake - dt
  end
end

game.draw = function()
  local offset = {math.ceil(screen.w/2-players[id].x-players[id].l/2), math.ceil(screen.h/2-players[id].y-players[id].z-players[id].w)}
  if game.screenshake > 0 then
    offset[1] = offset[1] + math.random(-2, 2)
    offset[2] = offset[2] + math.random(-2, 2)
  end
  shader.shadow:send("offset", offset)
  shader.layer:send("offset", offset)
  love.graphics.push()
  love.graphics.translate(offset[1], offset[2])
  -- draw map
  map.draw()
  -- draw shadows
  game.draw_shadows()
  -- draw objects
  game.draw_queue()
  -- target
  love.graphics.draw(target_img, target_quad[math.floor(players[id].target.frame)], players[id].target.x, players[id].target.y+players[id].target.z, 0, 1, 1, 16, 16)
  -- love.graphics.draw(layer_mask)

  love.graphics.pop()
  -- draw hud
  hud.draw()
  love.graphics.print(tostring(players[0].last_collide), 20, 0)
end

game.mousepressed = function(x, y, button)
end

game.abilities = function(mode, button, func)
  for i, v in ipairs(ability_keys) do
    if v[1] == mode and button == v[2] then
      func(i)
    end
  end
end

game.update_abilities = function(func, k, dt)
  for i, v in ipairs(players[k].abilities) do
    if v.active then
      func(i, k, dt)
    end
  end
end

game.mouse_pos = function()
  return players[id].x+players[id].l/2+(love.mouse.getX())/screen.scale-screen.w/2, players[id].y+players[id].z+players[id].w+(love.mouse.getY())/screen.scale-screen.h/2
end

game.draw_queue = function()
  table.sort(queue, function(a, b) return a.y+a.w < b.y+b.w end)

  for i, v in ipairs(queue) do
    love.graphics.setShader(shader.layer)
    shader.layer:send("xray_color", {.2, .2, .3, 1})
    shader.layer:send("coords", {0, 1+math.floor((v.y)/tile_size), 1+math.ceil((v.z+v.h)/tile_size)})
    graphics.draw(v)
    love.graphics.setShader()
  end
end

game.shadow = function(v)
  love.graphics.setShader(shader.shadow)
  for z_offset = 1+math.floor((v.z+v.h*0.5)/tile_size), #grid-1 do
    local diffuse = (z_offset*tile_size-(v.z+v.h))/tile_size/3
    local r = v.l/2
    if v.r then
      r = v.r
    end
    love.graphics.setColor(0.2, 0.2, 0.3, 0.5-diffuse/2)
    shader.shadow:send("z", z_offset+1)
    if v.shadow then
      shader.shadow:send("reflect", false)
      love.graphics.circle("fill", math.floor(v.x+v.l/2), math.floor(v.y+v.w/2+z_offset*tile_size), r*(1+diffuse), 24)
    end
    shader.shadow:send("reflect", true)
    local reflect = {img = v.img, quad = v.quad, x = v.x, y = v.y, z= z_offset*tile_size, angle = v.angle, ox = v.ox, oy = v.oy, sx = v.sx, sy = v.sy}
    if reflect.sy then
      reflect.sy = reflect.sy*-1
    else
      reflect.sy = -1
    end
    if reflect.oy then
      reflect.y = reflect.y + v.img:getHeight()-reflect.oy*2+8
    else
      reflect.y = reflect.y + v.img:getHeight()
    end
    graphics.draw(reflect)
  end
  love.graphics.setColor(1, 1, 1)
  love.graphics.setShader()
end

game.draw_shadows = function()
  table.sort(queue, function(a, b) return a.z < b.z end)
  for i, v in ipairs(queue) do -- draw object shadows
    game.shadow(v)
  end
end

-- map functions
game.draw_tiles = function(x, y, z, tile)
  if tile > 0 then
    -- floor
    if not map.floor_block(x, y, z) then
      graphics.draw_floor(x, y, z, tile)
    end

    -- wall
    if not map.wall_block(x , y, z) then
      graphics.draw_wall(x, y, z, tile)
    end
  end
  love.graphics.setColor(1, 1, 1)
end

game.draw_borders = function(x, y, z, tile)
  if tile > 0 and not map.floor_block(x, y, z) then
    shader.shadow:send("z", z)
    love.graphics.setShader(shader.shadow)
    graphics.draw_border(x, y, z, tile)
    love.graphics.setShader()
  end
end

game.draw_tile_shadows = function(x, y, z, tile)
  if tile > 0 then
    if not map.floor_block(x, y, z) then
      if z > 1 then
        local x_axis = map.column(x+1, y, z-1)
        local y_axis = map.column(x, y+1, z-1)
        if map.column(x, y, z-1) or map.column(x+1, y+1, z-1) or (x_axis and y_axis) then
          love.graphics.draw(tileshadow_img, tileshadow_quad[3], (x-1)*tile_size, (y+z-2)*tile_size)
        elseif x_axis then
          love.graphics.draw(tileshadow_img, tileshadow_quad[1], (x-1)*tile_size, (y+z-2)*tile_size)
        elseif y_axis then
          love.graphics.draw(tileshadow_img, tileshadow_quad[2], (x-1)*tile_size, (y+z-2)*tile_size)
        end
      end
    end
  end
end

game.draw_layer_mask = function(x, y, z, tile)
  if tile > 0 then
    love.graphics.setColor(0, 1.01 - 0.01*y, 1.01 - 0.01*z)
    if not map.floor_block(x, y, z) then
      love.graphics.rectangle("fill", (x-1)*tile_size, (y+z-2)*tile_size, tile_size, tile_size)
    end
    if not map.wall_block(x , y, z) then
      love.graphics.rectangle("fill", (x-1)*tile_size, (y+z-1)*tile_size, tile_size, tile_size)
    end
  end
end

game.draw_shadow_mask = function(x, y, z, tile)
  if tile > 0 and not map.floor_block(x, y, z) then
    if tiles[tile].reflect then
      love.graphics.setColor(1.01 - 0.01*z, 1, 0)
    else
      love.graphics.setColor(1.01 - 0.01*z, 0, 0)
    end
    love.graphics.rectangle("fill", (x-1)*tile_size, (y+z-2)*tile_size, tile_size, tile_size)
  end
end

game.target_norm = function(p, t, range)
  if not range then
    range = 1
  end
  local x, y, z = t.x-p.x-p.l/2, t.y-p.y-p.w/2, t.z-p.z-p.h/2
  local denom = math.sqrt(x*x+y*y+z*z)
  return {x = x/denom*range, y = y/denom*range, z = z/denom*range}
end

game.angle_norm = function(norm, angle)
  local c_angle = math.atan2(norm.y+norm.z, norm.x)
  local c_angle = c_angle + angle
  return {x = math.cos(c_angle), y = math.sin(c_angle), z = norm.z}
end

game.target_pos = function(p, t, range)
  if not range then
    range = 1
  end
  return {x = p.x+p.l/2+t.x*range, y= p.y+p.w/2+t.y*range, z = p.z+p.h/2+t.z*range}
end

game.draw_props = function(shade, mask, shadow)
  if mask then
    shader[shade]:send("mask", mask)
    shader[shade]:send("mask_size", {mask:getWidth(), mask:getHeight()})
    shader[shade]:send("tile_size", tile_size)
    shader[shade]:send("offset", {0, 0})
  end
  for i, v in ipairs(props) do
    if mask then
      shader[shade]:send("w", prop_info[v.type].w)
      shader[shade]:send("coords", {v.x, v.y, v.z})
    end
    if shadow then
      shader[shade]:send("shadow", prop_info[v.type].shadow or false)
    end
    love.graphics.setShader(shader[shade])
    love.graphics.draw(prop_img[prop_info[v.type].img], (v.x-1)*tile_size, (v.y+v.z-2)*tile_size)
    love.graphics.setShader()
  end
end

game.draw_prop_border = function(x, y)
  shader.prop_border:send("mask", layer_mask)
  shader.prop_border:send("mask_size", {x, y})
  shader.prop_border:send("offset", {0, 0})
  for i, v in ipairs(props) do
    if prop_info[v.type].shadow then
      shader.prop_border:send("coords", {v.x, v.y, v.z})
      love.graphics.setShader(shader.prop_border)
      for i = -2, 2 do
        for j = math.abs(i)-2, -math.abs(i)+2 do
          love.graphics.draw(prop_img[prop_info[v.type].img], (v.x-1)*tile_size+j, (v.y+v.z-2)*tile_size+i)
        end
      end
      love.graphics.setShader()
    end
  end
end

return game
