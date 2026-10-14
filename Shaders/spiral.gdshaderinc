uniform float intensity : hint_range(0.0, 1.0) = 1.0;
//uniform vec3 target_color : source_color = vec3(0.91, 0.72, 0.79);
global uniform float spiral_progress;
global uniform bool is_spiral_clockwise;
global uniform bool is_spiral_switching_colors;

vec4 gray_scale_color(vec3 target_color, vec4 texColor) {
    vec3 weights = vec3(0.2126, 0.7152, 0.0722);
    float gray = dot(texColor.rgb, weights);
    vec3 colorized = gray * target_color * 2.3;
	float peak = max(colorized.r, max(colorized.g, colorized.b));
    if (peak > 1.0) {
        colorized /= peak;
    }
    vec3 result = mix(vec3(gray), colorized, intensity);
    return vec4(result, texColor.a);
}

vec4 spiral_color(vec4 texColor, vec2 screen_uv, vec3 color_a, vec3 color_b) {
    vec2 p = screen_uv - vec2(0.5);
    float a = atan(p.x, -p.y);
    float t = fract(a / TAU + 0.5);
    if (!is_spiral_clockwise) t = 1.0 - t;
    float s = 0.0001;
    float edge = spiral_progress * (1.0 + s);
    float m = 1.0 - smoothstep(edge - s, edge, t);
	if (is_spiral_switching_colors) {
		return mix(gray_scale_color(color_b, texColor), gray_scale_color(color_a, texColor), m);
	}
    return mix(gray_scale_color(color_a, texColor), gray_scale_color(color_b, texColor), m);
}

//vec4 texColor = texture(screen_texture, SCREEN_UV);
	//vec3 weights = vec3(0.2126, 0.7152, 0.0722);
	//float gray = dot(texColor.rgb, weights);
	//COLOR = vec4(gray*2.4,0,gray*1.6, texColor.a);
	
	//vec4 texColor = texture(screen_texture, SCREEN_UV);
	//vec3 weights = vec3(0.2126, 0.7152, 0.0722);
	//float gray = dot(texColor.rgb, weights);
	 //// Preserve brightness variation while using a stronger pink palette.
    //vec3 pinkColor = vec3(
        //gray * 2.3,
        //gray * 1.2,
        //gray * 1.86
    //);
//
    //vec3 result = mix(vec3(gray), pinkColor, intensity);
//
    //COLOR = vec4(result, texColor.a);
