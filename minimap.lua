-- Load config parameters
local modpath = minetest.get_modpath(minetest.get_current_modname())


minetest.register_on_joinplayer(function(player)
      player:hud_set_flags({ minimap = true, minimap_radar = false })
end)


local has_map = minetest.get_modpath("map")
if has_map then
   function map.update_hud_flags(player)
      player:hud_set_flags({ minimap = true, minimap_radar = true })
   end
   minetest.debug("[CivMisc] Minimap enabled (\"map\" mod tweak)")
else
   minetest.debug("[CivMisc] Minimap enabled")
end
