local endmenu = {}

local scores = {}
local player_place = 0
local place_txt = {
  "st",
  "nd",
  "rd",
  "th"
}
local podium = {}
local endmenu_imgs = {}

endmenu.load = function()
  podium = {x = (screen.w-256)/2, y = (screen.h+256)/2-64, w = 84, border = 2}

  endmenu_imgs.header = gui.new_img(4, 256, 64)
  endmenu_imgs.footer = gui.new_img(4, 256, 32)
end

endmenu.start = function()
  scores = {}
  for k, v in pairs(players) do
    scores[#scores+1] = {k = k, score = v.score}
  end
  table.sort(scores, function(a, b) return a.score > b.score end)
  for i, v in ipairs(scores) do
    if v.k == id then
      player_place = i
    end
  end

  if #scores < 3 then
    podium.x = (screen.w-(podium.w+podium.border)*#scores)/2
  else
    podium.x = (screen.w-256)/2
  end

  gui.clear()
  local buttons = sidebar.new({{txt = "Done", func = wipe.start, args = {mainmenu.start}}})
  gui.add(1, buttons)
end

endmenu.update = function(dt)
end

endmenu.draw = function()
  for i = 1, 3 do
    local v = scores[i]
    if v then
      local player = players[v.k]
      love.graphics.draw(player.canvas, podium.x+(podium.w+podium.border)*(i-1)+(podium.w-player.l)/2, podium.y-player.w-player.h-38, 0, 1, 1, 32, 24)
      love.graphics.printf(player.name, podium.x+(podium.w+podium.border)*(i-1), podium.y-16, podium.w, "center")
      love.graphics.printf(endmenu.num_string(i), podium.x+(podium.w+podium.border)*(i-1), podium.y, podium.w, "center")
    end
  end
  love.graphics.draw(endmenu_imgs.footer, (screen.w-256)/2, podium.y+32)
  love.graphics.draw(endmenu_imgs.header, (screen.w-256)/2, (screen.h-256)/2)
  love.graphics.printf("Your Place: "..endmenu.num_string(player_place), (screen.w-256)/2+2, podium.y+44, 252, "center")
  love.graphics.printf(tostring(players[scores[1].k].name).." Wins!", (screen.w-256)/2+2, (screen.h-256)/2+28, 252, "center")
end

endmenu.num_string = function(num)
  if num < 4 then
    return tostring(num)..place_txt[num]
  else
    return tostring(num)..place_txt[4]
  end
end

return endmenu
