local MeoxSave = {}
MeoxSave.__index = MeoxSave

local serialise = require "serialise"

function MeoxSave:saveToFile(machine, col)
	local timestamp = os.time(os.date("!*t"))

	local save = {}

	save.hunger_v = machine.hunger_v
	save.sleep_v  = machine.sleep_v
	save.fun_v    = machine.fun_v
end

return MeoxSave
