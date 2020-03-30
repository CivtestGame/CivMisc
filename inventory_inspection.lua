--Adds an item which allows a player to inspect another persons inventory
--Idea:add gate block which only allows players with specific items in

local perm_table = {}

local function get_inv_formspec(player_name, inv_name)

   local open = {
    "size[8,5.5]",
    "label[0,0;", player_name, "'s Inventory]",
    "list[detached:", inv_name, ";main2;0,0.5;8,3;]",
    "list[detached:", inv_name,";main;0,4.5;8,1]",
 }
 return table.concat(open, "")
end

local function use(itemstack, user, pointed_thing)
    if pointed_thing.ref and pointed_thing.ref:is_player() then
        local target_name = pointed_thing.ref:get_player_name()
        if perm_table[target_name] and (perm_table[target_name] == true or perm_table[target_name] == user:get_player_name()) then
            local inv_name = target_name .. "_inspection"
            local inv = minetest.get_player_by_name(target_name):get_inventory()
            local inspection_inv = minetest.create_detached_inventory(inv_name, {
                allow_move = function(inv, from_list, from_index, to_list, to_index, count, player)
                    return 0
                end,

                allow_put = function(inv, listname, index, stack, player)
                    return 0
                end,

                allow_take = function(inv, listname, index, stack, player)
                    return 0
                end,
            })
            local main = inv:get_list("main")
            local main2 = inv:get_list("main2")
            inspection_inv:set_list("main", main)
            inspection_inv:set_list("main2", main2)
            minetest.show_formspec(user:get_player_name(), "inv_inspection", get_inv_formspec(target_name,inv_name))
            minetest.chat_send_player(target_name, user:get_player_name() .. " is inspecting your inventory.")
        else
            
            minetest.chat_send_player(user:get_player_name(), target_name .. " has not allowed you to inspect their inventory.")
            minetest.chat_send_player(target_name, user:get_player_name() .. " tried to inspect your inventory, but you have not allowed it.")
        end
    end
end

minetest.register_craftitem("civmisc:inspection_gloves", {
    description = "Inspection gloves",
    on_use = use
})

minetest.register_chatcommand(
   "allow_inspection",
   {
      params = "[<target>]",
      description = "Allows a target(or anyone) to inspect your inventory.",
      func = function(sender, target)
        if minetest.get_player_by_name(sender) then
            if target == "" then
                perm_table[sender] = true
            else
                perm_table[sender] = target
            end
            f_util.debug(perm_table)
        else
            return false
        end
      end
   }
)



minetest.register_chatcommand(
   "disallow_inspection",
   {
      description = "Disallows anyone from inspecting your inventory.",
      func = function(sender, target)
        if minetest.get_player_by_name(sender) then
            perm_table[sender] = nil
        else
            return false
        end
      end
   }
)