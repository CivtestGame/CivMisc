-- Load config parameters
local modpath = minetest.get_modpath(minetest.get_current_modname()) .. "/"

civmisc = {}

minetest.debug("CivMisc initializing...")

local groundcollect = dofile(modpath .. "groundcollect.lua")

local knockback = dofile(modpath .. "knockback.lua")

local sneakbob = dofile(modpath .. "sneakbob.lua")

local minimap = dofile(modpath .. "minimap.lua")

local cleanup = dofile(modpath .. "cleanup.lua")

local spawnutils = dofile(modpath .. "spawnutils.lua")

local worldborder = dofile(modpath .. "worldborder.lua")

local damagemod = dofile(modpath .. "damagemod.lua")

local rectifications = dofile(modpath .. "rectifications.lua")

local biome_utils = dofile(modpath .. "biome_utils.lua")

local timeutils = dofile(modpath .. "timeutils.lua")

local commands = dofile(modpath .. "commands.lua")

local onetimetp = dofile(modpath .. "onetimetp.lua")

local case_insensitivity = dofile(modpath .. "case_insensitivity.lua")

local oreofix = dofile(modpath .. "oreofix.lua")

local inventory_inspection = dofile(modpath .. "inventory_inspection.lua")

local inadequate_tool = dofile(modpath .. "inadequate_tool.lua")

local torchlight = dofile(modpath .. "torchlight.lua")

local healthtweaks = dofile(modpath .. "healthtweaks.lua")

local ie = minetest.request_insecure_environment() or
   error("CivMisc needs to be a trusted mod. "
            .."Add it to `secure.trusted_mods` in minetest.conf")

local fennel_exists, fennel_lib = pcall(ie.require, "fennel")
if fennel_exists then
   fennel = fennel_lib
   fennel.dofile(modpath .. "test.fnl")
end

local jeejah_exists, jeejah = pcall(ie.require, "jeejah")
local jeejah_port = tonumber(minetest.settings:get("civmisc_jeejah_port"))
if jeejah_exists and jeejah_port then
   local coro = jeejah.start(jeejah_port, { debug = true } )
   --
   -- Ouch. Tying the coroutine.resume to the globalstep means that jeejah is
   -- operating on minetest's (slowed-down) gametick schedule, thus leading to
   -- small but noticeable 'artificial' slowness when handling nREPL I/O.
   --
   -- Surely there's a way to escape this hell?!
   --
   minetest.register_globalstep(function(dtime)
         coroutine.resume(coro)
   end)
   minetest.log("[CivMisc] Jeejah initialised on port "..tostring(jeejah_port))
end

minetest.debug("CivMisc initialised.")

return civmisc
