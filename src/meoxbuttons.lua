local meoxassets = require "meoxassets"

local MeoxButtons = {

	state_l = "none", -- "none", "hover", "press", "held"
	state_m = "none",
	state_r = "none"

}
MeoxButtons.__index = MeoxButtons

function MeoxButtons:draw()
	--left button
	if self.state_l == "none" or self.state_l == "hover" then
		love.graphics.draw(meoxassets.button_l1_img,
		                   meoxassets.button_l_rect[1],
		                   meoxassets.button_l_rect[2])
	elseif self.state_l == "press" or self.state_l == "held" then
		love.graphics.draw(meoxassets.button_l2_img,
		                   meoxassets.button_l_rect[1],
		                   meoxassets.button_l_rect[2])
	end

	--middle button
	if self.state_m == "none" or self.state_m == "hover" then
		love.graphics.draw(meoxassets.button_m1_img,
		                   meoxassets.button_m_rect[1],
		                   meoxassets.button_m_rect[2])
	elseif self.state_m == "press" or self.state_m == "held" then
		love.graphics.draw(meoxassets.button_m2_img,
		                   meoxassets.button_m_rect[1],
		                   meoxassets.button_m_rect[2])
	end

	--right button
	if self.state_r == "none" or self.state_r == "hover" then
		love.graphics.draw(meoxassets.button_r1_img,
		                   meoxassets.button_r_rect[1],
		                   meoxassets.button_r_rect[2])
	elseif self.state_r == "press" or self.state_r == "held" then
		love.graphics.draw(meoxassets.button_r2_img,
		                   meoxassets.button_r_rect[1],
		                   meoxassets.button_r_rect[2])
	end
end

function MeoxButtons:update()
	local mx,my = love.mouse.getPosition()

	local function test_rect(r)
		return mx >= r[1] and
		       my >= r[2] and
					 mx <= r[1]+r[3] and
					 my <= r[2]+r[4]
	end

	if self.state_l == "press" then self.state_l = "held" end
	if self.state_m == "press" then self.state_m = "held" end
	if self.state_r == "press" then self.state_r = "held" end

	local l_h = test_rect(meoxassets.button_l_rect)
	local m_h = test_rect(meoxassets.button_m_rect)
	local r_h = test_rect(meoxassets.button_r_rect)

	-- lots of if statements but who cares xdd
	if scancodeIsDown("mouse1", CTRL.META) then
		if     l_h then self.state_l = "press" 
		elseif m_h then self.state_m = "press" 
		elseif r_h then self.state_r = "press" end
	elseif not scancodeIsHeld("mouse1", CTRL.META) then
		self.state_l = "none" 
		self.state_m = "none"
		self.state_r = "none"

		if     l_h then self.state_l = "hover" 
		elseif m_h then self.state_m = "hover" 
		elseif r_h then self.state_r = "hover" end
	end
end

function MeoxButtons:LDown()
	return self.state_l == "press" end
function MeoxButtons:MDown()
	return self.state_l == "press" end
function MeoxButtons:RDown()
	return self.state_l == "press" end

return MeoxButtons
