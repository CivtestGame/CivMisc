-- Load config parameters
local modpath = minetest.get_modpath(minetest.get_current_modname())

function core.calculate_knockback(player, hitter, time_from_last_punch, tool_capabilities, dir, distance, damage)
   if damage == 0 or player:get_armor_groups().immortal then
      return 0.0
   end
   -- a good approximation of Minecraft kb:
   local res = 7.5
   dir.y = 0.75

   return res
end

minetest.debug("[CivMisc] Knockback initialised.")
