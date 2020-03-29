
minetest.register_chatcommand(
   "oreofix",
   {
      description = "A fix for some clients with skybox rendering issues.",
      params = "",
      func = function(name)
         local player = minetest.get_player_by_name(name)
         if player then
            player:hud_add({
                  hud_elem_type = "image",
                  position = { x = 0.5, y = 0.5 },
                  scale = { x = -100, y = -100 },
                  text = "civmisc_oreo_hud.png"
            })
         end
      end
   }
)
