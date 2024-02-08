--[[ property table prototype for camera object
--]]
--

require "prop"

CameraPropPrototype = Props:prototype{

	-- prop      prop     prop default    prop input     prop      read
	-- name      type        value        validation     info      only

	{"ocam_position", "table", nil, PropDefaultTable{0,0,0},  "camera position" }, -- done

	{"ocam_mode", "string", "rotation", PropIsOneOf{"rotation","direction"}, "whether the camera is using a rotation or a direction vector"},
	{"ocam_rotation", "table", nil, PropDefaultTable{0,0,0},  "camera rotation" }, -- done
	{"ocam_direction", "table", nil, PropDefaultTable{0,0,-1}, "camera direction"},

	{"ocam_size", "number", 10.0, nil, "camera fov"},
	{"ocam_far_plane", "number", 1000.0, nil, "camera far plane distance"},

	{"cam_function", nil, nil, nil, [[a function(camera) called within Camera:update used to update the camera's position, rotation etc.
	                                  various camera controller functions can then be swapped with this one to have the camera, for example,
									  follow the player, follow a cutscene etc.]]}

}
