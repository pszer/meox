local scene = require "scene"
local assets = require "assetloader"
require "input"
require "math"

local Meox = {

}
Meox.__index = Meox

function Meox:load()
	self.case_img = assets:getTextureReference("case.png")
end

function Meox:update(dt)
	local cam_pos = scene.props.scene_camera.props.cam_position
	local cam_rot = scene.props.scene_camera.props.cam_rotation

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
