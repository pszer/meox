--[[ property table prototype for model object
--]]
--

require "prop"

ScenePropPrototype = Props:prototype{

	-- prop      prop     prop default    prop input     prop      read
	-- name      type        value        validation     info      only

	{"scene_models", "table", nil, PropDefaultTable{}, "scene model collection"},
	{"scene_background1", "table", nil, PropDefaultTable{}, "scene background colour"},
	{"scene_background2", "table", nil, PropDefaultTable{}, "scene background colour"},
	{"scene_camera", "camera", nil, nil, "scene's camera"},
	{"scene_camera_interp_speed", "number", 2.5, nil, "scene's camera movement interp speed"},
	{"scene_nightmode", "boolean", false, nil, "background night mode"},
												
}
