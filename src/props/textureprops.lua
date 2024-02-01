--[[ property table prototype for texture object
--]]
--

require "prop"

TexturePropPrototype = Props:prototype{

	-- prop      prop     prop default    prop input     prop      read
	-- name      type        value        validation     info      only

	{"texture_name", "string", "", nil, "texture name", "readonly" }, -- done

	{"texture_imgs", "table", nil, PropDefaultTable{},       "table of textures animation frames"},
	{"texture_frames", "number", 1, nil,                "number of animation frames"},
	{"texture_sequence", "table", nil, PropDefaultTable{},              "table of indices "},
	{"texture_sequence_length", "number", 1, nil,       "table of indices "},

	{"texture_merged_img", nil, nil, nil,               "all the frames of an animated texture in one"},
	{"texture_merged_dim_x", "number", 1, nil,        "how many textures there are in the x direction in merged texture"},
	{"texture_merged_dim_y", "number", 1, nil,        "how many textures there are in the x direction in merged texture"},
	{"texture_merged_coords", nil, nil, nil,            "uv texture coordinates for the merged image"},

	{"texture_animated", "boolean", false, nil,         "is texture animated?", "readonly"},

	{"texture_animation_delay", "number", 60/2,     nil,    "delay between each animation frame in 1/60th of a second"},
	{"texture_type",            "string", "2d",     PropIsOneOf{"2d","array","cube","volume"}},

	-- texture size is determined by first frame
	-- textures are expected to have the same size in an animation
	{"texture_height", "number", 1, nil, "texture height"},
	{"texture_width" , "number", 1, nil, "texture width"}

}
