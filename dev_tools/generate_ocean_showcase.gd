extends SceneTree

## Dev tool — generates ocean.nyx: the full Sea-of-Thieves ocean graph from
## .nyx-notes/ocean-showcase.md's build guide (Stages A-G), as pure data.
##
## Run with: godot --headless --script dev_tools/generate_ocean_showcase.gd
## (run from the project root so res:// resolves correctly)
##
## Like generate_node_gallery.gd, this NEVER instantiates the actual node
## scripts — every node in this graph (Ocean Waves, Depth Fade, Fresnel, FBM,
## Smoothstep) uses EditorSpinSlider in _ready(), which can only be constructed
## by the real running editor, not a bare --headless --script SceneTree. So the
## graph is built purely as {type, name, position, state} + {from/to node/port}
## dictionaries via NyxSerializer.dict_to_resource(), exactly the data shape a
## real Save writes to disk — never touching a live GraphNode.
##
## compiled_code is intentionally left empty: baking real GLSL requires running
## the actual compiler against real GraphNode port caches, which (like the node
## instantiation above) needs the real editor. Godot's importer falls back to a
## harmless placeholder for a `.nyx` with no compiled_code yet (same as any
## pre-direct-shader-feature file) — open this in Nyx and hit Ctrl+S once
## (nothing needs to change) to bake the real shader before dragging it onto a
## material.
##
## Every wire below was cross-checked against each node script's real
## set_slot()/get_output_snippet() port layout and the type-promotion matrix —
## not guessed. See the session log / feedback.md for the full derivation.

const NyxSerializer = preload("res://addons/nyx/nyx_serializer.gd")
const OUT_PATH := "res://ocean.nyx"

# Lane layout is cosmetic only (position_offset never affects compilation) —
# a simple auto-incrementing grid, one row per stage, so the graph doesn't
# open as a total pile the first time. Bands are spaced 800px apart — real
# rendered node heights aren't knowable headless (EditorSpinSlider only sizes
# in the real editor), so this is deliberately generous rather than tuned:
# Ocean Waves alone (8 sliders + 3 port rows) is easily 300-400px tall, and a
# tight gap here previously buried OutputNode/VertexOutputNode entirely under
# it (found live 2026-07-06 — they were never actually missing from the file,
# just rendered underneath a taller neighbor added after them in the tree).
# Sinks get their own row, well clear of every other lane.
const LANE_Y := {
	"misc": -800.0, "waves": 0.0, "ripple": 800.0, "foam": 1600.0,
	"color": 2400.0, "refract": 3200.0, "glow": 4000.0, "sink": 4800.0,
}
var _lane_x := {}

var _nodes := []
var _connections := []


func _next_pos(lane: String) -> Vector2:
	var x: float = _lane_x.get(lane, 0.0)
	_lane_x[lane] = x + 220.0
	return Vector2(x, LANE_Y[lane])


func _add(type: String, name: String, lane: String, state: Dictionary = {}) -> String:
	_nodes.append({"type": type, "name": name, "position": [_next_pos(lane).x, LANE_Y[lane]], "state": state})
	return name


func _wire(from_node: String, from_port: int, to_node: String, to_port: int) -> void:
	_connections.append({"from_node": from_node, "from_port": from_port, "to_node": to_node, "to_port": to_port})


# A param-mode Float wired into an existing override port — every slider+port
# node (Depth Fade/Fresnel/Smoothstep's Edge0/NormalFromHeight's Strength/FBM's
# Scale) already accepts an optional input alongside its inline default, so
# this needs no node-architecture change, just wiring one in. Note this only
# reaches ports that exist — Ocean Waves' 8 sliders and FBM's Octaves/
# Lacunarity/Gain have no corresponding port at all, so those stay baked state
# (a real, separate gap — see feedback.md).
func _param_float(value: float, param_name: String, lane: String, to_node: String, to_port: int) -> String:
	var n := _add("FloatNode", "Param_%s" % param_name, lane, {"value": value, "param_mode": true, "param_name": param_name})
	_wire(n, 0, to_node, to_port)
	return n


func _initialize() -> void:
	# ---- Sinks (explicit, so they exist before connections wire to them — see
	# _deserialize_graph's ordering; _ensure_spatial_sinks() only fills in what's
	# missing, so declaring them here is authoritative, not a fallback) ----
	# mode 1 = "blend_mix" (see output_node.gd's _SPATIAL_MODES) — required by
	# Depth Fade and Screen Texture, both used in the Albedo chain below; the
	# default opaque pass (mode 0) doesn't populate DEPTH_TEXTURE/SCREEN_TEXTURE
	# correctly, which is what actually caused the washed-out white result found
	# live 2026-07-06 (not a wiring bug — the shader compiled clean throughout).
	_add("OutputNode", "OutputNode", "sink", {"mode": 1, "shader_type": 0})
	_add("VertexOutputNode", "VertexOutputNode", "sink", {})

	# ---- Shared utility sources ----
	var world_pos := _add("WorldPositionNode", "WorldPosition", "misc")
	var time_node := _add("TimeNode", "TimeNode1", "misc")
	var scroll_dir1 := _add("Vector3Node", "ScrollDir1", "misc", {"x": 0.03, "y": 0.02, "z": 0.0})
	var scroll_dir2 := _add("Vector3Node", "ScrollDir2", "misc", {"x": -0.02, "y": 0.035, "z": 0.0})

	# ---- Stage B: the big waves (vertex) ----
	var ocean := _add("OceanWavesNode", "OceanWaves", "waves", {
		"waves": 5, "wavelength": 24.0, "amplitude": 0.6, "steepness": 0.55,
		"speed": 1.0, "direction": 25.0, "spread": 60.0, "seed": 0.0,
	})
	_wire(world_pos, 0, ocean, 0)              # WorldPosition -> Ocean Waves.Position
	_wire(ocean, 0, "VertexOutputNode", 0)     # Offset -> Vertex Output.Offset
	_wire(ocean, 1, "VertexOutputNode", 1)     # Normal -> Vertex Output.Normal

	# ---- Stage D: small waves / detail normals ----
	var split_wp := _add("SplitNode", "SplitWorldPos", "ripple")
	_wire(world_pos, 0, split_wp, 0)

	var combine_uv := _add("CombineNode", "CombineDetailUV", "ripple")
	_wire(split_wp, 0, combine_uv, 0)  # R(=X) -> Combine.R
	_wire(split_wp, 2, combine_uv, 1)  # B(=Z) -> Combine.G

	var scroll_uv1 := _add("MultiplyNode", "ScrollUV1", "ripple")
	_wire(time_node, 0, scroll_uv1, 0)
	_wire(scroll_dir1, 0, scroll_uv1, 1)

	var detail_uv_add := _add("AddNode", "DetailUVAdd", "ripple")
	_wire(combine_uv, 0, detail_uv_add, 0)
	_wire(scroll_uv1, 0, detail_uv_add, 1)

	var relay_detail_uv := _add("RelayNode", "RelayDetailUV", "ripple", {"pair_count": 1, "custom_name": "DetailUV"})
	_wire(detail_uv_add, 0, relay_detail_uv, 0)

	var scroll_uv2 := _add("MultiplyNode", "ScrollUV2", "ripple")
	_wire(time_node, 0, scroll_uv2, 0)
	_wire(scroll_dir2, 0, scroll_uv2, 1)

	var detail_uv_add2 := _add("AddNode", "DetailUVAdd2", "ripple")
	_wire(relay_detail_uv, 0, detail_uv_add2, 0)
	_wire(scroll_uv2, 0, detail_uv_add2, 1)

	var fbm1 := _add("FBMNode", "FBMRipple1", "ripple", {"scale": 2.5, "octaves": 3, "lacunarity": 2.0, "gain": 0.5})
	_wire(relay_detail_uv, 0, fbm1, 0)

	var fbm2 := _add("FBMNode", "FBMRipple2", "ripple", {"scale": 7.0, "octaves": 3, "lacunarity": 2.0, "gain": 0.5})
	_wire(detail_uv_add2, 0, fbm2, 0)

	var detail_height_add := _add("AddNode", "DetailHeightAdd", "ripple")
	_wire(fbm1, 0, detail_height_add, 0)
	_wire(fbm2, 0, detail_height_add, 1)

	var relay_detail_height := _add("RelayNode", "RelayDetailHeight", "ripple", {"pair_count": 1, "custom_name": "DetailHeight"})
	_wire(detail_height_add, 0, relay_detail_height, 0)

	var ripple_normal := _add("NormalFromHeightNode", "RippleNormal", "ripple", {"strength": 6.0})
	_wire(relay_detail_height, 0, ripple_normal, 0)
	_wire(ripple_normal, 0, "OutputNode", 5)  # -> Fragment Output.Normal
	_param_float(6.0, "ripple_normal_strength", "ripple", ripple_normal, 1)
	_param_float(2.5, "fbm1_scale", "ripple", fbm1, 1)
	_param_float(7.0, "fbm2_scale", "ripple", fbm2, 1)

	# ---- Stage E: foam ----
	var fbm_breakup := _add("FBMNode", "FBMBreakup", "foam", {"scale": 4.0, "octaves": 4, "lacunarity": 2.0, "gain": 0.5})
	_wire(relay_detail_uv, 0, fbm_breakup, 0)
	_param_float(4.0, "fbm_breakup_scale", "foam", fbm_breakup, 1)

	var breakup_ss := _add("SmoothstepNode", "BreakupSmoothstep", "foam", {"edge0": 0.42, "edge1": 0.65})
	_wire(fbm_breakup, 0, breakup_ss, 2)  # -> X
	_param_float(0.42, "breakup_edge0", "foam", breakup_ss, 0)
	_param_float(0.65, "breakup_edge1", "foam", breakup_ss, 1)

	var crest_ss := _add("SmoothstepNode", "CrestSmoothstep", "foam", {"edge0": 0.5, "edge1": 0.85})
	_wire(ocean, 2, crest_ss, 2)  # Ocean Waves.Crest -> X
	_param_float(0.5, "crest_edge0", "foam", crest_ss, 0)
	_param_float(0.85, "crest_edge1", "foam", crest_ss, 1)

	var crest_foam_mul := _add("MultiplyNode", "CrestFoamMul", "foam")
	_wire(crest_ss, 0, crest_foam_mul, 0)
	_wire(breakup_ss, 0, crest_foam_mul, 1)

	var depth_fade_shore := _add("DepthFadeNode", "DepthFadeShore", "foam", {"distance": 0.8})
	_param_float(0.8, "depth_shore_distance", "foam", depth_fade_shore, 0)
	var shore_one_minus := _add("OneMinusNode", "ShoreOneMinus", "foam")
	_wire(depth_fade_shore, 0, shore_one_minus, 0)

	var shore_foam_mul := _add("MultiplyNode", "ShoreFoamMul", "foam")
	_wire(shore_one_minus, 0, shore_foam_mul, 0)
	_wire(breakup_ss, 0, shore_foam_mul, 1)  # reuse breakup

	var foam_combine := _add("MinMaxNode", "FoamCombine", "foam", {"type": 1})  # Max
	_wire(crest_foam_mul, 0, foam_combine, 0)
	_wire(shore_foam_mul, 0, foam_combine, 1)

	var relay_foam_mask := _add("RelayNode", "RelayFoamMask", "foam", {"pair_count": 1, "custom_name": "FoamMask"})
	_wire(foam_combine, 0, relay_foam_mask, 0)

	# ---- Stage C: water body color ----
	var depth_fade_body := _add("DepthFadeNode", "DepthFadeBody", "color", {"distance": 4.0})
	_param_float(4.0, "depth_body_distance", "color", depth_fade_body, 0)
	var water_gradient := _add("GradientNode", "WaterGradient", "color", {
		"colors": ["2e8b8b", "1a5c6e", "123a4f"], "offsets": [0.0, 0.5, 1.0],
	})
	_wire(depth_fade_body, 0, water_gradient, 0)

	var horizon_color := _add("ColorNode", "HorizonColor", "color", {
		"color": [0.2431, 0.4314, 0.4941, 1.0], "param_mode": true, "param_name": "horizon_color",
	})
	var fresnel_horizon := _add("FresnelNode", "FresnelHorizon", "color", {"power": 4.0})
	_param_float(4.0, "fresnel_horizon_power", "color", fresnel_horizon, 0)
	var fresnel_mix := _add("MixNode", "FresnelHorizonMix", "color")
	_wire(horizon_color, 0, fresnel_mix, 1)
	_wire(fresnel_horizon, 0, fresnel_mix, 2)

	var foam_white := _add("ColorNode", "FoamWhiteColor", "color", {
		"color": [0.9176, 0.9647, 0.9490, 1.0], "param_mode": true, "param_name": "foam_white_color",
	})
	var albedo_mix := _add("MixNode", "AlbedoFoamMix", "color")
	_wire(fresnel_mix, 0, albedo_mix, 0)
	_wire(foam_white, 0, albedo_mix, 1)
	_wire(relay_foam_mask, 0, albedo_mix, 2)
	_wire(albedo_mix, 0, "OutputNode", 0)  # -> Albedo

	var float_rough_base := _add("FloatNode", "FloatRoughBase", "color", {"value": 0.08, "param_mode": true, "param_name": "rough_base"})
	var float_rough_foam := _add("FloatNode", "FloatRoughFoam", "color", {"value": 0.45, "param_mode": true, "param_name": "rough_foam"})
	var roughness_mix := _add("MixNode", "RoughnessFoamMix", "color")
	_wire(float_rough_base, 0, roughness_mix, 0)
	_wire(float_rough_foam, 0, roughness_mix, 1)
	_wire(relay_foam_mask, 0, roughness_mix, 2)
	_wire(roughness_mix, 0, "OutputNode", 2)  # -> Roughness

	var float_specular := _add("FloatNode", "FloatSpecular", "color", {"value": 0.6, "param_mode": true, "param_name": "specular"})
	_wire(float_specular, 0, "OutputNode", 6)  # -> Specular

	# ---- Stage F: refraction ----
	# FloatHalf stays baked (param_mode false): it's a mechanical centering
	# constant (recenters the ripple height around 0 before scaling), not a
	# "feel" dial anyone would want to drag independently of ripple_strength.
	var float_half := _add("FloatNode", "FloatHalf", "refract", {"value": 0.5, "param_mode": false, "param_name": "ripple_center"})
	var ripple_center_sub := _add("SubtractNode", "RippleCenterSubtract", "refract")
	_wire(relay_detail_height, 0, ripple_center_sub, 0)
	_wire(float_half, 0, ripple_center_sub, 1)

	var float_ripple_strength := _add("FloatNode", "FloatRippleStrength", "refract", {"value": 0.04, "param_mode": true, "param_name": "ripple_strength"})
	var ripple_strength_mul := _add("MultiplyNode", "RippleStrengthMul", "refract")
	_wire(ripple_center_sub, 0, ripple_strength_mul, 0)
	_wire(float_ripple_strength, 0, ripple_strength_mul, 1)

	var ripple_offset_combine := _add("CombineNode", "RippleOffsetCombine", "refract")
	_wire(ripple_strength_mul, 0, ripple_offset_combine, 0)  # R
	_wire(ripple_strength_mul, 0, ripple_offset_combine, 1)  # G (same wire into both)

	var screen_uv := _add("ScreenUVNode", "ScreenUV1", "refract")
	var screen_uv_offset_add := _add("AddNode", "ScreenUVOffsetAdd", "refract")
	_wire(screen_uv, 0, screen_uv_offset_add, 0)
	_wire(ripple_offset_combine, 0, screen_uv_offset_add, 1)

	var screen_tex := _add("ScreenTextureNode", "ScreenTextureRefr", "refract")
	_wire(screen_uv_offset_add, 0, screen_tex, 0)

	var depth_fade_refr := _add("DepthFadeNode", "DepthFadeRefraction", "refract", {"distance": 2.5})
	_param_float(2.5, "depth_refraction_distance", "refract", depth_fade_refr, 0)
	var refraction_mix := _add("MixNode", "RefractionColorMix", "refract")
	_wire(screen_tex, 0, refraction_mix, 0)
	_wire(water_gradient, 0, refraction_mix, 1)
	_wire(depth_fade_refr, 0, refraction_mix, 2)
	_wire(refraction_mix, 0, fresnel_mix, 0)  # re-route: replaces the direct Gradient->FresnelHorizonMix.A link

	# ---- Stage G: fake subsurface scattering (the SoT glow) ----
	var fresnel_glow := _add("FresnelNode", "FresnelGlow", "glow", {"power": 1.5})
	_param_float(1.5, "fresnel_glow_power", "glow", fresnel_glow, 0)
	var glow_crest_mul := _add("MultiplyNode", "GlowCrestFresnelMul", "glow")
	_wire(ocean, 2, glow_crest_mul, 0)  # raw Crest, before the foam smoothstep
	_wire(fresnel_glow, 0, glow_crest_mul, 1)

	var float_glow_strength := _add("FloatNode", "FloatGlowStrength", "glow", {"value": 0.35, "param_mode": true, "param_name": "glow_strength"})
	var glow_strength_mul := _add("MultiplyNode", "GlowStrengthMul", "glow")
	_wire(glow_crest_mul, 0, glow_strength_mul, 0)
	_wire(float_glow_strength, 0, glow_strength_mul, 1)

	var sss_color := _add("ColorNode", "SSSTealColor", "glow", {"color": [0.0980, 0.7647, 0.6118, 1.0], "param_mode": true, "param_name": "sss_color"})
	var glow_scale := _add("ScaleNode", "GlowScale", "glow")
	_wire(sss_color, 0, glow_scale, 0)
	_wire(glow_strength_mul, 0, glow_scale, 1)
	_wire(glow_scale, 0, "OutputNode", 4)  # -> Emission

	# ---- Write ----
	var d := {
		"shader_type": 0, "exported_shader_path": "", "compiled_code": "",
		"nodes": _nodes, "connections": _connections,
	}
	if not NyxSerializer.write(OUT_PATH, d):
		printerr("Failed to write %s" % OUT_PATH)
		quit(1)
		return
	print("Wrote %s — %d nodes, %d connections" % [OUT_PATH, _nodes.size(), _connections.size()])
	quit()
