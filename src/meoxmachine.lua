--[[
-- meox state machine
--]]

local meoxanim  = require "meoxanim"
local meoxstate = require "meoxstate"

local MeoxStateMachine = {

	model = nil,
	colour = nil,

	states = {},
	active_states = {},

	hunger = 1.0,
	sleep  = 1.0,
	fun    = 0.5,

}
MeoxStateMachine.__index = MeoxStateMachine

function MeoxStateMachine:update()
	for i,v in ipairs(self.active_states) do
		v:update(self)
	end
end

function MeoxStateMachine:activateState(state_name)
	local s = self.states[state_name]
	if not s then error("MeoxStateMachine:activateState(): non-existant state") end
	for i,v in ipairs(self.active_states) do
		if s == v then return end
	end
	table.insert(self.active_states, s)
	s:enter(self)
end

function MeoxStateMachine:deactivateState(state_name)
	local s = self.states[state_name]
	if not s then error("MeoxStateMachnue:deactivateState(): non-existant state") end
	for i,v in ipairs(self.active_states) do
		if s == v then
			table.remove(self.active_states, i)
			s:leave(self)
		end
	end
end

function MeoxStateMachine:init()

	local last_blink_time = 0
	self.states["meox_blink"] =
		meoxstate:new({},
		function(self,machine) -- enter
			local rand = math.random()*0.222 + 0.666 -- random speed 0.666-0.888
			last_blink_time = love.timer.getTime()
			meoxanim.action:playAnimationByName("blink",0,rand,false,
				function()
					machine:deactivateState("meox_blink") -- exit blink state once animation finishes
				end)
		end,
		function(self,machine) -- leave
		end,
		function(self,machine) -- update
		end
		)

	local function do_a_blink()
		-- at least 0.4s between blinks
		if love.timer.getTime() - last_blink_time < 0.4 then return end
		local rand = math.random()
		if rand < 1/(60*2.5) then -- avg 1 blink per 2.5 seconds
			self:activateState("meox_blink") end
	end

	local last_idle2_time = 0
	self.states["meox_idle1"] =
		meoxstate:new({},
		function(self,machine) -- enter
			meoxanim.animator1:playAnimationByName("idle1",0,1,true)
		end,

		function(self,machine) -- leave
		end,

		function(self,machine) -- update
			local dt = love.timer.getDelta() -- step interp towards animation slot 1
			meoxanim.meoxi:setAnimationInterp(
			 meoxanim.meoxi:getAnimationInterp() - dt
			)

			-- random chance for an idle2 animation, every 20 seconds+
			local time = love.timer.getTime()

			if time - last_idle2_time > 20.0 then
				local rand = math.random()
				if rand < 1/(60*20) then
					machine:activateState("meox_idle2")
					machine:deactivateState("meox_idle1")
					return
				end
			end

			do_a_blink()
		end
		)

	self.states["meox_idle2"] =
		meoxstate:new({},
		function(self,machine) -- enter
			last_idle2_time = love.timer.getTime()
			meoxanim.animator2:playAnimationByName("idle2",0,1,false,
				-- on animation finish, switch back to idle1
				function()
					machine:activateState("meox_idle1")
					machine:deactivateState("meox_idle2")
					return
				end
			)
		end,

		function(self,machine) -- leave
		end,

		function(self,machine) -- update
			local dt = love.timer.getDelta() -- step interp towards animation slot 2
			meoxanim.meoxi:setAnimationInterp(
			 meoxanim.meoxi:getAnimationInterp() + dt*2.0
			)

			do_a_blink()
		end
		)

end

return MeoxStateMachine
