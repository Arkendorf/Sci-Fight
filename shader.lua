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
      return pixel*color;
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

shader.prop_layer_mask = love.graphics.newShader[[
    extern Image mask;
    extern vec2 mask_size;
    extern vec3 coords;
    extern vec2 offset;
    extern number tile_size;
    extern number w;
    vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
      vec4 pixel = Texel(texture, texture_coords);
      if(pixel.a > 0){
        vec2 adjusted_coords = vec2(screen_coords.x-offset.x, screen_coords.y-offset.y);
        if(adjusted_coords.x >= 0.0 && adjusted_coords.x <= mask_size.x && adjusted_coords.y >= 0.0 && adjusted_coords.y <= mask_size.y){
          vec4 mask_pixel = Texel(mask, vec2(adjusted_coords.x/mask_size.x, adjusted_coords.y/mask_size.y));
          if(adjusted_coords.y/tile_size-coords.y-coords.z+2<w){
            if(mask_pixel.b <= 1.014-0.010*coords.z){
              return vec4(0, 1.01 - 0.01*(adjusted_coords.y/tile_size-coords.z+1), 1.01 - 0.01*coords.z, 1);
            }
          }
          else{
            if(mask_pixel.g >= 1.005-0.010*(coords.y) || (mask_pixel.g == 0.0)){
              return vec4(0, 1.01 - 0.01*(coords.y+w-1), 1.01 - 0.01*(coords.z-coords.y+adjusted_coords.y/tile_size-w), 1);
            }
          }
        }
      }
      return vec4(0, 0, 0, 0);
    }
  ]]

shader.prop_shadow_mask = love.graphics.newShader[[
    extern Image mask;
    extern vec2 mask_size;
    extern vec3 coords;
    extern vec2 offset;
    extern number tile_size;
    extern number w;
    vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
      vec4 pixel = Texel(texture, texture_coords);
      if(pixel.a > 0){
        vec2 adjusted_coords = vec2(screen_coords.x-offset.x, screen_coords.y-offset.y);
        if(adjusted_coords.x >= 0.0 && adjusted_coords.x <= mask_size.x && adjusted_coords.y >= 0.0 && adjusted_coords.y <= mask_size.y){
          vec4 mask_pixel = Texel(mask, vec2(adjusted_coords.x/mask_size.x, adjusted_coords.y/mask_size.y));
          if(adjusted_coords.y/tile_size-coords.y-coords.z+2<w){
            if(mask_pixel.b <= 1.014-0.010*coords.z){
              return vec4(1.01-0.01*coords.z, 0, 0, 1);
            }
          }
        }
      }
      return vec4(0, 0, 0, 1);
    }
  ]]

shader.prop_layer = love.graphics.newShader[[
    extern Image mask;
    extern vec2 mask_size;
    extern vec3 coords;
    extern vec2 offset;
    extern number tile_size;
    extern number w;
    vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
      vec4 pixel = Texel(texture, texture_coords);
      if(pixel.a > 0){
        vec2 adjusted_coords = vec2(screen_coords.x-offset.x, screen_coords.y-offset.y);
        if(adjusted_coords.x >= 0.0 && adjusted_coords.x <= mask_size.x && adjusted_coords.y >= 0.0 && adjusted_coords.y <= mask_size.y){
          vec4 mask_pixel = Texel(mask, vec2(adjusted_coords.x/mask_size.x, adjusted_coords.y/mask_size.y));
          if(adjusted_coords.y/tile_size-coords.y-coords.z+2<w){
            if(mask_pixel.b > 1.014-0.010*coords.z){
              return vec4(0, 0, 0, 0);
            }
          }
          else{
            if(mask_pixel.g < 1.005-0.010*(coords.y+w)){
              return vec4(0, 0, 0, 0);
            }
          }
        }
      }
      return pixel*color;
    }
  ]]

  shader.prop_shadow = love.graphics.newShader[[
      extern Image mask;
      extern vec2 mask_size;
      extern vec3 coords;
      extern vec2 offset;
      extern number tile_size;
      extern number w;
      vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
        vec4 pixel = Texel(texture, texture_coords);
        if(pixel.a > 0){
          vec2 adjusted_coords = vec2(screen_coords.x-offset.x, screen_coords.y-offset.y);
          if(adjusted_coords.x >= 0.0 && adjusted_coords.x <= mask_size.x && adjusted_coords.y >= 0.0 && adjusted_coords.y <= mask_size.y){
            vec4 mask_pixel = Texel(mask, vec2(adjusted_coords.x/mask_size.x, adjusted_coords.y/mask_size.y));
            if((mask_pixel.b <= 1.014-0.010*coords.z)){
              return color;
            }
          }
        }
        return vec4(0, 0, 0, 0);
      }
    ]]

shader.border = love.graphics.newShader[[
    vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
      vec4 pixel = Texel(texture, texture_coords);
      if(pixel.a > 0 && pixel.r > 0 && pixel.g > 0 && pixel.b > 0){
        return vec4(.2, .2, .3, .5);
      }
      return vec4(0, 0, 0, 0);
    }
  ]]

return shader
