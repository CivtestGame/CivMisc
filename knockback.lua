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
   local decimals_y = pos_y - round(pos_y)

   if decimals_y > 0 then
      dir.y = dir.y + 0.25
      return 2.5
   else
      dir.y = 0.75
      return 7.5
   end
end

minetest.debug("[CivMisc] Knockback initialised.")
