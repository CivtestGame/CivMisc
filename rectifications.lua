
-- Generalist file for rectifying the sins of other mods.

-- We use `register_on_mods_loaded` to avoid hard mod dependencies.

minetest.register_on_mods_loaded(function()

      -- xdecor: disable the hammer recipe so that players can't repair their tools in
      --         an xdecor:workbench.
      if minetest.get_modpath("xdecor") then
         minetest.clear_craft({ output = "xdecor:hammer" })
      end

      minetest.debug("[CivMisc] Rectifications initialised.")
end)
