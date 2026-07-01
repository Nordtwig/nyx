shader_type spatial;
void fragment() {
	ALBEDO = vec3(0.8802, 0.0138, 0.0138);
	ALPHA = 1.0;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	EMISSION = (mix(vec3(0.0000, 0.2656, 0.5000), vec3(0.2969, 0.9341, 1.0000), pow(clamp(1.0 - dot(NORMAL, VIEW), 0.0, 1.0), 3.0)) * sin(TIME));
}
