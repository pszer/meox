require "texture"

Textures = {
	loaded = {},
	missing_texture = nil
}
Textures.__index = Textures

local tex_attributes = require "cfg.texture_attributes"

function Textures.queryTexture(fname)
	local tex = Textures.loaded[fname]
	if tex then
		return tex
	else
		return Textures.missing_texture
	end
end

function Textures.isTextureLoaded(fname)
	return Textures.loaded[fname] ~= nil
end

function Textures.loadTexture(fname)
	if Textures.isTextureLoaded(fname) then return Textures.queryTexture(fname) end -- do nothing if already loaded

	local attributes = tex_attributes[fname] or {}
	local tex = Textures.openFilename(fname, attributes)
	if tex then Textures.loaded[fname] = tex end
	return tex
end

function Textures.openFilename(filename, attributes)
	if not attributes then attributes = tex_attributes[filename] or {} end

	local fpath = "img/" .. filename

	local img = Texture.openImage(fpath)
	if img then

		local props

		--cubemap
		if attributes.texture_type == "cube" then
			img = love.graphics.newCubeImage(fpath, {mipmaps = true, linear = false})

			props = {
				texture_name = filename,
				texture_imgs = {img},
				texture_frames  = 1,
				texture_animated = false,
				texture_type = "cube"
			}
		else
			-- non animated texture
			props = {
				texture_name = filename,
				texture_imgs = {img},
				texture_frames  = 1,
				texture_animated = false,
				texture_type = "2d"
			}
		end

		for i,v in pairs(attributes) do props[i]=v end
		return Texture:new(props)
	else
		-- check if animated texture

		-- first, we get a filepath without a file extension
		-- and have a copy of the file extension itself
		local extension_i = string.find(fpath, "%.")
		-- if no file extension, return nil
		if not extension_i then return nil end

		local fpathsub = string.sub(fpath, 1,extension_i-1)
		local fpathext = string.sub(fpath, extension_i,-1)

		local frames = {}
		local sequence = {}
		local i = 1
		local exists = false

		while true do
			local anim_path = fpathsub .. tostring(i) .. fpathext

			local img = Texture.openImage(anim_path)

			if img then
				exists = true
				frames[i] = img
				sequence[i] = i
				i = i + 1
			else
				break
			end
		end

		if exists then
			local props = {
				texture_name = filename,
				texture_imgs = frames,
				texture_frames  = i-1,
				texture_animated = true,
				texture_sequence = sequence,
				texture_type = "2d"
			}
			for i,v in pairs(attributes) do props[i]=v end
			return Texture:new(props)
		else
			-- texture at filename doesn`t exist
			return nil
		end

	end
end

-- returns an image with all the textures on one texture and
-- a table with texture coordinates for each entry in argument <--- removed
-- returns how many images are put side by side in the x direction and y direction
--
-- the textures in the argument are expected to be raw love2d images
function Textures.mergeTextures(textures)
	local count = #textures

	if count==1 then
		--return textures[1], {{0,0},{1,0},{1,1},{0,1}}
		return textures[1], 1, 1
	end

	if count == 0 then return nil, nil end
	local square_side = math.ceil(math.sqrt(count))

	local max_w,max_h = 0,0
	-- find biggest texture width and height
	for i = 1, count do
		local tex = textures[i]
		local w,h = tex:getWidth(), tex:getHeight()

		if w > max_w then max_w = w end
		if h > max_h then max_h = h end
	end

	local canvas = love.graphics.newCanvas(max_w * square_side, max_h * square_side, {type="2d"})
	love.graphics.push("all")
	love.graphics.reset()
	love.graphics.setCanvas(canvas)

	local texcoords_table = {}

	local coordstep = 1/square_side

	local x,y = 1,1
	for i = 1,count do

		local tx,ty = x-1, y-1

		local drawx,drawy = tx*max_w, ty*max_h

		love.graphics.draw(textures[i], drawx, drawy)

		texcoords_table[i] = {}

		texcoords_table[i][1] = {tx*coordstep,ty*coordstep}
		texcoords_table[i][2] = {(tx+1)*coordstep,ty*coordstep}
		texcoords_table[i][3] = {(tx+1)*coordstep,(ty+1)*coordstep}
		texcoords_table[i][4] = {tx*coordstep,(ty+1)*coordstep}
		
		x=x+1
		if  x>square_side then
			x=1
			y=y+1
		end
	end

	love.graphics.setCanvas()
	love.graphics.pop()
	--return love.graphics.newImage(canvas:newImageData()), texcoords_table
	return love.graphics.newImage(canvas:newImageData()), square_side, square_side
end

function Textures.generateMissingTexture()
	local canvas = love.graphics.newCanvas(16,16,{type="2d"})

	love.graphics.push("all")
	love.graphics.reset()
	love.graphics.setCanvas(canvas)

	love.graphics.clear(1,0,1,1)
	love.graphics.setColor(0,0,0,1)
	for y = 0,14,2 do
		for x = 0,16,4 do
			love.graphics.rectangle("fill",x+y%4,y,2,2)
		end
	end

	love.graphics.setCanvas()
	love.graphics.pop()

	local tex = Texture:new{
		texture_name = "missing",
		texture_imgs = {love.graphics.newImage(canvas:newImageData())},
		}
	Textures.missing_texture = tex
end
