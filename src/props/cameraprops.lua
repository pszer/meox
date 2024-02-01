--[[ property table prototype for camera object
--]]
--

require "prop"

CameraPropPrototype = Props:prototype{

	-- prop      prop     prop default    prop input     prop      read
	-- name      type        value        validation     info      only

	--{"cam_x", "number", 8.5*32, nil, "camera x position" }, -- done
	--{"cam_y", "number", -128-64, nil, "camera y position" }, -- done
	--{"cam_z", "number", -16, nil, "camera z position" }, -- done
	{"cam_position", "table", nil, PropDefaultTable{0,0,0},  "camera position" }, -- done

	{"cam_mode", "string", "rotation", PropIsOneOf{"rotation","direction"}, "whether the camera is using a rotation or a direction vector"},
	{"cam_rotation", "table", nil, PropDefaultTable{0,0,0},  "camera rotation" }, -- done
	{"cam_direction", "table", nil, PropDefaultTable{0,0,-1}, "camera direction"},

	--{"cam_yaw",   "number", 0, nil, "camera yaw angle" }, -- done
	--{"cam_pitch", "number", -0.95, nil, "camera pitch angle" }, -- done
	--{"cam_roll",  "number", 0, nil, "camera roll angle"},

	{"cam_fov", "number", 75.0, nil, "camera fov"},
	{"cam_far_plane", "number", 1750.0, nil, "camera far plane distance"},

	{"cam_perspective_matrix", nil, nil, nil, "perspective matrix"},
	{"cam_view_matrix", nil, nil, nil, "view position matrix"},
	{"cam_rot_matrix", nil, nil, nil, "view rotation matrix"},
	{"cam_rotview_matrix", nil, nil, nil, "view position matrix"},
	{"cam_viewproj_matrix", nil, nil, nil, "view*projection matrix"},
	{"cam_frustrum_corners", nil, nil, nil, "camera`s projection+view frustrum corner coordinates"},
	{"cam_frustrum_centre" , nil, nil, nil, "camera`s projection+view frustrum centre coordinates"},

	{"cam_bend_enabled", "boolean", true, nil,           "when enabled, things further away from the camera decrease in y value"},
	{"cam_bend_coefficient", "number", 8048, PropMin(1), "the lower the number, the more exaggerated the bend effect"},

	{"cam_function", nil, nil, nil, [[a function(camera) called within Camera:update used to update the camera's position, rotation etc.
	                                  various camera controller functions can then be swapped with this one to have the camera, for example,
									  follow the player, follow a cutscene etc.]]}

}
