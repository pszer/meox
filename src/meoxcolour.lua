local assets = require "assetloader"

local MeoxCol = {
	hsl = {
		0.516*360,
		0.259,
		0.720,
	},

	col_tex = love.graphics.newCanvas(128,128),
	lum_tex = love.graphics.newCanvas(1024,1024),
	lum_base = nil,
	lum_mask = nil,
}
MeoxCol.__index = {}

function MeoxCol:init()
	self.lum_base = assets:getTextureReference("meoxtexture@val.png")
	self.lum_mask = assets:getTextureReference("meoxmask.png")
end

-- Function to convert RGB to HSL
function MeoxCol:rgbToHsl(rgbColor)
	local Cmax = math.max(rgbColor[1], rgbColor[2], rgbColor[3])
	local Cmin = math.min(rgbColor[1], rgbColor[2], rgbColor[3])
	local delta = Cmax - Cmin

	local hue = 0.0
	if delta > 0.0 then
		if Cmax == rgbColor[1] then
				hue = ((rgbColor[2] - rgbColor[3]) / delta) % 6.0
		elseif Cmax == rgbColor.g then
				hue = ((rgbColor[3] - rgbColor[1]) / delta) + 2.0
		else
				hue = ((rgbColor[1] - rgbColor[2]) / delta) + 4.0
		end
		hue = hue * 60.0
	end

	local lightness = (Cmax + Cmin) / 2.0

	local saturation = 0.0
	if lightness > 0.0 and lightness < 1.0 then
		saturation = delta / (1.0 - math.abs(2.0 * lightness - 1.0))
	end

	return {hue, saturation, lightness}
end

-- Function to convert HSL to RGB
function MeoxCol:hslToRgb(hslColor)
	local C = (1.0 - math.abs(2.0 * hslColor[3] - 1.0)) * hslColor[2]
	local X = C * (1.0 - math.abs((hslColor[1] / 60.0) % 2.0 - 1.0))
	local m = hslColor[3] - C / 2.0

	local rgbColor

	if hslColor[1] >= 0.0 and hslColor[1] < 60.0 then
		rgbColor = {C, X, 0.0}
	elseif hslColor[1] >= 60.0 and hslColor[1] < 120.0 then
		rgbColor = {X, C, 0.0}
	elseif hslColor[1] >= 120.0 and hslColor[1] < 180.0 then
		rgbColor = {0.0, C, X}
	elseif hslColor[1] >= 180.0 and hslColor[1] < 240.0 then
		rgbColor = {0.0, X, C}
	elseif hslColor[1] >= 240.0 and hslColor[1] < 300.0 then
		rgbColor = {X, 0.0, C}
	else
		rgbColor = {C, 0.0, X}
	end

	for i = 1, 3 do
		rgbColor[i] = rgbColor[i] + m
	end

	return rgbColor
end

function MeoxCol:setHSV(hsv)
	self.hsv[1] = hsv[1]
	self.hsv[2] = hsv[2]
	self.hsv[3] = hsv[3]
end

function MeoxCol:generateColorTexture()
	love.graphics.reset()
	love.graphics.setCanvas(self.col_tex)

	local hsl = self.hsl
	local rgb = self:hslToRgb{hsl[1],hsl[2],0.5}
	love.graphics.clear(rgb[1],rgb[2],rgb[3],1.0)
	love.graphics.setCanvas()
end

function MeoxCol:generateValueTexture()
	love.graphics.reset()
	love.graphics.setCanvas(self.lum_tex)

	love.graphics.draw(self.lum_base)
	local L = self.hsl[3]
	love.graphics.setColor(L,L,L,1.0)
	love.graphics.draw(self.lum_mask)
	love.graphics.setColor(1,1,1)
	love.graphics.setCanvas()
end

function MeoxCol:generateTexture()
	self:generateColorTexture()
	self:generateValueTexture()
end

function MeoxCol:bindMaterial(material)
	material:setMaterial("colour",self.col_tex,{})
	material:setMaterial("value",self.lum_tex,{})
end

return MeoxCol
