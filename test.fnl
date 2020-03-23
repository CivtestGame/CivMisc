
(local modpath (.. (minetest.get_modpath "civmisc") "/"))

(minetest.register_chatcommand
 "rl"
 {:privs { :server true }
  :description "Reload the fennel file."
  :func (lambda [name]
           (minetest.chat_send_all "Reloaded fennel.")
           (fennel.dofile (.. modpath "test.fnl")))})

(minetest.log "[CivMisc] Fennel file loaded.")
