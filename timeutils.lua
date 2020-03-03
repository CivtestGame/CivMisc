

local last_timeofday = nil
local change_per_second = nil

local timer = 0
minetest.register_globalstep(function(dtime)
      timer = timer + dtime
      if timer < 1 then
         return
      end
      timer = 0

      -- Minetest time passage is variable depending on config. There doesn't
      -- seem to be an easy way to figure out how much in-game time passes per
      -- irl second, so we have to measure this rate of change manually.

      local timeofday = core.get_timeofday()

      if not last_timeofday then
         last_timeofday = timeofday
         return
      end

      if not change_per_second then
         change_per_second = math.abs(timeofday - last_timeofday)

         -- Measurements across the midnight wraparound are rare.
         -- Still, we'll handle this case.
         if timeofday < last_timeofday then
            change_per_second = 1 - change_per_second
         end
      end

      -- Speed up "night" (between 6pm and 6am) by 2x.
      if timeofday > 0.75 or timeofday < 0.25 then
         core.set_timeofday(timeofday + change_per_second)
      end
end)

minetest.register_chatcommand(
   "time",
   {
      params = "",
      description = "Show the time of day",
      privs = {},
      func = function(name)
         local current_time = math.floor(core.get_timeofday() * 1440)
         local minutes = current_time % 60
         local hour = (current_time - minutes) / 60
         return true, ("Current time is %d:%02d"):format(hour, minutes)
      end
})


minetest.register_chatcommand(
   "settime",
   {
      params = "[<0..23>:<0..59> | <0..24000>]",
      description = "Set the time of day",
      privs = { settime = true },
      func = function(name, param)
         if param == "" then
            return false, "Please supply a time."
         end
         local hour, minute = param:match("^(%d+):(%d+)$")
         if not hour then
            local new_time = tonumber(param)
            if not new_time then
               return false, "Invalid time."
            end
            -- Backward compatibility.
            core.set_timeofday((new_time % 24000) / 24000)
            core.log("action", name .. " sets time to " .. new_time)
            return true, "Time of day changed."
         end
         hour = tonumber(hour)
         minute = tonumber(minute)
         if hour < 0 or hour > 23 then
            return false, "Invalid hour (must be between 0 and 23 inclusive)."
         elseif minute < 0 or minute > 59 then
            return false, "Invalid minute (must be between 0 and 59 inclusive)."
         end
         core.set_timeofday((hour * 60 + minute) / 1440)
         core.log("action", ("%s sets time to %d:%02d"):format(name, hour, minute))
         return true, "Time of day changed."
      end,
})

minetest.debug("[CivMisc] TimeUtils initialised.")
