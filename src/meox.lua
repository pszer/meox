local scene   = require "scene"
local assets  = require "assetloader"
local meoxcol = require "meoxcolour"

require "input"
require "math"

local Meox = {
}
Meox.__index = Meox

function Meox:load()
	self.case_img = assets:getTextureReference("case.png")
	meoxcol:init()

	local meox = Model:fromLoader("meox.iqm")
	local meoxi = ModelInstance:newInstance(meox)
	meoxi.props.model_i_contour_flag = true
	scene:addModel(meoxi)

	meoxcol:bindMaterial(meox.props.model_material)
	meoxcol:generateTexture()
end

function Meox:update(dt)
	local cam_pos = scene.props.scene_camera.props.cam_position
	local cam_rot = scene.props.scene_camera.props.cam_rotation

	--[[meoxcol.hsl[1] = meoxcol.hsl[1] + dt*160.0
	if meoxcol.hsl[1] >= 360 then
		meoxcol.hsl[1] = 0.0
	end
	meoxcol:generateTexture()--]]

	if scancodeIsHeld("left", CTRL.META) then
		cam_rot[2] = cam_rot[2] - 1*dt
		--cam_pos[1] = cam_pos[1] - 5*dt
	end
	if scancodeIsHeld("right", CTRL.META) then
		cam_rot[2] = cam_rot[2] + 1*dt
		--cam_pos[1] = cam_pos[1] + 5*dt
	end
	if scancodeIsHeld("up", CTRL.META) then
		local sinT = math.sin(cam_rot[2])
		local cosT = math.cos(cam_rot[2])
		--cam_pos[3] = cam_pos[3] - 5*dt
		cam_pos[1] = cam_pos[1] + (sinT * 5*dt)
		cam_pos[3] = cam_pos[3] - (cosT * 5*dt)
	end
	if scancodeIsHeld("down", CTRL.META) then
		local sinT = math.sin(cam_rot[2])
		local cosT = math.cos(cam_rot[2])
		--cam_pos[3] = cam_pos[3] + 5*dt
		cam_pos[1] = cam_pos[1] - (sinT * 5*dt)
		cam_pos[3] = cam_pos[3] + (cosT * 5*dt)
	end
	if scancodeIsHeld("space", CTRL.META) then
		cam_pos[2] = cam_pos[2] - 5*dt
	end
	if scancodeIsHeld("lctrl", CTRL.META) then
		cam_pos[2] = cam_pos[2] + 5*dt
	end

	scene:update()
end

function Meox:draw()
	scene:draw()

	love.graphics.draw(self.case_img,0,0,0,1,1)
end

return Meox
