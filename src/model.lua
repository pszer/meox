local iqm = require 'iqm-exm'
local cpml = require 'cpml'
local matrix = require 'matrix'
local shadersend = require 'shadersend'

require "cfg.gfx"
require "props.modelprops"
require "modelaccessory"
require "texturemanager"
require "rotation"
require "animator"
local assets = require "assetloader"

local material = require 'materials'

Model = {__type = "model"}
Model.__index = Model

function Model:new(props)
	local this = {
		props = ModelPropPrototype(props),

		-- internally used
		baseframe = {},
		inversebaseframe = {},
		frames = {},

		outframe_buffer = {}, -- an outframe buffer that can be used during animation calculation

		dir_matrix = nil,
		outframes_allocated = false,
		bounds_corrected = false, -- has the bounding box been corrected by the direction fixing matrix?

		ref_count = 0
	}

	setmetatable(this,Model)

	if this:isAnimated() then
		local count = this:getSkeletonJointCount()
		local newmat4 = cpml.mat4.new
		for i=1,count do
			this.outframe_buffer[i] = newmat4()
		end
	end

	return this
end

function Model:fromLoader( filename )
	assert_type(filename, "string")
	local model_attributes = require 'cfg.model_attributes'
	local attributes   = model_attributes[ filename ] or {}

	local texture_name = attributes["model_texture_fname"]
	local winding      = attributes["model_vertex_winding"]

	local texture  = nil
	local mat = nil

	local objs = assets:getModelReference( filename )
	assert(objs)

	local bounds = nil
	local bounds_copy = nil
	if objs.bounds then
		bounds = objs.bounds.base
		bounds_copy = { ["min"]={unpack(bounds.min)}, ["max"]={unpack(bounds.max)} }
	end

	if not texture_name then
		texture_name = "undef.png"
		mat = material:empty()
		print(string.format("Model:fromLoader(): texture to use for model %s unknown, please specify in cfg/model_attributes",
			filename))
	end

	texture = assets:getTextureReference( texture_name )
	assert(texture)
	local mesh = objs.mesh
	mesh:setTexture(texture)
	if not mat then
		mat = material:new(texture_name)
	end

	local tangent_present = false
	local vert_format = mesh:getVertexFormat()
	for i,v in ipairs(vert_format) do
		if v[1]=="VertexTangent" then
			tangent_present = true
			break
		end
	end

	if not tangent_present then
		local attachTangent = require 'tangent'
		attachTangent(mesh)
	end

	local anims = nil
	local skeleton = nil
	local has_anims = false

	if objs.has_anims then
		anims = objs.anims
		skeleton = anims.skeleton
		has_anims = true
	end

	local model = Model:new{
		["model_name"] = filename,
		["model_texture_fname"] = texture_name,
		["model_vertex_winding"] = winding,
		["model_bounding_box"] = bounds,
		["model_bounding_box_unfixed"] = bounds_copy,
		["model_mesh"] = mesh,
		["model_skeleton"] = skeleton,
		["model_animations"] = anims,
		["model_animated"] = has_anims,
		["model_material"] = mat,
	}

	if objs.has_anims then
		model:generateBaseFrames()
		model:generateAnimationFrames()
	end

	model:generateDirectionFixingMatrix()
	model:correctBoundingBox()

	return model
end

function Model:release( )
	local ref_count = self.ref_count
	local name = self.props.model_name
	if ref_count ~= 0 then
		error(string.format("Model:release(): Model %s has %d references still remaining.", tostring(name), ref_count))
	end

	local tex_name = self.props.model_texture_fname
	assets:deref("model", name)
	assets:deref("texture", tex_name)
end

function Model:getMesh()
	return self.props.model_mesh
end

function Model:ref()
	--print(string.format("model:ref() ++ %s", self.props.model_name))
	self.ref_count = self.ref_count + 1
	--print(string.format("Model:ref(): %s ref_count %d", self.props.model_name, self.ref_count))
end

function Model:deref()
	print(string.format("model:ref() -- %s", self.props.model_name))
	if self.ref_count <= 0 then
		error(string.format("Model:deref(): ref count is <=0, (%s)", self.props.model_name))
	end
	self.ref_count = self.ref_count - 1
	--print(string.format("Model:deref(): %s ref_count %d", self.props.model_name, self.ref_count))
end

ModelInstance = {__type = "modelinstance"}
ModelInstance.__index = ModelInstance

--[[
--
--
-- ModelInstance
--
--
--]]

-- this should never be called directly
function ModelInstance:__new(props)
	local this = {
		props = ModelInstancePropPrototype(props),

		static_model_matrix = nil,
		static_normal_matrix = nil,

		bone_matrices = {}, -- bone matrices pushed to shader
		--bone_matrices2 = {}, -- 2nd allocated buffer to use when interpolating between animator1 and 2

		model_moved = true, -- changed to true whenever the models position/rotation/scale components change
		matrix_changed = true, -- changed to true whenever the model is in matrix mode and the model matrix has changed

		-- a flag that signals that this model has moved, so anything
		-- that uses its bounding box needs to be recalculated i.e.
		-- the space partitioning used for view culling
		recalculate_bounds_flag = false
	}

	setmetatable(this,ModelInstance)

	--this:fillOutBoneMatrices(nil, 0)

	--local id = {1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1}
	--local function id_table() local t={} for i=1,16 do t[i]=id[i] end return t end
	this.static_model_matrix = cpml.mat4.new()
	this.static_normal_matrix = cpml.mat4.new()

	local a = {0,0,0}
	local b = {0,0,0}
	this.props.model_i_bounding_box.min = a
	this.props.model_i_bounding_box.max = b

	if not this:isStatic() and this.props.model_i_reference:isAnimated() then
		this.props.model_i_animator1 = Animator:new(this)
		this.props.model_i_animator2 = Animator:new(this)
		this:allocateOutframeMatrices()
	end

	this:modelMatrix()

	return this
end

function ModelInstance:clone()
	local function clone(dest, t, clone)
		for i,v in pairs(t) do
			local typ = provtype(v)
			if typ ~= "table" then
				dest[i] = v
			else
				dest[i] = {}
				clone(dest[i], v, clone)
			end
		end
		return dest
	end

	local t ={}
	clone(t, self.props, clone)
	if t.model_i_reference then t.model_i_reference:ref() end
	return ModelInstance:__new(t)
end

function ModelInstance:newInstance(model, props)
	local p

	if provtype(props) == "modelinfo" then
		if props.matrix then
			p = {
				["model_i_static"] = true,
				["model_i_matrix"] = props.matrix,
				["model_i_transformation_mode"] = "matrix",
			}
		else
			p = {
				["model_i_static"]   = true,
				["model_i_position"] = props.position,
				["model_i_rotation"] = props.rotation,
				["model_i_scale"]    = props.scale
			}
		end
	else
		p = props or {}
	end

	p.model_i_reference = model
	model:ref()
	return ModelInstance:__new(p)
end

function ModelInstance:newInstances(model, instances)
	local count = #instances
	instances.mesh = ModelInfo.newMeshFromInfoTable(model, instances)

	local props = {
		["model_i_static"] = true,
		["model_i_reference"] = model,
		["model_i_draw_instances"] = true,
		["model_i_instances"] = instances,
		["model_i_instances_count"] = count
	}

	model:ref()
	return ModelInstance:__new(props)
end

function ModelInstance:releaseModel()
	local model = self:getModel()
	model:deref()
	self:releaseDecorations()
end

function ModelInstance:usesModelInstancing()
	return self.props.model_i_draw_instances
end

function ModelInstance:allocateOutframeMatrices()
	if self.outframes_allocated then return end

	local model = self:getModel()
	if model.props.model_animated then
		local count = model:getSkeletonJointCount()
		local mat4new = cpml.mat4.new
		for i=1,count do
			self.bone_matrices[i] = cpml.mat4.new()
			--self.bone_matrices2[i] = cpml.mat4.new()
		end
		self.outframes_allocated = true
	end
end

function ModelInstance:getOutframe()
	return self.bone_matrices, self.bone_matrices2
end

function ModelInstance:updateAnimation(dont_step)
	local animator1 = self.props.model_i_animator1
	local animator2 = self.props.model_i_animator2
	if animator1 then animator1:update() end
	if animator2 then animator2:update() end
	self:fillOutBoneMatrices()
end

local __vec3temp = cpml.vec3.new()
local __mat4temp = cpml.mat4.new()
function ModelInstance:modelMatrix()
	local model_mode = self.props.model_i_transformation_mode

	-- calculates the determinanet of the 3x3 portion in a 4x4 matrix
	-- 1 2 3
	-- 4 5 6
	-- 7 8 9
	--
	-- 1  2  3  4
	-- 5  6  7  8
	-- 9  10 11 12
	-- 13 14 15 16
	function det(matrix)
		local det = matrix[1] * (matrix[6] * matrix[11] - matrix[7] * matrix[10])
				  - matrix[2] * (matrix[5] * matrix[11] - matrix[7] * matrix[9])
				  + matrix[3] * (matrix[5] * matrix[10] - matrix[6] * matrix[9])
		return det
	end

	if model_mode == "component" then
		if not self.model_moved then
			return self.static_model_matrix, self.static_normal_matrix
		end

		local props = self.props
		local pos = props.model_i_position
		local rot = props.model_i_rotation
		local scale = props.model_i_scale

		local m = self.static_model_matrix

		local id =
		{1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1}
		for i=1,16 do
			m[i] = id[i]
		end

		--m = cpml.mat4.new()

		--m:scale(m,  cpml.vec3(unpack(props.model_i_scale)))
		__vec3temp.x = scale[1]
		__vec3temp.y = scale[2]
		__vec3temp.z = scale[3]
		m:scale(m,  __vec3temp)

		rotateMatrix(m, rot)

		__vec3temp.x = pos[1]
		__vec3temp.y = pos[2]
		__vec3temp.z = pos[3]
		m:translate(m, __vec3temp )

		local dirfix = props.model_i_reference:getDirectionFixingMatrix()
		m = cpml.mat4.mul(m, m, dirfix )
		--m = m * dirfix 

		local norm_m = self.static_normal_matrix
		norm_m = norm_m:invert(m)
		norm_m = norm_m:transpose(norm_m)


		self.static_model_matrix = m
		self.static_normal_matrix = norm_m
		local m_det = det(m)
		self.props.model_i_matrix_det = m_det

		self.model_moved = false

		self.recalculate_bounds_flag = true
		self:calculateBoundingBox()
		return m, norm_m
	elseif model_mode == "matrix" then
		if not self.matrix_changed then
			return self.static_model_matrix, self.static_normal_matrix
		end
		self.matrix_changed = false

		local props = self.props
		local model_m = self.props.model_i_matrix
		local m = __mat4temp

		for i=1,16 do
			m[i] = model_m[i]
		end

		local dirfix = props.model_i_reference:getDirectionFixingMatrix()
		m = cpml.mat4.mul(m,m,dirfix)

		for i=1,16 do
			self.static_model_matrix[i] = m[i]
		end

		local norm_m = self.static_normal_matrix
		norm_m = norm_m:invert(m)
		norm_m = norm_m:transpose(norm_m)
		--self.static_model_matrix = 
		self.static_normal_matrix = norm_m
		local m_det = det(m)
		self.props.model_i_matrix_det = m_det

		self.recalculate_bounds_flag = true
		self:calculateBoundingBox()
		return model_m, norm_m
	end
end

function ModelInstance:areBoundsChanged()
	return self.recalculate_bounds_flag
end

function ModelInstance:informNewBoundsAreHandled()
	self.recalculate_bounds_flag = false
end

function ModelInstance:getModelReferenceBoundingBox()
	return self.props.model_i_reference.props.model_bounding_box
end

function ModelInstance:getUnfixedModelReferenceBoundingBox()
	return self.props.model_i_reference.props.model_bounding_box_unfixed
end

local __p_temptable = {
{0,0,0,0},
{0,0,0,0},
{0,0,0,0},
{0,0,0,0},
{0,0,0,0},
{0,0,0,0},
{0,0,0,0},
{0,0,0,0}}
local __tempnewmin = {}
local __tempnewmax = {}
function ModelInstance:calculateBoundingBox()
	local bbox = self:getUnfixedModelReferenceBoundingBox()
	local min = bbox.min
	local max = bbox.max

	local model_mat = self.static_model_matrix

	local p = __p_temptable
	-- beautiful
	p[1][1] = min[1]     p[1][2] = min[2]    p[1][3] = min[3]  p[1][4] = 1
	p[2][1] = max[1]     p[2][2] = min[2]    p[2][3] = min[3]  p[2][4] = 1
	p[3][1] = min[1]     p[3][2] = max[2]    p[3][3] = min[3]  p[3][4] = 1
	p[4][1] = max[1]     p[4][2] = max[2]    p[4][3] = min[3]  p[4][4] = 1
	p[5][1] = min[1]     p[5][2] = min[2]    p[5][3] = max[3]  p[5][4] = 1
	p[6][1] = max[1]     p[6][2] = min[2]    p[6][3] = max[3]  p[6][4] = 1
	p[7][1] = min[1]     p[7][2] = max[2]    p[7][3] = max[3]  p[7][4] = 1
	p[8][1] = max[1]     p[8][2] = max[2]    p[8][3] = max[3]  p[8][4] = 1

	local mat_vec4_mul = cpml.mat4.mul_vec4
	-- transform all 8 vertices by the model matrix
	for i=1,8 do
		local vec = p[i]
		mat_vec4_mul(vec, model_mat, vec)

		-- perform w perspective division
		local w = vec[4]
		vec[1] = vec[1] / w
		vec[2] = vec[2] / w
		vec[3] = vec[3] / w
		--vec[4] = 1 
	end

	-- we find out the new min/max x,y,z components of all the
	-- transformed vertices to get the min/max for our new
	-- bounding box
	local new_min = __tempnewmin
	local new_max = __tempnewmax
	--local new_min = { 1/0,  1/0,  1/0}
	--local new_max = {-1/0, -1/0, -1/0}
	new_min[1] = 1/0
	new_min[2] = 1/0
	new_min[3] = 1/0
	new_max[1] =-1/0
	new_max[2] =-1/0
	new_max[3] =-1/0

	for i=1,8 do
		local vec = p[i]
		if vec[1] < new_min[1] then new_min[1] = vec[1] end
		if vec[2] < new_min[2] then new_min[2] = vec[2] end
		if vec[3] < new_min[3] then new_min[3] = vec[3] end

		if vec[1] > new_max[1] then new_max[1] = vec[1] end
		if vec[2] > new_max[2] then new_max[2] = vec[2] end
		if vec[3] > new_max[3] then new_max[3] = vec[3] end
	end

	local self_bbox = self.props.model_i_bounding_box
	self_bbox.min[1] = new_min[1]
	self_bbox.min[2] = new_min[2]
	self_bbox.min[3] = new_min[3]
	self_bbox.max[1] = new_max[1]
	self_bbox.max[2] = new_max[2]
	self_bbox.max[3] = new_max[3]
end

-- returns the bounding box
-- returns two tables for the position and size for the box
function ModelInstance:getBoundingBoxPosSize()
	local bbox = self.props.model_i_bounding_box
	local min = bbox.min
	local max = bbox.max
	local size = {max[1]-min[1], max[2]-min[2], max[3]-min[3]}
	return min, size
end

function ModelInstance:getBoundingBoxMinMax()
	local bbox = self.props.model_i_bounding_box
	local min = bbox.min
	local max = bbox.max
	return min, max
end

function ModelInstance:getModelReference()
	return self.props.model_i_reference
end

function ModelInstance:setPosition(pos)
	local v = self.props.model_i_position
	if pos[1]~=v[1]or pos[2]~=v[2] or pos[3]~=v[3] then
		self.props.model_i_position[1] = pos[1]
		self.props.model_i_position[2] = pos[2]
		self.props.model_i_position[3] = pos[3]
		--self.props.model_i_position = pos
		self.model_moved = true
	end
end
function ModelInstance:setRotation(rot)
	local r = self.props.model_i_rotation
	if rot[1]~=r[1] or rot[2]~=r[2] or rot[3]~=r[3] or rot[4] ~= rot[4] then
		--self.props.model_i_rotation = rot
		self.props.model_i_rotation[1] = rot[1]
		self.props.model_i_rotation[2] = rot[2]
		self.props.model_i_rotation[3] = rot[3]
		self.props.model_i_rotation[4] = rot[4]
		self.model_moved = true
	end
end
ModelInstance.setDirection = ModelInstance.setRotation
function ModelInstance:setScale(scale)
	local s = self.props.model_i_scale
	if scale[1]~=s[1] or scale[2]~=s[2] or scale[3]~=s[3] then
		self.props.model_i_scale[1] = scale[1]
		self.props.model_i_scale[2] = scale[2]
		self.props.model_i_scale[3] = scale[3]
		self.model_moved = true
	end
end

function ModelInstance:setMatrix(mat)
	local m = self.props.model_i_matrix
	local change = false
	for i=1,16 do
		if m[i] ~= mat[i] then change = true end
		m[i] = mat[i]
	end
	self.matrix_changed = change
end

function ModelInstance:getPosition()
	return self.props.model_i_position end
function ModelInstance:getRotation()
	return self.props.model_i_rotation end
function ModelInstance:getScale()
	return self.props.model_i_scale end

function ModelInstance:getTransformMode()
	return self.props.model_i_transformation_mode end
function ModelInstance:getTransformMatrix()
	return self.props.model_i_matrix end

function ModelInstance:isStatic()
	return self.props.model_i_static
end

function ModelInstance:getModel()
	return self.props.model_i_reference
end

function ModelInstance:getDirection()
	local rot = self.props.model_i_rotation
	if rot[4] == "dir" then return rot end
	return {0,0,-1,"dir"}
end

function ModelInstance:queryModelMatrix()
	local m,n = self.static_model_matrix, self.static_normal_matrix
	return self.static_model_matrix, self.static_normal_matrix
end

function ModelInstance:getAnimator()
	local props = self.props
	local a1,a2 = props.model_i_animator1, props.model_i_animator2
	return a1,a2
end

--function ModelInstance:fillOutBoneMatrices(animation, frame)
function ModelInstance:fillOutBoneMatrices()
	--if not self.update_bones() then return end

	local model = self:getModel()

	local animator1 = self.props.model_i_animator1
	local animator2 = self.props.model_i_animator2

	if animator1 and animator2 then

		local interp = self.props.model_i_animator_interp
		local outframe = self:getOutframe()
		local outframe_buffer = model:getOutframeBuffer() -- 2nd buffer for calculation of the right size
		                                                  -- supplied by the model :]

		Animator.interpolateTwoAnimators(animator1, animator2, interp,
		  outframe, outframe_buffer, outframe)

		--self.bone_matrices = model:getBoneMatrices(animation, frame, self.bone_matrices)
		self.anim_generated = true
	end
end

function ModelInstance:sendBoneMatrices(shader)
	local model = self:getModel()
	if not model.props.model_animated or not self.anim_generated then
		shadersend(shader, "u_skinning", 0)
	else
		shadersend(shader, "u_skinning", 1)
		shadersend(shader, "u_bone_matrices", "column", unpack(self.bone_matrices))
	end
end

function ModelInstance:sendToShader(shader, animate)
	local shader = shader or love.graphics.getShader()

	local model_u, normal_u = self:queryModelMatrix()
	--model_u, normal_u = self:modelMatrix()
	shadersend(shader, "u_model", "column", matrix(model_u))
	shadersend(shader, "u_normal_model", "column", matrix(normal_u))

	self:sendBoneMatrices(shader)
end

function ModelInstance:draw(shader, is_main_pass)
	local shader = shader or love.graphics.getShader()

	self:sendToShader(shader)

	local det = self.props.model_i_matrix_det
	if det > 0 then
		love.graphics.setFrontFaceWinding("cw") end

	if is_main_pass then
		local base_model = self:getModel()
		base_model:sendMaterial(shader)
	end

	local props = self.props

	local colour = props.model_i_colour
	love.graphics.setColor(colour[1],colour[2],colour[3],colour[4])

	if props.model_i_draw_instances then
		self:drawInstances(shader)
	elseif is_main_pass then
		self:drawOutlined(shader)
		self:drawDecorations(shader)
	else
		shadersend(shader,"texture_animated", false)
		self:callDrawMesh()
	end

	if det > 0 then
		love.graphics.setFrontFaceWinding("ccw")
	end
	shadersend(shader, "u_skinning", 0)
	love.graphics.setColor(1,1,1,1)
end

function ModelInstance:callDrawMesh()
	local model = self:getModel()
	love.graphics.draw(model.props.model_mesh)
end

function ModelInstance:drawOutlined(shader)
	local shader = shader or love.graphics.getShader()
	local model = self:getModel()
	local mesh = model:getMesh()

	if self.props.model_i_contour_flag and gfxSetting("enable_contour") then
		self:drawContour(shader)
	end
	self:callDrawMesh()
end

function ModelInstance:drawContour(shader)
	if not (self.props.model_i_contour_flag and gfxSetting("enable_contour")) then return end

	local shader = shader or love.graphics.getShader()
	local model = self:getModel()
	--local mesh = model:getMesh()
	local colour = self.props.model_i_outline_colour
	local offset = self.props.model_i_outline_scale

	--love.graphics.setFrontFaceWinding(model.props.model_vertex_winding)
	love.graphics.setMeshCullMode("back")

	shader:send("u_contour_outline_offset", offset)
	shader:send("u_draw_as_contour", true)
	--shader:send("u_contour_colour", colour)

	self:callDrawMesh()
	--mesh:drawModel(shader)

	love.graphics.setMeshCullMode("front")
	shader:send("u_contour_outline_offset", 0.0)
	shader:send("u_draw_as_contour", false)
	--love.graphics.setFrontFaceWinding("ccw")
end

function ModelInstance:drawInstances(shader) 
	local shader = shader or love.graphics.getShader()
	local attr_mesh = self:getInstancesAttributeMesh()
	local model_mesh = self:getModel():getMesh()
	model_mesh:attachAttribute("InstanceColumn1", attr_mesh, "perinstance")
	model_mesh:attachAttribute("InstanceColumn2", attr_mesh, "perinstance")
	model_mesh:attachAttribute("InstanceColumn3", attr_mesh, "perinstance")
	model_mesh:attachAttribute("InstanceColumn4", attr_mesh, "perinstance")

	shadersend(shader, "instance_draw_call", true)
	love.graphics.drawInstanced(model_mesh, self.props.model_i_instances_count)
	shadersend(shader, "instance_draw_call", false)
end

function ModelInstance:getInstancesAttributeMesh()
	return self.props.model_i_instances.mesh
end

function ModelInstance:drawDecorations(shader)
	local shader = shader or love.graphics.getShader()

	for i,decor in ipairs(self:decorations()) do
		decor:draw(self, shader)
	end
end

function ModelInstance:queryBoneMatrix(bone)
	local index = self:getModel():getBoneIndex(bone)
	if index then
		return self.bone_matrices[index]
	else
		return nil
	end
end

function ModelInstance:decorations()
	return self.props.model_i_decorations
end

function ModelInstance:attachDecoration(decor)
	local name = decor:name()
	assert_type(name, "string")
	local decor_table = self.props.model_i_decorations

	if decor_table[name] then
		error(string.format("ModelInstance:attachDecoration(): decor with name \"%s\" already attached", name))
	end

	table.insert(decor_table, decor)
	decor_table[name] = decor
end

-- name argument can either be the decor_name of the decoration
-- or an index in the decor_table
function ModelInstance:detachDecoration(name)
	local decor_table = self.props.model_i_decorations
	if type(name) == "string" then
		local decor = decor_table[name]
		if not decor then
			error(string.format("ModelInstance:detachDecoration(string): no decor with name \"%s\" found", name))
		end
		decor:releaseModel()
		decor_table[name] = nil
		for i,decor in ipairs(decor_table) do
			if decor:name() == name then
				table.remove(decor_table, i)
				return
			end
		end
	else -- if the argument name is a number index
		local decor = decor_table[name]
		if not decor then
			error(string.format("ModelInstance:detachDecoration(int): index %d out of range", name))
		end
		decor:releaseModel()
		decor_name = decor_table[name]:name()
		decor_table[decor_name] = nil
		table.remove(decor_table, name)
	end
end

function ModelInstance:releaseDecorations()
	local decor_table = self.props.model_i_decorations
	for i,decor in ipairs(decor_table) do
		decor_name = decor:name()
		decor:releaseModel()
		decor_table[decor_name] = nil
		table.remove(decor_table, i)
	end
end

function ModelInstance:isAnimated()
	if self.props.model_i_static then return false end
	return self.props.model_i_reference:isAnimated()
end

function ModelInstance:defaultPose()
	if not self:isAnimated() then return end
	local outframe = self.props.model_i_reference:getDefaultPose(self.bone_matrices)
	self.bone_matrices = outframe
end

function ModelInstance:getAnimationInterp()
	return self.props.model_i_animator_interp
end
function ModelInstance:setAnimationInterp(i)
	if i < 0.0 then i = 0.0 end
	if i > 1.0 then i = 1.0 end
	self.props.model_i_animator_interp = i
end

--[[
--
--
-- Model
--
--
--]]

function Model:generateDirectionFixingMatrix()
	local up_v = cpml.vec3(self.props.model_up_vector)
	local dir_v = cpml.vec3(self.props.model_dir_vector)
	local mat = cpml.mat4.from_direction(up_v, dir_v)
	self.dir_matrix = mat
end

function Model:getDirectionFixingMatrix()
	if not self.dir_matrix then self:generateDirectionFixingMatrix() end
	return self.dir_matrix
end

-- corrects the models bounding box by the model direction fixing matrix
function Model:correctBoundingBox()
	if self.bounds_corrected then return self.props.model_bounding_box end

	local bounds = self.props.model_bounding_box
	local b_min = bounds.min
	local b_max = bounds.max
	local mat4 = cpml.mat4
	local dir_mat = self:getDirectionFixingMatrix()

	-- give the coordinates a 0 w component so they can be multiplied by a mat4
	b_min[4] = 0
	b_max[4] = 0

	-- multiply bounds by the direction fixing matrix
	mat4.mul_vec4(b_min, dir_mat, b_min)
	mat4.mul_vec4(b_max, dir_mat, b_max)

	local function swap(a,b,i)
		local temp = a[i]
		a[i] = b[i]
		b[i] = temp
	end
	-- after transformation, we need to determine the new min/max for x,y,z
	if b_min[1] > b_max[1] then swap(b_min,b_max,1) end
	if b_min[2] > b_max[2] then swap(b_min,b_max,2) end
	if b_min[3] > b_max[3] then swap(b_min,b_max,3) end

	self.bounds_corrected = true
	return bounds
end

-- returns the bounding box
-- returns two tables for the position and size for the box
--function Model:getBoundingBoxPosSize()
--	local bbox = self.model_bounding_box
--	local pos = bbox.min
--	local max = bbox.max
--	local size = {max[1]-min[1], max[2]-min[2], max[3]-min[3]}
--end
--
--

function Model:getMaterial()
	return self.props.model_material
end

function Model:sendMaterial(shader)
	local shader = shader or love.graphics.getShader()
	local mat = self.props.model_material
	mat:send(shader)
end

function Model:isAnimated()
	if not self.props.model_animated then return false end
	return true
end

function Model:getSkeleton()
	return self.props.model_skeleton
end

function Model:getSkeletonJointCount()
	if self.props.model_skeleton then
		return #self.props.model_skeleton
	else
		return 0
	end
end

function Model:generateBaseFrames()
	local skeleton = self:getSkeleton()

	for bone_id,bone in ipairs(skeleton) do
		local position_v = bone.position
		local rotation_q = bone.rotation
		local scale_v = bone.scale

		local bone_pos_v = cpml.vec3.new(position_v[1], position_v[2], position_v[3])
		local bone_rot_q = cpml.quat.new(rotation_q[1], rotation_q[2], rotation_q[3], rotation_q[4])
		bone_rot_q = bone_rot_q:normalize()
		local bone_scale_v = cpml.vec3.new(scale_v[1], scale_v[2], scale_v[3])

		local rotation_u = cpml.mat4.from_quaternion( bone_rot_q )
		local position_u = cpml.mat4.new(1)
		local scale_u    = cpml.mat4.new(1)

		position_u:translate(position_u, bone_pos_v)
		scale_u:scale(scale_u, bone_scale_v)

		local matrix = position_u * rotation_u * scale_u
		local invmatrix = cpml.mat4():invert(matrix)

		self.baseframe[bone_id] = matrix
		self.inversebaseframe[bone_id] = invmatrix

		if bone.parent > 0 then -- if bone has a parent
			self.baseframe[bone_id] = self.baseframe[bone.parent] * self.baseframe[bone_id]
			self.inversebaseframe[bone_id] = self.inversebaseframe[bone_id] * self.inversebaseframe[bone.parent]
		end

		bone.offset = matrix
	end
end

function Model:generateAnimationFrames()
	for frame_i, frame in ipairs(self.props.model_animations.frames) do
		self.frames[frame_i] = {}
		local output_frames = self.frames[frame_i]

		for pose_i, pose in ipairs(frame) do
			
			local position = pose.translate
			local rotation = pose.rotate
			local scale = pose.scale

			local pos_v = cpml.vec3.new(position[1], position[2], position[3])
			local rot_q = cpml.quat.new(rotation[1], rotation[2], rotation[3], rotation[4])
			rot_q = rot_q:normalize()
			local scale_v = cpml.vec3.new(scale[1], scale[2], scale[3])

			local position_u = cpml.mat4.new(1)
			local rotation_u = cpml.mat4.from_quaternion( rot_q )
			local scale_u    = cpml.mat4.new(1)

			position_u:translate(position_u, pos_v)
			scale_u:scale(scale_u, scale_v)

			--local matrix = scale_u * rotation_u * position_u
			local matrix = position_u * rotation_u * scale_u
			local invmatrix = cpml.mat4():invert(matrix)

			local bone = self:getSkeleton()[pose_i]

			if bone.parent > 0 then -- if bone has a parent
				output_frames[pose_i] = self.baseframe[bone.parent] * matrix * self.inversebaseframe[pose_i]
			else
				output_frames[pose_i] = matrix * self.inversebaseframe[pose_i]
			end
		end
	end
end

-- if animation is nil, then default reference pose is used
function Model:getBoneMatrices(animation, frame, outframe)
	if not self.props.model_animated then return end

	local skeleton = self:getSkeleton()

	--local outframe = outframe or {}

	local anim_data = nil
	if animation then
		anim_data = self.props.model_animations[animation]
	end
	if not anim_data then
		--local outframe = self.outframes
		if animation then
		print("getBoneMatrices(): animation \"" .. animation .. "\" does not exist, (model " .. self.props.model_name .. ")")
		end

		return self:getDefaultPose(outframe)
	end

	local frame1,frame2,interp = self:getInterpolatedFrames(animation, frame)
	outframe = self:interpolateTwoFrames(frame1, frame2, interp, outframe)
	return outframe
end

function Model:getInterpolatedFrames(animation, frame, dont_loop)
	if not self.props.model_animated then return nil, nil end

	local anim_data = nil
	if animation then
		anim_data = self.props.model_animations[animation]
	end
	if not anim_data then
		--local outframe = self.outframes
		if animation then
			print("getInterpolatedFrames(): animation \"" .. animation .. "\" does not exist, (model " .. self.props.model_name .. ")")
			return nil,nil,nil
		end
	end

	local anim_first  = anim_data.first
	local anim_last   = anim_data.last
	local anim_length = anim_last - anim_first
	local anim_rate   = anim_data.framerate

	local frame_fitted = frame * anim_rate / tickRate()
	local frame_floor  = math.floor(frame_fitted)
	local frame_interp = frame_fitted - frame_floor
	--local frame_interp_i = 1.0 - frame_interp 

	local frame1_id = anim_first + (frame_floor-1) % anim_length
	local frame2_id = anim_first + (frame_floor) % anim_length

	local frame1 = self.frames[frame1_id]
	local frame2 = self.frames[frame2_id]

	return frame1, frame2, frame_interp
end

function Model:getInterpolatedFrameIndices(animation, frame, dont_loop)
	if not self.props.model_animated then return nil, nil end

	local anim_data = nil
	if animation then
		anim_data = self.props.model_animations[animation]
	end
	if not anim_data then
		if animation then
			print("getInterpolatedFrameIndices(): animation \"" .. animation .. "\" does not exist, (model " .. self.props.model_name .. ")")
			return nil,nil
		end
	end

	local anim_first  = anim_data.first
	local anim_last   = anim_data.last
	local anim_length = anim_last - anim_first
	local anim_rate   = anim_data.framerate

	local frame_fitted = frame * anim_rate / tickRate()
	local frame_floor  = math.floor(frame_fitted)
	local frame_interp = frame_fitted - frame_floor
	--local frame_interp_i = 1.0 - frame_interp 

	local clamp = function(a,low,up) return min(max(a,low),up) end
	
	if not dont_loop then
		local frame1_id = anim_first + (frame_floor-1) % anim_length
		local frame2_id = anim_first + (frame_floor) % anim_length
		return frame1_id, frame2_id
	else
		local frame1_id = clamp(anim_first + (frame_floor-1), anim_first, anim_last)
		local frame2_id = clamp(anim_first + (frame_floor),   anim_first, anim_last)
		return frame1_id, frame2_id
	end
end

function Model:getUninterpolatedFrame(animation, frame, dont_loop)
	if not self.props.model_animated then return nil, nil end
	local dont_loop = dont_loop or false

	local anim_data = nil
	if animation then
		anim_data = self.props.model_animations[animation]
	end
	if not anim_data then
		--local outframe = self.outframes
		if animation then
			print("getInterpolatedFrames(): animation \"" .. animation .. "\" does not exist, (model " .. self.props.model_name .. ")")
		end
		return nil,nil,nil
	end

	local anim_first  = anim_data.first
	local anim_last   = anim_data.last
	local anim_length = anim_last - anim_first
	local anim_rate   = anim_data.framerate

	local frame_fitted = frame * anim_rate / tickRate()
	local frame_floor  = math.floor(frame_fitted)
	--local frame_interp = frame_fitted - frame_floor
	--local frame_interp_i = 1.0 - frame_interp
	--
	local clamp = function(a,low,up) return min(max(a,low),up) end

	local frame_id = nil
	if not dont_loop then
		frame_id = anim_first + (frame_floor-1) % anim_length
	else
		frame_id = clamp(anim_first + (frame_floor-1), anim_first, anim_last)
	end
	--local frame1_id = anim_first + (frame_floor-1) % anim_length
	--local frame2_id = anim_first + (frame_floor) % anim_length

	local frame = self.frames[frame_id]

	return frame
end

function Model:interpolateTwoFrames(frame1, frame2, interp, outframe)
	local skeleton = self:getSkeleton()

	local mat4 = cpml.mat4
	local mat4new = mat4.new
	local mat4mul = mat4.mul

	local frame_interp   = interp
	local frame_interp_i = 1.0 - interp

	local temps = self.outframes_buffer
	local temp_mat = mat4new()

	for i,pose1 in ipairs(frame1) do
		pose2 = frame2[i]

		for j=1,16 do
			outframe[i][j] =
			 (frame_interp_i)*pose1[j] + frame_interp*pose2[j]
		end

		local parent_i = skeleton[i].parent
		if parent_i > 0 then
			mat4mul(outframe[i], outframe[parent_i], outframe[i])
		else
			--outframe[i] = outframe[i]
		end
	end

	return outframe
end

function Model:getAnimationFrame(index)
	local frame = self.frames[index]
	assert(frame~=nil,"Model:getAnimationFrame(): index out of range")
	return frame
end

function Model:getDefaultPose(outframe)
	local id =
	{1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1}

	for i=1,self:getSkeletonJointCount() do
		for j=1,16 do
			outframe[i][j] = id[j]
		end
	end
	return outframe
end

function Model:animationExists(animation)
	if not animation then return false end
	if not self.props.model_animated then return false end
	anim_data = self.props.model_animations[animation]
	return anim_data ~= nil
end

function Model:getAnimation(animation)
	if not animation then return nil end
	if not self.props.model_animated then return nil end
	anim_data = self.props.model_animations[animation]
	if not anim_data then error(string.format("Model:getAnimation(): model \"%s\" has no animation \"%s\".", self.props.model_name, animation)) end
	return anim_data
end

-- this is for use in multi-threaded animation calculation
-- basically the same as get getBoneMatrices, but we just return frame1, frame2, parents and the interp value so
-- all the later steps can be multi-threaded :]
-- returns nil,nil,nil,nil if model is not animated/default animation is used
function Model:getAnimationFramesDataForThread(animation, frame)
	if not self.props.model_animated then return nil, nil end

	local skeleton = self:getSkeleton()

	local mat4 = cpml.mat4
	local mat4new = mat4.new
	local mat4mul = mat4.mul

	--local outframe = outframe or {}

	local anim_data = nil
	if animation then
		anim_data = self.props.model_animations[animation]
	end
	if not anim_data then
		--local outframe = self.outframes
		if animation then
		print("getBoneMatrices(): animation \"" .. animation .. "\" does not exist, (model " .. self.props.model_name .. ")")
		end

		local mat = mat4new(1.0)
		for i,v in ipairs(skeleton) do
			outframe[i] = mat
		end
		return outframe
	end

	local anim_first  = anim_data.first
	local anim_last   = anim_data.last
	local anim_length = anim_last - anim_first
	local anim_rate   = anim_data.framerate

	local frame_fitted = frame * anim_rate / tickRate()
	local frame_floor  = math.floor(frame_fitted)
	local frame_interp = frame_fitted - frame_floor
	local frame_interp_i = 1.0 - frame_interp 

	local frame1_id = anim_first + (frame_floor-1) % anim_length
	local frame2_id = anim_first + (frame_floor) % anim_length

	local frame1 = self.frames[frame1_id]
	local frame2 = self.frames[frame2_id]

	local parents = {}

	local s = #frame1
	for i=1,s do
		parents[i] = skeleton[i].parent
	end

	return frame1,frame2,parents,frame_interp
end

function Model:getAnimationFrames()
	local frames = self.frames
	assert(frames)
	return frames
end

function Model:getOutframeBuffer()
	local buf = self.outframe_buffer
	assert(buf)
	return buf
end

function Model:getBoneIndex(bone)
	local joint_map = self.props.model_animations.joint_map
	assert(joint_map)
	return joint_map[bone]
end
