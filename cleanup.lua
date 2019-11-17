
-- A less panicky shutdown framework.

--  minetest.on_shutdown doesn't seem to work so well. I've had mods screaming
--  about their db connections being nuked before they got the chance to flush
--  data, so I'm not going to take chances with it in future.

-- Herein lies the One True Way to close a Civtest server.

cleanup = {}
cleanup.actions = {}

function cleanup.register_cleanup_action(description, func)
   table.insert(cleanup.actions, { description = description, func = func })
end

minetest.register_chatcommand("shutdown_safe", {
   params = "",
   description = "Safely shutdown the server",
   privs = { server = true },
   func = function(pname, param)
      local total_count = 0
      local success_count = 0
      for n, entry in ipairs(cleanup.actions) do
         local func = entry.func
         local description = entry.description
         local cleanup_successful, description = func()
         minetest.log("Clean up of [" .. description .. "] "
                         .. (cleanup_successful and "SUCCESS") or "FAILED"
                         .. (description and (" (" .. description .. ")")) or "")
         total_count = total_count + 1
         if cleanup_successful then
            success_count = success_count + 1
         end
      end
      local cleanup_msg = "All cleanup handlers executed (" .. tostring(success_count)
         .. "/" .. tostring(total_count) .. " succeeded)."
      minetest.log(cleanup_msg)
      if pname then
         minetest.chat_send_player(pname, cleanup_msg)
      end
      minetest.chat_send_all("*** Server shutting down (operator request).")
      minetest.request_shutdown("", false, 0)
   end
})

-- cleanup.register_cleanup_action("TEST",
--                                 function()
--                                    return true, "Test successful."
--                                 end
-- )
