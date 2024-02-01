-- stack implementation
--
--

require "table"

local __stack = {}
__stack.__index = __stack

function newStack()
	local this = {}
	this[0] = 0
	setmetatable(this, __stack)
	return this
end

function __stack:empty()
	return self[0] == 0
end

function __stack:clear( destructor )
	local destructor = destructor or function() end
	for i,v in ipairs(self) do
		destructor(v)
		self[i] = nil
	end
	self[0] = 0
end

function __stack:peek()
	if self:empty() then return nil end	
	return self[self[0]]
end

function __stack:push( obj )
	self[0] = self[0]+1
	self[self[0]] = obj
end

function __stack:pop( )
	if self:empty() then return nil end	
	local obj = self[self[0]]
	self[0] = self[0] - 1
	return obj
end

function __stack:count()
	return self[0]
end

-- queue implementation
--
--
local __queue = {}
__queue.__index = __queue

function newQueue()
	local this = {}
	this[0] = 0
	setmetatable(this, __queue)
	return this
end

function __queue:empty()
	return self[0] == 0
end

function __queue:clear( destructor )
	local destructor = destructor or function() end
	for i,v in ipairs(self) do
		destructor(v)
		self[i] = nil
	end
	self[0] = 0
end

function __queue:peek()
	if self:empty() then return nil end	
	return self[1]
end

function __queue:push( obj )
	self[0] = self[0]+1
	self[self[0]] = obj
end

function __queue:pop( )
	if self:empty() then return nil end	
	local obj = self[1]
	table.remove(self, 1)
	self[0] = self[0] - 1
	return obj
end

function __queue:count()
	return self[0]
end
