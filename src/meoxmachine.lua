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

	hunger_v = 1.0,
	sleep_v  = 1.0,
	fun_v    = 0.5,

}
MeoxStateMachine.__index = MeoxStateMachine

function MeoxStateMachine:update(dt)
	for i,v in ipairs(self.active_states) do
		v:update(self)
	end

	self.hunger_v = self.hunger_v - dt/(3600 * 5)
	if self.hunger_v < 0.0 then self.hunger_v = 0.0 end
	if self.hunger_v > 1.0 then self.hunger_v = 1.0 end

	self.sleep_v = self.sleep_v - dt/(3600 * 12)
	if self.sleep_v < 0.0 then self.sleep_v = 0.0 end
	if self.sleep_v > 1.0 then self.sleep_v = 1.0 end

	self.fun_v = self.fun_v - dt/(3600 * 4)
	if self.fun_v < 0.0 then self.fun_v = 0.0 end
	if self.fun_v > 1.0 then self.fun_v = 1.0 end
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
			return
		end
	end
end

-- alias
function MeoxStateMachine:transitionState(from,to)
	self:deactivateState(from)
	self:activateState(to)
end

function MeoxStateMachine:add(s)
	for i,v in ipairs(self.active_states) do
		if s == v then return end
	end
	table.insert(self.active_states, s)
	s:enter(self)
end

function MeoxStateMachine:remove(s)
	for i,v in ipairs(self.active_states) do
		if s == v then 
			table.remove(self.active_states, i)
			s:leave(self)
			return
		end
	end
end

function MeoxStateMachine:getStateName(s)
	for i,v in pairs(self.states) do
		if v==s then return i end
	end
	error("")
end

local function chance(N)
	local rand = math.random()
	return rand < 1/N
end

function MeoxStateMachine:init()

	self.states["meox_blink"] =
		meoxstate:new({},
		function(self,machine) -- enter
			local rand = math.random()*0.222 + 0.666 -- random speed 0.666-0.888
			meoxanim.action:playAnimationByName("blink",0,rand,false,
				function()
					machine:deactivateState("meox_blink") -- exit blink state once animation finishes
				end)

		end,
		nil,nil--leave,update
		)

	local function do_a_blink()
		-- at least 0.4s between blinks
		if self.states.meox_blink:getDuration() < 0.4 then return end
		if chance(60*2.5) then -- avg 1 blink per 2.5 seconds
			self:activateState("meox_blink") end
	end

	self.states["meox_idle"] = 
		meoxstate:new({},
		function(self,machine) -- enter
		end,
		function(self,machine) -- leave
		end,
		function(self,machine) -- update
		end
		)

	local last_idle1_time = 0
	local last_idle2_time = 0
	local last_idle3_time = 0
	local last_idlesit_time = 0

	local idle_anim_name = "idle2"

-- meox_idle1
	self.states["meox_idle1"] =
		meoxstate:new({ self.states["meox_idle"] },

		function(self,machine) -- enter
			meoxanim.animator1:playAnimationByName("idle1",0,1,true)
		end,

		function(self,machine) -- leave
		end,

		function(self,machine) -- update
			local dt = love.timer.getDelta() -- step interp towards animation slot 1
			meoxanim.meoxi:setAnimationInterp(
			 meoxanim.meoxi:getAnimationInterp() - dt)

			-- random chance for an animation
			if machine.states.meox_idle1:getDuration() > 15.0 and chance(60*10) then
				local rand = math.random()
				if rand<0.5 then
					idle_anim_name = "idle2"
				else
					idle_anim_name = "idle3"
				end

				machine:transitionState("meox_idle1","meox_idle2")
				return
			end

			-- random chance to go to idlesit animation
			if machine.states.meox_idle1:getDuration() > 30.0 and chance(60*10) then
				machine:transitionState("meox_idle1","meox_idletosit")
			end

			do_a_blink()
		end
		)
-- meox_idle1

-- meox_idle2
	self.states["meox_idle2"] =
		meoxstate:new({ self.states["meox_idle"] },
		function(self,machine) -- enter
			meoxanim.animator2:playAnimationByName(idle_anim_name,0,1,false,
				-- on animation finish, switch back to idle1
				function()
					machine:transitionState("meox_idle2","meox_idle1")
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
-- meox_idle2
	
-- meox_idletosit
	self.states["meox_idletosit"] =
		meoxstate:new({ self.states["meox_idle"] },
		function(self,machine) -- enter
			meoxanim.animator1:playAnimationByName("idletosit",0,1,false,
				function()
					machine:transitionState("meox_idletosit","meox_idlesit")
				end)
		end,
		nil,nil--leave,update
		)
-- meox_idletosit

-- meox_sittoidle
	self.states["meox_sittoidle"] =
		meoxstate:new({ self.states["meox_idle"] },
		function(self,machine) -- enter
			meoxanim.animator1:playAnimationByName("sittoidle",0,1,false,
				function()
					machine:transitionState("meox_sittoidle","meox_idle1")
				end)
		end,
		nil,nil--leave,update
		)
-- meox_sittoidle

-- meox_idlesit
	self.states["meox_idlesit"] =
		meoxstate:new({ self.states["meox_idle"] },
		function(self,machine) -- enter
			meoxanim.animator1:playAnimationByName("idlesit",0,1,true)
		end,

		function(self,machine) -- leave
		end,

		function(self,machine) -- update
			local dt = love.timer.getDelta() -- step interp towards animation slot 1
			meoxanim.meoxi:setAnimationInterp(
			 meoxanim.meoxi:getAnimationInterp() - dt)

			-- random chance top return to idle1 animation, every 90 seconds+
			if machine.states.meox_idle1:getDuration() > 25.0 and chance(60*10) then
				machine:transitionState("meox_idlesit","meox_sittoidle")
				return
			end

			do_a_blink()
		end
		)
-- meox_idlesit

end

return MeoxStateMachine
