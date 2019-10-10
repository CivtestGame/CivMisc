-- Load config parameters
local modpath = minetest.get_modpath(minetest.get_current_modname())

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

local view_offset = -1.5

minetest.register_globalstep(function(dtime)
    for  _,player in ipairs(minetest.get_connected_players()) do
        local keys = player:get_player_control()
        local offset = player:get_eye_offset()
        if keys.sneak == true  and offset['y'] == 0 then
            offset["y"] = view_offset
            player:set_eye_offset(offset, offset)
        elseif  keys.sneak == false  and offset['y'] == view_offset then
            offset["y"] = 0
            player:set_eye_offset(offset, offset)
        end
    end
end)

minetest.debug("[CivMisc] SneakBob initialised.")

