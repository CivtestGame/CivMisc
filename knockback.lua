-- Load config parameters
local modpath = minetest.get_modpath(minetest.get_current_modname())

local function round(x)
   return x >= 0
      and math.floor(x + 0.5)
      or math.ceil(x - 0.5)
end

function core.calculate_knockback(player, hitter, time_from_last_punch,
                                  tool_capabilities, dir, distance, damage)
   if damage == 0
      or player:get_armor_groups().immortal
      or not (player:get_hp() > 0)
      or default.player_attached[player:get_player_name()]
   then
      return 0.0
   end

   local pos = player:get_pos()
   local pos_y = pos.y

   if time_from_last_punch > 1 then
      dir.y = 1
      return 4.75
   else
      dir.y = 0.9
      return 4.25
   end

end

minetest.debug("[CivMisc] Knockback initialised.")
