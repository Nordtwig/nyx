shader_type spatial;
uniform sampler2D curve_curve : hint_default_white;
uniform sampler2D grad_gradient : source_color, hint_default_white;

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
void fragment() {
	ALBEDO = texture(grad_gradient, vec2(clamp(texture(curve_curve, vec2(clamp(nyx_fbm((VERTEX).xy * 5.00, 4, 2.00, 0.50), 0.0, 1.0), 0.5)).r, 0.0, 1.0), 0.5)).rgb;
	ALPHA = 1.0;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	EMISSION = vec3(0.0, 0.0, 0.0);
}
