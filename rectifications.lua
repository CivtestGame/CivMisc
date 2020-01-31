
-- Generalist file for rectifying the sins of other mods.

-- xdecor: disable the hammer recipe so that players can't repair their tools in
--         an xdecor:workbench.
minetest.clear_craft({
      output = "xdecor:hammer"
})

minetest.debug("[CivMisc] Rectifications initialised.")
