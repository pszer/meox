-- 
-- rotations in most contexts can be described by a vec3 pitch/yaw/roll or vec3 direction vector
--
-- rotations are stored as tables {a,b,c, "rot"/"dir"}, with the 4th component showing
-- which type it is
-- 
-- these are functions for working with these dual-type rotation vectors
--
--

M_PI = 3.1415926535897932384626433832795

-- casts a rotation vector to a rotation type
function toRotationVector(vec)
	if vec[4] == "rot" then
		return vec
	else
		-- things
	end
end

function toDirectionVector(vec)
	if vec[4] == "rot" then
		return vec
	else
		-- things
	end
end

-- if the input is nil, it returns the fallback direction vector
-- of {0,0,-1,"direction"}
function nonNilDirection(vec)
	if vec[4] == "rot" then
		return vec
	end

	if vec[1]==0 and vec[2]==0 and vec[3]==0 then
		local d = {0,0,-1,"dir"}
		return d
	end
	return vec
end

local cpml = require 'cpml'
local __tempvec3 = cpml.vec3.new()
local __tempvec3nil = cpml.vec3.new(0,0,0)
local __tempvec3up = cpml.vec3.new(0,1,0)
local __mat4temp = cpml.mat4.new()
function rotateMatrix(mat, rot)
	if rot[4] == "rot" then
		mat:rotate(mat, rot[1], cpml.vec3.unit_x)
		mat:rotate(mat, rot[2], cpml.vec3.unit_y)
		mat:rotate(mat, rot[3], cpml.vec3.unit_z)
		return mat
	else
		local rot = nonNilDirection(rot)

		__tempvec3.x = rot[1]
		__tempvec3.y = -rot[2]
		__tempvec3.z = -rot[3]

		--local vec3 = cpml.vec3.new
		--local look = cpml.mat4.new(1)
		local look = cpml.mat4.look_at(
			__mat4temp,
			__tempvec3nil,
			__tempvec3,
			__tempvec3up
		)

		cpml.mat4.mul(mat, look, mat)
		return mat
	end
end

local cpml = require 'cpml'
function createQuatTheta(A, B, theta)
	-- Calculate the axis of rotation
	local axis = {
		A[2] * B[3] - A[3] * B[2],
		A[3] * B[1] - A[1] * B[3],
		A[1] * B[2] - A[2] * B[1]
	}
	print("AXIS",unpack(axis))
	if axis[1]==0 and axis[2]==0 and axis[3]==0 then
		print("AYO")
		local sign = A[1]*B[1] + A[2]*B[2] + A[3]*B[3]
		print(sign)
		local id = nil
		if sign>0 then
			--id = cpml.quat.new(0,0,0,-1)
			id = cpml.quat.from_angle_axis(math.pi,0,1,0)
		else
			id = cpml.quat.new(0,0,0,1)
		end
		return id
	end

	return cpml.quat.from_angle_axis(theta,axis[1],axis[2],axis[3])
	--[[
	local halfTheta = 0.5 * theta
	local sinHalfTheta = math.sin(halfTheta)
	local cosHalfTheta = math.cos(halfTheta)

	-- Construct the quaternion
	return cpml.quat.new(
		sinHalfTheta * axis[1],
		sinHalfTheta * axis[2],
		sinHalfTheta * axis[3],
		cosHalfTheta
	)--]]
end

function createQuat(A, B)
	-- Calculate the axis of rotation
	local dot = A[1]*B[1] + A[2]*B[2] + A[3]*B[3]
	local angle = math.acos(dot)
	print("A",unpack(A))
	print("B",unpack(B))
	print("ANGLE",angle)
	return createQuatTheta(A,B,angle)
end
