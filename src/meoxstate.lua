local MeoxState = {}
MeoxState.__index = {}

function MeoxState:new(parents, enter, leave, update)
	local t = {
		parents = {},
		enter = enter,
		leave = leave,
		update = function(self,machine)
			for i,v in ipairs(self.parents) do
				v.update(self,machine)
			end
			update(self,machine)
		end
	}

	for i,v in ipairs(parents) do
		t.parents[i]=v
	end

	setmetatable(t, MeoxState)
end

return MeoxState
