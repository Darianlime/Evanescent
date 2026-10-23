shader_type canvas_item;

uniform float max_x = 1000000.0;
uniform float min_x = -1000000.0;
uniform float max_y = 1000000.0;
varying vec2 world_xy;

void vertex() {
	world_xy = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	if (world_xy.x < min_x || world_xy.x > max_x) {
        discard;
    }
}
