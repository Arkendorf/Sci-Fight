local particle = {}

particle.load = function()
  particles = {}

  particle_info = {}
  particle_info.fire = {t = 0.4, slow = 1, speed = 24, img = "fire"}
  particle_info.radiant = {t = 0.6, slow = 1, speed = 24, img = "radiant"}
  particle_info.push = {t = 0.3, slow = 0.9, speed = 24, img = "push", angle = true}
  particle_info.dust = {t = 0.8, slow = 0.9, speed = 24, img = "dust"}
  particle_info.flare = {t = 0.2, slow = 1, speed = 12, img = "flare"}
  particle_info.spark = {t = 0.3, slow = 1, speed = 0, img = "spark"}

end

particle.update = function(dt)
  for k, v in pairs(particles) do
    -- update position
    v.x = v.x + v.xV * dt * 60
    v.y = v.y + v.yV * dt * 60
    v.z = v.z + v.zV * dt * 60

    -- update velocity
    v.xV = v.xV * particle_info[v.type].slow
    v.yV = v.yV * particle_info[v.type].slow
    v.zV = v.zV * particle_info[v.type].slow

    v.frame = v.frame + dt * particle_info[v.type].speed
    if v.frame >  #particle_quad[particle_info[v.type].img]+1 then
      v.frame = 1
    end

    -- delete
    v.t = v.t + dt
    if v.t > particle_info[v.type].t then
      particles[k] = nil
    end
  end
end

particle.queue = function()
  for k, v in pairs(particles) do
    queue[#queue + 1] = {img = particle_img[particle_info[v.type].img], quad = particle_quad[particle_info[v.type].img][math.floor(v.frame)], x = v.x, y = v.y, z = v.z, w = 0, h = 0, l = 0, ox = 16, oy = 16, angle = v.angle, color = v.color}
  end
end

particle.new = function(x, y, z, xV, yV, zV, type, player, color)
  if player then
    xV = xV + player.xV
    yV = yV + player.yV
    zV = zV + player.zV
  end
  local angle = 0
  if particle_info[type].angle then
    angle = math.atan2(yV+zV, xV)
  end
  local c = {1, 1, 1}
  if color then
    c = color
  end
  particles[#particles+1] = {x = x, y = y, z = z, xV = xV, yV = yV, zV = zV, type = type, t = 0, frame = 1, angle = angle, color = c}
end

return particle
