--[[
-- extend lua's type() function
-- types can be specified in the __type field of a metatable
--]]

function kontype(x)
	local t = type(x)
	if t ~= "table" then
		return t
	end
	local mt = getmetatable(x)

	if mt then
		local typemt = mt.__type
		if typemt == nil then
			return t
		elseif type(typemt) == "function" then
			return typemt(x)
		elseif type(mt) == "table" then
			if mt.__type then
				return mt.__type
			end
			return kontype(mt)
		else
			return typemt
		end
	else
		return t
	end
end

function assert_type(x,datatype)
	if kontype(x)~=datatype then
		error(string.format("expected %s, got %s", datatype, kontype(x)),2)
	end
end
