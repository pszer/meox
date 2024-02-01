GFX_SETTINGS = {
	
	["shadow_map_size"] = { "medium" ,	
		default = "medium" , low = 1024  , medium = 1024*2 , high = 1024*4 , ultra = 1024*8 },
	["static_shadow_map_size"] = { "high" ,
		default = "medium" , low = 1024 , medium = 1024+2   , high = 1024*4 , ultra = 1024*8 },
	["enable_contour"] = { "enable" ,
		default = "enable" , enable = true, disable = false },
	["multithread_animation"] = { "disable", -- bad, keep disabled. 
		default = "enable" , enable = true, disable = false }

}

function gfxSetting( setting )
	local s = GFX_SETTINGS[setting]
	if s[1] then return s[s[1]] else
	return s[s.default] end
end

function gfxChangeSetting( setting , quality )
	local s = GFX_SETTINGS[setting]
	if not s then return end
	local possible,found = {"low","medium","high","ultra","enable","disable"},nil
	for i,v in ipairs(possible) do
		if quality==v then found=v break end
	end
	found=found or s.default
	s[1]=found
end
