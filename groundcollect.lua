
local timer = 0
minetest.register_globalstep(function(dtime)
    timer = timer + dtime
    if timer < 0.5 then
       return
    end
    timer = 0

    for _,player in ipairs(minetest.get_connected_players()) do
       local keys = player:get_player_control()
       if player:get_hp() <= 0 then
          goto continue
       end

       -- Take items 1.5 units away from the approximate centre of the
       -- player. This pickup behaviour mimics Minecraft's.
       local ppos = player:get_pos()
       local pos = vector.new(ppos.x, ppos.y + 0.5, ppos.z)

       for _,obj in ipairs(minetest.get_objects_inside_radius(pos, 1.5)) do
          if not obj:is_player() then
             -- Simulate the player punching nearby item entities (which
             -- triggers an attempt to pick them up).
             --
             -- We limit this behaviour to items older than 2 seconds to avoid
             -- picking up items that have only just been dropped.
             local entity = obj:get_luaentity()
             if entity
                and entity.name == "__builtin:item"
                and entity.age > 2
             then
                entity:on_punch(player)
             end
          end
       end

       ::continue::
    end
end)

minetest.log("[CivMisc] GroundCollect initialised.")
