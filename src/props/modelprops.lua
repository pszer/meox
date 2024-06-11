--[[ property table prototype for model object
--]]
--

require "prop"

ModelPropPrototype = Props:prototype{

	-- prop      prop     prop default    prop input     prop      read
	-- name      type        value        validation     info      only

	{"model_name"         , "string", "", nil, "model's name" },
	{"model_texture_fname", "string", "", nil, "model's texture filename"},
	{"model_material", "material", nil, nil,   "model's material"},

	{"model_position", "table", nil, PropDefaultTable{0,0,0}, "model's world position", "readonly"}, -- unused
	{"model_rotation", "table", nil, PropDefaultTable{0,0,0,"rot"}, "model's world rotation"},       -- unused
	{"model_scale"   , "table", nil, PropDefaultTable{1,1,1}, "model's scale"},                      -- unused

	{"model_up_vector" , "table", nil, PropDefaultTable{ 0 , -1 ,  0 }, "model`s upward pointing vector",  "readonly"},
	{"model_dir_vector", "table", nil, PropDefaultTable{ 0 ,  0 , -1 }, "model`s forward pointing vector", "readonly"},
	{"model_vertex_winding", "string", "ccw", PropIsOneOf{"ccw","cw"},  "vertex winding for this model`s mesh", "readonly"},

	{"model_bounding_box_unfixed", "table", nil, PropDefaultTable{min={0,0,0},max={0,0,0}}, [[model's bounding box, given by two min/max vectors,
	                                                                                          uncorrected by this models getDirectionFixingMatrix() ]]},
	{"model_bounding_box", "table", nil, PropDefaultTable{min={0,0,0},max={0,0,0}}, "model's bounding box, given by two min/max vectors"},

	{"model_mesh", nil, nil, nil, "model's mesh object"},

	{"model_animations", nil, nil, nil, "model's animations"},
	{"model_skeleton"  , nil, nil, nil, "model's skeleton"},
	{"model_animated"  , "boolean", false, nil, "is model animated?"},
}

ModelInstancePropPrototype = Props:prototype{

	-- prop      prop     prop default    prop input     prop      read
	-- name      type        value        validation     info      only

	{"model_i_reference", nil, nil, nil, "the model this instance is referencing" },

	{"model_i_transformation_mode", "string", "component", nil, PropIsOneOf{"component","matrix"},
	[[a model can be transformed either by specifying a position, rotation and scale component from which a model matrix is then
	  derived, or a model matrix can be supplied directly. component mode is much easier to work with and recommended
	  for dynamic models]]},

	{"model_i_position", "table", nil, PropDefaultTable{0,0,0}, "model's world position, don't change directly use setPosition"},
	{"model_i_rotation", "table", nil, PropDefaultTable{0,0,0,"rot"}, "model's world rotation, don't change directly use setRotation"},
	{"model_i_scale"   , "table", nil, PropDefaultTable{1,1,1}, "model's scale, don't change directly use setScale"},

	{"model_i_matrix", nil, nil, PropDefaultMatrix(), "matrix to use if transformation_mode is in matrix mode"},
	{"model_i_matrix_det", "number", 1, nil, "determinant of the model matrix"},

	{"model_i_outline_colour", "table", nil, PropDefaultTable{0,0,0,1}, "model's contour colour"},
	{"model_i_outline_scale", "number", 0.20, nil,                      "model's contour scale factor"},
	{"model_i_contour_flag", "boolean", false},

	{"model_i_bounding_box", "table", nil, PropDefaultTable{min={0,0,0},max={0,0,0}}, [[model's bounding box, given by two min/max vectors, 
	                                                                                  calculated by transforming the bounding box from model_i_reference 
	                                                                                  this this model instances model matrix]]},

	{"model_i_static"    , "boolean", false, nil, "is model instance static?"},

	{"model_i_draw_instances", "boolean", false, nil, [[only for static models, if true then model is drawn several times with different
	                                                   positions, rotations, scale specified in model_i_instances using GPU instancing]], "readonly"},
	{"model_i_instances", "table", nil, PropDefaultTable{}, [[a table of the instances to be drawn of this model with GPU instancing, each entry
	                                                          is of the form {position={x,y,z}, rotation={pitch,yaw,roll}, scale={x,y,z}}.
													     	  these instances do NOT inherit properties from this ModelInstance object

															  once a ModelInstance is created, this table should have a member called ["mesh"]
															  with the vertex attributes for each instane (see love.graphics.drawInstanced())
															  ]], "readonly"},
	{"model_i_instances_count", "number", 0, nil, "count of instances in model_i_instances", "readonly"},

	{"model_i_decorations", "table", nil, PropDefaultTable{}, "model's ModelDecor objects"},

	{"model_i_animator1", nil, nil, nil, "model's animator"},
	{"model_i_animator2", nil, nil, nil, "each model has two animators to allow for interpolating between animations"},
	{"model_i_animator_interp", "number", 0.0, nil, "interpolation between the two animators, 0.0 = animator1, 1.0 = animator2"},

	{"model_i_colour", "table", nil, PropDefaultTable{1,1,1,1}, "model tint"}
												
}
