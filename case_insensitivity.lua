
local case_insensitive_name_mapping = {}

minetest.register_on_joinplayer(function(player)
      local pname = player:get_player_name()
      case_insensitive_name_mapping[pname:lower()] = pname
end)

local old_minetest_get_player_by_name = minetest.get_player_by_name
minetest.get_player_by_name = function(name)
   return old_minetest_get_player_by_name(name)
      or
      old_minetest_get_player_by_name(
         case_insensitive_name_mapping[name:lower()]
      )
end

minetest.log("[CivMisc] CaseInsensitivity initialised.")
