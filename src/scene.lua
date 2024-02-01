require "props.sceneprops"

local render = require "render"
local camera = require "camera"
local model  = require "model"

local Scene = {
	props = ScenePropPrototype{
		scene_background = {0.084,0.212,0.217,1.0},
		scene_camera = camera:new{
			cam_position  = {0.0,0.0,20.0},
			--cam_direction = {0.0,0.0,-1.0},
			cam_rotation  = {0.00,0.00,0.00},
		},
		scene_models = {
		}
	}
}
Scene.__index = Scene

function Scene:update(dt)
	self.props.scene_camera:update(dt)
end

function Scene:draw()
	render:setup3DCanvas()

	local bg_col = self.props.scene_background
	local r,g,b = love.math.linearToGamma(bg_col[1], bg_col[2], bg_col[3])
	--local r,g,b = bg_col[1], bg_col[2], bg_col[3]
	love.graphics.clear(r,g,b)

	render:setup3DShader()
	self.props.scene_camera:pushToShader()
	self:drawModels()

	render:dropShader()
	love.graphics.reset()

	-- apply the faux-lcd screen filter
	love.graphics.setCanvas(render.viewport3d_buffer)
	
	local w,h = render.viewport3d_buffer:getDimensions()
	render.shader_screen_filter:set()
	render.shader_screen_filter:send("texture_size",{w,h})

	love.graphics.draw(render.viewport3d)
	render:swapViewport3DBuffer()
	render:dropShader()

	render:blit3DCanvasToViewport()
end

function Scene:addModel(model)
	local mods = self.props.scene_models
	for i,v in ipairs(mods) do
		if v==model then return end end
	table.insert(mods, model)
end
function Scene:deleteModel(model)
	local mods = self.props.scene_models
	for i,v in ipairs(mods) do
		if v==model then
			table.remove(mods, i)
			return
		end
	end
end

function Scene:drawModels()
	for i,mod in ipairs(self.props.scene_models) do
		mod:draw(nil, true)
	end
end

return Scene
