local scene       = require "scene"
local render      = require "render"
local assets      = require "assetloader"
local meoxcol     = require "meoxcolour"
local meoxanim    = require "meoxanim"
local meoxmachine = require "meoxmachine"
local meoxassets  = require "meoxassets"
local meoxbuttons = require "meoxbuttons"
local meoxsave = require 'meoxsave'
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
	scene:addModel(meoxassets.meoxi)

	meoxanim:init(meoxassets.meoxi)

	meoxcol:bindMaterial(meoxassets.meox.props.model_material)
	meoxcol:generateTexture()

	local anim1, anim2 = meoxassets.meoxi:getAnimator()
	anim1:staticAnimationByName("default")
	anim2:staticAnimationByName("default")

	meoxmachine:init()
	--meoxmachine:activateState("meox_idle1")

	meoxicons:init()
--	meoxicons:switchToMenu("main_menu")
	meoxicons:hide()

	meoxsave:readFromFile()
end

function Meox:update(dt)
	local cam_pos = scene.props.scene_camera.props.cam_position
	local cam_rot = scene.props.scene_camera.props.cam_rotation
	
	meoxbuttons:update(dt)
	meoxicons:update(dt)
	meoxmachine:update(dt)
	scene:update(dt)
	meoxanim:updateActionAnimation()

	if scancodeIsHeld("left", CTRL.META) then
		cam_rot[2] = cam_rot[2] - 1*dt
	end
	if scancodeIsHeld("right", CTRL.META) then
		cam_rot[2] = cam_rot[2] + 1*dt
	end
	if scancodeIsHeld("up", CTRL.META) then
		local sinT = math.sin(cam_rot[2])
		local cosT = math.cos(cam_rot[2])
		cam_pos[1] = cam_pos[1] + (sinT * 5*dt)
		cam_pos[3] = cam_pos[3] - (cosT * 5*dt)
	end
	if scancodeIsHeld("down", CTRL.META) then
		local sinT = math.sin(cam_rot[2])
		local cosT = math.cos(cam_rot[2])
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
end

function Meox:draw()
	scene:draw()
	meoxicons:draw()

	render:applyLCDEffect()
	render:blit3DCanvasToViewport()

	--love.graphics.setCanvas(render.viewport)
	local meoxcolour = require 'meoxcolour'
	local hsl = meoxcolour.hsl
	local rgb = meoxcolour:hslToRgb{hsl[1],hsl[2],math.max(hsl[3]*0.5+0.35,0.45)}
	love.graphics.setColor(rgb[1],rgb[2],rgb[3],1.0)
	love.graphics.draw(meoxassets.case_img,0,0,0,1,1)
	love.graphics.setColor(1,1,1,1)
	love.graphics.draw(meoxassets.caseh_img,0,0,0,1,1)
	if meoxicons.hidden and (meoxicons.curr_menu=="main_menu") then
		love.graphics.draw(meoxassets.hunger_i)
		love.graphics.draw(meoxassets.sleep_i)
		love.graphics.draw(meoxassets.fun_i)

		-- fun meter
		love.graphics.rectangle("line",38,78,82,20)
		love.graphics.rectangle("line",39,79,80,18)
		love.graphics.rectangle("fill",40,80,(meoxmachine.fun_v+1/79)*79,16)
		-- sleep meter
		love.graphics.rectangle("line",38,134,82,20)
		love.graphics.rectangle("line",39,135,80,18)
		love.graphics.rectangle("fill",40,136,(meoxmachine.sleep_v+1/79)*79,16)
		-- hunger meter
		love.graphics.rectangle("line",38,190,82,20)
		love.graphics.rectangle("line",39,191,80,18)
		love.graphics.rectangle("fill",40,192,(meoxmachine.hunger_v+1/79)*79,16)
	end

	meoxbuttons:draw()

end

function Meox:quit()
	local machine = meoxmachine
	local hsl = meoxcol.hsl

	local meoxsave = require 'meoxsave'
	meoxsave:saveToFile(machine, hsl)
end

return Meox
