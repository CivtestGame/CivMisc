
-- Generalist file for rectifying the sins of mods.

function disable_xdecor_hammer()
   -- xdecor: disable the hammer recipe so that players can't repair their tools in
   --         an xdecor:workbench.
   if minetest.get_modpath("xdecor") then
      minetest.clear_craft({ output = "xdecor:hammer" })
   end
end


function disable_xdecor_enderchest()
   -- xdecor: disable the enderchest. No config variable, nice.
   if minetest.get_modpath("xdecor") then
      minetest.unregister_item("xdecor:enderchest")
   end
end


function enable_diggable_containers()
   -- global: containers should always be breakable.
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
      local def = core.registered_nodes[name]
      if def then
         def.can_dig = function(pos)
            return true
         end
      end
   end
end

function enable_global_oddly_breakable_by_hand()
   for name,def in pairs(core.registered_nodes) do
      if name and
         (name ~= "bedrock:bedrock"
             or name ~= "air:air"
             or not name:find("water")) then
            if name == "default:stone" then
               minetest.log ("1: " .. name)
            end
            if def
            and def.groups
            and not def.groups['oddly_breakable_by_hand'] then
               def.groups.oddly_breakable_by_hand = 1
               if name == "default:stone" then
                  minetest.log("2: " .. dump(def.groups))
               end
               minetest.register_node(":" .. name, def)
            end
      end
   end
end

-- We use `register_on_mods_loaded` to avoid hard mod dependencies.

minetest.register_on_mods_loaded(function()

      disable_xdecor_hammer()
      disable_xdecor_enderchest()
      enable_diggable_containers()
      enable_global_oddly_breakable_by_hand()

      minetest.debug("[CivMisc] Rectifications initialised.")
end)
