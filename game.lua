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
  -- update masks (e.g. layer and shadow)
  map.update_masks()
end

game.draw = function()
  local offset = {math.ceil(screen.w/2-players[id].x-players[id].l/2), math.ceil(screen.h/2-players[id].y-players[id].z-players[id].w)}
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
  love.graphics.circle("line", players[id].target.x, players[id].target.y+players[id].target.z, 12, 24)

  love.graphics.pop()
  -- draw hud
  hud.draw()
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
    shader.shadow:send("z", z_offset+1)
    love.graphics.setColor(0.2, 0.2, 0.3, 0.5-diffuse/2)
    love.graphics.circle("fill", math.floor(v.x+v.l/2), math.floor(v.y+v.w/2+z_offset*tile_size), r*(1+diffuse), 24)
  end
  love.graphics.setColor(1, 1, 1)
  love.graphics.setShader()
end

game.draw_shadows = function()
  table.sort(queue, function(a, b) return a.z < b.z end)
  for i, v in ipairs(queue) do -- draw object shadows
    if v.shadow then
      game.shadow(v)
    end
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
    graphics.draw_border(x, y, z, tile)
  end
end

game.draw_tile_shadows = function(x, y, z, tile)
  if tile > 0 then
    if not map.floor_block(x, y, z) then
      if z > 1 then
        if map.column(x, y, z-1) or map.column(x+1, y+1, z-1) then
          love.graphics.draw(tileshadow_img, tileshadow_quad[3], (x-1)*tile_size, (y+z-2)*tile_size)
        elseif map.column(x+1, y, z-1) then
          love.graphics.draw(tileshadow_img, tileshadow_quad[1], (x-1)*tile_size, (y+z-2)*tile_size)
        elseif map.column(x, y+1, z-1) then
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
  if tile > 0 then
    love.graphics.setColor(1.01 - 0.01*z, 0, 0)
    if not map.floor_block(x, y, z) then
      love.graphics.rectangle("fill", (x-1)*tile_size, (y+z-2)*tile_size, tile_size, tile_size)
    end
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

game.draw_props = function(shade, mask, asd)
  if mask then
    shader[shade]:send("mask", mask)
    shader[shade]:send("mask_size", {mask:getWidth(), mask:getHeight()})
    shader[shade]:send("tile_size", tile_size)
    shader[shade]:send("offset", {0, 0})
  end
  for i, v in ipairs(props) do
    if mask then
      shader[shade]:send("w", prop_info[v.type].w)
      shader[shade]:send("coords", {0, v.y+prop_info[v.type].w, v.z})
    end
    love.graphics.setShader(shader[shade])
    love.graphics.draw(prop_img[prop_info[v.type].img], (v.x-1)*tile_size, (v.y+v.z-2)*tile_size)
    love.graphics.setShader()
  end
end

game.draw_prop_border = function(x, y)
  shader.prop_shadow:send("mask", layer_mask)
  shader.prop_shadow:send("mask_size", {x, y})
  shader.prop_shadow:send("offset", {0, 0})
  for i, v in ipairs(props) do
    shader.prop_shadow:send("coords", {0, v.y+prop_info[v.type].h, v.z})
    love.graphics.setShader(shader.prop_shadow)
    for i = -2, 2 do
      for j = math.abs(i)-2, -math.abs(i)+2 do
        love.graphics.draw(prop_img[prop_info[v.type].img], (v.x-1)*tile_size+j, (v.y+v.z-2)*tile_size+i)
      end
    end
    love.graphics.setShader()
  end
end

return game
