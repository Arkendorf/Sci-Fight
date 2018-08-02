local shader = {}

shader.shadow = love.graphics.newShader[[
    extern Image mask;
    extern vec2 mask_size;
    extern number z;
    extern vec2 offset;
    vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
      vec2 adjusted_coords = vec2(screen_coords.x-offset.x, screen_coords.y-offset.y);
      if(adjusted_coords.x >= 0.0 && adjusted_coords.x <= mask_size.x && adjusted_coords.y >= 0.0 && adjusted_coords.y <= mask_size.y){
        vec4 pixel = Texel(texture, texture_coords);
        vec4 mask_pixel = Texel(mask, vec2(adjusted_coords.x/mask_size.x, adjusted_coords.y/mask_size.y));
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
    extern vec2 offset;
    extern bool flash;
    vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
      vec4 pixel = Texel(texture, texture_coords);
      if(pixel.a > 0){
        vec2 adjusted_coords = vec2(screen_coords.x-offset.x, screen_coords.y-offset.y);
        if(adjusted_coords.x >= 0.0 && adjusted_coords.x <= mask_size.x && adjusted_coords.y >= 0.0 && adjusted_coords.y <= mask_size.y){
          vec4 mask_pixel = Texel(mask, vec2(adjusted_coords.x/mask_size.x, adjusted_coords.y/mask_size.y));
          if((mask_pixel.z > 1.014-0.010*coords.z) && (mask_pixel.y < 1.014-0.010*coords.y)){
            return xray_color;
          }
        }
      }
      if (flash){
        return color;
      }
      else{
        return pixel*color;
      }
    }
  ]]

shader.color = love.graphics.newShader[[
    vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
      vec4 pixel = Texel(texture, texture_coords);
      if(pixel.a > 0){
        return color;
      }
      return vec4(0, 0, 0, 0);
    }
  ]]

shader.greyscale = love.graphics.newShader[[
  vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
    vec4 pixel = Texel(texture, texture_coords);
    number avg = (pixel.r+pixel.g+pixel.b) / 3.0;
    return vec4(avg, avg, avg, pixel.a);
  }
  ]]

return shader
