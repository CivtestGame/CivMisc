-- Adds an item which allows a player to inspect another persons inventory
-- Idea: add gate block which only allows players with specific items in

local perm_table = {}
local invite_table = {}

local function disallow_inspect(name)
   perm_table[name] = nil
end

local function get_inv_formspec(player_name, inv_name)
   local open = {
      "size[8,5.5]",
      "label[0,0;", player_name, "'s Inventory]",
      "list[detached:", inv_name, ";main2;0,0.5;8,3;]",
      "list[detached:", inv_name,";main;0,4.5;8,1]",
   }
   return table.concat(open, "")
end

local function on_inspection_gloves_use(itemstack, user, pointed_thing)
   if not pointed_thing.ref
      or not pointed_thing.ref:is_player()
   then
      return
   end

   local target_name = pointed_thing.ref:get_player_name()
   local user_name = user:get_player_name()

   if not perm_table[target_name] then
      minetest.chat_send_player(
         user_name,
         target_name .. " has not allowed you to inspect their inventory."
      )
      minetest.chat_send_player(
         target_name,
         user_name .. " tried to inspect your inventory, but you have "
            .. "not allowed it.\n"
            .. "Use '/allow_inspection " .. user_name .. "' to allow it."
      )
      invite_table[target_name] = user_name
      return
   end

   local inv_name = target_name .. "_inspection"
   local inv = minetest.get_player_by_name(target_name):get_inventory()
   local inspection_inv = minetest.create_detached_inventory(
      inv_name,
      {
         allow_move = function() return 0 end,
         allow_put = function() return 0 end,
         allow_take = function() return 0 end,
      }
   )

   local main = inv:get_list("main")
   local main2 = inv:get_list("main2")
   inspection_inv:set_list("main", main)
   inspection_inv:set_list("main2", main2)

   minetest.show_formspec(
      user_name, "inv_inspection", get_inv_formspec(target_name, inv_name)
   )

   minetest.chat_send_player(
      target_name, user_name .. " is inspecting your inventory."
   )

   perm_table[target_name] = nil

   itemstack:take_item()
   return itemstack
end

minetest.register_craftitem(
   "civmisc:inspection_gloves",
   {
      description = "Inspection Gloves",
      on_use = on_inspection_gloves_use,
      inventory_image = "civmisc_inspection_gloves.png"
   }
)

minetest.register_chatcommand(
   "allow_inspection",
   {
      params = "<target> [<time (seconds)>]",
      description = "Allows a target (or anyone) to inspect your inventory.",
      func = function(sender, params)
         local player = minetest.get_player_by_name(sender)
         if not player then
            return false
         end
         sender = player:get_player_name()

         local split_result = params:split(" ")
         local target = split_result[1]
         if not target then
            target = invite_table[sender]
         end

         local time = tonumber(split_result[2]) or 30

         -- Clamp potential time inputs between 1s and 5mins.
         if time < 1 then time = 1 end
         if time > 300 then time = 300 end

         minetest.after(time, disallow_inspect, sender)

         if not target then
            return false, "No target specified"
         end

         minetest.chat_send_player(
            sender, target .. " can now inspect your inventory for "
               .. " the next " .. time .. " seconds"
         )

         perm_table[sender] = target
         return true
      end
   }
)

minetest.register_chatcommand(
   "disallow_inspection",
   {
      params = "",
      description = "Disallows inspections of your inventory.",
      func = function(sender)
         local player = minetest.get_player_by_name(sender)
         if not player then
            return false
         end

         local pname = player:get_player_name()

         disallow_inspect(pname)

         minetest.chat_send_player(
            pname, "You disallowed inspections of your inventory."
         )
         return true
      end
   }
)
