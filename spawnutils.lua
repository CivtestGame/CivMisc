
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

local has_prisonpearl = minetest.get_modpath("prisonpearl")

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
            local player_has_cell

            if has_prisonpearl and pp.player_has_cell_core(pname) then
               -- PrisonPearl handles the respawn of cell prisoners
               return
            end

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

local book_text = [[
Welcome to Civtest!

Civtest is a Minetest server that provides players with a powerful sandbox for building a civilization.

Please read the Getting Started Guide here:
  https://reddit.com/r/Civtest/wiki/getting-started

If you don't want to explore the wilderness alone, you should find someone who will accept a '/teleport_request'. Your chat messages are limited to a 1000 block radius. Please note that ore distribution is different on this server, see the Getting Started guide for more information.

Come and get involved in our community!
   Reddit:  https://reddit.com/r/Civtest
   Discord: https://discord.gg/DHEbhDF
]]

-- Spawn book creation popped up in the profiler, so here's an optimisation
local memoised_spawn_book

minetest.register_on_newplayer(function(player)
      if not memoised_spawn_book then
         local book = ItemStack("default:book_written")
         local data = book:get_meta():to_table().fields

         data.title = "Civtest Starter Guide (0.2)"
         data.description = "\"Civtest Starter Guide (0.2)\" by R3"
         data.text = book_text
         data.owner = "R3"
         data.page = 1
         data.page_max = 1

         book:get_meta():from_table({ fields = data })
         memoised_spawn_book = book
         minetest.log("[CivMisc] Spawn book memoised.")
      end

      player_api.give_item(player, memoised_spawn_book)
      player_api.give_item(player, "default:torch 10")
      player_api.give_item(player, "default:blueberries 5")
      player_api.give_item(player, "default:apple 2")

      random_spawn(player)
end)

--------------------------------------------------------------------------------
-- Newbie setup formspecs:
--  * Allow them to select inventory mode.
--------------------------------------------------------------------------------

local newbie_formspecs = {} -- List
local newbie_formspecs_check = {} -- Table

local newbie_formspec_idxs = {} -- Table

function civmisc.register_newbie_formspec(def)
   def.formname = def.formname
      or error("register_newbie_formspec: no formname defined.")
   -- def.fields = def.fields
   --    or error("register_newbie_formspec: no fields array defined.")
   def.func = def.func
      or error("register_newbie_formspec: no func defined.")

   local old_func = def.func
   def.func = function(player)
      local fs = old_func(player)
      minetest.show_formspec(player:get_player_name(), def.formname, fs)
   end

   newbie_formspecs[#newbie_formspecs + 1] = def
   newbie_formspecs_check[def.formname] = true
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
      local newbie_fs_def = newbie_formspecs_check[formname]
      if not newbie_fs_def then
         return
      end

      if not fields["quit"] then
         return
      end

      local pname = player:get_player_name()

      if not newbie_formspec_idxs[pname] then
         return
      end

      newbie_formspec_idxs[pname] = newbie_formspec_idxs[pname] + 1

      if newbie_formspec_idxs[pname] > #newbie_formspecs then
         newbie_formspec_idxs[pname] = nil
      else
         newbie_formspecs[newbie_formspec_idxs[pname]].func(player)
      end
end)

function civmisc.trigger_newbie_formspecs(player)
   local pname = player:get_player_name()
   newbie_formspec_idxs[pname] = newbie_formspec_idxs[pname] or 1
   newbie_formspecs[newbie_formspec_idxs[pname]].func(player)
end

-- DEVMODE: minetest.register_on_joinplayer(civmisc.trigger_newbie_formspecs)
minetest.register_on_newplayer(civmisc.trigger_newbie_formspecs)

--------------------------------------------------------------------------------
-- Newbie inventory mode setting
--------------------------------------------------------------------------------

local function show_inventory_mode_formspec(player)
   local pname = player:get_player_name()
   local fs_tab = {
      "size[7,4]",
      "label[0,0;Welcome to Civtest, ", pname, "!]",
      "label[0,0.75;This is a brief setup to help you get started.]",
      "label[0,2;Which game are you more familiar with?]",
      "button_exit[1,3;2,1;mc;Minecraft]",
      "button_exit[4,3;2,1;mt;Minetest]",
   }

   return table.concat(fs_tab)
end

civmisc.register_newbie_formspec(
   {
      formname = "civmisc:inventory_mode_fs",
      func = show_inventory_mode_formspec,
   }
)

minetest.register_on_player_receive_fields(function(player, formname, fields)
      if formname ~= "civmisc:inventory_mode_fs" then
         return
      end

      if not fields["quit"] then
         return
      end

      local meta = player:get_meta()
      if fields["mc"] then
         meta:set_string("sfinv:inventory_type", "minecraft")
      elseif fields["mt"] then
         meta:set_string("sfinv:inventory_type", "minetest")
      end
      sfinv.set_player_inventory_formspec(player)

      local pname = player:get_player_name()
      local new_mode = meta:get_string("sfinv:inventory_type")
      minetest.chat_send_player(
         pname, "Inventory mode switched to: " .. new_mode:upper() .. "\n"
            .. "You can toggle it with '/inventory_mode'."
      )
end)

--------------------------------------------------------------------------------
-- Final newbie formspec
--------------------------------------------------------------------------------

local function show_final_formspec(player)
   local pname = player:get_player_name()
   local fs_tab = {
      "size[6,5]",
      "label[0,0;All done, ", pname, ". Your inventory is ready.]",
      "label[0,1;We've given you some basic supplies, and a] ",
      "label[0,1.5;Starter Guide to help you on your way.]",
      "label[0,2;We hope you enjoy Civtest!]",
      "label[1,3;Good luck on your adventure!]",
      "button_exit[2,4;2,1;exit;OK]",
   }

   return table.concat(fs_tab)
end


minetest.register_on_mods_loaded(function()
      civmisc.register_newbie_formspec(
         {
            formname = "civmisc:final_fs",
            func = show_final_formspec,
         }
      )
end)

--------------------------------------------------------------------------------

minetest.debug("[CivMisc] SpawnUtils initialised.")
