-- Load config parameters
local modpath = minetest.get_modpath(minetest.get_current_modname()) .. "/"

minetest.debug("CivMisc initializing...")

local groundcollect = dofile(modpath .. "groundcollect.lua")

local knockback = dofile(modpath .. "knockback.lua")

local sneakbob = dofile(modpath .. "sneakbob.lua")

local minimap = dofile(modpath .. "minimap.lua")

local cleanup = dofile(modpath .. "cleanup.lua")

local spawnutils = dofile(modpath .. "spawnutils.lua")

local worldborder = dofile(modpath .. "worldborder.lua")

local chat = dofile(modpath .. "chat.lua")

local damagemod = dofile(modpath .. "damagemod.lua")

local rectifications = dofile(modpath .. "rectifications.lua")

minetest.debug("CivMisc initialised.")
