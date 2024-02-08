require "props.sceneprops"

local render = require "render"
local camera = require "camera"
local model  = require "model"

local camera_angles = require "cfg.camera_angles"

local Scene = {
	props = ScenePropPrototype{
		--scene_background = {0.084,0.212,0.217,1.0},
		--
		--scene_background = {0.612, 0.38, 0.282},
		scene_background2 = {0.878, 0.745, 0.686},
		scene_background1 = {0.878, 0.573, 0.525},

		--scene_background = {0.431,0.671,0.651,1.0},
		scene_camera = camera:new{
			cam_position  = {-2.240,-5.001,10.441},
			--cam_direction = {0.0,0.0,-1.0},
			cam_rotation  = {-0.1,0.38,0.00},
		},
		scene_models = {
		},
		scene_camera_interp_speed = 12
	},

	target_pos = camera_angles.default.pos,
	target_rot = camera_angles.default.rot,
}
Scene.__index = Scene

function Scene:update(dt)
	self:interpCameraPosition(dt)
	self.props.scene_camera:update(dt)
	self:updateModels()
	-- print("pos:", unpack(self.props.scene_camera.props.cam_position))
	-- print("rot:", unpack(self.props.scene_camera.props.cam_rotation))
end

function Scene:setCameraAngle(pos, rot)
	if rot == nil then
		self:setCameraAngle(pos.pos, pos.rot)
		return
	end

	self.target_pos = pos
	self.target_rot = rot
end

function Scene:interpCameraPosition(dt)
	local camp,camr = self.props.scene_camera:getPosition(), self.props.scene_camera:getRotation()

	local tP = self.target_pos
	local tR = self.target_rot

	local pDx,pDy,pDz = tP[1]-camp[1], tP[2]-camp[2], tP[3]-camp[3]
	local pRx,pRy,pRz = tR[1]-camr[1], tR[2]-camr[2], tR[3]-camr[3]

	dt=dt*self.props.scene_camera_interp_speed
	if dt>1.0 then dt=1.0 end

	local nx,ny,nz =
		camp[1]+pDx * dt,
		camp[2]+pDy * dt,
		camp[3]+pDz * dt
	self.props.scene_camera:setPosition{nx,ny,nz}

	nx,ny,nz =
		camr[1]+pRx * dt*0.66,
		camr[2]+pRy * dt*0.66,
		camr[3]+pRz * dt*0.66
	self.props.scene_camera:setRotation{nx,ny,nz}

end

function Scene:updateModels()
	for i,mod in ipairs(self.props.scene_models) do
		mod:modelMatrix()
		mod:updateAnimation()
	end
end

function Scene:draw()
	love.graphics.reset()

	render:setup3DCanvas()
	love.graphics.clear(false,true,true)

	local bg_col1 = self.props.scene_background1
	local bg_col2 = self.props.scene_background2
	local bg_shader = render.shader_background

	local vw,vh = render.viewport3d:getDimensions()

	love.graphics.clear(false,true,true)

	love.graphics.setShader(bg_shader.shader)
	bg_shader.shader:sendColor("col1", bg_col1)
	bg_shader.shader:sendColor("col2", bg_col2)
	love.graphics.draw(render.nil_texture)

	render:setup3DShader()
	self.props.scene_camera:pushToShader()
	self:drawModels()

	love.graphics.reset()
end

function Scene:addModel(model)
	local mods = self.props.scene_models
	for i,v in ipairs(mods) do
		if v==model then return end end
	table.insert(mods, model)
end
function Scene:removeModel(model)
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
