local shader = require "shader"

local Render = {
	viewport = nil,
	viewport3d = nil,
	viewport3d_depth = nil,
	shader3d   = nil,
	shader_gamma = nil,
	shader_screen_filter = nil,
	shader_background = nil,

	nil_texture = nil
}

function Render:init()
	local w,h = love.graphics.getDimensions()

	self.nil_texture = love.graphics.newCanvas(w/2,h/2)
	self.viewport   = love.graphics.newCanvas(w,h, {format="rgba16f"})

	self.viewportgui = love.graphics.newCanvas(w,h, {format="rgba8"})

	self.viewport3d = love.graphics.newCanvas(w/2,h/2, {format="rgba16f"})
	self.viewport3d:setFilter("nearest","nearest")

	self.viewport3d_buffer = love.graphics.newCanvas(w/2,h/2, {format="rgba16f"})
	self.viewport3d_buffer:setFilter("nearest","nearest")

	self.viewport3d_depth = love.graphics.newCanvas(w/2,h/2, {format="depth24stencil8"})

	self.shader3d = shader:new(
		love.graphics.newShader("glsl/3d.glsl","glsl/3d.glsl"),
		{u_light={1.0,1.0,1.0},u_enable_shadows=true})

	self.shader_gamma = shader:new(
		love.graphics.newShader("glsl/gamma.glsl","glsl/gamma.glsl"),
		{exposure = 1.05,gamma=2.2})

	self.shader_screen_filter = shader:new(
		love.graphics.newShader("glsl/screenfilter.glsl","glsl/screenfilter.glsl"),
		{strength=0.45,alpha_strength=0.55})

	self.shader_background = shader:new(
		love.graphics.newShader("glsl/bg.glsl","glsl/bg.glsl"),
		{col1={0,0,0},col2={1,1,1}})
end

function Render:setup3DCanvas()
	love.graphics.setCanvas{
		self.viewport3d,
		depth = true,
		depthstencil = self.viewport3d_depth
	 }
end
function Render:setup3DShader(shadows)
	self.shader3d:set()
	love.graphics.setDepthMode("less",true)
	self.shader3d:send("u_enable_shadows", shadows)
end
function Render:dropShader()
	love.graphics.setShader()
	love.graphics.setDepthMode()
end

function Render:applyLCDEffect()
	-- apply the faux-lcd screen filter
	love.graphics.setCanvas(self.viewport3d_buffer)
	
	local w,h = self.viewport3d_buffer:getDimensions()
	self.shader_screen_filter:set()
	self.shader_screen_filter:send("texture_size",{w,h})

	love.graphics.draw(self.viewport3d)
	self:swapViewport3DBuffer()
	self:dropShader()
end

function Render:blit3DCanvasToViewport(viewport)
	local v3d = viewport or self.viewport3d
	self:setupViewport()

	local w1,h1 = self.viewport:getDimensions()
	local w2,h2 = v3d:getDimensions()
	local sx,sy = w1/w2, h1/h2

	love.graphics.draw(v3d,0,0,0,sx,sy)
end

function Render:setupViewport()
	love.graphics.setCanvas(self.viewport)
end
function Render:blitViewport()
	love.graphics.setCanvas()
	love.graphics.draw(self.viewport)
end
function Render:blitViewportGammaCorrect()
	love.graphics.setCanvas()
	self.shader_gamma:set()
	love.graphics.draw(self.viewport)
	self:dropShader()
end

function Render:swapViewport3DBuffer()
	local temp = self.viewport3d
	self.viewport3d = self.viewport3d_buffer
	self.viewport3d_buffer = temp 
end

return Render
