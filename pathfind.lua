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
  local x_min, x_max = math.floor(math.min(n1.x, n2.x)), math.ceil(math.max(n1.x, n2.x))
  local y_min, y_max = math.floor(math.min(n1.y, n2.y)), math.ceil(math.max(n1.y, n2.y))
  local z_min, z_max = math.floor(math.min(n1.z, n2.z)), math.ceil(math.max(n1.z, n2.z))

  for y = y_min, y_max do
    for x = x_min, x_max do
      if (y ~= n1.y or x ~= n1.x) and slope == (n2.y-y)/(n2.x-x) then -- check if nearer node with same slope exists (no overlap)
        return false
      end
    end
  end

  if z_min == z_max then -- straight walk
    local walk = true
    for x= x_min, x_max do
      for y = y_min, y_max do
        if pathfind.is_block(x, y, z_min) then
          walk = false
        end
      end
    end
    if walk then -- if walk is possible, return edge
      return {dist = pathfind.dist(n1, n2), action = "walk"}
    end
  end
  if math.floor(n1.z) - math.floor(n2.z) <= 1 then -- jump or fall
    local dist_sq = (n2.x-n1.x)*(n2.x-n1.x)+(n2.y-n1.y)*(n2.y-n1.y)
    local h_sq = (n2.z-n1.z)*math.abs(n2.z-n1.z)
    local action = ""
    if dist_sq <= h_sq then -- if in fall range
      action = "fall"
    elseif dist_sq <= 10+h_sq then -- if jump is necessary
      action = "jump"
      if math.floor(n1.z) < math.floor(n2.z) then -- make sure airspace is checked if action is jumping fall
        z_min = z_min - 1
      end
    else -- if not in range
      return false
    end
    for z = z_min, z_max do
      for y = y_min, y_max do
        for x = x_min, x_max do
          if z == z_min or (z <= math.floor(n1.z) and pathfind.check_tile(x, y, n2, n1)) or (z > math.floor(n1.z) and pathfind.check_tile(x, y, n1, n2)) then -- in bounds
            if pathfind.blocked(x, y, z) then
              return false
            end
          end
        end
      end
    end
    return {dist = pathfind.dist(n1, n2), action = action}
  end
  return false
end

pathfind.check_tile = function(x, y, n1, n2)
  local x_sign = pathfind.sign(n2.x-n1.x)
  local y_sign = pathfind.sign(n2.y-n1.y)
  return ((x*x_sign > math.floor(n1.x)*x_sign or math.floor(n1.x) == math.floor(n2.x)) and (y*y_sign > math.floor(n1.y)*y_sign or math.floor(n1.y) == math.floor(n2.y)))
end

pathfind.sign = function(num)
  if num > 0 then return 1 elseif num < 0 then return -1 else return 0 end
end

pathfind.astar = function(p1, p2)
  local start_pos = {x = p1.x/tile_size+1, y = p1.y/tile_size+1, z = p1.z/tile_size+1}
  local goal_pos = {x = p2.x/tile_size+1, y = p2.y/tile_size+1, z = p2.z/tile_size+1}


  local frontier = {}
  local node_info = {came_from = {[0] = false}, cost = {[0] = 0}, scores = {}}

  -- find options from initial "node"
  local path = pathfind.check_end(0, goal_pos, start_pos) -- if path can go from start to goal
  if path then return path end
  for next_num, node in ipairs(nodes) do
    local edge = pathfind.legal_edge(start_pos, node)
    pathfind.score_node(next_num, edge, frontier, node_info, 0, goal_pos)
  end
  while #frontier > 0 do
    local current = frontier[1]
    table.remove(frontier, 1)
    local path = pathfind.check_end(current, goal_pos, start_pos, node_info)
    if path then return path end
    for next_num, edge in ipairs(nodes[current].edges) do
      pathfind.score_node(next_num, edge, frontier, node_info, current, goal_pos)
    end
  end
  return {}
end

pathfind.check_end = function(current, goal_pos, start_pos, node_info)
  if current > 0 then
    if pathfind.legal_edge(nodes[current], goal_pos) then
      local path = {start_pos, goal_pos}
      while node_info.came_from[current] do
        table.insert(path, 2, nodes[current])
        current = node_info.came_from[current]
      end
      return path
    end
  elseif pathfind.legal_edge(start_pos, goal_pos) then
    return {start_pos, goal_pos}
  end
end

pathfind.score_node = function(next_num, edge, frontier, node_info, current, goal_pos)
  if edge and next_num ~= current then
    local new_cost = node_info.cost[current] + edge.dist
    if not node_info.cost[next_num] or new_cost < node_info.cost[next_num] then
      node_info.cost[next_num] = new_cost
      node_info.scores[next_num] = new_cost + pathfind.heuristic(goal_pos, nodes[next_num])
      node_info.came_from[next_num] = current
      local placed = false
      for i, v in ipairs(frontier) do -- put item in proper place
        if node_info.scores[v] > node_info.scores[next_num] then
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

pathfind.dist = function(n1, n2)
  return math.sqrt((n2.x-n1.x)*(n2.x-n1.x)+(n2.y-n1.y)*(n2.y-n1.y)+(n2.z-n1.z)*(n2.z-n1.z))
end

pathfind.heuristic = function(n1, n2)
  return pathfind.dist(n1, n2)
end

return pathfind
