local meox = require "meox"
local assets = require "assetloader"

require "gamestate"

local LoadingScreen = {}
LoadingScreen.__index = LoadingScreen

function LoadingScreen:load()
	self.splash = love.graphics.newImage("img/splash.png")

	local model_atts = require "cfg.model_attributes"
	local tex_atts = require "cfg.texture_attributes"

	for name,v in pairs(model_atts) do
		assets:openModel(name) end
	for name,v in pairs(tex_atts) do
		assets:openTexture(name) end
end
function LoadingScreen:update(dt)
	if assets:finished() then
		SET_GAMESTATE(meox)		
	end
end
function LoadingScreen:draw()
	love.graphics.draw(self.splash)
end

return LoadingScreen
