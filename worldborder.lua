
local world_border_radius = 1000

local zerozero = vector.new(0, 0, 0)

local function position_in_world_border(pos)
   local pos_no_y = vector.new(pos.x, 0, pos.z)
   return vector.distance(pos_no_y, zerozero) < world_border_radius
end

local function get_closest_position_in_border(pos)
   local pos_no_y = vector.new(pos.x, 0, pos.z)
   local normalized = vector.normalize(pos_no_y)
   local new_pos = vector.multiply(normalized, world_border_radius)
   -- Preserve the player's y position
   new_pos.y = pos.y
   return new_pos
end

local timer = 0
minetest.register_globalstep(function(dtime)
      -- check player position every 500ms
      timer = timer + dtime
      if timer >= 0.5 then
         for _,player in ipairs(minetest.get_connected_players()) do
            local pname = player:get_player_name()
            local ppos = player:get_pos()
            if not position_in_world_border(ppos) then
               minetest.chat_send_player(pname, "You're at the world border.")
               local new_pos = get_closest_position_in_border(ppos)
               player:set_pos(new_pos)
            end
         end
         timer = 0
      end
end)


-- Don't allow block modification outside of the border.
local old_is_protected = minetest.is_protected
function minetest.is_protected(pos, name)
   if not position_in_world_border(pos) then
      minetest.chat_send_player(name, "You can't modify blocks beyond the border.")
      return true
   end
   return old_is_protected(pos, name)
end


local boats_loaded = minetest.get_modpath("boats")

if boats_loaded then
   minetest.log("WorldBorder is aware of the 'boats' plugin.")

   -- Stop boats from exceeding the world border
   local old_boat_on_step = minetest.registered_entities["boats:boat"].on_step
   minetest.registered_entities["boats:boat"].on_step = function(self, dtime)
      old_boat_on_step(self, dtime)
      local pos = self.object:get_pos()
      if not position_in_world_border(pos) then
         local new_pos = get_closest_position_in_border(pos)
         self.object:set_pos(new_pos)

         local velocity = self.object:get_velocity()
         local acceleration = self.object:get_acceleration()
         self.object:set_velocity(vector.multiply(velocity, -1))
         self.object:set_acceleration(vector.multiply(acceleration, -1))
      end
   end

end
minetest.debug("[CivMisc] WorldBorder initialised.")
