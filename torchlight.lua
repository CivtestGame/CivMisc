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
local timer = 0
minetest.register_globalstep(function(dtime)
    timer = timer + dtime
    if timer < 0.5 then
       return
    end
    timer = 0
    for _,player in ipairs(minetest.get_connected_players()) do
        local inv = player:get_inventory()
        local ppos = player:getpos()
        local holding = false

        if player:get_wielded_item():get_name() == "default:torch" then
            holding = true
            -- minetest.chat_send_all("Player is holding torch")
        end

        local found = false
        for _,obj in ipairs(minetest.get_objects_inside_radius(ppos, 1)) do
            local entity = obj:get_luaentity()
            if entity and entity.name == "civmisc:torchlight" then
                found = true
                if not holding then
                    entity:destroy()
                end
            end
        end

        if holding and not found then
            -- spawn
            local tlight = minetest.add_entity(ppos, "civmisc:torchlight", nil)
            tlight:set_attach(player, "Arm_Right", {0,0,0}, {0,0,0})
        end

    end
end)

