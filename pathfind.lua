local pathfind = {}

local nodes = {}

pathfind.start = function()
  nodes = pathfind.make_nodes()
end

pathfind.draw = function()
  for i, v in ipairs(nodes) do
    love.graphics.setColor(1-(v.z-1)*.1, 0, 0)
    love.graphics.print(tostring(i), (v.x-1)*tile_size+tile_size/2-5, (v.y+v.z-2)*tile_size+tile_size/2-5)
    for j, w in ipairs(v.edges) do
      if w then
        love.graphics.line((v.x-1)*tile_size+tile_size/2, (v.y+v.z-2)*tile_size+tile_size/2, (nodes[j].x-1)*tile_size+tile_size/2, (nodes[j].y+nodes[j].z-2)*tile_size+tile_size/2)
      end
    end
  end

  local path = pathfind.astar(players[0], {x = 0, y = 9*32, z = 2*32})
  for i, v in ipairs(path) do
    love.graphics.setColor(1-(v.z-1)*.1, 1-(v.z-1)*.1, 0)
    if i < #path then
      love.graphics.line((v.x-1)*tile_size+tile_size/2, (v.y+v.z-2)*tile_size+tile_size/2, (path[i+1].x-1)*tile_size+tile_size/2, (path[i+1].y+path[i+1].z-2)*tile_size+tile_size/2)
    end
  end
  love.graphics.setColor(1, 1, 1)
  love.graphics.print(#path)
end

pathfind.make_nodes = function()
  local nodes = {}

  for z, _ in ipairs(grid) do
    for y, _ in ipairs(grid[z]) do
      for x, tile in ipairs(grid[z][y]) do
        if tiles[tile].solid and not tiles[grid[z][y][x]].damage and not pathfind.blocked(x, y, z) then -- make sure tile is solid and has space above
          if pathfind.is_node(x, y, z) then -- check if tile should be node
            nodes[#nodes+1] = {x = x, y = y, z = z}
          end
        end
      end
    end
  end

  for i, v in ipairs(nodes) do
    pathfind.make_edges(v, nodes)
  end

  return nodes
end

pathfind.make_edges = function(n, nodes)
  n.edges = {}
  for i, v in ipairs(nodes) do
    n.edges[i] = pathfind.legal_edge(n, v)
  end
end

pathfind.is_node = function(x, y, z)
  for y_offset = -1, 1 do
    for x_offset = -1, 1 do
      if y_offset ~= 0 or x_offset ~= 0 then
        if pathfind.is_block(x+x_offset, y+y_offset, z) then
          return true
        end
      end
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
    for y = math.floor(math.min(n1.y, n2.y)), math.ceil(math.max(n1.y, n2.y)) do
      for x = math.floor(math.min(n1.x, n2.x)), math.ceil(math.max(n1.x, n2.x)) do
        if pathfind.blocked(x, y, math.floor(n1.z)) or tiles[grid[math.floor(n1.z)][y][x]].damage or not tiles[grid[math.floor(n1.z)][y][x]].solid then -- no obstacles on diagonal
          return false
        end
      end
    end
  elseif n1.z-1 == n2.z then -- requires jump
    if (n2.x-n1.x)*(n2.x-n1.x)+(n2.y-n1.y)*(n2.y-n1.y) > 9 then -- jump range
      return false
    end
    for y = math.floor(math.min(n1.y, n2.y)), math.ceil(math.max(n1.y, n2.y)) do
      for x = math.floor(math.min(n1.x, n2.x)), math.ceil(math.max(n1.x, n2.x)) do
        if pathfind.blocked(x, y, math.floor(n2.z)) or tiles[grid[math.floor(n2.z)][y][x]].damage then -- make sure airspace is clear
          return false
        end
      end
    end
  elseif n1.z < n2.z then -- fall
    if (n2.x-n1.x)*(n2.x-n1.x)+(n2.y-n1.y)*(n2.y-n1.y) > (n1.z-n2.z)*(n1.z-n2.z) then -- fall range
      return false
    end
    for z = math.floor(n1.z), math.ceil(n2.z) do
      for y = math.floor(math.min(n1.y, n2.y))+pathfind.sign(n2.y-n1.y), math.ceil(math.max(n1.y, n2.y)) do
        for x = math.floor(math.min(n1.x, n2.x))+pathfind.sign(n2.x-n1.x), math.ceil(math.max(n1.x, n2.x)) do
          if pathfind.blocked(x, y, z) then -- make sure airspace is clear
            return false
          end
        end
      end
    end
  else
    return false
  end
  return pathfind.dist(n1, n2)
end

pathfind.sign = function(num)
  if num > 0 then return 1 elseif num < 0 then return -1 else return 0 end
end

pathfind.astar = function(p1, p2)
  -- add start and end to node list
  local astar_nodes = {unpack(nodes)}
  local start_num = #astar_nodes + 1
  local goal_num = #astar_nodes + 2
  astar_nodes[start_num] = {x = math.floor(p1.x/tile_size+.5)+1, y = math.floor(p1.y/tile_size+.5)+1, z = math.ceil(p1.z/tile_size)+1}
  pathfind.make_edges(astar_nodes[start_num], nodes)
  astar_nodes[goal_num] = {x = math.floor(p2.x/tile_size+.5)+1, y = math.floor(p2.y/tile_size+.5)+1, z = math.ceil(p2.z/tile_size)+1}
  for i = 1, #nodes do
    astar_nodes[i].edges[start_num] = false
    -- astar_nodes[i].edges[goal_num] = pathfind.legal_edge(astar_nodes[i], astar_nodes[goal_num])
  end

  local frontier = {start_num}
  local came_from = {}
  local cost_so_far = {[start_num] = 0}
  local scores = {[start_num] = 0}

  while #frontier > 0 do
    local current = frontier[1]
    table.remove(frontier, 1)
    if current == goal_num then
      break
    end
    for next_num, dist in ipairs(astar_nodes[current].edges) do
      if dist then
        local new_cost = cost_so_far[current] + dist
        if not cost_so_far[next_num] or new_cost < cost_so_far[next_num] then
          cost_so_far[next_num] = new_cost
          scores[next_num] = new_cost + pathfind.heuristic(astar_nodes[goal_num], astar_nodes[next_num])
          came_from[next_num] = current
          local placed = false
          for i, v in ipairs(frontier) do -- put item in proper place
            if scores[v] > scores[next_num] then
              table.insert(frontier, i, next_num)
              placed = true
              break
            end
          end
          if not placed then -- if next has highest cost
            table.insert(frontier, next_num)
          end
        end
      end
    end
  end
  if came_from[goal_num] then -- path is possible
    local path = {}
    local current = goal_num
    while current ~= start_num do
      table.insert(path, 1, astar_nodes[current])
      current = came_from[current]
    end
    table.insert(path, 1, astar_nodes[start_num])
    return path
  else
    return {}
  end
end

pathfind.dist = function(n1, n2)
  return math.sqrt((n2.x-n1.x)*(n2.x-n1.x)+(n2.y-n1.y)*(n2.y-n1.y)+(n2.z-n1.z)*(n2.z-n1.z))
end

pathfind.heuristic = function(n1, n2)
  return pathfind.dist(n1, n2)
end

return pathfind
