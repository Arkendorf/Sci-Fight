local shader = {}
--
shader.cloud_shadow = love.graphics.newShader[[
    extern Image game;
    vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
      vec4 cloud_pixel = Texel(texture, texture_coords);
      if(texture_coords.y-0.1 > 0.0){
        vec4 game_pixel = Texel(game, vec2(texture_coords.x, texture_coords.y-0.1));
        if(game_pixel.a == 1.0 && cloud_pixel == vec4(1.0, 1.0, 1.0, 1.0)){
          return color;
        }
      }
      return cloud_pixel;
    }
  ]]

shader.shadow = love.graphics.newShader[[
    extern Image grid;
    extern number grid_w;
    extern vec2 grid_size;
    extern vec3 coords;
    vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
      vec4 pixel = Texel(texture, texture_coords);
      vec4 grid_pixel = Texel(grid, vec2((screen_coords.x+coords.z)/grid_size.x, (screen_coords.y)/grid_size.y));
      if(grid_pixel.a == 1.0){
        return pixel;
      }
      return vec4(0.0, 0.0, 0.0, 0.0);
    }
  ]]

return shader
