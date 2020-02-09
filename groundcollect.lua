-- Load config parameters
local modpath = minetest.get_modpath(minetest.get_current_modname())

local timer = 0
minetest.register_globalstep(function(dtime)
    timer = timer + dtime
    if timer >= 0.75 then
       for _,player in ipairs(minetest.get_connected_players()) do
          if player:get_hp() > 0 then
             for _,obj in ipairs(minetest.get_objects_inside_radius(player:get_pos(), 1)) do
                if not obj:is_player() then
                   -- only care about items on the ground
                   local entity = obj:get_luaentity()
                   if entity.name == "__builtin:item" then
                      -- obj punch
                      entity:on_punch(player, nil, nil, nil)
                   end
                end
             end
          end
       end
       timer = 0
    end
end)

minetest.debug("[CivMisc] GroundCollect initialised.")
