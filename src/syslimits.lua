require "math"
require "string"
local limit = {}
-- returns x,y dimensions for maximum canvas/texture size
function limit.maxTextureSize()
	local l = love.graphics.getSystemLimits()
	local s = l.texturesize
	return s,s
end

-- returns x,y dimensions clamped to the maximum supported texture
-- size
function limit.clampTextureSize(w,h)
	local h = h or w
	local max_w, max_h = limit.maxTextureSize()
	return math.min(max_w, w), math.min(max_h, h)
end

function limit.sysInfoString()
 	local major, minor, revision, codename = love.getVersion( )
	local version_str = string.format("Version %d.%d.%d - %s", major, minor, revision, codename)

	local name, version, vendor, device = love.graphics.getRendererInfo( )
	local system_str = string.format("%s (%s), %s %s", device, vendor, version, name)

	return version_str .. "\n" .. system_str
end

return limit
