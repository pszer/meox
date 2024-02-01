-- i once programmed without having something to manage shader uniforms
-- never again
--

local Shader = {__type="shaderobj"}
Shader.__index = Shader

-- takes in a love2d shader and table as argument
-- each key is a uniform values identifier, with the value being the uniforms default value
function Shader:new(sh, uniforms)
	assert(sh)
	local t = {
		shader = sh,
		vals     = {},
		defaults = {},
		keys     = {},
		is_array = {}
	}

	local count = 1
	for i,v in pairs(uniforms) do
		-- the way sending an array to a shader works using shader:send()
		-- is shader:send(name, value1, value2, value3, ...)
		-- determine in v is an array and if so, unpack it into the send() function
		local is_array = false
		local v_type = type(v)
		if v_type=="table" then
			local v1_type = type(v[1])
			if v1_type=="table" then
				is_array = true
			end
		end
		if not is_array then
			t.shader:send(i,v)
		else
			t.shader:send(i,unpack(v))
		end

		t.vals[i]     = v
		t.defaults[i] = v
		t.is_array[i] = is_array

		t.keys[count] = i
		count = count+1
	end

	setmetatable(t, Shader)
	t:default()
	return t
end

function Shader:send(name, value)
	--if self.vals[name]==value then return end -- ignore resending an identical value
	self.shader:send(name, value)
end

function Shader:sendArray(name, array)
	self.shader:send(name, unpack(array))
end

function Shader:set()
	love.graphics.setShader(self.shader)
end

function Shader:default(name)
	local all = name==nil
	if all then
		for i,uniform in ipairs(self.keys) do
			print("uniform = \'" .. uniform .. "\'")
			self:default(uniform)
		end
		return
	end

	local default_val = self.defaults[name]
	local is_array = self.is_array[name]
	local uniform = name
	
	if not is_array then
		self.shader:send(uniform, default_val)
	else
		self.shader:send(uniform, unpack(default_val))
	end
end

function Shader:reset()
	self:default(nil)
end

return Shader
