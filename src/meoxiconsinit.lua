local meoxicon    = require "meoxicondef"
local meoxicons   = require "meoxicons"
local meoxmachine = require "meoxmachine"
local meoxbuttons = require "meoxbuttons"
local meoxassets  = require "meoxassets"
local camera      = require "camera"

local meoxcolour  = require "meoxcolour"

local camera_angles = require "cfg.camera_angles"

function meoxicons:init()
	self.camera = camera:new{
	}
	self.camera:setPosition(camera_angles.icons_hide.pos)
	self.camera:setRotation(camera_angles.icons_hide.rot)

	self.icon_defs["sleep"] = meoxicon:new(meoxassets.icon_sleep,
		function()
		end)
	self.icon_defs["eat"] = meoxicon:new(meoxassets.icon_eat,
		function()
			meoxmachine:transitionState("meox_idle", "meox_eat")
			self:switchToMenu("eat_menu")
		end)
	self.icon_defs["pet"] = meoxicon:new(meoxassets.icon_pet,
		function()
			meoxmachine:transitionState("meox_idle", "meox_pet")
			self:switchToMenu("pet_menu")
		end)
	self.icon_defs["misc"] = meoxicon:new(meoxassets.icon_misc,
		function()
			self:switchToMenu("colour_menu")
		end)
	self.icon_defs["back_main"] = meoxicon:new(meoxassets.icon_back,
		function()
			self:hide()
		end)

	self.icon_defs["back_t1"] = meoxicon:new(meoxassets.icon_back,
		function()
			self:switchToMenu("main_menu")
		end)
	self.icon_defs["back_t2"] = meoxicon:new(meoxassets.icon_back,
		function()
			self:switchToMenu("main_menu")
		end)
	self.icon_defs["back_t3"] = meoxicon:new(meoxassets.icon_back,
		function()
			self:switchToMenu("main_menu")
		end)
	self.icon_defs["back_t4"] = meoxicon:new(meoxassets.icon_back,
		function()
			self:switchToMenu("main_menu")
		end)


	self.icon_defs["colour_back"] = meoxicon:new(meoxassets.icon_back,
		function()
			self:switchToMenu("main_menu")
		end)
	self.icon_defs["hueplus"] = meoxicon:new(meoxassets.icon_hueplus,
		function() meoxcolour:huePlus() end)
	self.icon_defs["hueminus"] = meoxicon:new(meoxassets.icon_hueminus,
		function() meoxcolour:hueMinus() end)
	self.icon_defs["satplus"] = meoxicon:new(meoxassets.icon_satplus,
		function() meoxcolour:satPlus() end)
	self.icon_defs["satminus"] = meoxicon:new(meoxassets.icon_satminus,
		function() meoxcolour:satMinus() end)
	self.icon_defs["lumplus"] = meoxicon:new(meoxassets.icon_lumplus,
		function() meoxcolour:lumPlus() end)
	self.icon_defs["lumminus"] = meoxicon:new(meoxassets.icon_lumminus,
		function() meoxcolour:lumMinus() end)

	self.icon_defs["pet_back"] = meoxicon:new(meoxassets.icon_back,
		function()
			meoxmachine:transitionState("meox_pet","meox_idle1")
			self:switchToMenu("main_menu")
		end)
end
