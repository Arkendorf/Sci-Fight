local pathfind = {}

local nodes = {}

pathfind.start = function()
  nodes = pathfind.make_nodes()
end

pathfind.draw = function()
  for i, v in ipairs(nodes) do
    love.graphics.setColor(1-(v.z-1)*.1, 0, 0)
    love.graphics.circle("fill", (v.x-1)*tile_size+tile_size/2, (v.y+v.z-2)*tile_size+tile_size/2, 4, 16)
    for j, w in ipairs(v.edges) do
      if w then
        love.graphics.line((v.x-1)*tile_size+tile_size/2, (v.y+v.z-2)*tile_size+tile_size/2, (nodes[j].x-1)*tile_size+tile_size/2, (nodes[j].y+nodes[j].z-2)*tile_size+tile_size/2)
      end
    end
  end
  love.graphics.setColor(1, 1, 1)
end

pathfind.make_nodes = function()
  local nodes = {}

  for z, _ in ipairs(grid) do
    for y, _ in ipairs(grid[z]) do
      for x, tile in ipairs(grid[z][y]) do
        if tiles[tile].solid and not tiles[grid[z][y][x]].damage and not pathfind.blocked(x, y, z) then -- make sure tile is solid and has space above
          if pathfind.is_corner(x, y, z) or pathfind.is_side(x, y, z) then -- check if tile should be node
            nodes[#nodes+1] = {x = x, y = y, z = z}
          end
        end
      end
    end
  end

  for i, v in ipairs(nodes) do
    v.edges = {}
    for j, w in ipairs(nodes) do
      v.edges[j] = pathfind.legal_edge(v, w)
    end
  end

  return nodes
end

pathfind.is_corner = function(x, y, z)
  for y_offset = -1, 1, 2 do
    for x_offset = -1, 1, 2 do
      if pathfind.is_block(x+x_offset, y+y_offset, z) and not pathfind.is_block(x, y+y_offset, z) and not pathfind.is_block(x+x_offset, y, z) then
        return true
      end
    end
  end
  return false
end

pathfind.is_side = function(x, y, z)
  if pathfind.is_block(x-1, y, z) or pathfind.is_block(x+1, y, z) then
    if pathfind.is_block(x, y-1, z) or pathfind.is_block(x, y+1, z) then
      return true
    end
  end
  return false
end

pathfind.is_block = function(x, y, z)
  if map.in_bounds(x, y, z) then
    return not tiles[grid[z][y][x]].solid or tiles[grid[z][y][x]].damage or pathfind.blocked(x, y, z)
  else
    return true
  end
end

pathfind.blocked = function(x, y, z)
  if map.in_bounds(x, y, z-1) then
    if tiles[grid[z-1][y][x]].solid then
      return true
    else
      for i, v in ipairs(props) do
        if collision.cube_and_cube({x = v.x, y = v.y, z = v.z, l = prop_info[v.type].l, w = prop_info[v.type].w, h = prop_info[v.type].h}, {x = x, y = y, z = z-1, l = 1, w = 1, h = 1}) then
          return true
        end
      end
    end
  end
  return false
end

pathfind.legal_edge = function(n1, n2)
  if n1.z == n2.z then -- flat walk
    for y = math.min(n1.y, n2.y), math.max(n1.y, n2.y) do
      for x = math.min(n1.x, n2.x), math.max(n1.x, n2.x) do
        if pathfind.blocked(x, y, n1.z) or tiles[grid[n1.z][y][x]].damage or not tiles[grid[n1.z][y][x]].solid then -- no obstacles on diagonal
          return false
        end
      end
    end
  elseif n1.z-1 == n2.z then -- requires jump
    if (n2.x-n1.x)*(n2.x-n1.x)+(n2.y-n1.y)*(n2.y-n1.y) <= 9 then -- jump range
      for y = math.min(n1.y, n2.y), math.max(n1.y, n2.y) do
        for x = math.min(n1.x, n2.x), math.max(n1.x, n2.x) do
          if pathfind.blocked(x, y, n2.z) or tiles[grid[n2.z][y][x]].damage then -- make sure airspace is clear
            return false
          end
        end
      end
    else
      return false
    end
  elseif n1.z < n2.z then -- fall
    if (n2.x-n1.x)*(n2.x-n1.x)+(n2.y-n1.y)*(n2.y-n1.y) <= (n1.z-n2.z)*(n1.z-n2.z) then -- fall range
      for z = n1.z, n2.z do
        for y = math.min(n1.y, n2.y)+pathfind.sign(n2.y-n1.y), math.max(n1.y, n2.y) do
          for x = math.min(n1.x, n2.x)+pathfind.sign(n2.x-n1.x), math.max(n1.x, n2.x) do
            if pathfind.blocked(x, y, z) then -- make sure airspace is clear
              return false
            end
          end
        end
      end
    else
      return false
    end
  else
    return false
  end
  return true
end

pathfind.sign = function(num)
  if num > 0 then
    return 1
  elseif num < 0 then
    return -1
  else
    return 0
  end
end

return pathfind
