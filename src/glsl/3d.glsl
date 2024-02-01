#pragma language glsl3

varying vec3 frag_position;
varying vec3 frag_w_position;
varying vec4 dir_frag_light_pos;
varying vec4 dir_static_frag_light_pos;
varying vec3 frag_normal;
varying vec3 frag_v_normal;

uniform int u_point_light_count;
uniform float u_shadow_imult;
uniform mat4 u_dir_lightspace;
uniform mat4 u_dir_static_lightspace;

// used to set the brightness of fog
uniform float skybox_brightness;

uniform bool  u_uses_tileatlas;
uniform Image u_tileatlas;
uniform vec4  u_tileatlas_uv[128];
uniform bool  u_tileatlas_clampzero;

#ifdef VERTEX

uniform mat4 u_view;
uniform mat4 u_rot;
uniform mat4 u_model;
uniform mat4 u_proj;
uniform mat4 u_normal_model;

attribute vec3 VertexNormal;
attribute vec4 VertexWeight;
attribute vec4 VertexBone;
attribute vec3 VertexTangent;

uniform mat4 u_bone_matrices[48];
uniform int  u_skinning;

uniform float u_contour_outline_offset;

uniform bool  u_depth_bias_enable;
uniform float u_depth_bias;

uniform int output_w;
uniform int output_h;

mat4 get_deform_matrix() {
	if (u_skinning != 0) {
		return
			u_bone_matrices[int(VertexBone.x*255.0)] * VertexWeight.x +
			u_bone_matrices[int(VertexBone.y*255.0)] * VertexWeight.y +
			u_bone_matrices[int(VertexBone.z*255.0)] * VertexWeight.z +
			u_bone_matrices[int(VertexBone.w*255.0)] * VertexWeight.w;
	}
	return mat4(1.0);
}

mat3 get_normal_matrix(mat4 skin_u) {
	// u_normal_model matrix is calculated outside and passed to shader
	// if skinning is enabled then this needs to be recalculated
	if (u_skinning != 0) {
		return mat3(transpose(inverse(skin_u)));
	} 
	return mat3(u_normal_model);
}

mat4 get_model_matrix() {
	return u_model;
}

vec4 position(mat4 transform, vec4 vertex) {
	mat4 skin_u = get_model_matrix() * get_deform_matrix();
	mat4 skinview_u = u_view * skin_u;

	frag_normal = normalize(get_normal_matrix(skin_u) * VertexNormal);
	frag_v_normal = frag_normal;

	vec4 model_v = skin_u * vertex;
	vec4 view_v = skinview_u * vertex;

	frag_position = (u_rot * view_v).xyz;

	vec4 surface_offset = vec4(normalize(frag_normal) * u_contour_outline_offset, 0.0);
	view_v += surface_offset;

	view_v = u_rot * view_v;
	frag_v_normal = mat3(u_rot) * frag_v_normal;

	// interpolate fragment position in viewspace and worldspace
	frag_w_position = model_v.xyz;

	vec4 result_v = u_proj * view_v;
	if (u_depth_bias_enable) {
		result_v.z -= u_depth_bias;
		return result_v;
	} else {
		return result_v;
	}
}
#endif

#ifdef PIXEL

uniform vec3 view_pos;

uniform Image MainTex;

uniform vec3 u_light;

uniform float draw_to_outline_buffer;
uniform vec4 outline_colour;

uniform bool u_draw_as_contour;
uniform vec4 u_contour_colour;

// material info
uniform Image MatEmission;
uniform Image MatColour;

float random(vec3 seed, int i){
	vec4 seed4 = vec4(seed,i);
	float dot_product = dot(seed4, vec4(12.9898,78.233,45.164,94.673));
	return fract(sin(dot_product) * 43758.5453);
}

void effect( ) {
	// when drawing the model in contour line phase, we only need a solid
	// colour and can skip all the other fragment calculations
	if (u_draw_as_contour) {
		love_Canvases[0] = u_contour_colour;
		return;
	}

	float dist = (frag_position.z*frag_position.z) + (frag_position.x*frag_position.x) + (frag_position.y*frag_position.y);
	dist = sqrt(dist);

	// normal bump-mapping
	vec3 normal = frag_normal;

	vec4 texcolor;
	texcolor = Texel(MainTex, VaryingTexCoord.xy);
	vec4 emission;
	emission = Texel(MatEmission, VaryingTexCoord.xy);

	love_Canvases[0] = texcolor*vec4(u_light,1.0) + texcolor*vec4(emission.xyz,1.0);
}

#endif
