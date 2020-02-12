
minetest.register_chatcommand(
   "biome",
   {
      params = "",
      description = "Retrieves information about the biome.",
      func = function(name)
         local player = minetest.get_player_by_name(name)
         if not player then
            return false
         end
         local pname = player:get_player_name()
         local pos = player:get_pos()

         local biome_data = minetest.get_biome_data(pos)
         if biome_data then
            local biome_name = minetest.get_biome_name(biome_data.biome)
            local heat = tostring(biome_data.heat)
            local humidity = tostring(biome_data.humidity)
            minetest.chat_send_player(
               pname,
               "Biome: " .. biome_name .. ", heat: " .. heat
                  .. ", humidity: " .. humidity)
         else
            minetest.chat_send_player(pname, "Biome data not found.")
         end
      end
})

minetest.debug("[CivMisc] BiomeUtils initialised.")
