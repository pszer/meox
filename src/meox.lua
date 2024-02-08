local scene       = require "scene"
local render      = require "render"
local assets      = require "assetloader"
local meoxcol     = require "meoxcolour"
local meoxanim    = require "meoxanim"
local meoxmachine = require "meoxmachine"
local meoxassets  = require "meoxassets"
local meoxbuttons = require "meoxbuttons"

local meoxicons   = require "meoxicons"
require "meoxiconsinit"

local camera_angles = require "cfg.camera_angles"

require "input"
require "math"

local Meox = {
}
Meox.__index = Meox

function Meox:load()
	meoxcol:init()

	assets:openModel("bowl.iqm")

	meoxassets:init()
	--local meox = Model:fromLoader("meox.iqm")
	--meoxi = ModelInstance:newInstance(meox)
	--meoxi.props.model_i_contour_flag = true
	scene:addModel(meoxassets.meoxi)
	--scene:addModel(meoxassets.iconi)

	meoxanim:init(meoxassets.meoxi)

	meoxcol:bindMaterial(meoxassets.meox.props.model_material)
	meoxcol:generateTexture()

	local anim1, anim2 = meoxassets.meoxi:getAnimator()
	anim1:staticAnimationByName("default")
	anim2:staticAnimationByName("default")

	meoxmachine:init()
	meoxmachine:activateState("meox_idle1")

	meoxicons:init()
	meoxicons:switchToMenu("main_menu")
	meoxicons:hide()
	--
end

function Meox:update(dt)
	local cam_pos = scene.props.scene_camera.props.cam_position
	local cam_rot = scene.props.scene_camera.props.cam_rotation
	
	meoxbuttons:update(dt)
	meoxicons:update(dt)
	scene:update(dt)
	meoxmachine:update(dt)
	meoxanim:updateActionAnimation()

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

	if scancodeIsDown("b", CTRL.META) then
		if meoxicons.target_pos == camera_angles.icons_show.pos then
			meoxicons.target_pos = camera_angles.icons_hide.pos
			meoxicons.target_rot = camera_angles.icons_hide.rot

			scene.target_pos = camera_angles.default.pos
			scene.target_rot = camera_angles.default.rot
		else
			meoxicons.target_pos = camera_angles.icons_show.pos
			meoxicons.target_rot = camera_angles.icons_show.rot

			scene.target_pos = camera_angles.menu_open.pos
			scene.target_rot = camera_angles.menu_open.rot
		end
	end

	if not meoxbuttons.locked then
		if meoxbuttons:LDown() then
			meoxicons:selectionMoveUp() end
		if meoxbuttons:RDown() then
			meoxicons:selectionMoveDown() end
		if meoxbuttons:MDown() then
			meoxicons:click() end
	end
	--scene.props.scene_camera:setPosition(cam_pos)
	--scene.props.scene_camera:setRotation(cam_rot)
end

function Meox:draw()
	scene:draw()
	meoxicons:draw()

	render:applyLCDEffect()
	render:blit3DCanvasToViewport()

	--love.graphics.setCanvas(render.viewport)
	love.graphics.draw(meoxassets.case_img,0,0,0,1,1)
	meoxbuttons:draw()
end

return Meox
