local MeoxIcon = {

}
MeoxIcon.__index = MeoxIcon

function MeoxIcon:new(model, func)
	local t = {
		model = model,
		func  = func
	}

	setmetatable(t, MeoxIcon)
	return t
end

function MeoxIcon:click()
	self.func()
end

return MeoxIcon
