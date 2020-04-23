
local ONE_TIME_TP_PERIOD = 60 * 60 -- 60 mins

minetest.register_on_newplayer(function(player)
      local pname = player:get_player_name()
      local meta = player:get_meta()
      local time = os.time(os.date("!*t"))
      meta:set_int("onetimetp", time)
      minetest.after(3,
         function()
            minetest.chat_send_player(
               pname, "Your one-time teleport is available!\n"
                  .. "   See `/teleport_request` for more information."
            )
         end
      )
      minetest.chat_send_all(
         pname .. " joined the server for the first time!"
      )
end)

local teleport_requests = {}

minetest.register_chatcommand(
   "teleport_request",
   {
      description = "Sends a one-time teleport request to a player.",
      params = "<player>",
      func = function(sender_name, params)
         local sender = minetest.get_player_by_name(sender_name)
         local sender_meta = sender:get_meta()

         local now = os.time(os.date("!*t"))
         if (not sender_meta:contains("onetimetp"))
            or sender_meta:get_int("onetimetp") + ONE_TIME_TP_PERIOD < now
            or (sender_meta:contains("onetimetp_available")
                   and sender_meta:get_int("onetimetp_available") == 0)
         then
            return false, "Your one-time teleport is no longer available."
         end

         if params == ""
            or not sender_meta:contains("onetimetp_available")
         then
            local mins = tostring(math.floor(
               ((sender_meta:get_int("onetimetp") + ONE_TIME_TP_PERIOD) - now)
                  / 60
            ))
            minetest.chat_send_player(
               sender_name,
               "\nBefore using /teleport_request, please note:\n "
                  .. " 1. You can only teleport once using this command.\n "
                  .. " 2. Your ability to teleport expires in "..mins.." minutes.\n "
                  .. " 3. There are limits on what you can take with you.\n"
            )
            if params ~= "" then
               minetest.chat_send_player(
                  sender_name,
                  "Use `/teleport_request " .. params
                     .. "` again to confirm your teleport."
               )
               sender_meta:set_int("onetimetp_available", 1)
            end
            minetest.chat_send_player(sender_name, " \n")
            -- The player must see the above message before trying to teleport.
            return false
         end

         if params == "" then
            return false, "Please specify the player you wish to teleport to."
         end

         local target_name = params

         if not minetest.get_player_by_name(target_name) then
            return false, target_name .. " is not online."
         end

         minetest.chat_send_player(
            target_name, sender_name .. " has requested a "
               .. "teleport to you. Use '/teleport_accept " .. sender_name
               .. "' to accept the request."
         )
         teleport_requests[target_name] = teleport_requests[target_name] or {}
         teleport_requests[target_name][sender_name] = true

         return true, "One-time teleport request sent to " .. target_name
            .. ". Please wait for them to accept it."
      end
   }
)

-- If the item name contains any of these, newfriends shouldn't be able to
-- transport them.
local INVALID_ITEMS = {
   "tin", "copper", "bronze", "iron", "steel", "obsidian", "gold", "tnt",
   "lava", "mese", "diamond", "mithril", "bucket", "coke", "smelter",
   "fortress", "stronghold", "civindustry"
}

-- Newfriends shouldn't be able to bring large amounts of stuff with them.
-- Four stacks is a good limit.
local ITEM_LIMIT = 396

local function is_teleportable_item(item)
   local name = item:get_name()

   for _,invalid_name in ipairs(INVALID_ITEMS) do
      if name:find(invalid_name) then
         return false
      end
   end

   return true
end

local function check_teleported_inventory(player)
   local errors = {}

   local pname = player:get_player_name()
   local inv = player:get_inventory()
   local name, armor_inv = armor:get_valid_player(player, "[on_dieplayer]")
   if not name then
      minetest.log("warning", "filter_teleported_inventory invalid armor inv")
      return false
   end

   if not armor_inv:is_empty("armor") then
      errors[#errors + 1] = "Take off your armor and put it in your inventory."
   end

   local item_total = 0

   local invlists = inv:get_lists()
   -- hbhunger strikes again with its archaic ways...
   invlists["hunger"] = nil

   for invname,contents in pairs(invlists) do
      for i,item in ipairs(contents) do
         if is_teleportable_item(item) then
            if not item:is_empty() then
               item_total = item_total + item:get_count()
            end
         else
            local def = item:get_definition()
            local name = item:get_name()
            errors[#errors + 1] = "Remove the " .. def.description
               .. " from your inventory (" .. name .. ")."
         end
      end
   end

   if item_total > ITEM_LIMIT then
      errors[#errors + 1] = "Reduce the items and blocks you carry by "
         .. tostring(item_total - ITEM_LIMIT) .. "."
   end

   return not next(errors), errors
end

local function teleport_player(src_name, dst_name)
   if not teleport_requests[dst_name]
      or not teleport_requests[dst_name][src_name]
   then
      minetest.chat_send_player(
         dst_name, src_name .. " did not request to teleport to you."
      )
      return false
   end

   local src = minetest.get_player_by_name(src_name)
   if not src then
      minetest.chat_send_player(
         dst_name, src_name .. " is not online."
      )
      return false
   end

   local src_meta = src:get_meta()
   local now = os.time(os.date("!*t"))
   if (not src_meta:contains("onetimetp"))
      or src_meta:get_int("onetimetp") + ONE_TIME_TP_PERIOD < now
      or (not src_meta:contains("onetimetp_available"))
      or src_meta:get_int("onetimetp_available") == 0
   then
      minetest.chat_send_player(
         dst_name, src_name .. " can no longer teleport to you."
      )
      return false
   end

   -- The dst is the sender of this command, so this obj will always be valid.
   local dst = minetest.get_player_by_name(dst_name)

   local valid_inv, errors = check_teleported_inventory(src)

   if not valid_inv then
      minetest.chat_send_player(
         src_name, "Teleport to "..dst_name.." failed. Try again after "
            .. "following these steps:\n - "
            .. table.concat(errors, "\n - ")
      )
      minetest.chat_send_player(
         dst_name, src_name.." failed to teleport because of inventory "
         .. "restrictions. Please wait for them to correct this, and try again."
      )
      return false
   end

   src_meta:set_int("onetimetp_available", 0)
   minetest.chat_send_player(
      src_name, "You have been teleported to "..dst_name.."!"
   )
   minetest.chat_send_player(
      dst_name, src_name .. " has been teleported to you!"
   )

   src:set_pos(dst:get_pos())

   return true
end

minetest.register_chatcommand(
   "teleport_accept",
   {
      params = "<player>",
      func = function(sender_name, params)
         -- local sender = minetest.get_player_by_name(sender_name)

         if params == "" then
            return false, "Please specify a player name to teleport to you."
         end

         local target_name = params

         return teleport_player(target_name, sender_name)

      end
   }
)

minetest.debug("[CivMisc] OneTimeTp initialised.")
