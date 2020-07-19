
-- Complains when a node is punched with a tool incapable of providing the node
-- drops. Has some exemptions, like for swords, and Citadella's /ctr

local has_citadella = minetest.get_modpath("citadella")

local already_spammed = {}

minetest.register_on_punchnode(function(pos, node, puncher, pointed_thing)
   local pname = puncher:get_player_name()
   local held = puncher:get_wielded_item()
   local held_name = held:get_name()
   local held_def = core.registered_items[held_name]

   if not held_def then
      return
   end

   if (has_citadella and ct.player_modes[pname])
      or held:get_name():find("sword")
   then
      return
   end

   already_spammed[pname] = already_spammed[pname] or {}

   if already_spammed[pname][node.name] then
      return
   end

   already_spammed[pname][node.name] = true

   local node_def = core.registered_nodes[node.name]
   local node_level = (node_def
                          and node_def.groups
                          and node_def.groups.level) or 0

   local toolcaps = held_def.tool_capabilities
   local tool_level = (toolcaps and toolcaps.max_drop_level) or 0

   if tool_level < node_level then
      local held_desc = held_def.description
      if tool_level == 0 then
         held_desc = "your hand"
      end

      local node_desc = node_def.description
      minetest.chat_send_player(
         pname, "You will not get a drop from "
            .. node_desc .. " if you dig with " .. held_desc .. "."
      )
   end
end)

minetest.debug("[CivMisc] InadequateTool initialised.")
