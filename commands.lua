
minetest.register_chatcommand(
   "kill",
   {
      params = "[<target>]",
      description = "Kills somebody.",
      privs = { server = true },
      func = function(sender, target)
         if target == "" then
            target = nil
         end

         local player = minetest.get_player_by_name(target or sender)
         if not player then
            minetest.chat_send_player(sender, "Player not found.")
            return false
         end

         player:set_hp(0)
      end
   }
)

local function register_alias(alias, command)
   local c_split = string.split(command, " ", nil, 1)
   local cname = c_split[1]
   local cargs = c_split[2] or ""

   minetest.chatcommands[alias] = table.copy(minetest.chatcommands[cname])

   local old_func = minetest.chatcommands[alias].func

   minetest.chatcommands[alias].func = function(sender, param)
      if cargs == "" then
         return old_func(sender, param)
      elseif param == "" then
         return old_func(sender, cargs)
      else
         return old_func(sender, cargs .. " " .. param)
      end
   end

   minetest.chatcommands[alias].description = "Alias of '/" .. command .. "'."
   minetest.chatcommands[alias].params = ""
   minetest.log("[CivMisc] Command alias: /" .. alias .. " --> /" .. command)
end

minetest.register_on_mods_loaded(function()
      -- clearinv being unprivileged is INSANE! wtf minetest
      minetest.chatcommands["clearinv"].privs = { server = true }
      minetest.chatcommands["pulverize"].privs = { server = true }
      -- for some reason /time (and aliases) were appearing green in /help for
      -- those without the privilege...
      minetest.chatcommands["time"].privs = { settime = true }

      register_alias("tp", "teleport")
      register_alias("day", "time 5:30")
      register_alias("night", "time 18:00")

      register_alias("gc", "group create")
      register_alias("ga", "group add")
      register_alias("gr", "group remove")
      register_alias("gi", "group info")

      -- we have a more flexible /kill above
      minetest.unregister_chatcommand("killme")

      -- chatplus should handle this
      minetest.unregister_chatcommand("me")

      minetest.debug("[CivMisc] Commands initialised.")
end)
