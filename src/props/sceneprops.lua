--[[ property table prototype for model object
--]]
--

require "prop"

ScenePropPrototype = Props:prototype{

	-- prop      prop     prop default    prop input     prop      read
	-- name      type        value        validation     info      only

	{"scene_models", "table", nil, PropDefaultTable{}, "scene model collection"},
	{"scene_background", "table", nil, PropDefaultTable{}, "scene background colour"},
	{"scene_camera", "camera", nil, nil, "scene's camera"}
												
}
