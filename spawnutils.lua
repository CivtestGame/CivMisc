
local random_spawn_radius = tonumber(minetest.settings:get("civmisc_random_spawn_radius"))
if not random_spawn_radius then
   random_spawn_radius = 500
   minetest.log(
      "warning",
      "[CivMisc] No random spawn radius specified, defaulting to "
         .. tonumber(random_spawn_radius) .. "."
   )
else
   minetest.log(
      "[CivMisc] Random spawn radius set to "
         .. tonumber(random_spawn_radius) .. "."
   )
end

-- From https://dev.minetest.net/minetest.get_node
-- should only be ignore if there's not generated map
local function get_far_node(pos)
   local node = minetest.get_node(pos)
   if node.name == "ignore" then
      minetest.get_voxel_manip():read_from_map(pos, pos)
      node = minetest.get_node(pos)
   end
   return node
end

local SPAWN_GROUND_NOT_FOUND = "ground_not_found"
local SPAWN_AREA_NOT_EMERGED = "aread_not_emerged"

-- Adapted from https://forum.minetest.net/viewtopic.php?f=9&t=9286
local function get_ground_level(target_x, target_z)
   -- Search from y=100 to y=-100
   for i = 100, -100, -1 do
      local pos = { x = target_x, y = i, z = target_z }
      local node = get_far_node(pos)
      -- Area isn't emerged, return nil and the reason
      if node.name == "ignore" then
         return nil, SPAWN_AREA_NOT_EMERGED
      elseif node.name ~= "air" then
         -- We found a suitable candidate...
         if node.name == "default:water_source" then
            -- Oh, it's watery. The ocean is not suitable for a spawn...
            break
         end
         -- Success, return the position with a little y bump
         return { x = target_x, y = i + 1, z = target_z }
      end
   end
   -- Search failed for whatever reason
   return nil, SPAWN_GROUND_NOT_FOUND
end

local function get_random_xz_in_circle(radius)
   local a = math.random() * 2 * math.pi
   local r = radius * math.sqrt(math.random())

   local x = math.floor(r * math.cos(a))
   local z = math.floor(r * math.sin(a))

   return x, z
end

local function try_random_spawn(player, x, z)
   -- Ensure we have coordinates to try to spawn the player at. Generate random
   -- ones if none are supplied.
   local rx, rz = x, z
   if rx == nil or rz == nil then
       rx, rz = get_random_xz_in_circle(random_spawn_radius)
   end
   -- Get the ground level at these coordinates, or a reason we failed to do this.
   local ground_vector, reason = get_ground_level(rx, rz)

   -- If we found the ground location, success! Spawn the player there.
   if ground_vector then
      player:set_pos(ground_vector)
    -- If no suitable location was found, try again elsewhere...
   elseif reason == SPAWN_GROUND_NOT_FOUND then
      try_random_spawn(player)
    -- If the mapblock wasn't emerged/generated, emerge it, and try again with
    -- the same coordinates.
   elseif reason == SPAWN_AREA_NOT_EMERGED then
      minetest.emerge_area(
         vector.new(rx, -100, rz),
         vector.new(rx, 100, rz),
         function(blockpos, action, calls_remaining, param)
            if calls_remaining < 1 then
               try_random_spawn(player, rx, rz)
            end
         end
      )
   end
end

local function random_spawn(player)
   local pname = player:get_player_name()
   -- Temporarily send the player to the sky until we get a spawn point
   player:set_pos({x=math.random(-100, 100), y=9999, z=math.random(-100, 100)})

   -- Then, randomspawn the player, and send a pleasant message
   try_random_spawn(player)
   minetest.after(
      3,
      function(pname)
         minetest.chat_send_player(
            pname,
            "You wake up in an unfamiliar place..."
         )
      end,
      pname)
end



-- This code depends on hbhunger
minetest.register_on_mods_loaded(function()
      local player_can_respawn_on_bed = function(player)
         return true
      end
      if not minetest.get_modpath("hbhunger") then
         minetest.log("hbhunger not found! Players will always respawn at their bed!", "warn")
      else
         -- player_can_respawn_on_bed = function(player)
         --    local pname = player:get_player_name()
         --    return not hbhunger.did_starve[pname]
         -- end
      end

      -- Respawn player at bed if it still exists. If not, randomspawn them.
      minetest.register_on_respawnplayer(function(player)
            local pname = player:get_player_name()
            local pos = beds.spawn[pname]
            if pos and player_can_respawn_on_bed(player) then
               local node = get_far_node(pos)
               local node_name = node.name
               if (node_name == "beds:bed_bottom"
                      or node_name == "beds:bed_top"
                      or node_name == "beds:fancy_bed_bottom"
                      or node_name == "beds:fancy_bed_top")
               then
                  player:set_pos(pos)
               else
                  random_spawn(player)
               end
            else
               random_spawn(player)
            end
      end)
end)

minetest.register_on_newplayer(function(player)
      random_spawn(player)
end)


minetest.debug("[CivMisc] SpawnUtils initialised.")
