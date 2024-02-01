#pragma language glsl3

#ifdef VERTEX
	vec4 position(mat4 transform, vec4 vertex) {
		return transform * vertex;
	}
#endif

#ifdef PIXEL
	uniform float exposure;
	uniform float gamma;

	vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords ) {
		float exposure_val = exposure;

		vec4 pix_color = Texel(tex, texture_coords);
		vec3 hdr_color = pix_color.rgb;

		vec3 result = vec3(1.0) - exp(-hdr_color * exposure_val) + gamma*vec3(0.0000001,0,0);

    //result.rgb = pow(result.rgb, vec3(1.0/gamma));

		return vec4(result, 1.0);
	}
#endif
