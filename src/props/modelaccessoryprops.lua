ModelDecorPropPrototype = Props:prototype{

	-- prop      prop     prop default    prop input     prop      read
	-- name      type        value        validation     info      only

	{"decor_name",       "string", "", nil, "model decor ID"},
	{"decor_reference",   nil, nil, nil, "model accessory model" },
	{"decor_model_name", "string", "", nil, "filename for this model decor's reference model"},

	{"decor_position", "table", nil, PropDefaultTable{0,0,0}, "model accessory's local position"},
	{"decor_rotation", "table", nil, PropDefaultTable{0,0,0, "rot"}, "model accessory's local rotation"},
	{"decor_scale"   , "table", nil, PropDefaultTable{1,1,1}, "model accessory's local scale"},

	{"decor_shadow_mult", "number", 0.5, nil, "1.0 is full shadows, 0.0 is no shadows, numbers inbetween lessen shadows"},

	{"decor_animated_face", nil, nil, nil, "if this decor is meant for an animated face, put it here"},

	{"decor_parent_bone", "string", "", nil, "parent bone to follow"}

}
