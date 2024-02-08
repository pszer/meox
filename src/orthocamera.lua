local cpml = require 'cpml'
local matrix = require 'matrix'

require "resolution"
local shadersend = require 'shadersend'

require "props.orthocameraprops"

local OrthoCamera = {__type = "camera"}
OrthoCamera.__index = OrthoCamera

function OrthoCamera:new(props)
	local this = {
		props = OrthoCameraPropPrototype(props),

		__last_aspect    = 16/9,
		__last_fov       = 75.0,
		__last_far_plane = 2000.0,
	}

	setmetatable(this,OrthoCamera)

	this.props.ocam_view_matrix = cpml.mat4.new()
	this.props.ocam_rot_matrix = cpml.mat4.new()
	this.props.ocam_perspective_matrix = cpml.mat4.new()
	this.props.ocam_rotview_matrix = cpml.mat4.new()
	this.props.ocam_viewproj_matrix = cpml.mat4.new()

	this:generatePerspectiveMatrix()
	this:generateViewMatrix()

	return this
end

function OrthoCamera:pushToShader(sh)
	local props = self.props
	local pos = self:getPosition()
	local rot = self:getRotation()

	sh = sh or love.graphics.getShader()
	shadersend(sh, "u_proj", "column", matrix(props.ocam_perspective_matrix))
	shadersend(sh, "u_view", "column", matrix(props.ocam_view_matrix))
	shadersend(sh, "u_rot", "column", matrix(props.ocam_rot_matrix))
	shadersend(sh, "view_pos", pos)
end

function OrthoCamera:getPosition()
	return self.props.ocam_position end
function OrthoCamera:getRotation()
	return self.props.ocam_rotation end
function OrthoCamera:getDirection()
	return self.props.ocam_direction end

function OrthoCamera:directionMode()
	self.props.ocam_mode = "direction" end
function OrthoCamera:rotationMode()
	self.props.ocam_mode = "rotation" end
function OrthoCamera:getMode()
	return self.props.ocam_mode end
function OrthoCamera:isDirectionMode()
	return self:getMode() == "direction" end
function OrthoCamera:isRotationMode()
	return self:getMode() == "rotation" end

function OrthoCamera:setPosition(pos)
	--self.props.ocam_position = {pos[1], pos[2], pos[3]}
	self.props.ocam_position[1] = pos[1]
	self.props.ocam_position[2] = pos[2]
	self.props.ocam_position[3] = pos[3]
end

-- these functions automatically set the camera mode to direction/rotation
function OrthoCamera:setDirection(dir)
	-- ensure that the direction vector is never nil
	if dir[1]==0 and dir[2]==0 and dir[3]==0 then	
		self.props.ocam_direction = { 0 , 0 , -1 }
	else
		local x,y,z = dir[1],dir[2],dir[3]
		local length = math.sqrt(x*x + y*y + z*z)
		self.props.ocam_direction = {x/length, y/length, z/length}
	end
	self:directionMode()
end
function OrthoCamera:setRotation(rot)
	self.props.ocam_rotation = {rot[1], rot[2], rot[3]}
	self:rotationMode()
end

-- generates and returns perspective matrix
function OrthoCamera:generatePerspectiveMatrix(aspect_ratio)
	local aspect_ratio = aspect_ratio or RESOLUTION_ASPECT_RATIO()
	self.__last_aspect = aspect_ratio

	local props = self.props
	local size = self.props.ocam_size
	props.ocam_perspective_matrix = cpml.mat4.from_ortho(
		-size*aspect_ratio, size*aspect_ratio, -size, size, 1.0, self.props.ocam_far_plane)
	return props.ocam_perspective_matrix
end

function OrthoCamera:getProjectionMatrix()
	local projm = self.props.ocam_perspective_matrix
	if projm then
		return projm
	else
		return self:generatePerspectiveMatrix()
	end
end

-- generates and returns view,rot matrix
local __tempvec3 = cpml.vec3.new()
local __tempvec3nil = cpml.vec3.new(0,0,0)
local __tempvec3up = cpml.vec3.new(0,1,0)
function OrthoCamera:generateViewMatrix()
	local props = self.props
	local mat4 = cpml.mat4
	local vec3 = cpml.vec3
	--local v = mat4():identity()
	--local m = mat4()
	local m = props.ocam_view_matrix
	local v = props.ocam_rot_matrix
	
	local id =
	{1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1}
	for i=1,16 do
		m[i] = id[i]
		v[i] = id[i]
	end

	local P = self:getPosition()
	--local position = vec3(P[1], P[2], P[3])
	__tempvec3.x = -P[1]
	__tempvec3.y = -P[2]
	__tempvec3.z = -P[3]
	m:translate(m, __tempvec3)

	local mode = self:getMode()
	if mode == "rotation" then
		local R = self:getRotation()
		v:rotate(v, R[1], vec3.unit_x)
		v:rotate(v, R[2], vec3.unit_y)
		v:rotate(v, R[3], vec3.unit_z)
	else
		local D = self:getDirection()
		__tempvec3.x = D[1]
		__tempvec3.y = D[2]
		__tempvec3.z = D[3]
		v:look_at(__tempvec3nil,         -- eye
		          __tempvec3, -- look at
				  __tempvec3up)       -- up dir
	end

	props.ocam_view_matrix = m
	props.ocam_rot_matrix  = v

	local rotview = props.ocam_rotview_matrix
	cpml.mat4.mul(rotview, v, m)

	return props.ocam_view_matrix, props.ocam_rot_matrix
end

function OrthoCamera:getViewProjMatrix()
	local props = self.props
	local vp = props.ocam_viewproj_matrix
	local v  = props.ocam_rotview_matrix
	local p  = props.ocam_perspective_matrix
	cpml.mat4.mul(vp, p, v)
	return vp
end

local __temp_dir_v = {0,0,0,0}
function OrthoCamera:getDirectionVector( dir )
	local dir_v = __temp_dir_v
	if dir then
		dir_v[1] = dir[1]
		dir_v[2] = dir[2]
		dir_v[3] = dir[3]
		dir_v[4] = 0.0
	else
		dir_v[1] = 0
		dir_v[2] = 0
		dir_v[3] = -1
		dir_v[4] = 0
	end
	local rot = self.props.ocam_rot_matrix
	if rot then
		cpml.mat4.mul_vec4(dir_v, -rot, dir_v)
		return dir_v[1], dir_v[2], dir_v[3]
	else
		return 0,0,-1
	end
end

local __tempmat4i = cpml.mat4.new()
function OrthoCamera:getInverseDirectionVector( dir )
	local dir_v = __temp_dir_v
	if dir then
		dir_v[1] = dir[1]
		dir_v[2] = dir[2]
		dir_v[3] = dir[3]
		dir_v[4] = 0.0
	else
		dir_v[1] = 0
		dir_v[2] = 0
		dir_v[3] = -1
		dir_v[4] = 0
	end
	local rot = self.props.ocam_rot_matrix
	if rot then
		local inv_rot = __tempmat4i
		inv_rot:invert(-rot)
		cpml.mat4.mul_vec4(dir_v, inv_rot, dir_v)
		--cpml.mat4.mul_vec4(dir_v, rot, dir_v)
		return dir_v[1], dir_v[2], dir_v[3]
	else
		return 0,0,-1
	end
end

-- a test to see if anything has changed that requires
-- a new perspective matrix
function OrthoCamera:checkNeedToUpdatePerspective()
	local props = self.props
	if (RESOLUTION_ASPECT_RATIO() ~= self.__last_aspect) or
	   (self.__last_fov ~= props.ocam_fov) or
	   (self.__last_far_plane ~= props.ocam_far_plane)
	then
	   return true
	end
end

function OrthoCamera:setController(func)
	self.props.ocam_function = func
end

function OrthoCamera:update()
	local mode = self.props.ocam_function
	if mode then mode(self) end

	if self:checkNeedToUpdatePerspective() then
		self:generatePerspectiveMatrix()
	end
	-- a similar checkNeedToUpdateView test is not done because
	-- a camera is assumed to be always moving
	self:generateViewMatrix()
end

function OrthoCamera:map3DCoords(x,y)
	if RESOLUTION_ASPECT == "16:9" then
		return x*self.__viewport_w_half,
		       y*self.__viewport_h_half
	else
		return x*self.__viewport_w_half * 0.875,
		       y*self.__viewport_h_half
	end
end

return OrthoCamera
