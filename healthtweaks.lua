
-- Tweaks to player HP

minetest.register_on_joinplayer(function(player)
      player:set_properties({
            hp_max = 200
      })
end)

minetest.register_on_newplayer(function(player)
      player:set_properties({
            hp_max = 200
      })
      player:set_hp(200)
end)
