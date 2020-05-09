
-- Generalist file for rectifying the sins of mods.

local function enable_citadella_for_containers()
   -- global: containers should be Citadella aware.

   if not minetest.get_modpath("citadella") then
       return
   end

   local containers = {
      "xdecor:mailbox", "xdecor:multishelf", "xdecor:cabinet_half",
      "xdecor:empty_shelf", "xdecor:cabinet", "bones:bones", "citadella:chest"
   }

   for _,name in ipairs(containers) do
      local olddef = core.registered_nodes[name]
      if olddef then
         local def = ct.override_definition(olddef)
         minetest.register_node(":"..name, def)
      end
   end
end

local function enable_prisonpearl_tracking_for_containers()
  -- global: containers should be PrisonPearl aware.
   if not minetest.get_modpath("prisonpearl") then
       return
   end
   local containers = {
      "xdecor:hive", "xdecor:enchantment_table", "xdecor:mailbox", "xdecor:workbench",
      "xdecor:itemframe",
      "xdecor:multishelf", "xdecor:cabinet_half",
      "xdecor:empty_shelf", "xdecor:cabinet", "xdecor:workbench", "bones:bones",
      "citadella:furnace", "citadella:chest"
   }

   for k,_ in pairs(simplecrafting_lib.type) do
      local node_name = "civindustry:" .. k
      local node_def = minetest.registered_nodes[node_name]
      if node_def then
         containers[#containers + 1] = node_name
      end
   end

   for _,name in ipairs(containers) do
      local olddef = core.registered_nodes[name]
      if olddef then
         local def = pp.override_definition(olddef)
         minetest.register_node(":"..name, def)
      end
   end
end

local function disable_xdecor_hammer()
   -- xdecor: disable the hammer recipe so that players can't repair their tools in
   --         an xdecor:workbench.
   if minetest.get_modpath("xdecor") then
      minetest.clear_craft({ output = "xdecor:hammer" })
   end
end


local function disable_xdecor_enderchest()
   -- xdecor: disable the enderchest. No config variable, nice.
   if minetest.get_modpath("xdecor") then
      minetest.unregister_item("xdecor:enderchest")
   end
end

local function disable_xdecor_cauldron()
   -- xdecor: disable the cauldron. Again, no config variable, nice.
   --         At least we might want this one in the future.
   if minetest.get_modpath("xdecor") then
      minetest.unregister_item("xdecor:cauldron_empty")
   end
end

local function enable_diggable_containers()
   -- global: containers should always be breakable, and should always drop
   --         their contents.
   --
   -- We prioritise this at all costs, even if it's hamfisted; we NEVER want
   -- players placing indestructible nodes. EVER.
   local sinners = {
      "xdecor:hive", "xdecor:enchantment_table", "xdecor:mailbox", "xdecor:workbench",
      "xdecor:itemframe", "default:bookshelf",
      "xdecor:multishelf",
      "xdecor:cabinet_half", "xdecor:empty_shelf", "xdecor:cabinet", "xdecor:workbench",
      "bones:bones", "vessels:shelf", "citadella:chest", "default:chest",
      "fancy_vend:player_vendor"
   }

   for k,_ in pairs(simplecrafting_lib.type) do
      local node_name = "civindustry:" .. k
      local node_def = minetest.registered_nodes[node_name]
      if node_def then
         sinners[#sinners + 1] = node_name
      end
   end

   for _,name in ipairs(sinners) do
      local olddef = core.registered_nodes[name]

      if olddef then
         local def = table.copy(olddef)

         def.can_dig = function(pos)
            return true
         end

         if def.name ~= "fancy_vend:player_vendor" then
            def.on_dig = minetest.node_dig
         end

         def.after_dig_node = function(pos, old, meta, digger)
            local drops = {}
            for inv_name, inv_contents in pairs(meta.inventory) do
               if inv_name == "forms" and def.name == "xdecor:workbench" then
                  -- "forms" is used by xdecor:workbench as an output preview,
                  -- so we don't want to drop them
                  goto continue
               end
               if (inv_name == "wanted_item" or inv_name == "given_item")
                  and def.name == "fancy_vend:player_vendor"
               then
                  -- fancy_vend uses some inventories for presentation purposes,
                  -- but they don't store actual items. So, don't drop 'em.
                  goto continue
               end
               for _, stack in ipairs(inv_contents) do
                  local item = stack:to_string()
                  if item ~= "" then
                     drops[#drops + 1] = item
                  end
               end
               ::continue::
            end
            minetest.handle_node_drops(pos, drops, digger)
         end
         minetest.register_node(":" .. name, def)
      end
   end
end

local function fix_xdecor_breakable_chairs()
   -- xdecor: Fix chair invincibility, and fix the consequences of vincibility.
   -- Specifically, reset player physics overrides, animations, and eye locations.
   if not minetest.get_modpath("xdecor") then
      return
   end

   local new_sit_dig = function(pos, digger)
      for _, player in pairs(minetest.get_objects_inside_radius(pos, 0.1)) do
         if player:is_player()
            and default.player_attached[player:get_player_name()]
         then
            default.player_attached[player:get_player_name()] = false
            default.player_set_animation(player, "stand", 30)
            player:set_eye_offset({x=0,y=0,z=0},{x=0,y=0,z=0})
            player:set_physics_override({speed = 1, jump = 1, gravity = 1})
         end
      end
      return true
   end

   core.registered_nodes["xdecor:chair"].can_dig = new_sit_dig
   core.registered_nodes["xdecor:cushion"].can_dig = new_sit_dig
end


local function enable_ore_infotexts()
   -- global: ores should announce what they are.
   local ores = {
      "default:stone_with_coal", "default:stone_with_copper",
      "default:stone_with_tin", "default:stone_with_iron",
      "default:stone_with_gold", "default:stone_with_diamond",
      "default:stone_with_mese"
   }

   for _,name in ipairs(ores) do
      local olddef = core.registered_nodes[name]

      if olddef then
         local def = table.copy(olddef)

         def.on_rightclick = function(pos, node, clicker)
            if clicker:is_player() then
               local pname = clicker:get_player_name()
               minetest.chat_send_player(
                  pname, "This is a block of " .. def.description .. "."
               )
            end
         end

         minetest.register_node(":" .. name, def)
      end
   end
end

local function enable_floodable_flora()
   for name,def in pairs(core.registered_nodes) do
      local groups = def.groups
      if groups.flora
         or groups.food_mushroom
      then
         local newdef = table.copy(def)
         newdef.floodable = true
         newdef.on_flood = function(pos, oldnode, newnode)
            if not minetest.is_protected(pos) then
               minetest.dig_node(pos)
               return false
            else
               return true
            end
         end

         minetest.register_node(":" .. name, newdef)
      end
   end
end

-- ties into xdecor things above but applicable globally. Players, if damaged,
-- should have physics/attachment/anim/camera state reverted to vanilla.
--
-- We also want to close any formspecs they have open. The docs suggest that
-- this is dangerous though. We'll see.
--
minetest.register_on_player_hpchange(function(player, hp_change, reason)
      if default.player_attached[player:get_player_name()] then
         player:set_physics_override({speed = 1, jump = 1, gravity = 1})
         default.player_attached[player:get_player_name()] = false
         default.player_set_animation(player, "stand", 30)
         player:set_eye_offset({x=0,y=0,z=0},{x=0,y=0,z=0})
         minetest.close_formspec(player:get_player_name(), "")
      end
end, false)

minetest.register_on_respawnplayer(function(player)
      default.player_attached[player:get_player_name()] = false
      player:set_physics_override({speed = 1, jump = 1, gravity = 1})
      default.player_set_animation(player, "stand", 30)
      player:set_eye_offset({x=0,y=0,z=0},{x=0,y=0,z=0})
end)

minetest.register_on_mods_loaded(function()

      disable_xdecor_hammer()
      disable_xdecor_enderchest()
      disable_xdecor_cauldron()
      enable_diggable_containers()
      enable_citadella_for_containers()
      enable_prisonpearl_tracking_for_containers()
      fix_xdecor_breakable_chairs()
      enable_ore_infotexts()
      enable_floodable_flora()

      minetest.debug("[CivMisc] Rectifications initialised.")
end)


-- Transform all chests into Citadella ones.
if minetest.get_modpath("citadella") then
   minetest.register_lbm({
         label = "default:chest fixer",
         name = "civmisc:chest_fixer2",
         nodenames = { "default:chest", "default:chest_locked" },
         action = function(pos, node)
            local old_meta = minetest.get_meta(pos)
            local old_inv = old_meta:get_inventory()

            local old_invlist_main = table.copy(old_inv:get_list("main"))

            minetest.remove_node(pos)
            minetest.set_node(
               pos, { name = "citadella:chest", param1 = 0, param2 = 0}
            )
            local new_meta = minetest.get_meta(pos)
            local new_inv = new_meta:get_inventory()
            new_inv:set_list("main", old_invlist_main)
         end
   })
   minetest.log(
      "[CivMisc] default:chest --> citadella:chest transformer LBM is active!"
   )
end
