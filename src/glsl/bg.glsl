#pragma language glsl3

#ifdef VERTEX
	vec4 position(mat4 transform, vec4 vertex) {
		return transform * vertex;
	}
#endif

#ifdef PIXEL
	uniform vec3 col1;
	uniform vec3 col2;

	uniform float modulate;

	vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords ) {
		//return vec4(
		//	texture_coords.y       * texture_coords.y * col1 +
		//	(1.0-texture_coords.y*texture_coords.y) * col2 , 1.0);
		float p = pow(texture_coords.y,modulate);
		return vec4(
			p * col1 +
			(1.0-p) * col2 , 1.0);
	}
#endif
