--local orthocam = require "orthocamera"
local camera = require "camera"

local meoxicon    = require "meoxicondef"
local meoxassets  = require "meoxassets"
local render      = require "render"

local camera_angles = require "cfg.camera_angles"
local menus         = require "cfg.menus"

local scene = require "scene"

require "props.meoxiconguientprops"
require "stack"
require "model"

local MeoxIcons = {

	camera = nil, -- ortho camera

	target_pos = camera_angles.icons_hide.pos,
	target_rot = camera_angles.icons_hide.rot,
	camera_interp_speed = 15,

	ref_size = 14,
	y_acc_start = -0.4,

	icon_defs = {},

	icon_stack = {},
	icon_gui_stack = {},

	selection_index = 1,

	hidden = true,
	curr_menu = nil

}
MeoxIcons.__index = MeoxIcons

local MeoxIconGUIEnt = {}
MeoxIconGUIEnt.__index = MeoxIconGUIEnt

function MeoxIconGUIEnt:new(props)
	local t = {
		props = MeoxIconGUIEntPropPrototype(props)
	}
	setmetatable(t, MeoxIconGUIEnt)
	return t
end


function MeoxIcons:fixSelectionIndex()
	if self.selection_index < 1 then self.selection_index = 1 end
	local s = #self.icon_stack
	if self.selection_index > s then self.selection_index = s end
end
function MeoxIcons:selectionMoveDown()
	self.selection_index = self.selection_index + 1
	if self.selection_index > #self.icon_stack then
		self.selection_index = 1 end
	self:fixSelectionIndex()
end
function MeoxIcons:selectionMoveUp()
	self.selection_index = self.selection_index - 1
	if self.selection_index < 1 then
		self.selection_index = #self.icon_stack end
	self:fixSelectionIndex()
end

function MeoxIcons:getGUIEntityIndexInStack(ent)
	local parent = ent.props.icongui_icon_parent
	for i,v in ipairs(self.icon_stack) do
		if v == parent then return i end
	end
	return nil
end

function MeoxIcons:update(dt)
	self:fixSelectionIndex()
	self:interpCameraPosition(dt)
	self.camera:update(dt)
	self:updateModels(dt)
end

function MeoxIcons:draw()
	render:setup3DCanvas()
	render:setup3DShader(false)

	self.camera:pushToShader()

	for i,v in ipairs(self.icon_gui_stack) do
		local model_i = v.props.icongui_model
		model_i:draw(nil, true)
	end

	render:dropShader()
	love.graphics.reset()
end

function MeoxIcons:show()
	self.hidden = false
	self.target_pos = camera_angles.icons_show.pos
	self.target_rot = camera_angles.icons_show.rot
	scene:setCameraAngle(camera_angles.menu_open)
end
function MeoxIcons:hide()
	self.hidden = true
	self.target_pos = camera_angles.icons_hide.pos
	self.target_rot = camera_angles.icons_hide.rot
	scene:setCameraAngle(camera_angles.default)
end

function MeoxIcons:click()
	if self.hidden then
		self:show()
		return
	end
	local icon = self.icon_stack[self.selection_index]
	icon:click()
end

function MeoxIcons:switchToMenu(name)
	self.curr_menu = name
	local menu = menus[name]
	if not menu then error("MeoxIcons:switchToMenu(): undefined menu") end

	for i,v in ipairs(self.icon_gui_stack) do
		v.props.icongui_delete = true
	end

	self.icon_stack = {} -- clear 
	for i,icon_name in ipairs(menu) do
		self:addIcon(icon_name, i)
	end
	self.selection_index = 1
end

function MeoxIcons:addIcon(def_name, index)
	local ic_def = self.icon_defs[def_name]
	if index then
		table.insert(self.icon_stack, index, ic_def)
	else
		table.insert(self.icon_stack, ic_def)
	end

	local model_i = ModelInstance:newInstance( ic_def.model )
	model_i.props.model_i_contour_flag = true
	model_i.props.model_i_outline_scale = 0.15
	--model_i:setPosition{0,3.25 * (index-1),0}
	--model_i:setRotation{0.2 * (index-2.1),0,0,"rot"}
	model_i:setScale{self.ref_size,self.ref_size,self.ref_size}
	local gui_ent = MeoxIconGUIEnt:new{
		icongui_model = model_i,
		icongui_icon_parent = ic_def,
		icongui_size = 0.1
	}

	if index then
		table.insert(self.icon_gui_stack, index, gui_ent)
	else
		table.insert(self.icon_gui_stack, gui_ent)
	end
end

function MeoxIcons:updateModels(dt)
	self:updateModelSizes(dt)
	self:updateModelPositions(dt)
	self:iconsFaceCamera()
	for i,v in ipairs(self.icon_gui_stack) do
		local col = v.props.icongui_model.props.model_i_colour

		--[[local meoxcolour = require 'meoxcolour'
		local hsl = meoxcolour.hsl
		local rgb = meoxcolour:hslToRgb{hsl[1],0.5,0.8}
		col[1]=rgb[1]
		col[2]=rgb[2]
		col[3]=rgb[3]--]]
	end
end

function MeoxIcons:iconsFaceCamera()
	for i,v in ipairs(self.icon_gui_stack) do
		local model_i = v.props.icongui_model

		local cam_pos = self.camera:getPosition()
		local mod_pos = model_i:getPosition()

		local dx =  cam_pos[1]-mod_pos[1]
		local dy = -cam_pos[2]+mod_pos[2]
		local dz =  cam_pos[3]-mod_pos[3]

		model_i:setRotation{dx,dy,dz,"dir"}

		model_i:modelMatrix()
	end
end

local function l_interp(a,b,I)
	return a*(1.0-I) + b*I
end

function MeoxIcons:updateModelSizes(dt)
	dt = dt * 8
	if dt > 1.0 then dt = 1.0 end

	for i,ent in ipairs(self.icon_gui_stack) do
		local stack_i = self:getGUIEntityIndexInStack(ent)

		local curr_size = ent.props.icongui_size
		-- if icon is not in current menu
		if not stack_i or ent.props.icongui_delete then -- shrink icon towards 0 (disappear) 
			ent.props.icongui_size = l_interp(curr_size, 0.0, math.min(dt*1.33,1.0))

		-- if icon is in current menu
		else -- make unselected icons smaller
			local select_diff = math.abs(self.selection_index - stack_i)
			local target_size = 1.0 - math.min(select_diff*0.05, 0.30)
			if select_diff ~= 0 then target_size = target_size - 0.3 end
			ent.props.icongui_size = l_interp(curr_size, target_size, dt)
		end
	end

	-- delete any icons that are small enough, make em disappear >:-))
	for i=#self.icon_gui_stack,1,-1 do
		local ent = self.icon_gui_stack[i]
		local stack_i = self:getGUIEntityIndexInStack(ent)
		local curr_size = ent.props.icongui_size
		if curr_size < 0.05 and (not stack_i or ent.props.icongui_delete) then
			table.remove(self.icon_gui_stack, i)
		end
	end
end

function MeoxIcons:updateModelPositions(dt)
	dt = dt * 8
	if dt > 1.0 then dt = 1.0 end
	self.y_acc_start = l_interp(self.y_acc_start, -0.8 * self.selection_index + 1.5, dt)

	--local y_acc = -0.4 * self.selection_index
	local y_acc = self.y_acc_start
	local icon_y_gap = 3.25
	local icon_size = self.ref_size

	for i,ent in ipairs(self.icon_gui_stack) do
		local size = ent.props.icongui_size
		local fs = icon_size * size

		local ent2 = self.icon_gui_stack[i+1]
		local size2 = size
		if ent2 then size2 = ent2.props.icongui_size end
		size = (size+size2)*0.5

		ent.props.icongui_model:setPosition{0,y_acc,0}
		ent.props.icongui_model:setScale{fs,fs,fs}
		y_acc = y_acc + icon_y_gap*size + 0.5
	end
end

function MeoxIcons:interpCameraPosition(dt)
	local camp,camr = self.camera:getPosition(), self.camera:getRotation()

	local tP = self.target_pos
	local tR = self.target_rot

	local pDx,pDy,pDz = tP[1]-camp[1], tP[2]-camp[2], tP[3]-camp[3]
	local pRx,pRy,pRz = tR[1]-camr[1], tR[2]-camr[2], tR[3]-camr[3]

	dt=dt*self.camera_interp_speed
	if dt>1.0 then dt=1.0 end

	local nx,ny,nz =
		camp[1]+pDx * dt,
		camp[2]+pDy * dt,
		camp[3]+pDz * dt
	self.camera:setPosition{nx,ny,nz}

	nx,ny,nz =
		camr[1]+pRx * dt*0.66,
		camr[2]+pRy * dt*0.66,
		camr[3]+pRz * dt*0.66
	self.camera:setRotation{nx,ny,nz}
end

return MeoxIcons
