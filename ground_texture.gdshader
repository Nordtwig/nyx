shader_type spatial;
uniform sampler2D tex_texturesample : source_color, hint_default_white;
uniform sampler2D nrm_normalmap : hint_normal;

void fragment() {
	ALBEDO = texture(tex_texturesample, (vec3(UV, 0.0)).xy).rgb;
	ALPHA = 1.0;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	EMISSION = vec3(0.0, 0.0, 0.0);
	NORMAL_MAP = texture(nrm_normalmap, (vec3(UV, 0.0)).xy).rgb;
}
