local abilities = {}

abilities[1] = {
press_func = function(player, index, target)
  local i = bullet.new(players[index], target, index)
  server:sendToAll("bullet", {info = bullets[i], i = i})
  return true
end,
update_func = nil;
delay = 0.2
}

return abilities
