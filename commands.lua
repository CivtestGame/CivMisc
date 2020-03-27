
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
      -- clearinv being unprivileged is weird
      minetest.chatcommands["clearinv"].privs = { server = true }
      minetest.chatcommands["pulverize"].privs = { server = true }

      register_alias("tp", "teleport")
      register_alias("day", "settime 5:30")
      register_alias("night", "settime 18:00")

      register_alias("gc", "group create")
      register_alias("gr", "group remove")
      register_alias("g", "group info")
      register_alias("gi", "group invite")
      register_alias("gl", "group list")

      register_alias("ppl", "pplocate")

      register_alias("pm", "msg")

      -- we have a more flexible /kill above
      minetest.unregister_chatcommand("killme")

      minetest.debug("[CivMisc] Commands initialised.")
end)

local C = minetest.colorize

minetest.register_chatcommand(
   "players",
   {
      params = "",
      description = "Lists online players.",
      func = function(sender)
         local player = minetest.get_player_by_name(sender)
         if not player then
            return false
         end

         local tab = {}
         local count = 0
         for _,p in ipairs(minetest.get_connected_players()) do
            tab[#tab + 1] = p:get_player_name()
            count = count + 1
         end
         table.sort(tab)
         minetest.chat_send_player(
            sender, C("#0f0", "Players (") .. C("#fff", tostring(count))
               .. C("#0f0", "):\n") .. table.concat(tab, " ")
         )
         return true
      end
   }
)

if minetest.get_modpath("simplecrafting_lib") then

   minetest.register_chatcommand(
      "factory_recipes",
      {
         params = "<name>",
         description = "Shows the recipes of a factory.",
         func = function(sender, param)
            local player = minetest.get_player_by_name(sender)
            if not player then
               return
            end

            if not param or param == "" then
               return false, "Please specify a factory."
            end

            param = param:lower():gsub(" ", "_")

            simplecrafting_lib.show_crafting_guide(param, player)
         end
      }
   )
end
