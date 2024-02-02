local animator = require "animator"
local cpml = require 'cpml'
local matrix = require 'matrix'

local MeoxAnim = {

	action_outframes = nil,
	action = nil,

	animator1 = nil,
	animator2 = nil,
	meoxi = nil

}
MeoxAnim.__index = MeoxAnim

function MeoxAnim:init(meoxi)
	local a1,a2 = meoxi:getAnimator()
	self.animator1 = a1
	self.animator2 = a2
	self.meoxi = meoxi

	self.action = Animator:new(meoxi)
	local count = self.meoxi:getModel():getSkeletonJointCount()
	self.action_outframes = {}
	for i=1,count do
		self.action_outframes[i] = cpml.mat4.new{1,0,0,0,
		                                         0,1,0,0,
																						 0,0,1,0,
																						 0,0,0,1}
	end
end

function MeoxAnim:updateActionAnimation()
	local act = self.action
	self.action:update()
	if not act:isPlaying() then return end
	self.action:pushToOutframe(self.action_outframes)

	local outframes = self.meoxi:getOutframe()
	for i,m in ipairs(outframes) do
		--cpml.mat4.mul(outframes[i], outframes[i], self.action_outframes[i])
		cpml.mat4.mul(outframes[i], self.action_outframes[i], outframes[i])
	end
end

return MeoxAnim
