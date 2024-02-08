require "prop"

MeoxIconGUIEntPropPrototype = Props:prototype{

	-- prop      prop     prop default    prop input     prop      read
	-- name      type        value        validation     info      only

	{"icongui_model", nil, nil, nil, "model instance" }, -- done
	{"icongui_size", "number", 1.0, nil, "current icon scale"},
	{"icongui_delete", "boolean", false, nil, "set true to shrink and disappear"},
	{"icongui_icon_parent", nil, nil, nil, "the icon object this gui object represents"},

}
