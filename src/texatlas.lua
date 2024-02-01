local function getTotalArea( imgs )
	local total = 0
	for i,v in ipairs( imgs ) do
		local w,h = v:getDimensions()
		total = total + w*w + h*h
	end
	return total
end

-- takes in a table of Love2d images
-- return a canvas with all the input images on it and a
-- a table of UV co-ordinates, stored in the same order as
-- the input images
--
--
local function createTextureAtlas( imgs,w,h )
	assert(imgs and w)

	local h = h or w
	local canvas = love.graphics.newCanvas(w,h)
	local canvas_area = w*h
	local area = getTotalArea(imgs)

	if area > canvas_area then
		error(string.format("createTextureAtlas(): given dimensions too small (atlas area %d^2, imgs area %d^2)",
			math.sqrt(canvas_area), math.sqrt(area)))
	end

	local imgs_sorted = {}
	local imgs_sorted_count = 0
	for i,img in ipairs(imgs) do
		local img_w,img_h = img:getDimensions()

		-- we sort all images into imgs_sorted by decreasing height
		-- and store each entry as {img,width,height,original_index}
		local j = 1
		while true do
			if j > imgs_sorted_count then break end
			local entry = imgs_sorted[j]
			if entry[3] <= img_h then break end
			j = j + 1
		end
		imgs_sorted_count = imgs_sorted_count + 1
		local entry = {img,img_w,img_h, i}
		table.insert(imgs_sorted, j, entry)
	end

	love.graphics.origin()
	love.graphics.setShader()
	love.graphics.setColor(1,1,1,1)
	love.graphics.setDefaultFilter("nearest","nearest")
	love.graphics.setCanvas(canvas)

	-- the positions the textures will take on the atlas are stored here,
	-- each entry is {imgs_sorted_index, x, y}
	local positions = {}
	local levels = {} -- each entry is level_y, level_max_y, x_accumulate
	local levels_count = 0

	for i,v in ipairs(imgs_sorted) do
		local img_w,img_h = v[2],v[3]

		local added = false
		for j=1,levels_count do
			local L = levels[j]
			if L[3] + img_w <= w then
				love.graphics.draw(v[1], L[3], L[1])
				table.insert(positions, {i, L[3], L[1]})
				L[3] = L[3] + img_w
				added = true
				break
			end
		end

		if not added then
			local top_level = levels[levels_count]
			local y = 0
			if top_level then
				y = top_level[2] end
			levels_count = levels_count + 1
			levels[levels_count] = {y, y+img_h, img_w}
			love.graphics.draw(v[1], 0, y)
			table.insert(positions, {i, y, 0})
		end
	end

	local UVs = {}
	for i,v in ipairs(positions) do
		local sorted_i, x, y = v[1],v[2],v[3]
		local sorted_entry = imgs_sorted[sorted_i]
		local img_w, img_h = sorted_entry[2],sorted_entry[3]
		local og_i = sorted_entry[4]

		UVs[og_i] = { x    /w , y    /h ,
		              img_w/w , img_h/h }
	end

	love.graphics.setCanvas()

	return canvas, UVs
end

return createTextureAtlas
