shader_type spatial;
render_mode blend_mix;

vec2 nyx_hash2_vr(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(sin(p) * 43758.5453);
}
float nyx_voronoi(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float d = 8.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 n = vec2(float(x), float(y));
			vec2 diff = n + nyx_hash2_vr(i + n) - f;
			d = min(d, dot(diff, diff));
		}
	}
	return sqrt(d);
}
void fragment() {
	ALBEDO = vec3(0.5, 0.5, 0.5);
	ALPHA = smoothstep(0.2000, 0.9000, nyx_voronoi((VERTEX).xy * 8.00));
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	EMISSION = (vec3(1.0000, 1.0000, 1.0000) * smoothstep(0.2000, 0.9000, nyx_voronoi((VERTEX).xy * 8.00)));
}
