-- entity to track player position passively
local TorchLight = {
    initial_properties = {
        is_visible = false,
        static_save = false,
        physical = false,
        collide_with_objects = false,
    },

    oldpos = nil,
}
minetest.register_entity("civmisc:torchlight", TorchLight)

-- Invisible Node to display light
minetest.register_node("civmisc:torchlight", {
	description = "Light for held torches",
	drawtype = "airlike",
	-- paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = false,
	drop = "",
	groups = {not_in_creative_inventory = 1},
	floodable = true,
    climbable = false,
    light_source = 8,
})


local function place_light(pos)
    -- check for space at head hight
    pos = vector.add(pos, {x=0,y=1,z=0})
    local node = minetest.get_node(pos)

    if node.name == "air" then
        minetest.set_node(pos, {name = "civmisc:torchlight"})
    end
end

local function remove_light(pos)
    -- remove at head hight
    pos = vector.add(pos, {x=0,y=1,z=0})

    if minetest.get_node(pos).name == "civmisc:torchlight" then
        minetest.remove_node(pos)
    end
end

function TorchLight:destroy()
    -- remove entity & node
    local pos = self.oldpos
    remove_light(pos)
    self.object:remove()
    -- minetest.chat_send_all("Removed torchlight at: " .. minetest.pos_to_string(pos))
end

function TorchLight:on_step(dtime)
    -- compare pos == oldpos
    local curpos = self.object:getpos()
    if vector.distance(self.oldpos, curpos) > 0 then
        -- remove old
        remove_light(self.oldpos)
        -- place new
        place_light(curpos)
        -- set new position
        self.oldpos = curpos
        -- minetest.chat_send_all("Torchlight moved to " .. minetest.pos_to_string(curpos))
    end
end

function TorchLight:on_activate(staticdata, dtime_s)
    local pos = self.object:get_pos()
    self.oldpos = pos
    place_light(pos)
    -- minetest.chat_send_all("Created torchlight at: " .. minetest.pos_to_string(pos))
end

-- hook player leave
minetest.register_on_leaveplayer(function(player, timeout)
    local ppos = player:getpos()
    for _,obj in ipairs(minetest.get_objects_inside_radius(ppos, 1)) do
        local entity = obj:get_luaentity()
        if entity and entity.name == "civmisc:torchlight" then
            entity:destroy()
            break
        end
    end
end)

-- detect player active item
-- local timer = 0
-- minetest.register_globalstep(function(dtime)
--     timer = timer + dtime
--     if timer < 0.5 then
--        return
--     end
--     timer = 0
--     for _,player in ipairs(minetest.get_connected_players()) do
--         local inv = player:get_inventory()
--         local ppos = player:getpos()
--         local holding = false

--         if player:get_wielded_item():get_name() == "default:torch" then
--             holding = true
--             -- minetest.chat_send_all("Player is holding torch")
--         end

--         local found = false
--         for _,obj in ipairs(minetest.get_objects_inside_radius(ppos, 1)) do
--             local entity = obj:get_luaentity()
--             if entity and entity.name == "civmisc:torchlight" then
--                 found = true
--                 if not holding then
--                     entity:destroy()
--                 end
--             end
--         end

--         if holding and not found then
--             -- spawn
--             local tlight = minetest.add_entity(ppos, "civmisc:torchlight", nil)
--             tlight:set_attach(player, "Arm_Right", {0,0,0}, {0,0,0})
--         end

--     end
-- end)

-- Glowstick, adapted from Nightscapes mod by Darkflame999 https://forum.minetest.net/viewtopic.php?f=9&t=24555

minetest.register_entity("civmisc:glowstick_entity", {
	initial_properties = {
		hp_max = 1,
		physical = true,
		collisionbox = {-0.14, -0.14, -0.14, 0.14, 0.14, 0.14},
		visual = "sprite",
		visual_size = {x=0.6, y=0.6},
		textures = {"civmisc_glowstick.png"},
		spritediv = {x=1, y=1},
		initial_sprite_basepos = {x=0, y=0},
		is_visible = true,
		timer = 0,
		physical = true,
		collide_with_objects = true,
	},
	on_activate = function(self, staticdata, dtime_s)
           self.last_pos = self.object:get_pos() or {x=-1, y=-1, z=-1}
	end,
	on_step = function(self, dtime)
		local temp = self.object:getpos()
		if self.last_pos.y ~= temp.y then
			minetest.set_node(self.last_pos, {name="air"})
			self.last_pos = temp
			minetest.set_node(self.last_pos, {name = "civmisc:torchlight"})
		end
		local node = minetest.get_node({x=self.last_pos.x, y=self.last_pos.y-0.3, z=self.last_pos.z})
		if minetest.registered_nodes[node.name].walkable then
			self.object:setvelocity({x=0, y=-2, z=0})
			self.object:setacceleration({x=0, y=-10, z=0})
		end
	end,
	on_punch = function(self, hitter)
		local nodes_in_area = minetest.find_nodes_in_area({x=self.last_pos.x-1, y=self.last_pos.y-1, z=self.last_pos.z-1}, {x=self.last_pos.x+1, y=self.last_pos.y+1, z=self.last_pos.z+1}, {"civmisc:torchlight"})
		for i=1, table.getn(nodes_in_area) do
			minetest.set_node(nodes_in_area[i], {name = "air"})
		end
		if hitter:is_player() then
			hitter:get_inventory():add_item("main", "civmisc:glowstick")
		end
	end,
})
minetest.register_craftitem("civmisc:glowstick", {
	description = "Glowstick",
	inventory_image = "civmisc_glowstick.png",
	on_drop = function(itemstack, dropper, pos)
		local obj = minetest.add_entity({x=pos.x, y=pos.y+1.3, z=pos.z}, "civmisc:glowstick_entity")
		local dir = dropper:get_look_dir()
		obj:setvelocity({x=dir.x*12, y=dir.y*10, z=dir.z*12})
		obj:setacceleration({x=dir.x*-3, y=-10, z=dir.z*-3})
		itemstack:take_item()
		return itemstack
	end,
})
minetest.register_craft({
	output = "civmisc:glowstick",
	recipe = {
		{"", "default:glass", "group:coal"},
		{"default:glass", "default:quicklime", "default:glass"},
		{"group:coal", "default:glass", ""},
		},
})
