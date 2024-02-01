-- model "decorations" are models that can be attached to other models bones
-- main use is for attaching transparent meshes to heads for drawing animated faces
--

require "props.modelaccessoryprops"
local shadersend = require 'shadersend'
local cpml = require 'cpml'
local matrix = require 'matrix'

ModelDecor = {__type = "decor"}
ModelDecor.__index = ModelDecor

function ModelDecor:__new(props)
	local this = {
		props = ModelDecorPropPrototype(props),

		recalc_model = true,
		local_model_u = nil
	}

	setmetatable(this,ModelDecor)

	this.local_model_u = cpml.mat4.new()

	return this
end

function ModelDecor:newInstance(model, props)
	assert_type(model, "model")

	local decor = ModelDecor:__new(props)
	decor.props.decor_reference = model
	decor.props.decor_model_name = model.props.model_name
	model:ref()
	return decor
end

function ModelDecor:releaseModel()
	local model = self.props.decor_reference
	model:deref()

	local animface = self.props.decor_animated_face
	if animface then animface:release() end
end

local __tempvec3 = cpml.vec3.new()
function ModelDecor:getLocalModelMatrix()
	-- decor objects are attached to another models bones, it's rare
	-- to ever need it's local position to change so we only calculate the local
	-- model matrix once
	if self.recalc_model then

		local props = self.props
		local pos = props.decor_position
		local rot = props.decor_rotation
		local scale = props.decor_scale

		pos[4] = 0
		cpml.mat4.mul_vec4(pos, self:getModel():getDirectionFixingMatrix(), pos)

		local m = self.local_model_u

		__tempvec3.x = scale[1]
		__tempvec3.y = scale[2]
		__tempvec3.z = scale[3]
		--m:scale(m,  cpml.vec3(unpack(props.decor_scale)))
		m = m:scale(m, __tempvec3)

		rotateMatrix(m, rot)
		--m:rotate(m, rot[1], cpml.vec3.unit_x)
		--:rotate(m, rot[2], cpml.vec3.unit_y)
		--m:rotate(m, rot[3], cpml.vec3.unit_z)

		--m:translate(m, cpml.vec3( pos[1], pos[2], pos[3] ))
		__tempvec3.x = pos[1]
		__tempvec3.y = pos[2]
		__tempvec3.z = pos[3]
		m = m:translate(m, __tempvec3)

		self.local_model_u = m
		self.recalc_model = false

		return m
	end

	return self.local_model_u
end

local __tempmat4__ = cpml.mat4.new(1)
local __tempmat4__2 = cpml.mat4.new(1)
local __tempmat4id__ = cpml.mat4.new(1)
-- returns model_u, normal_model_u to be used in shader
function ModelDecor:getGlobalModelMatrix(parent)
	local local_model_u = self:getLocalModelMatrix()

	local props = self.props
	local model_matrix = parent:queryModelMatrix()
	local bone_matrix  = parent:queryBoneMatrix(props.decor_parent_bone)
	--local model_u = model_matrix * bone_matrix * local_model_u
	__tempmat4__:mul(model_matrix,bone_matrix)
	__tempmat4__:mul(__tempmat4__, local_model_u)

	local norm_m = __tempmat4__2
	norm_m = norm_m:invert(__tempmat4__)
	norm_m = norm_m:transpose(norm_m)

	return __tempmat4__, norm_m
	--return model_u, norm_m
end

function ModelDecor:getModel()
	return self.props.decor_reference
end

function ModelDecor:compositeFace()
	local face = self.props.decor_animated_face
	if face then
		face:composite()
	end
end

function ModelDecor:updateFaceAnimation()
	local face = self.props.decor_animated_face
	if face then
		face:updateAnimation()
	end
end

function ModelDecor:draw(parent, shader)
	local shader = shader or love.graphics.getShader()

	local face = self.props.decor_animated_face
	prof.push("face_pass")
	if face then
		--local canvas = love.graphics.getCanvas()
		prof.push("pushcomposite")
		--face:pushComposite()
		face:pushTexture()
		prof.pop("pushcomposite")
		--love.graphics.setShader(shader)
		--love.graphics.setCanvas(canvas)
	end
	prof.pop("face_pass")

	prof.push("get_global_model_matrix")
	local model_u, norm_u = self:getGlobalModelMatrix(parent)
	prof.pop("get_global_model_matrix")

	shadersend(shader, "u_model", "column", matrix(model_u))
	shadersend(shader, "u_normal_model", "column", matrix(norm_u))
	shadersend(shader, "u_skinning", 0) -- bone matrix is preapplied by getGlobalModelMatrix, so disable skinning

	local shadow_mult = 1.0 - self.props.decor_shadow_mult
	shadersend(shader, "u_shadow_imult", shadow_mult)

	local mesh = self:getModel():getMesh()
	love.graphics.draw(mesh)
	--mesh:drawModel(shader)

	shadersend(shader, "u_shadow_imult", 0.0)
end

function ModelDecor:name()
	return self.props.decor_name
end
