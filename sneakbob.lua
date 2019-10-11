-- Load config parameters
local modpath = minetest.get_modpath(minetest.get_current_modname())

local view_offset = -1.5
local timer = 0
minetest.register_globalstep(function(dtime)
    timer = timer + dtime
    if timer >= 0.1 then
        for  _,player in ipairs(minetest.get_connected_players()) do
            local keys = player:get_player_control()
            local offset = player:get_eye_offset()
            if keys.sneak == true  and offset['y'] == 0 then
                offset["y"] = view_offset
                player:set_eye_offset(offset, {x=0,y=0,z=0})
            elseif  keys.sneak == false  and offset['y'] == view_offset then
                offset["y"] = 0
                player:set_eye_offset(offset, {x=0,y=0,z=0})
            end
        end
        timer = 0
    end
end)

minetest.debug("[CivMisc] SneakBob initialised.")

