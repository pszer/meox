-- functions for loading and getting textures
--
--
--
--
--
--
--
--
--
-- unused legacy code, can be safely removed
--
--
--
--
--
--
--
--
--
--

require "props.textureprops"
require "string"
require "tick"

require "math"

Texture = {__type = "texture"}
Texture.__index = Texture

local tex_attributes = require "cfg.texture_attributes"

function Texture:new(props)
	local this = {
		props = TexturePropPrototype(props),
	}

	setmetatable(this,Texture)
	this.props.texture_sequence_length = #this.props.texture_sequence
	this.props.texture_width = this.props.texture_imgs[1]:getWidth()
	this.props.texture_height = this.props.texture_imgs[1]:getHeight()

	local merge,x,y = Textures.mergeTextures(this.props.texture_imgs)
	this.props.texture_merged_img = merge
	this.props.texture_merged_dim_x = x
	this.props.texture_merged_dim_y = x

	return this
end

function Texture:getImage(frame)
	if not self.props.texture_animated then
		return self.props.texture_imgs[1]
	else
		if frame then
			return self.props.texture_imgs[frame]
		end

		--local props = self.props
		--local tick = getTick()

		--local anim_delay = props.texture_animation_delay
		--local anim_length = props.texture_sequence_length * props.texture_animation_delay
		--local anim_frame = math.floor((tick%anim_length)/anim_delay) + 1

		--local f = props.texture_sequence[anim_frame]

		--return props.texture_imgs[f]
		return self.props.texture_merged_img
	end
end

function Texture:getAnimationFrame()
	if not self.props.texture_animated then
		return 1
	end

	local props = self.props
	local tick = getTick()

	local anim_delay = props.texture_animation_delay
	local anim_length = props.texture_sequence_length * props.texture_animation_delay
	local anim_frame = math.floor((tick%anim_length)/anim_delay) + 1

	local f = props.texture_sequence[anim_frame]
	return f
end

-- checks if texture exists, if it does
-- calls love.graphics.newImage() along with
-- setting desired texture attributes
function Texture.openImage(f)
	local finfo = love.filesystem.getInfo(f)
	if not finfo or finfo.type ~= "file" then return nil end

	local img = love.graphics.newImage(f, {linear=false})
	if not img then return nil end

	img:setWrap("repeat","repeat")

	return img
end

function Texture:animationChangesThisTick()
	if not self.props.texture_animated then return false end

	local delay = self.props.texture_animation_delay
	if getTick() % delay == 0 and tickChanged() then return true end
	return false
end

function Texture:release()
	for i,v in ipairs(self.props.texture_imgs) do
		v:release()
	end
	if self.props.texture_merged_img then
		self.props.texture_merged_img:release() end
end

function Texture:getWidth()
	return self.props.texture_width
end
function Texture:getHeight()
	return self.props.texture_height
end
