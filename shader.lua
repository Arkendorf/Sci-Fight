local shader = {}

shader.shadow = love.graphics.newShader[[
    extern Image mask;
    extern vec2 mask_size;
    extern number z;
    vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
      if(screen_coords.x <= mask_size.x && screen_coords.y <= mask_size.y){
        vec4 pixel = Texel(texture, texture_coords);
        vec4 mask_pixel = Texel(mask, vec2(screen_coords.x/mask_size.x, screen_coords.y/mask_size.y));
        if((mask_pixel.r < 1.014 - 0.010*z) && (mask_pixel.r >= 1.005 - 0.010*z)){
          return pixel*color;
        }
      }
      return vec4(0.0, 0.0, 0.0, 0.0);
    }
  ]]

  shader.layer = love.graphics.newShader[[
      extern Image mask;
      extern vec2 mask_size;
      extern vec3 coords;
      extern vec4 xray_color;
      vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
        vec4 pixel = Texel(texture, texture_coords);
        if(screen_coords.x <= mask_size.x && screen_coords.y <= mask_size.y){
          vec4 mask_pixel = Texel(mask, vec2(screen_coords.x/mask_size.x, screen_coords.y/mask_size.y));
          if((mask_pixel.z > 1.014-0.010*coords.z) && (mask_pixel.y < 1.014-0.010*coords.y)){
            return xray_color;
          }
        }
        return pixel*color;
      }
    ]]

shader.trans = love.graphics.newShader[[
    vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
      vec4 pixel = Texel(texture, texture_coords);
      if(pixel.a > 0.5){
        number trans = pixel.r;
        vec4 new_pixel = vec4(color.r, color.g, color.b, trans);
        return new_pixel;
      }
      return vec4(0.0, 0.0, 0.0, 0.0);
    }
  ]]

return shader
