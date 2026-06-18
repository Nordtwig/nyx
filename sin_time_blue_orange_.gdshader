shader_type spatial;
void fragment() {
	ALBEDO = mix(vec3(0.0273, 0.0658, 0.4375), vec3(0.7760, 0.3917, 0.0525), sin(TIME));
	ALPHA = 1.0;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	EMISSION = vec3(0.0, 0.0, 0.0);
}
