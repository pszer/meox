-- animator object to attach to models
--
-- it's functionality is limited, it's simply an object to pass
-- which animation and frame should be applied to a model, with support
-- to play an entire animation with a callback function upon the
-- animations completion
--
-- when dealing with animations, the unit of time used is ticks, there are 60 ticks in a second
-- the current game tick can be retrieved with getTickSmooth() in tick.lua

require "math"

require "provtype"
require "stack"

Animator = {}
Animator.__index = Animator

-- takes in an ModelInstance
function Animator:new(model_inst)
	assert_type(model_inst, "modelinstance")

	local this = {
		anim_model_ref = model_inst,

		anim_play_animation = false, -- if true, the animator will update itself in Animator:update()
		                             -- to play out the animation. if false it stays static
		anim_play_last_time = 0,
		anim_play_time_acc = 0,
		anim_play_speed = 1.0,
		anim_play_loop  = true,
		anim_curr_animation = nil,
		anim_curr_animation_finished = false,

		anim_finish_callback = nil, -- called when animation finished, function(Animator)

		-- internal use
		__anim_curr_frame = 0
	}

	setmetatable(this, Animator)
	return this
end

function Animator:update()
	if not self.anim_curr_animation then return end

	if self.anim_curr_animation_finished then
		local callback = self.anim_finish_callback
		if callback then
			if not self.anim_play_loop then
				self.anim_play_animation = false
			end
			self.anim_finish_callback = nil
			callback(self)
		else
			if not self.anim_play_loop then
				self.anim_play_animation = false
			end
		end
	end

	if self.anim_play_animation then
		local diff = getTickSmooth() - self.anim_play_last_time

		self.anim_play_time_acc = self.anim_play_time_acc + diff * self.anim_play_speed
		self.anim_play_last_time = getTickSmooth()
	end
end

-- stops the animation ands calls anim_finish_callback
function Animator:suspendAnimation()
	if not self.anim_play_animation then return end
	self.anim_play_animation = false
	local callback = self.anim_finish_callback
	if callback then callback(self) end
end

-- same as suspendAnimation but doesnt call the callback function
function Animator:stopAnimation()
	self.anim_play_animation = false
end

function Animator:resumeAnimation()
	self.anim_play_animation = true
	self.anim_play_last_time  = getTickSmooth()
end

function Animator:isPlaying()
	return self.anim_play_animation end

function Animator:getSpeed()
	return self.anim_play_speed end
function Animator:setSpeed(s)
	self.anim_play_speed = s end
function Animator:setTime(t)
	self.anim_play_time_acc = t
end

-- pushes it's current animation state onto its model reference
function Animator:pushToOutframe( outframe )
	assert(outframe, "Animator:pushToOutframe(): no outframe provided")

	local model_inst = self.anim_model_ref
	local base_model = model_inst:getModel()

	local animation = self.anim_curr_animation
	if not animation then
		base_model:getDefaultPose( outframe )
		return 
	end

	local frame1_id, frame2_id, interp, is_finished =
		Animator.timeToIndex(animation,
		                     self.anim_play_time_acc,
							 not self.anim_play_loop)
	
	self.anim_curr_animation_finished = is_finished
	self.__anim_curr_frame = frame1_id

	local frame1 = base_model:getAnimationFrame(frame1_id)
	local frame2 = base_model:getAnimationFrame(frame2_id)
	base_model:interpolateTwoFrames(frame1, frame2, interp, outframe)
end

-- sets the animation to a static frame
function Animator:staticAnimation(anim, time)
	if not anim then return end

	self.anim_curr_animation  = anim

	self.anim_play_animation  = false
	self.anim_play_last_time  = getTickSmooth()
	self.anim_play_time_acc   = time or 0
	self.anim_play_speed      = 1.0
	self.anim_play_loop       = false
	self.anim_curr_animation_finished = false
	self.anim_finished_callback = nil
end

function Animator:playAnimation(anim, time, speed, loop, callback)
	if not anim then return end

	self.anim_curr_animation  = anim

	self.anim_play_animation  = true
	self.anim_play_last_time  = getTickSmooth()
	self.anim_play_time_acc   = time or 0
	self.anim_play_speed      = speed or 1.0
	if loop==false then self.anim_play_loop=false else self.anim_play_loop=true end
	self.anim_finish_callback = callback
	
	self.anim_curr_animation_finished = false
end

function Animator:getAnimationByName(name)
	local model = self.anim_model_ref:getModel()
	local anim = model:getAnimation(name)
	if not anim then
		error(string.format("Animator:getAnimationByName(): no animation found with name \"%s\"", name))
	end
	return anim
end

function Animator:staticAnimationByName(name, time)
	self:staticAnimation(self:getAnimationByName(name), time)
end

function Animator:playAnimationByName(name, time, speed, loop, callback)
	self:playAnimation(self:getAnimationByName(name), time, speed, loop, callback)
end

-- returns frame_id1, frame_id2, interp, finish?
function Animator.timeToIndex( anim_data, time, dont_loop )
	if not anim_data then
		error("Animator.timeToIndex() got given nil as animation data")
	end

	local anim_first  = anim_data.first
	local anim_last   = anim_data.last
	local anim_length = anim_last - anim_first
	local anim_rate   = anim_data.framerate

	local speed = speed or 1.0

	local frame_fitted = time * anim_rate / tickRate()
	local frame_floor  = math.floor(frame_fitted)
	local frame_interp = frame_fitted - frame_floor

	local min = math.min
	local max = math.max
	local clamp = function(a,low,up) if a>up then return up end if a<low then return low end return a end

	local is_finished = anim_first + frame_floor >= anim_last

	local frame_id1 = nil
	local frame_id2 = nil
	if not dont_loop then
		frame_id1 = anim_first + (frame_floor) % anim_length
		frame_id2 = anim_first + (frame_floor+1) % anim_length
	else
		frame_id1 = clamp(anim_first + (frame_floor) , anim_first, anim_last)
		frame_id2 = clamp(anim_first + (frame_floor+1) , anim_first, anim_last)
	end

	return frame_id1, frame_id2, frame_interp, is_finished
end

-- returns the current animation frame this animator is set to
function Animator:getAnimationFrame()
	if not self.anim_curr_animation then
		error("Animator:getAnimationFrame(): no animation configured!")
	end
	return Animator.timeToIndex(self.anim_curr_animation, self.anim_play_time_acc, self.anim_play_loop)
end

-- takes two Animators and interpolates between their animations by the interp argument (0.0 = animator1, 1.0 = animator2)
-- the outframe for animator1's animation is put in outframe_buf1, likewise animator2 goes to outframe_buf2
-- the final interpolated result goes into outframe
--
-- as an optimisation, if interp is <0.01 then animator2's animation is never evaluated and vise versa for interp >0.99
function Animator.interpolateTwoAnimators(animator1, animator2, interp, outframe_buf1, outframe_buf2, outframe)
	if interp < 0.01 then
		animator1:pushToOutframe(outframe)
		return
	elseif interp > 0.99 then
		animator2:pushToOutframe(outframe)
		return
	end

	animator2:pushToOutframe(outframe_buf2)
	animator1:pushToOutframe(outframe_buf1)

	local count = #outframe_buf1
	local interp_i = 1.0 - interp

	for i=1,count do
		local pose1 = outframe_buf1[i]
		local pose2 = outframe_buf2[i]

		for j=1,16 do
			outframe[i][j] =
			 (interp_i)*pose1[j] + interp*pose2[j]
		end
	end
end
