
-- Generalist file for rectifying the sins of mods.

local function enable_citadella_for_containers()
   -- global: containers should be Citadella aware.

   local containers = {
      "xdecor:mailbox", "default:bookshelf", "xdecor:multishelf", "xdecor:cabinet_half",
      "xdecor:empty_shelf", "xdecor:cabinet", "bones:bones"
   }

   for _,name in ipairs(containers) do
      local olddef = core.registered_nodes[name]
      if olddef then
         local def = ct.override_definition(olddef)
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


local function enable_diggable_containers()
   -- global: containers should always be breakable, and should always drop
   --         their contents.
   --
   -- We prioritise this at all costs, even if it's hamfisted; we NEVER want
   -- players placing indestructible nodes. EVER.
   local sinners = {
      "xdecor:hive", "xdecor:enchantment_table", "xdecor:mailbox", "xdecor:workbench",
      "xdecor:itemframe", "default:bookshelf", "factory_mod:burner", "factory_mod:smelter",
      "factory_mod:advanced_smelter", "xdecor:multishelf", "xdecor:cabinet_half",
      "xdecor:empty_shelf", "xdecor:cabinet", "xdecor:workbench", "bones:bones"
   }

   for _,name in ipairs(sinners) do
      local olddef = core.registered_nodes[name]

      if olddef then
         local def = table.copy(olddef)

         def.can_dig = function(pos)
            return true
         end

         def.on_dig = minetest.node_dig

         def.after_dig_node = function(pos, old, meta, digger)
            local drops = {}
            for inv_name, inv_contents in pairs(meta.inventory) do
               for _, stack in ipairs(inv_contents) do
                  local item = stack:to_string()
                  if item ~= "" then
                     table.insert(drops, item)
                  end
               end
               minetest.handle_node_drops(pos, drops, digger)
            end
         end
         minetest.register_node(":" .. name, def)
      end
   end
end

-- local function enable_global_oddly_breakable_by_hand()
--    for name,def in pairs(core.registered_nodes) do
--       if name ~= "bedrock:bedrock"
--          and name ~= "air:air"
--          and not name:find("water")
--       then
--          if def.groups
--             and not def.groups.oddly_breakable_by_hand
--          then
--             local newdef = table.copy(def)
--             newdef.groups.oddly_breakable_by_hand = 1
--             minetest.register_node(":" .. name, newdef)
--          end
--       end
--    end
-- end

-- We use `register_on_mods_loaded` to avoid hard mod dependencies.

minetest.register_on_mods_loaded(function()

      disable_xdecor_hammer()
      disable_xdecor_enderchest()
      enable_diggable_containers()
      -- enable_global_oddly_breakable_by_hand()
      enable_citadella_for_containers()

      minetest.debug("[CivMisc] Rectifications initialised.")
end)
