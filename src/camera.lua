local cpml = require 'cpml'
local matrix = require 'matrix'

require "resolution"
local shadersend = require 'shadersend'

require "props/cameraprops"

local Camera = {__type = "camera"}
Camera.__index = Camera

function Camera:new(props)
	local this = {
		props = CameraPropPrototype(props),

		__last_aspect    = 16/9,
		__last_fov       = 75.0,
		__last_far_plane = 2000.0,
		__frustrum_generated = false
	}

	setmetatable(this,Camera)

	this.props.cam_view_matrix = cpml.mat4.new()
	this.props.cam_rot_matrix = cpml.mat4.new()
	this.props.cam_perspective_matrix = cpml.mat4.new()
	this.props.cam_rotview_matrix = cpml.mat4.new()
	this.props.cam_viewproj_matrix = cpml.mat4.new()

	this.props.cam_frustrum_corners = {{},{},{},{},{},{},{},{}}
	this.props.cam_frustrum_centre  = {}

	this:generatePerspectiveMatrix()
	this:generateViewMatrix()

	return this
end

function Camera:pushToShader(sh)
	local props = self.props
	local pos = self:getPosition()
	local rot = self:getRotation()

	sh = sh or love.graphics.getShader()
	shadersend(sh, "u_proj", "column", matrix(props.cam_perspective_matrix))
	shadersend(sh, "u_view", "column", matrix(props.cam_view_matrix))
	shadersend(sh, "u_rot", "column", matrix(props.cam_rot_matrix))
	shadersend(sh, "view_pos", pos)
end

function Camera:getPosition()
	return self.props.cam_position end
function Camera:getRotation()
	return self.props.cam_rotation end
function Camera:getDirection()
	return self.props.cam_direction end

function Camera:directionMode()
	self.props.cam_mode = "direction" end
function Camera:rotationMode()
	self.props.cam_mode = "rotation" end
function Camera:getMode()
	return self.props.cam_mode end
function Camera:isDirectionMode()
	return self:getMode() == "direction" end
function Camera:isRotationMode()
	return self:getMode() == "rotation" end

function Camera:setPosition(pos)
	--self.props.cam_position = {pos[1], pos[2], pos[3]}
	self.props.cam_position[1] = pos[1]
	self.props.cam_position[2] = pos[2]
	self.props.cam_position[3] = pos[3]
end

-- these functions automatically set the camera mode to direction/rotation
function Camera:setDirection(dir)
	-- ensure that the direction vector is never nil
	if dir[1]==0 and dir[2]==0 and dir[3]==0 then	
		self.props.cam_direction = { 0 , 0 , -1 }
	else
		local x,y,z = dir[1],dir[2],dir[3]
		local length = math.sqrt(x*x + y*y + z*z)
		self.props.cam_direction = {x/length, y/length, z/length}
	end
	self:directionMode()
end
function Camera:setRotation(rot)
	self.props.cam_rotation = {rot[1], rot[2], rot[3]}
	self:rotationMode()
end

-- generates and returns perspective matrix
function Camera:generatePerspectiveMatrix(aspect_ratio)
	local aspect_ratio = aspect_ratio or RESOLUTION_ASPECT_RATIO()
	self.__last_aspect = aspect_ratio

	local props = self.props
	props.cam_perspective_matrix = cpml.mat4.from_perspective(
		props.cam_fov, aspect_ratio, 0.5, props.cam_far_plane)

	return props.cam_perspective_matrix
end

function Camera:calculatePerspectiveMatrix(aspect_ratio, far_plane)
	local aspect_ratio = aspect_ratio or RESOLUTION_ASPECT_RATIO()
	local props = self.props
	return cpml.mat4.from_perspective(
		props.cam_fov, aspect_ratio, 0.5, far_plane)
end

function Camera:getProjectionMatrix()
	local projm = self.props.cam_perspective_matrix
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
function Camera:generateViewMatrix()
	local props = self.props
	local mat4 = cpml.mat4
	local vec3 = cpml.vec3
	--local v = mat4():identity()
	--local m = mat4()
	local m = props.cam_view_matrix
	local v = props.cam_rot_matrix
	
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

	props.cam_view_matrix = m
	props.cam_rot_matrix  = v

	local rotview = props.cam_rotview_matrix
	cpml.mat4.mul(rotview, v, m)

	return props.cam_view_matrix, props.cam_rot_matrix
end

function Camera:getViewProjMatrix()
	local props = self.props
	local vp = props.cam_viewproj_matrix
	local v  = props.cam_rotview_matrix
	local p  = props.cam_perspective_matrix
	cpml.mat4.mul(vp, p, v)
	return vp
end

-- returns corners of camera`s view frustrum in world space,
-- also returns the vector in the middle of this frustrum
local __mat4temp = cpml.mat4.new()
local __X = {-1.0,1.0}
local __Y = {-1.0,1.0}
local __Z = {-1.0,1.0}
local __temppoint = {}
function Camera:generateFrustrumCornersWorldSpace(proj, view)
	local props = self.props
	local proj = proj or props.cam_perspective_matrix
	local view = view or props.cam_rot_matrix * props.cam_view_matrix
	local scale = scale or 1.0

	self.__frustrum_generated = true

	--local inv_m = cpml.mat4.new()
	__mat4temp = __mat4temp:mul(proj, view)
	__mat4temp = __mat4temp:invert(__mat4temp)
	--inv_m:invert(proj * view)
	--
	local inv_m = __mat4temp

	local corners = props.cam_frustrum_corners

	-- used to find vector in the centre
	local sum_x, sum_y, sum_z = 0.0, 0.0, 0.0

	local count = 1
	for x=1,2 do
		for y=1,2 do
			for z=1,2 do
				--[[local point = {
					2.0 * x - 1.0,
					2.0 * y - 1.0,
					2.0 * z - 1.0,
					1.0 }]]
				--local point = {
				--	__X[x],__Y[y],__Z[z],1.0
				--}
				__temppoint[1] = __X[x]
				__temppoint[2] = __Y[y]
				__temppoint[3] = __Z[z]
				__temppoint[4] = 1.0
				local point = __temppoint
				cpml.mat4.mul_vec4(point, inv_m, point)

				-- perform perspective division by w component
				point[1] = point[1]/point[4]
				point[2] = point[2]/point[4]
				point[3] = point[3]/point[4]
				--point[4] = point[4]/point[4]
				point[4] = 1.0

				sum_x = sum_x + point[1]
				sum_y = sum_y + point[2]
				sum_z = sum_z + point[3]

				--table.insert(corners, point)
				corners[count][1] = point[1]
				corners[count][2] = point[2]
				corners[count][3] = point[3]
				corners[count][4] = 1.0
				count = count + 1
			end
		end
	end

	sum_x = sum_x / 8.0
	sum_y = sum_y / 8.0
	sum_z = sum_z / 8.0
	--local centre = {sum_x, sum_y, sum_z}
	local centre = props.cam_frustrum_centre
	centre[1] = sum_x
	centre[2] = sum_y
	centre[3] = sum_z

	props.cam_frustrum_corners = corners
	props.cam_frustrum_centre  = centre
	return corners, centre
end

function Camera:getFrustrumCornersWorldSpace()
	local props = self.props
	if not self.__frustrum_generated then
		self:generateFrustrumCornersWorldSpace()
	end
	return props.cam_frustrum_corners, props.cam_frustrum_centre
end

local __temp_dir_v = {0,0,0,0}
function Camera:getDirectionVector( dir )
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
	local rot = self.props.cam_rot_matrix
	if rot then
		cpml.mat4.mul_vec4(dir_v, -rot, dir_v)
		return dir_v[1], dir_v[2], dir_v[3]
	else
		return 0,0,-1
	end
end

local __tempmat4i = cpml.mat4.new()
function Camera:getInverseDirectionVector( dir )
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
	local rot = self.props.cam_rot_matrix
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
function Camera:checkNeedToUpdatePerspective()
	local props = self.props
	if (RESOLUTION_ASPECT_RATIO() ~= self.__last_aspect) or
	   (self.__last_fov ~= props.cam_fov) or
	   (self.__last_far_plane ~= props.cam_far_plane)
	then
	   return true
	end
end

function Camera:setController(func)
	self.props.cam_function = func
end

function Camera:update()
	local mode = self.props.cam_function
	if mode then mode(self) end

	if self:checkNeedToUpdatePerspective() then
		self:generatePerspectiveMatrix()
	end
	-- a similar checkNeedToUpdateView test is not done because
	-- a camera is assumed to be always moving
	self:generateViewMatrix()
end

function Camera:map3DCoords(x,y)
	if RESOLUTION_ASPECT == "16:9" then
		return x*self.__viewport_w_half,
		       y*self.__viewport_h_half
	else
		return x*self.__viewport_w_half * 0.875,
		       y*self.__viewport_h_half
	end
end

return Camera
