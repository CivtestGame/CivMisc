
minetest.register_on_player_hpchange(function(player, hp_change, reason)
      if hp_change < 0 and reason then
         if reason.type == "fall" then
            return hp_change * 7
         elseif reason.type == "node_damage" then
            return hp_change * 8
         elseif reason.type == "drown" then
            return hp_change * 15
         end
      end
      return hp_change
end, true)

minetest.debug("[CivMisc] DamageMod initialised.")
