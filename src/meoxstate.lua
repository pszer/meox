local MeoxState = {}
MeoxState.__index = MeoxState

function MeoxState:new(parents, enter, leave, update)
	local t = {
		parents = {},
		enter = function(self,machine)
			self.entry_time = love.timer.getTime()
			for i,v in ipairs(self.parents) do
				if v.enter then
					v.enter(v,machine)
				end
			end
			if enter then
				enter(self,machine)
			end
		end,
		leave = function(self,machine)
			for i,v in ipairs(self.parents) do
				if v.leave then
					v.leave(v,machine)
				end
			end
			if leave then
				leave(self,machine)
			end
		end,
		update = function(self,machine)
			for i,v in ipairs(self.parents) do
				if v.update then
					v.update(v,machine)
				end
			end
			if update then
				update(self,machine)
			end
		end,
		entry_time = 0
	}

	for i,v in ipairs(parents) do
		t.parents[i]=v
	end

	setmetatable(t, MeoxState)
	return t
end

function MeoxState:getTimeEntered()
	return self.entry_time or 0
end
function MeoxState:getDuration()
	local t = self.entry_time
	if not t then return 0 end
	return love.timer.getTime() - t
end

return MeoxState
