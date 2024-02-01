#pragma language glsl3

#ifdef VERTEX
vec4 position( mat4 transform_projection, vec4 vertex_position ) {
	return transform_projection * vertex_position;
}
#endif

#ifdef PIXEL

uniform float strength;
uniform float alpha_strength;
uniform ivec2 texture_size;

vec4 effect( vec4 color, sampler2D tex, vec2 texture_coords, vec2 screen_coords ) {
	ivec2 size = texture_size;
	int x = int(size.x * texture_coords.x);
	int y = int(size.y * texture_coords.y);
	float scalar1 = max(0.0, 1.0 - (y % 2)*strength);
	float scalar2 = max(0.0, 1.0 - (x % 2)*strength*0.2);
	float scalar = scalar1*scalar2;
	float a_scalar = max(0.0, 1.0 - (y % 2)*alpha_strength);

	vec4 texcolor = Texel(tex, texture_coords);
	return texcolor * color * vec4(scalar,scalar,scalar,a_scalar);
}
#endif
