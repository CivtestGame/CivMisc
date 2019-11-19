
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

-- From https://forum.minetest.net/viewtopic.php?f=9&t=9286
local function groundLevel(targetX,targetZ)
   local manip = minetest.get_voxel_manip()   -- the voxel_manip is require to force loading of the block

   local groundLevel = nil
   local i
   -- This will fail if ground level is 100 or above or below below -100 (but this doesn't happen very often)
   for i = 96, -100, -1 do
      local p = {x=targetX, y=i, z=targetZ}
      local node = get_far_node(p)
      minetest.log("node name: " .. node.name)
      if node.name ~= "air" and node.name ~= "ignore" then
         groundLevel = i
         break
      end
   end
   if groundLevel ~= nil then
      -- Search Successful
      return {x=targetX, y=groundLevel, z=targetZ}
   else
      -- Search Failed
      print("groundLevel Search Failed. Groundlevel could be deeper than -100")
      return nil
   end
end

-- TODO: config this
local randomSpawnMinX = -500
local randomSpawnMaxX = 500
local randomSpawnMinZ = -500
local randomSpawnMaxZ = 500

function random_spawn(player)
   -- Slight hack: make it so the player is floating somewhere until after we've
   -- loaded the mapblock.
   player:set_pos({x=9999, y=9999, z=9999})

   -- Find some appropriate airy place to randomly spawn a player.
   local rx = math.random(randomSpawnMinX, randomSpawnMaxX)
   local rz = math.random(randomSpawnMinZ, randomSpawnMaxZ)
   local ground_vector = groundLevel(rx, rz)
   -- ground_vector is nil if the mapblock hasn't yet been generated. Force
   -- generate the area, recompute the y level, and place the player there.

   -- If ground_vector is non-nil, it's a valid, already-generated location, so
   -- we're fine to use it.
   if not ground_vector then
      minetest.emerge_area(
         vector.new(rx, -100, rz),
         vector.new(rx, 100, rz),
         function(blockpos, action, calls_remaining, param)
            if calls_remaining < 1 then
               local new_ground_vector = groundLevel(rx, rz)
               player:set_pos(new_ground_vector)
            end
         end
      )
   else
      player:set_pos(ground_vector)
   end
   return
end

-- Respawn player at bed if it still exists. If not, randomspawn them.
minetest.register_on_respawnplayer(function(player)
      local pname = player:get_player_name()
      local pos = beds.spawn[pname]
      local node = get_far_node(pos)
      local node_name = node.name
      minetest.log("node name: "..node_name)
      if pos and (node_name == "beds:bed_bottom"
                     or node_name == "beds:bed_top"
                     or node_name == "beds:fancy_bed_bottom"
                     or node_name == "beds:fancy_bed_top")
      then
         player:set_pos(pos)
      else
         random_spawn(player)
         minetest.chat_send_player(pname, "You wake up in an unfamiliar place.")
      end
end)

minetest.debug("[CivMisc] SpawnUtils initialised.")
