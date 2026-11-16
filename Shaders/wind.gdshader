shader_type particles;

uniform float height = 140.0;        // how tall the column is, in px
uniform float base_radius = 14.0;    // radius at the bottom
uniform float top_radius = 42.0;     // radius at the top
uniform float radius_curve = 1.0;    // 1 = straight funnel, above 1 = stays narrow longer
uniform float spin_speed = 7.0;      // radians per second
uniform float squash = 0.25;         // 0 = pure side view, higher = looking down on it a bit
uniform float sway = 6.0;            // px the top swings side to side
uniform float only_side = 0.0;       // 1 = front half only, -1 = back half only, 0 = all
uniform vec4 color_back : source_color = vec4(0.5, 0.55, 0.65, 0.5);
uniform vec4 color_front : source_color = vec4(0.95, 0.97, 1.0, 1.0);
uniform float size_back = 0.6;
uniform float size_front = 1.0;

void start() {
	float n = float(NUMBER);
	CUSTOM.x = fract(n * 0.618034) * TAU;   // starting angle, spread evenly around the circle
	CUSTOM.y = 0.0;                         // age in seconds
	CUSTOM.z = fract(n * 0.754877);         // per-dot random
}

void process() {
	CUSTOM.y += DELTA;
	float t = CUSTOM.y / LIFETIME;          // 0 at the bottom, 1 at the top
	if (t >= 1.0) {
		ACTIVE = false;
	}

	float r = mix(base_radius, top_radius, pow(t, radius_curve)) * (0.75 + 0.5 * CUSTOM.z);
	float a = CUSTOM.x + CUSTOM.y * spin_speed;
	float depth = sin(a);                   // +1 = in front of the column, -1 = behind it

	vec2 pos;
	pos.x = cos(a) * r + sin(TIME * 1.7) * sway * t;
	pos.y = -height * t + depth * r * squash;

	float front = depth * 0.5 + 0.5;
	float s = mix(size_back, size_front, front);
	if (only_side != 0.0 && depth * only_side < 0.0) {
		s = 0.0;
	}

	COLOR = mix(color_back, color_front, front);
	COLOR.a *= smoothstep(0.0, 0.15, t) * (1.0 - smoothstep(0.75, 1.0, t));

	TRANSFORM = mat4(
		vec4(s, 0.0, 0.0, 0.0),
		vec4(0.0, s, 0.0, 0.0),
		vec4(0.0, 0.0, 1.0, 0.0),
		vec4(pos, 0.0, 1.0));
}
