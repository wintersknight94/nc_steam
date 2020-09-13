-- LUALOCALS < ---------------------------------------------------------
local minetest, nodecore, pairs, ipairs
    = minetest, nodecore, pairs, ipairs
-- LUALOCALS > ---------------------------------------------------------
local get_node = minetest.get_node
local set_node = minetest.swap_node
local water_level = tonumber(minetest.get_mapgen_setting("water_level"))
local all_direction_permutations = {              -- table of all possible permutations of horizontal direction to avoid lots of redundant calculations.
	{{x=0,z=1},{x=0,z=-1},{x=1,z=0},{x=-1,z=0}},
	{{x=0,z=1},{x=0,z=-1},{x=-1,z=0},{x=1,z=0}},
	{{x=0,z=1},{x=1,z=0},{x=0,z=-1},{x=-1,z=0}},
	{{x=0,z=1},{x=1,z=0},{x=-1,z=0},{x=0,z=-1}},
	{{x=0,z=1},{x=-1,z=0},{x=0,z=-1},{x=1,z=0}},
	{{x=0,z=1},{x=-1,z=0},{x=1,z=0},{x=0,z=-1}},
	{{x=0,z=-1},{x=0,z=1},{x=-1,z=0},{x=1,z=0}},
	{{x=0,z=-1},{x=0,z=1},{x=1,z=0},{x=-1,z=0}},
	{{x=0,z=-1},{x=1,z=0},{x=-1,z=0},{x=0,z=1}},
	{{x=0,z=-1},{x=1,z=0},{x=0,z=1},{x=-1,z=0}},
	{{x=0,z=-1},{x=-1,z=0},{x=1,z=0},{x=0,z=1}},
	{{x=0,z=-1},{x=-1,z=0},{x=0,z=1},{x=1,z=0}},
	{{x=1,z=0},{x=0,z=1},{x=0,z=-1},{x=-1,z=0}},
	{{x=1,z=0},{x=0,z=1},{x=-1,z=0},{x=0,z=-1}},
	{{x=1,z=0},{x=0,z=-1},{x=0,z=1},{x=-1,z=0}},
	{{x=1,z=0},{x=0,z=-1},{x=-1,z=0},{x=0,z=1}},
	{{x=1,z=0},{x=-1,z=0},{x=0,z=1},{x=0,z=-1}},
	{{x=1,z=0},{x=-1,z=0},{x=0,z=-1},{x=0,z=1}},
	{{x=-1,z=0},{x=0,z=1},{x=1,z=0},{x=0,z=-1}},
	{{x=-1,z=0},{x=0,z=1},{x=0,z=-1},{x=1,z=0}},
	{{x=-1,z=0},{x=0,z=-1},{x=1,z=0},{x=0,z=1}},
	{{x=-1,z=0},{x=0,z=-1},{x=0,z=1},{x=1,z=0}},
	{{x=-1,z=0},{x=1,z=0},{x=0,z=-1},{x=0,z=1}},
	{{x=-1,z=0},{x=1,z=0},{x=0,z=1},{x=0,z=-1}},
}

--------------------Making Water Finite--------------------
local override_def = {liquid_renewable = false}
	minetest.override_item("nc_terrain:water_source", override_def)
	minetest.override_item("nc_terrain:water_flowing", override_def)

--------------------Making Water Dynamic--------------------
nodecore.register_limited_abm({
		label = "hydrodynamics",
		nodenames = {"nc_terrain:water_source"},
		neighbors = {"nc_terrain:water_flowing"},
		interval = 1,
		chance = 1,
		action = function(pos,node) -- Do everything possible to optimize this method
				local check_pos = {x=pos.x, y=pos.y-1, z=pos.z}
				local check_node = get_node(check_pos)
				local check_node_name = check_node.name
				if check_node_name == "nc_terrain:water_flowing" or check_node_name == "air" then
					set_node(pos, check_node)
					set_node(check_pos, node)
					return
				end
				local perm = all_direction_permutations[math.random(24)]
				local dirs -- declare outside of loop so it won't keep entering/exiting scope
				for i=1,4 do
					dirs = perm[i]
					-- reuse check_pos to avoid allocating a new table
					check_pos.x = pos.x + dirs.x 
					check_pos.y = pos.y
					check_pos.z = pos.z + dirs.z
					check_node = get_node(check_pos)
					check_node_name = check_node.name
					if check_node_name == "nc_terrain:water_flowing" or check_node_name == "air" then
						set_node(pos, check_node)
						set_node(check_pos, node)
						return
					end
				end
			end
		})

--------------------Making Lava Dynamic--------------------
nodecore.register_limited_abm({
		label = "lavadynamics",
		nodenames = {"nc_terrain:lava_source"},
		neighbors = {"nc_terrain:lava_flowing"},
		interval = 1,
		chance = 1,
		action = function(pos,node) -- Do everything possible to optimize this method
				local check_pos = {x=pos.x, y=pos.y-1, z=pos.z}
				local check_node = get_node(check_pos)
				local check_node_name = check_node.name
				if check_node_name == "nc_terrain:lava_flowing" or check_node_name == "air" then
					set_node(pos, check_node)
					set_node(check_pos, node)
					return
				end
				local perm = all_direction_permutations[math.random(24)]
				local dirs -- declare outside of loop so it won't keep entering/exiting scope
				for i=1,4 do
					dirs = perm[i]
					-- reuse check_pos to avoid allocating a new table
					check_pos.x = pos.x + dirs.x 
					check_pos.y = pos.y
					check_pos.z = pos.z + dirs.z
					check_node = get_node(check_pos)
					check_node_name = check_node.name
					if check_node_name == "nc_terrain:lava_flowing" or check_node_name == "air" then
						set_node(pos, check_node)
						set_node(check_pos, node)
						return
					end
				end
			end
		})

--------------------Liquid Displacement--------------------
	local cardinal_dirs = {
		{x= 0, y=0,  z= 1},
		{x= 1, y=0,  z= 0},
		{x= 0, y=0,  z=-1},
		{x=-1, y=0,  z= 0},
		{x= 0, y=-1, z= 0},
		{x= 0, y=1,  z= 0},
	}
	-- breadth-first search passing through liquid searching for air or flowing liquid.
	local flood_search_outlet = function(start_pos, source, flowing)
		local start_node =  minetest.get_node(start_pos)
		local start_node_name = start_node.name
		if start_node_name == "air" or start_node_name == "nc_terrain:water_flowing" then
			return start_pos
		end
	
		local visited = {}
		visited[minetest.hash_node_position(start_pos)] = true
		local queue = {start_pos}
		local queue_pointer = 1
		
		while #queue >= queue_pointer do
			local current_pos = queue[queue_pointer]		
			queue_pointer = queue_pointer + 1
			for _, cardinal_dir in ipairs(cardinal_dirs) do
				local new_pos = vector.add(current_pos, cardinal_dir)
				local new_hash = minetest.hash_node_position(new_pos)
				if visited[new_hash] == nil then
					local new_node = minetest.get_node(new_pos)
					local new_node_name = new_node.name
					if new_node_name == "air" or new_node_name == "nc_terrain:water_flowing" then
						return new_pos
					end
					visited[new_hash] = true
					if new_node_name == source then
						table.insert(queue, new_pos)
					end
				end
			end		
		end
		return nil
	end

	-- Conserve liquids, when placing nodes in liquids try to find a place to displace the liquid to.
	minetest.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
		local flowing = "nc_terrain:water_flowing"
		if flowing ~= nil then
			local dest = flood_search_outlet(pos, oldnode.name, flowing)
			if dest ~= nil then
				minetest.swap_node(dest, oldnode)
			end
		end
	end
	)

--------------------Worldgen--------------------
local mapgen_prefill = true
local data = {}
local waternodes

if mapgen_prefill then
	local c_water = minetest.get_content_id("nc_terrain:water_source")
	local c_air = minetest.get_content_id("air")
	waternodes = {}

	local fill_to = function (vi, data, area)
		if area:containsi(vi) and area:position(vi).y <= water_level then
			if data[vi] == c_air then
				data[vi] = c_water
				table.insert(waternodes, vi)
			end
		end
	end

--	local count = 0
	local drop_liquid = function(vi, data, area, min_y)
		if data[vi] ~= c_water then
			-- we only care about water.
			return
		end
		local start = vi -- remember the water node we started from
		local ystride = area.ystride
		vi = vi - ystride
		if data[vi] ~= c_air then
			-- if there's no air below this water node, give up immediately.
			return
		end
		vi = vi - ystride -- There's air below the water, so move down one.
		while data[vi] == c_air and area:position(vi).y > min_y do
			-- the min_y check is here to ensure that we don't put water into the mapgen
			-- border zone below our current map chunk where it might get erased by future mapgen activity.
			-- if there's more air, keep going.
			vi = vi - ystride
		end
		vi = vi + ystride -- Move back up one. vi is now pointing at the last air node above the first non-air node.
		data[vi] = c_water
		data[start] = c_air
--		count = count + 1
--		if count % 100 == 0 then
--			minetest.chat_send_all("dropped water " .. (start-vi)/ystride .. " at " .. minetest.pos_to_string(area:position(vi)))
--		end
	end
	
	minetest.register_on_generated(function(minp, maxp, seed)
		if minp.y > water_level then
			-- we're in the sky.
			return
		end
	
		local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
		local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
		vm:get_data(data)
		local maxp_y = maxp.y
		local minp_y = minp.y
		
		if maxp_y > -70 then
			local top = vector.new(maxp.x, math.min(maxp_y, water_level), maxp.z) -- prevents flood fill from affecting any water above sea level
			for vi in area:iterp(minp, top) do
				if data[vi] == c_water then
					table.insert(waternodes, vi)
				end
			end
			
			while table.getn(waternodes) > 0 do
				local vi = table.remove(waternodes)
				local below = vi - area.ystride
				local left = vi - area.zstride
				local right = vi + area.zstride
				local front = vi - 1
				local back = vi + 1
				
				fill_to(below, data, area)
				fill_to(left, data, area)
				fill_to(right, data, area)
				fill_to(front, data, area)
				fill_to(back, data, area)
			end
		else
			-- Caves sometimes generate with liquid nodes hovering in mid air.
			-- This immediately drops them straight down as far as they can go, reducing the ABM thrashing.
			-- We only iterate down to minp.y+1 because anything at minp.y will never be dropped farther anyway.
			for vi in area:iter(minp.x, minp_y+1, minp.z, maxp.x, maxp_y, maxp.z) do
				-- fortunately, area:iter iterates through y columns going upward. Just what we need!
				-- We could possibly be a bit more efficient by remembering how far we dropped then
				-- last liquid node in a column and moving stuff down that far,
				-- but for now let's keep it simple.
				drop_liquid(vi, data, area, minp_y)
			end
		end
		
		vm:set_data(data)
		vm:write_to_map()
		vm:update_liquids()
	end)
end

