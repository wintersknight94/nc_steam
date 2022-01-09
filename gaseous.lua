-- LUALOCALS < ---------------------------------------------------------
local minetest, nodecore, math
    = minetest, nodecore, math
-- LUALOCALS > ---------------------------------------------------------
local modname = minetest.get_current_modname()
local get_node = minetest.get_node
local set_node = minetest.swap_node
local directions = {
	{x=1, y=0, z=0},
	{x=-1, y=0, z=0},
	{x=0, y=0, z=1},
	{x=0, y=0, z=-1},
}
local steam = {name = modname .. ":steam"}
--local suspension = {"air", "group:water", "group:lava"}
   
----- ----- Lighter Than Air ----- -----
nodecore.register_abm({
     label = "gaseous:lighter than air",
     nodenames = {"group:gaseous"},
     interval = 2,
     chance = 2,
     action = function(pos, node)
          local next_pos = {x=pos.x, y=pos.y+1, z=pos.z}
		local next_node = minetest.get_node(next_pos)
			if next_node.name == "air" then
				minetest.swap_node(next_pos, steam)
				minetest.swap_node(pos, next_node)
			else 
			     local dir = directions[math.random(1,4)]
				local next_pos = vector.add(pos, dir)
				local next_node = minetest.get_node(next_pos)	
				     if next_node.name == "air" then
				          minetest.swap_node(next_pos, steam)
				          minetest.swap_node(pos, next_node)
               end
          end
     end,
})
----- ----- Lighter Than Water ----- -----
nodecore.register_abm({
     label = "gaseous:lighter than water",
     nodenames = {"group:gaseous"},
     interval = 2,
     chance = 1,
     action = function(pos, node)
          local next_pos = {x=pos.x, y=pos.y+1, z=pos.z}
		local next_node = minetest.get_node(next_pos)
			if next_node.name == "nc_terrain:water_flowing" then
				minetest.swap_node(next_pos, steam)
				minetest.swap_node(pos, next_node)
			else 
			     local dir = directions[math.random(1,4)]
				local next_pos = vector.add(pos, dir)
				local next_node = minetest.get_node(next_pos)	
				     if next_node.name == "nc_terrain:water_flowing" then
				          minetest.swap_node(next_pos, steam)
				          minetest.swap_node(pos, next_node)
               end
          end
     end,
})

nodecore.register_abm({
     label = "gaseous:lighter than water source",
     nodenames = {"group:gaseous"},
     interval = 2,
     chance = 1,
     action = function(pos, node)
          local next_pos = {x=pos.x, y=pos.y+1, z=pos.z}
		local next_node = minetest.get_node(next_pos)
			if next_node.name == "nc_terrain:water_source" then
				minetest.swap_node(next_pos, steam)
				minetest.swap_node(pos, next_node)
			else 
			     local dir = directions[math.random(1,4)]
				local next_pos = vector.add(pos, dir)
				local next_node = minetest.get_node(next_pos)	
				     if next_node.name == "nc_terrain:water_source" then
				          minetest.swap_node(next_pos, steam)
				          minetest.swap_node(pos, next_node)
               end
          end
     end,
})

----- ----- Gaseous Dissapation ----- -----
nodecore.register_abm({
		label = "gaseous:dissapation",
		interval = 1,
		chance = 10,
		nodenames = {modname .. ":steam"},
		action = function(pos, node)
          local pressure = #nodecore.find_nodes_around(pos, "group:steam")
          local airway = #nodecore.find_nodes_around(pos, "air")
               if pressure < 4 and airway > 2 then
		     nodecore.set_node(pos, {name = "air"})
          end
	end	
})

nodecore.register_abm({
		label = "thin atmoshpere",
		interval = 1,
		chance = 1,
		nodenames = {modname .. ":steam"},
		action = function(pos, node)
		local altitude = pos.y
               if altitude > 120 and airway > 1 then
		     nodecore.set_node(pos, {name = "air"})
          end
	end	
})

