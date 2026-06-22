shader_type spatial;
render_mode blend_mix;
uniform sampler2D curve_curve : hint_default_white;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_nearest;

float nyx_hash_gn(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
vec2 nyx_grad_gn(vec2 p) {
	float a = nyx_hash_gn(p) * 6.28318;
	return vec2(cos(a), sin(a));
}
float nyx_gradient_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(dot(nyx_grad_gn(i), f),
			dot(nyx_grad_gn(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0)), u.x),
		mix(dot(nyx_grad_gn(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0)),
			dot(nyx_grad_gn(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0)), u.x),
		u.y) * 0.5 + 0.5;
}
float nyx_fbm(vec2 p, int octaves, float lacunarity, float gain) {
	float value = 0.0;
	float amplitude = 0.5;
	float frequency = 1.0;
	for (int i = 0; i < octaves; i++) {
		value += amplitude * nyx_gradient_noise(p * frequency);
		frequency *= lacunarity;
		amplitude *= gain;
	}
	return value;
}
vec3 nyx_normal_from_height(float h, float strength) {
	vec3 n = normalize(vec3(-dFdx(h) * strength, -dFdy(h) * strength, 1.0));
	return n * 0.5 + 0.5;
}
vec3 nyx_blend_normals(vec3 a, vec3 b) {
	vec3 n1 = a * 2.0 - 1.0;
	vec3 n2 = b * 2.0 - 1.0;
	return normalize(vec3(n1.xy + n2.xy, n1.z)) * 0.5 + 0.5;
}
float nyx_depth_fade(float fade_dist, vec2 screen_uv, float frag_depth, mat4 inv_proj) {
	float depth = textureLod(DEPTH_TEXTURE, screen_uv, 0.0).r;
	vec4 pixel_view = inv_proj * vec4(screen_uv * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
	pixel_view.xyz /= pixel_view.w;
	vec4 surface_view = inv_proj * vec4(screen_uv * 2.0 - 1.0, frag_depth * 2.0 - 1.0, 1.0);
	surface_view.xyz /= surface_view.w;
	return clamp((surface_view.z - pixel_view.z) / max(fade_dist, 0.001), 0.0, 1.0);
}
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
void vertex() {
	VERTEX += vec3(0.0000, ((sin(((vec3((VERTEX).r) * 4.0000) + vec3((TIME * 0.3000)))) * 0.0500)).g, 0.0000);
}

void fragment() {
	ALBEDO = mix(vec3(1.0000, 1.0000, 0.9255), mix(vec3(0.0000, 0.2295, 0.4896), texture(SCREEN_TEXTURE, (vec3((vec3(SCREEN_UV, 0.0)).xy + (nyx_blend_normals(nyx_blend_normals(nyx_normal_from_height(nyx_fbm((vec3((vec3(UV, 0.0)).xy * vec2(8.0000, 8.0000) + vec2((sin(TIME) * 0.3000), 0.0000), 0.0)).xy * 1.00, 4, 2.00, 0.50), 15.0000), nyx_normal_from_height(nyx_fbm((vec3((vec3(UV, 0.0)).xy * vec2(11.0000, 11.0000) + vec2(0.0000, (cos(TIME) * 0.3000)), 0.0)).xy * 1.50, 5, 2.00, 0.50), 10.0000)), (nyx_normal_from_height(nyx_voronoi((vec3((vec3(UV, 0.0)).xy * vec2(17.0000, 17.0000) + vec2((0.5000 * TIME), 0.0000), 0.0)).xy * 2.00), 2.0000) * 0.9000))).xy * 0.2000, 0.0)).xy).rgb, 0.3000), nyx_depth_fade(2.0000, SCREEN_UV, FRAGCOORD.z, INV_PROJECTION_MATRIX));
	ALPHA = texture(curve_curve, vec2(clamp(pow(clamp(1.0 - dot(NORMAL, VIEW), 0.0, 1.0), 2.5000), 0.0, 1.0), 0.5)).r;
	ROUGHNESS = 0.2000;
	METALLIC = 0.0;
	EMISSION = vec3(0.0, 0.0, 0.0);
	NORMAL_MAP = nyx_blend_normals(nyx_blend_normals(nyx_normal_from_height(nyx_fbm((vec3((vec3(UV, 0.0)).xy * vec2(8.0000, 8.0000) + vec2((sin(TIME) * 0.3000), 0.0000), 0.0)).xy * 1.00, 4, 2.00, 0.50), 15.0000), nyx_normal_from_height(nyx_fbm((vec3((vec3(UV, 0.0)).xy * vec2(11.0000, 11.0000) + vec2(0.0000, (cos(TIME) * 0.3000)), 0.0)).xy * 1.50, 5, 2.00, 0.50), 10.0000)), (nyx_normal_from_height(nyx_voronoi((vec3((vec3(UV, 0.0)).xy * vec2(17.0000, 17.0000) + vec2((0.5000 * TIME), 0.0000), 0.0)).xy * 2.00), 2.0000) * 0.9000));
}
