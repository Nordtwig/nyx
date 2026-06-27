@tool
extends Control

const NyxNodeBase = preload("res://addons/nyx/nodes/nyx_node.gd")
const OutputNode = preload("res://addons/nyx/nodes/output_node.gd")
const ColorNode = preload("res://addons/nyx/nodes/color_node.gd")
const AddNode = preload("res://addons/nyx/nodes/add_node.gd")
const MultiplyNode = preload("res://addons/nyx/nodes/multiply_node.gd")
const MixNode = preload("res://addons/nyx/nodes/mix_node.gd")
const UVNode = preload("res://addons/nyx/nodes/uv_node.gd")
const FloatNode = preload("res://addons/nyx/nodes/float_node.gd")
const SubtractNode = preload("res://addons/nyx/nodes/subtract_node.gd")
const ClampNode = preload("res://addons/nyx/nodes/clamp_node.gd")
const PowerNode = preload("res://addons/nyx/nodes/power_node.gd")
const SinNode = preload("res://addons/nyx/nodes/sin_node.gd")
const CosNode = preload("res://addons/nyx/nodes/cos_node.gd")
const TimeNode = preload("res://addons/nyx/nodes/time_node.gd")
const SplitNode = preload("res://addons/nyx/nodes/split_node.gd")
const CombineNode = preload("res://addons/nyx/nodes/combine_node.gd")
const TextureSampleNode = preload("res://addons/nyx/nodes/texture_sample_node.gd")
const FresnelNode = preload("res://addons/nyx/nodes/fresnel_node.gd")
const ScaleNode = preload("res://addons/nyx/nodes/scale_node.gd")
const StepNode = preload("res://addons/nyx/nodes/step_node.gd")
const SmoothstepNode = preload("res://addons/nyx/nodes/smoothstep_node.gd")
const NoiseNode = preload("res://addons/nyx/nodes/noise_node.gd")
const FBMNode = preload("res://addons/nyx/nodes/fbm_node.gd")
const GradientNode = preload("res://addons/nyx/nodes/gradient_node.gd")
const CurveNode = preload("res://addons/nyx/nodes/curve_node.gd")
const TilingOffsetNode = preload("res://addons/nyx/nodes/tiling_offset_node.gd")
const NormalFromHeightNode = preload("res://addons/nyx/nodes/normal_from_height_node.gd")
const BlendNormalsNode = preload("res://addons/nyx/nodes/blend_normals_node.gd")
const ScreenUVNode = preload("res://addons/nyx/nodes/screen_uv_node.gd")
const ScreenTextureNode = preload("res://addons/nyx/nodes/screen_texture_node.gd")
const DepthFadeNode = preload("res://addons/nyx/nodes/depth_fade_node.gd")
const RotateUVNode = preload("res://addons/nyx/nodes/rotate_uv_node.gd")
const WarpNode = preload("res://addons/nyx/nodes/warp_node.gd")
const VertexNode = preload("res://addons/nyx/nodes/vertex_node.gd")
const NormalMapNode = preload("res://addons/nyx/nodes/normal_map_node.gd")
const AbsNode = preload("res://addons/nyx/nodes/abs_node.gd")
const CeilNode = preload("res://addons/nyx/nodes/ceil_node.gd")
const FloorNode = preload("res://addons/nyx/nodes/floor_node.gd")
const FractNode = preload("res://addons/nyx/nodes/fract_node.gd")
const NegateNode = preload("res://addons/nyx/nodes/negate_node.gd")
const OneMinusNode = preload("res://addons/nyx/nodes/one_minus_node.gd")
const RoundNode = preload("res://addons/nyx/nodes/round_node.gd")
const SqrtNode = preload("res://addons/nyx/nodes/sqrt_node.gd")
const MinMaxNode = preload("res://addons/nyx/nodes/min_max_node.gd")
const DivideNode = preload("res://addons/nyx/nodes/divide_node.gd")
const ModNode = preload("res://addons/nyx/nodes/mod_node.gd")
const NormalizeNode = preload("res://addons/nyx/nodes/normalize_node.gd")
const CustomGLSLNode = preload("res://addons/nyx/nodes/custom_glsl_node.gd")
const Vector3Node = preload("res://addons/nyx/nodes/vector3_node.gd")
const RerouteNode = preload("res://addons/nyx/nodes/reroute_node.gd")
const RelayNode = preload("res://addons/nyx/nodes/relay_node.gd")
const PreviewRelayNode = preload("res://addons/nyx/nodes/preview_relay_node.gd")
const SpriteTextureNode = preload("res://addons/nyx/nodes/sprite_texture_node.gd")
const VertexColorNode = preload("res://addons/nyx/nodes/vertex_color_node.gd")
const TexturePixelSizeNode = preload("res://addons/nyx/nodes/texture_pixel_size_node.gd")
const LengthNode = preload("res://addons/nyx/nodes/length_node.gd")
const DotNode = preload("res://addons/nyx/nodes/dot_node.gd")
const ParticleStartNode = preload("res://addons/nyx/nodes/particle_start_node.gd")
const ParticleProcessNode = preload("res://addons/nyx/nodes/particle_process_node.gd")
const ParticleAgeNode = preload("res://addons/nyx/nodes/particle_age_node.gd")
const ParticleVelocityNode = preload("res://addons/nyx/nodes/particle_velocity_node.gd")
const ParticlePositionNode = preload("res://addons/nyx/nodes/particle_position_node.gd")
const ParticleDeltaNode = preload("res://addons/nyx/nodes/particle_delta_node.gd")
const ParticleRandomNode = preload("res://addons/nyx/nodes/particle_random_node.gd")
const ParticleIndexNode = preload("res://addons/nyx/nodes/particle_index_node.gd")

const _NODE_REGISTRY := [
	{"category": "Inputs", "nodes": [
		{"label": "Color", "id": 0,
			"summary": "A constant colour, optionally exposed for runtime animation.",
			"description": "Click the node body to open a colour picker. Enable Param mode to expose as a named uniform vec4 — animate from GDScript with set_shader_parameter(). Outputs RGB as a vec3.",
			"ports": ["Out (vec3) — the selected colour as RGB"],
			"uses": ["Base albedo colour", "Tint multiplied over a texture", "Animatable colour parameter"]},
		{"label": "Float", "id": 5,
			"summary": "A single number, optionally exposed for runtime animation.",
			"description": "Enable Param mode to expose this as a named uniform — animate it at runtime via set_shader_parameter() from GDScript.",
			"ports": ["Out (float) — the current value"],
			"uses": ["Dissolve threshold", "Blend weight", "Any value you want to animate from code"]},
		{"label": "Vector3", "id": 48,
			"summary": "A constant XYZ vector, optionally exposed for runtime animation.",
			"description": "Set X, Y, Z individually. Enable Param mode to expose as a named uniform vec3 — animate from GDScript with set_shader_parameter().",
			"ports": ["Out (vec3) — the XYZ value"],
			"uses": ["Direction vectors", "Positional offsets", "Any vec3 you want to control from code"]},
		{"label": "UV", "id": 4, "particle_unsafe": true,
			"summary": "The mesh's texture coordinates.",
			"description": "Outputs the UV coordinates of the current fragment as a vec3 (Z is always 0). UV runs from (0,0) at one corner to (1,1) at the opposite corner.",
			"ports": ["Out (vec3) — UV.x, UV.y, 0.0"],
			"uses": ["Input for textures and noise", "Coordinate-based effects", "Tiling operations"]},
		{"label": "Vertex", "id": 20, "spatial_only": true,
			"summary": "The local 3D position of the current surface point.",
			"description": "Unlike UV, vertex position is continuous across the mesh with no seams where UV islands meet. Particularly valuable as noise input on spheres and organic shapes.",
			"ports": ["Out (vec3) — local position XYZ"],
			"uses": ["Seamless noise on spheres", "Position-based patterns", "Effects that shouldn't depend on UV unwrapping"]},
		{"label": "Time", "id": 11,
			"summary": "The current time in seconds, with pre-computed oscillating variants.",
			"description": "Three outputs driven by the engine clock. Sin and Cos save you adding extra nodes for the most common time-based animation patterns.",
			"ports": ["Time (float) — elapsed seconds", "Sin (float) — sin(TIME), oscillates -1 to 1", "Cos (float) — cos(TIME), oscillates -1 to 1"],
			"uses": ["Pulsing emission", "Animated dissolve", "Scrolling textures", "Wave effects"]},
	]},
	{"category": "Texture", "nodes": [
		{"label": "Texture Sample", "id": 14, "particle_unsafe": true,
			"summary": "Samples a colour from a 2D texture at UV coordinates.",
			"description": "The texture is exported as a shader uniform, so it's baked into the material. Connect a UV or Tiling & Offset node to control mapping.",
			"ports": ["UV (vec3) — texture coordinates", "Out (vec3) — sampled RGB colour"],
			"uses": ["Painted textures", "Photo albedo", "Using a texture as a mask or detail layer"]},
		{"label": "Normal Map", "id": 21, "particle_unsafe": true,
			"summary": "Samples a normal map texture and applies it to the surface.",
			"description": "Like Texture Sample but configured for normal maps — uses the hint_normal sampler and writes to NORMAL_MAP. Connect the output to the Output node's Normal slot.",
			"ports": ["UV (vec3) — texture coordinates", "Out (vec3) — normal map value"],
			"uses": ["Adding surface detail without extra geometry", "Bricks, fabric, skin, scratches"]},
		{"label": "Gradient", "id": 37,
			"summary": "Maps a float to a colour using a visual gradient you design.",
			"description": "Click the colour bar to open the gradient editor in the inspector. Define any number of colour stops. Float in, vec3 colour out — no math nodes needed to get a custom colour ramp.",
			"ports": ["T (float) — position along the gradient, 0-1", "Color (vec3) — sampled colour"],
			"uses": ["Heat maps", "Sky gradients", "Colour-coding noise or distance", "Any effect that maps a value to a colour"]},
		{"label": "Curve", "id": 38,
			"summary": "Remaps a float through an editable bezier curve.",
			"description": "Click the curve preview to open the curve editor in the inspector. Draw any shape — S-curves, exponentials, custom falloffs. Far more expressive than chaining Power and Smoothstep nodes.",
			"ports": ["T (float) — input value 0-1", "Out (float) — remapped value"],
			"uses": ["Custom falloff shapes", "Non-linear remapping", "Artistic control over noise or Fresnel", "Shaping dissolve edges"]},
	]},
	{"category": "Math", "nodes": [
		{"label": "Add", "id": 1, "summary": "Adds A and B. (A + B)"},
		{"label": "Subtract", "id": 6, "summary": "Subtracts B from A. (A - B)"},
		{"label": "Multiply", "id": 2, "summary": "Multiplies A by B. (A * B)"},
		{"label": "Divide", "id": 24, "summary": "Divides A by B. (A / B)"},
		{"label": "Mix", "id": 3,
			"summary": "Blends between two values by a weight.",
			"description": "When T is 0 the output is A; when T is 1 the output is B. Values between give a proportional blend. The fundamental blending operation in shader programming.",
			"ports": ["A (vec3) — first value", "B (vec3) — second value", "T (float) — blend weight 0-1", "Out (vec3)"],
			"uses": ["Blending two colours", "Fading between textures", "Dissolve transitions"]},
		{"label": "Clamp", "id": 7,
			"summary": "Constrains a value to stay within a range.",
			"description": "Ensures output never goes below Min or above Max. Essential for keeping values in the 0-1 range expected by most shader outputs.",
			"ports": ["V (vec3) — value to clamp", "Min (float) — lower bound", "Max (float) — upper bound", "Out (vec3)"],
			"uses": ["Preventing oversaturation", "Keeping alpha values valid", "Clamping noise before using as a mask"]},
		{"label": "Power", "id": 8,
			"summary": "Raises a value to an exponent.",
			"description": "Low exponents (0.5-1) spread and lighten a value; high exponents (2-8) concentrate and darken it. This non-linear curve shapes most falloff effects.",
			"ports": ["Base (vec3) — input value", "Exp (float) — exponent", "Out (vec3)"],
			"uses": ["Shaping Fresnel falloff", "Sharpening noise edges", "Gamma-style adjustment"]},
		{"label": "Min / Max", "id": 23, "summary": "Returns the smaller (Min) or larger (Max) of two values."},
		{"label": "Modulo", "id": 25, "summary": "Returns the remainder after dividing A by B."},
		{"label": "Abs", "id": 22, "summary": "Returns the absolute (positive) value. Negative inputs become positive."},
		{"label": "Ceil", "id": 29, "summary": "Rounds up to the nearest integer."},
		{"label": "Floor", "id": 30, "summary": "Rounds down to the nearest integer."},
		{"label": "Fract", "id": 31, "summary": "Returns the fractional part. fract(2.7) = 0.7"},
		{"label": "Negate", "id": 32, "summary": "Flips the sign. Positive becomes negative and vice versa."},
		{"label": "One Minus", "id": 33, "summary": "Returns 1 - V. Inverts a 0-1 value."},
		{"label": "Round", "id": 34, "summary": "Rounds to the nearest integer."},
		{"label": "Sqrt", "id": 35, "summary": "Returns the square root."},
		{"label": "Sin", "id": 9,
			"summary": "Sine of the input — oscillates smoothly between -1 and 1.",
			"description": "In shader work, most useful for turning a time value into smooth repeating oscillation, or for building wave patterns.",
			"ports": ["V (float) — angle in radians", "Out (float)"],
			"uses": ["Values that pulse or breathe", "Wave and ripple patterns", "Combining with Time for looping animation"]},
		{"label": "Cos", "id": 10,
			"summary": "Cosine of the input — oscillates smoothly between -1 and 1.",
			"description": "Like Sin but offset by a quarter cycle. Useful when you need two oscillating values that don't peak at the same moment.",
			"ports": ["V (float) — angle in radians", "Out (float)"],
			"uses": ["Phase-offset oscillation alongside Sin", "Circular motion combined with Sin", "Wave patterns"]},
	]},
	{"category": "Vector", "nodes": [
		{"label": "Normalize", "id": 26,
			"summary": "Scales a vector to length 1.",
			"description": "Returns a vector pointing the same direction as V but with magnitude exactly 1. Required when a direction vector is used in lighting calculations.",
			"ports": ["V (vec3) — input", "Out (vec3)"],
			"uses": ["Cleaning up normals before lighting", "Ensuring direction vectors are valid for dot product operations"]},
		{"label": "Length", "id": 27,
			"summary": "Returns the length (magnitude) of a vector.",
			"description": "Calculates how long a vec3 is — the distance from the origin to that point.",
			"ports": ["V (vec3) — input", "Out (float)"],
			"uses": ["Radial gradients from a point", "Distance-based effects", "Circular and spherical masks"]},
		{"label": "Dot", "id": 28,
			"summary": "How aligned two vectors are. 1 = same direction, 0 = perpendicular, -1 = opposite.",
			"description": "The dot product is the fundamental operation behind most lighting and angle-based effects in shaders. Nearly every lighting model is built on it.",
			"ports": ["A (vec3) — first vector", "B (vec3) — second vector", "Out (float)"],
			"uses": ["Angle-based masking", "Measuring how directly a surface faces a light or camera", "Rim lighting", "Custom Fresnel calculations"]},
		{"label": "Split", "id": 12,
			"summary": "Breaks a vec3 into its R, G, B float components.",
			"description": "Separates a colour or vector into three individual channels for independent processing.",
			"ports": ["In (vec3) — input", "R (float)", "G (float)", "B (float)"],
			"uses": ["Extracting a single texture channel", "Separating world position axes", "Channel-specific operations before recombining"]},
		{"label": "Combine", "id": 13,
			"summary": "Builds a vec3 from three floats. The counterpart to Split.",
			"description": "Takes three separate float values and packs them into a single vec3.",
			"ports": ["R (float)", "G (float)", "B (float)", "Out (vec3)"],
			"uses": ["Assembling colour from independently-calculated channels", "Building direction vectors from scalar results"]},
		{"label": "Normal from Height", "id": 42, "particle_unsafe": true,
			"summary": "Converts a greyscale height field into a normal map using screen-space derivatives.",
			"description": "Uses dFdx/dFdy to compute the surface gradient of the height input and outputs a tangent-space normal. Connects directly to the Output node's Normal slot. Strength controls how pronounced the bumps appear.",
			"ports": ["Height (float) — the height field (e.g. FBM output)", "Strength (float) — bump intensity", "Normal (vec3) — tangent-space normal for Output Normal slot"],
			"uses": ["Procedural water normals from FBM", "Bump mapping without a texture", "Converting any noise to surface detail"]},
		{"label": "Blend Normals", "id": 43, "particle_unsafe": true,
			"summary": "Combines two normal maps correctly.",
			"description": "Unpacks both normals from the 0–1 NORMAL_MAP encoding, adds their XY deflections, and repacks. More accurate than simply adding or mixing, especially at steep angles. Both inputs should come from Normal from Height or Normal Map nodes.",
			"ports": ["A (vec3) — first normal (NORMAL_MAP encoded)", "B (vec3) — second normal (NORMAL_MAP encoded)", "Normal (vec3) — blended normal for Output Normal slot"],
			"uses": ["Combining two scrolling water normal layers", "Layering detail normals on top of a base normal map", "Blending procedural and texture-based normals"]},
		{"label": "Scale", "id": 16,
			"summary": "Multiplies a vec3 by a float. Bridges float values into colour pipelines.",
			"description": "Multiplies every channel of V by scalar T. The primary way to apply a float-output node (Fresnel, Noise, FBM) to a colour or direction.",
			"ports": ["V (vec3) — colour or vector input", "T (float) — scalar multiplier", "Out (vec3)"],
			"uses": ["Tinting a colour by noise intensity", "Applying Fresnel as emission strength", "Weighting a normal map contribution"]},
	]},
	{"category": "Shape", "nodes": [
		{"label": "Fresnel", "id": 15, "spatial_only": true,
			"summary": "Brighter at glancing angles, darker head-on. The classic edge-glow effect.",
			"description": "Computes how much the surface faces away from the camera. High power = tight rim; low power = spreads across the whole surface. Connect a Float to the Power port to drive it dynamically.",
			"ports": ["Power (float) — falloff sharpness, default 3.0", "Out (float)"],
			"uses": ["Rim lighting", "Force fields and hologram edges", "Atmospheric haze on planets", "X-ray effects", "Iridescence"]},
		{"label": "Step", "id": 17,
			"summary": "Returns 0 or 1 based on a hard threshold. No blending.",
			"description": "A binary cut: 0 if X is below Edge, 1 if at or above. Useful wherever you need an instantaneous on/off boundary.",
			"ports": ["Edge (float) — threshold", "X (float) — value to test", "Out (float)"],
			"uses": ["Hard dissolve edges", "Binary masks", "Cutout alpha effects"]},
		{"label": "Smoothstep", "id": 18,
			"summary": "Smooth 0-to-1 transition between two edges.",
			"description": "Like Step but with an ease-in/ease-out curve. Below Edge0 returns 0, above Edge1 returns 1, between them is a smooth S-curve blend. One of the most-used nodes in shader work.",
			"ports": ["Edge0 (float) — lower edge", "Edge1 (float) — upper edge", "X (float) — value to test", "Out (float)"],
			"uses": ["Soft dissolve edges", "Smooth masks", "Anti-aliased procedural shapes", "Gradient falloffs"]},
	]},
	{"category": "Screen", "nodes": [
		{"label": "Screen UV", "id": 44, "particle_unsafe": true,
			"summary": "The current fragment's position in screen space (0-1).",
			"description": "Outputs the UV coordinates of the current pixel on screen. Use as input to Screen Texture for basic sampling, or offset it with a normal map for refraction effects.",
			"ports": ["Screen UV (vec3) — screen-space UV, XY in 0-1 range"],
			"uses": ["Input to Screen Texture for refraction", "Warping with a normal for underwater distortion"]},
		{"label": "Screen Texture", "id": 45, "particle_unsafe": true,
			"summary": "Samples the rendered scene behind the current surface.",
			"description": "Reads the colour of what's been rendered behind this transparent surface. Offset the UV input with a water normal to create convincing refraction. Requires the material's render mode to be Mix, Add, or Premult Alpha.",
			"ports": ["UV (vec3) — screen UV to sample (offset for refraction)", "Color (vec3) — the scene colour at that UV"],
			"uses": ["Water refraction", "Glass distortion", "Heat haze", "Any transparent surface that should show a distorted view of what's behind it"]},
		{"label": "Depth Fade", "id": 46, "spatial_only": true,
			"summary": "Returns 0 at surface intersections and 1 in deep water.",
			"description": "Compares the depth buffer against the current surface depth. Where scene geometry is close to the surface (shallow water, shorelines), the output is near 0. Where the water is deep, it approaches 1. Requires a transparent render mode.",
			"ports": ["Distance (float) — the depth range over which the fade occurs", "Out (float) — 0 at edges/intersections, 1 in deep areas"],
			"uses": ["Shoreline foam (1 - DepthFade drives foam mask)", "Soft transparency at water edges", "Depth-based colour (shallow vs deep)", "Soft particles that don't clip geometry"]},
	]},
	{"category": "UV", "nodes": [
		{"label": "Tiling & Offset", "id": 39, "particle_unsafe": true,
			"summary": "Tiles and scrolls UV coordinates.",
			"description": "Multiplies UV by a tiling factor (zoom) and adds an offset (scroll). Connect Time to Offset X or Y to animate scrolling. Use two of these at different speeds for layered water or cloud effects.",
			"ports": ["UV (vec3) — coordinate input", "Tiling X (float) — horizontal tile count", "Tiling Y (float) — vertical tile count", "Offset X (float) — horizontal scroll", "Offset Y (float) — vertical scroll", "Out (vec3) — transformed UV"],
			"uses": ["Scrolling normal maps for water", "Tiling a texture at a different scale", "Animated UV for fire or clouds", "Offsetting two layers at different speeds"]},
		{"label": "Rotate UV", "id": 40, "particle_unsafe": true,
			"summary": "Rotates UV coordinates around the centre.",
			"description": "Rotates the UV around the point (0.5, 0.5). Angle is in radians. Connect Time to Angle for a continuously spinning effect, or use a small fixed angle to make two texture layers feel independent.",
			"ports": ["UV (vec3) — coordinate input", "Angle (float) — rotation in radians", "Out (vec3) — rotated UV"],
			"uses": ["Spinning effects", "Making two water normal layers feel independent", "Slow UV rotation for lava or energy fields"]},
		{"label": "Warp", "id": 41, "particle_unsafe": true,
			"summary": "Distorts UV coordinates using an offset input.",
			"description": "Shifts UV by the XY of an Offset vector, scaled by Strength. Feed noise or FBM into Offset to get organic, fluid-looking distortion. The key node for making water feel alive rather than just sliding.",
			"ports": ["UV (vec3) — coordinate input", "Offset (vec3) — distortion direction, uses XY", "Strength (float) — distortion amount", "Out (vec3) — distorted UV"],
			"uses": ["Water surface distortion", "Heat haze", "Warping a texture with noise", "Organic UV deformation"]},
	]},
	{"category": "Noise", "nodes": [
		{"label": "Noise", "id": 19, "particle_unsafe": true,
			"summary": "Procedural noise — organic, hash-based variation across a surface.",
			"description": "Three types via dropdown: Value (smooth, slightly blocky), Gradient (classic Perlin-style, most organic), Voronoi (cell-based, crystalline or cracked). Scale controls feature size — higher values mean smaller, denser features.",
			"ports": ["UV (vec3) — coordinate input (use Vertex for seamless noise on spheres)", "Scale (float) — feature size", "Out (float)"],
			"uses": ["Organic textures", "Dissolve masks", "Cloud-like patterns", "Randomising roughness or emission"]},
		{"label": "FBM", "id": 36, "particle_unsafe": true,
			"summary": "Fractal Brownian Motion — noise layered at multiple scales for natural, rich detail.",
			"description": "Stacks multiple octaves of gradient noise, each at higher frequency and lower amplitude. The result looks like natural phenomena — clouds, terrain, smoke, fire. Octaves adds detail layers. Lacunarity controls frequency growth per octave (default 2.0). Gain controls how fast amplitude fades (default 0.5).",
			"ports": ["UV (vec3) — coordinate input (use Vertex for seamless results on spheres)", "Scale (float) — base feature size", "Out (float)"],
			"uses": ["Clouds and smoke", "Fire and lava", "Organic terrain", "Any effect needing natural multi-scale variation"]},
	]},
	{"category": "Canvas", "nodes": [
		{"label": "Sprite Texture", "id": 49, "canvas_only": true,
			"summary": "Samples the sprite's own texture at UV coordinates.",
			"description": "Reads from TEXTURE — the built-in texture of the current CanvasItem (Sprite2D, TextureRect, etc.). Unlike Texture Sample, this doesn't require assigning an external texture; it uses whatever the node already has.",
			"ports": ["UV (vec3) — texture coordinates", "Color (vec3) — sampled RGBA colour"],
			"uses": ["Tinting a sprite", "Masking by the sprite's own alpha", "Layering effects on top of the base sprite"]},
		{"label": "Vertex Color", "id": 50, "canvas_only": true,
			"summary": "The sprite's modulate color set in the scene.",
			"description": "Outputs COLOR.rgb — the per-vertex tint inherited from the CanvasItem's Modulate property. Multiply it against your output to respect the scene-level tint.",
			"ports": ["Color (vec3) — the modulate colour"],
			"uses": ["Respecting the sprite's scene-level tint", "Blending shader output with the sprite's colour", "Reactive colour effects driven from GDScript"]},
		{"label": "Pixel Size", "id": 51, "canvas_only": true,
			"summary": "The size of one texel in the sprite's texture.",
			"description": "Outputs TEXTURE_PIXEL_SIZE as a vec3 (XY = pixel size, Z = 0). Use this to offset UVs by exactly one pixel — essential for outlines, blur, and pixel-perfect effects that need to stay sharp at any scale.",
			"ports": ["Size (vec3) — texel dimensions in UV space, XY only"],
			"uses": ["Pixel-art outline shaders", "Nearest-neighbour blur", "Edge detection"]},
	]},
	{"category": "Particles", "nodes": [
		{"label": "Particle Start", "id": 55, "particle_only": true,
			"summary": "Initial per-particle state — runs once when a particle spawns.",
			"description": "The spawn brain. Set a particle's starting Position, Velocity, Color, Scale and Rotation. Unconnected slots use sensible defaults (Position 0, Velocity 0, Color white, Scale 1, Rotation 0). Position is an offset from the emitter; Rotation is euler radians.",
			"ports": ["Position (vec3) — spawn offset from emitter", "Velocity (vec3) — initial velocity", "Color (vec4) — initial colour", "Scale (vec3) — initial scale", "Rotation (vec3) — initial euler rotation"],
			"uses": ["Spawning particles in a shape", "Randomised initial velocity (with Random)", "Per-particle starting colour"]},
		{"label": "Particle Process", "id": 56, "particle_only": true,
			"summary": "Per-frame per-particle update — runs every frame.",
			"description": "The motion brain. Override Velocity to apply forces, fade Color over life, or set an absolute Position. Each slot only takes effect if connected; leave a slot empty to keep the default behaviour. Position auto-integrates from velocity unless you drive it directly.",
			"ports": ["Velocity (vec3) — apply forces / override", "Color (vec4) — fade over Age Ratio", "Position (vec3) — absolute override (else auto-integrates)"],
			"uses": ["Gravity and drag", "Fading particles out over their life", "Steering and attraction forces"]},
		{"label": "Age Ratio", "id": 57, "particle_only": true,
			"summary": "How far through its life a particle is, 0 to 1.",
			"description": "0 the instant a particle spawns, 1 as it dies. The single most useful particle input — drive Color, Scale or alpha through a Gradient or Curve to animate over lifetime.",
			"ports": ["Age (float) — 0 at birth, 1 at death"],
			"uses": ["Fading alpha out over life", "Colour-over-life via Gradient", "Shrinking or growing with a Curve"]},
		{"label": "Velocity", "id": 58, "particle_only": true,
			"summary": "The particle's current velocity vector.",
			"description": "Reads the live velocity in the Process stage. Use it to build forces relative to motion — drag (negate and scale), or steering.",
			"ports": ["Velocity (vec3) — current velocity"],
			"uses": ["Velocity-based drag", "Aligning particles to motion", "Speed-based colour"]},
		{"label": "Position", "id": 59, "particle_only": true,
			"summary": "The particle's current world position.",
			"description": "Reads TRANSFORM[3].xyz. Use for position-dependent forces such as radial attraction toward a point or keeping particles within bounds.",
			"ports": ["Position (vec3) — current position"],
			"uses": ["Radial attraction / repulsion", "Bounding-box forces", "Position-based colour"]},
		{"label": "Delta", "id": 60, "particle_only": true,
			"summary": "Seconds since the last simulation frame.",
			"description": "Multiply any force or rate by Delta to make it frame-rate independent. The default velocity integration already applies Delta for you.",
			"ports": ["Delta (float) — frame time in seconds"],
			"uses": ["Frame-rate-independent forces", "Time-stepped accumulation"]},
		{"label": "Random", "id": 61, "particle_only": true,
			"summary": "A stable per-particle random value, in a range you set.",
			"description": "Hashed from the particle's unique number, so the same particle always returns the same value — safe in both Start and Process. Vector mode gives three decorrelated channels (random direction/position); Scalar mode gives one number. Min/Max set the output range directly, so Vector → Velocity scatters with no extra math (default range is a symmetric -1 to 1).",
			"ports": ["Random (vec3 or float) — per-particle random within [Min, Max]"],
			"uses": ["Randomised initial velocity / scatter direction", "Per-particle size or colour jitter", "Random spawn offset", "Staggering behaviour across particles"]},
		{"label": "Index", "id": 62, "particle_only": true,
			"summary": "This particle's index as a float.",
			"description": "A deterministic per-particle counter. Unlike Random it's ordered, so it's ideal for striping or sequencing particles — e.g. drive a gradient by Index for a rainbow spread.",
			"ports": ["Index (float) — particle index"],
			"uses": ["Sequenced colour ramps", "Deterministic striping", "Index-based fan-out"]},
	]},
	{"category": "Organisation", "nodes": [
		{"label": "Relay", "id": 53,
			"summary": "Named, coloured pass-through — one to many pairs.",
			"description": "A flexible wire organiser. Start with one in/out pair and press + to add more, making it a bus. Give it a name and colour to group related wires visually across your graph. Polymorphic — each pair independently carries float or vec3.",
			"ports": ["In N — any type", "Out N — same type as In N"],
			"uses": ["Redirecting wires around clutter", "Grouping related wires with colour", "Bundling multiple signals as a bus", "Annotating what a wire represents"]},
		{"label": "Preview Relay", "id": 54, "particle_unsafe": true,
			"summary": "Like Relay but with an always-visible preview.",
			"description": "A single in/out pass-through that always shows a live preview of what's flowing through it — no chevron toggle needed. Name and colour it to document the signal. Ideal as a checkpoint in a complex graph.",
			"ports": ["In — any type", "Out — same type as input"],
			"uses": ["Inspecting intermediate values mid-graph", "Debugging a complex chain without adding a branch", "Named checkpoints in a large graph"]},
		{"label": "Reroute", "id": 52,
			"summary": "Minimal pass-through for bending wires. Press R to place.",
			"description": "A compact polymorphic connector. Place with R and reconnect wires through it to route them cleanly around other nodes. For named, coloured, or multi-wire organisation, use Relay instead.",
			"ports": ["In — any type", "Out — same type as input"],
			"uses": ["Quick wire bends", "Reducing crossing lines"]},
	]},
	{"category": "Advanced", "nodes": [
		{"label": "Custom Function", "id": 47,
			"summary": "Write raw GLSL directly as a node in the graph.",
			"description": "The function body you write receives up to 4 vec3 inputs named in0–in3 and must return a vec3. Use this when the graph can't express what you need — complex math, custom sampling, or anything that would take dozens of nodes to wire up.",
			"ports": ["in0–in3 (vec3) — connected inputs", "Out (vec3) — return value of your function"],
			"uses": ["Complex custom math", "Escape hatch for unsupported operations", "Porting existing GLSL snippets into the graph"]},
	]},
]

# Twilight palette — cooler, muted category accents that sit clearly above the
# dark abyss background without competing with the bright connection lines.
# Tune a whole category by editing one constant here.
const _CAT_INPUTS  := Color(0.14, 0.14, 0.18)
const _CAT_MATH    := Color(0.14, 0.14, 0.18)
const _CAT_VECTOR  := Color(0.14, 0.14, 0.18)
const _CAT_TEXTURE := Color(0.14, 0.14, 0.18)
const _CAT_OUTPUT  := Color(0.14, 0.14, 0.18)

const _TYPE_COLORS := {
	# Inputs
	"FloatNode":    _CAT_INPUTS,
	"Vector3Node":  _CAT_INPUTS,
	"UVNode":       _CAT_INPUTS,
	"VertexNode":   _CAT_INPUTS,
	"TimeNode":     _CAT_INPUTS,
	# Screen
	"ScreenUVNode":      _CAT_INPUTS,
	"ScreenTextureNode": _CAT_INPUTS,
	"DepthFadeNode":     _CAT_INPUTS,
	# Math
	"AddNode":      _CAT_MATH,
	"SubtractNode": _CAT_MATH,
	"MultiplyNode": _CAT_MATH,
	"DivideNode":   _CAT_MATH,
	"MixNode":      _CAT_MATH,
	"ClampNode":    _CAT_MATH,
	"PowerNode":    _CAT_MATH,
	"MinMaxNode":   _CAT_MATH,
	"ModNode":      _CAT_MATH,
	"AbsNode":      _CAT_MATH,
	"CeilNode":     _CAT_MATH,
	"FloorNode":    _CAT_MATH,
	"FractNode":    _CAT_MATH,
	"NegateNode":   _CAT_MATH,
	"OneMinusNode": _CAT_MATH,
	"RoundNode":    _CAT_MATH,
	"SqrtNode":     _CAT_MATH,
	"SinNode":      _CAT_MATH,
	"CosNode":      _CAT_MATH,
	# Shape — mathematical value ops
	"FresnelNode":    _CAT_MATH,
	"StepNode":       _CAT_MATH,
	"SmoothstepNode": _CAT_MATH,
	# Advanced
	"CustomGLSLNode": _CAT_MATH,
	# Vector
	"NormalizeNode":       _CAT_VECTOR,
	"LengthNode":          _CAT_VECTOR,
	"DotNode":             _CAT_VECTOR,
	"SplitNode":           _CAT_VECTOR,
	"CombineNode":         _CAT_VECTOR,
	"NormalFromHeightNode": _CAT_VECTOR,
	"BlendNormalsNode":    _CAT_VECTOR,
	"ScaleNode":           _CAT_VECTOR,
	# Texture
	"TextureSampleNode": _CAT_TEXTURE,
	"NormalMapNode":     _CAT_TEXTURE,
	"GradientNode":      _CAT_TEXTURE,
	"CurveNode":         _CAT_TEXTURE,
	# UV
	"TilingOffsetNode": _CAT_TEXTURE,
	"RotateUVNode":     _CAT_TEXTURE,
	"WarpNode":         _CAT_TEXTURE,
	# Noise/Procedural
	"NoiseNode": _CAT_TEXTURE,
	"FBMNode":   _CAT_TEXTURE,
	# Organisation
	"RerouteNode":      _CAT_OUTPUT,
	"RelayNode":        _CAT_OUTPUT,
	"PreviewRelayNode": _CAT_OUTPUT,
	# Canvas — scene-provided inputs, like UV/Time/ScreenUV
	"SpriteTextureNode":    _CAT_INPUTS,
	"VertexColorNode":      _CAT_INPUTS,
	"TexturePixelSizeNode": _CAT_INPUTS,
	# Particles — per-particle context inputs (sinks keep their own slate style)
	"ParticleAgeNode":      _CAT_INPUTS,
	"ParticleVelocityNode": _CAT_INPUTS,
	"ParticlePositionNode": _CAT_INPUTS,
	"ParticleDeltaNode":    _CAT_INPUTS,
	"ParticleRandomNode":   _CAT_INPUTS,
	"ParticleIndexNode":    _CAT_INPUTS,
}

const NODE_CLASSES := {
	"OutputNode": OutputNode,
	"ColorNode": ColorNode,
	"AddNode": AddNode,
	"MultiplyNode": MultiplyNode,
	"MixNode": MixNode,
	"UVNode": UVNode,
	"FloatNode": FloatNode,
	"SubtractNode": SubtractNode,
	"ClampNode": ClampNode,
	"PowerNode": PowerNode,
	"SinNode": SinNode,
	"CosNode": CosNode,
	"TimeNode": TimeNode,
	"SplitNode": SplitNode,
	"CombineNode": CombineNode,
	"TextureSampleNode": TextureSampleNode,
	"FresnelNode": FresnelNode,
	"ScaleNode": ScaleNode,
	"StepNode": StepNode,
	"SmoothstepNode": SmoothstepNode,
	"NoiseNode": NoiseNode,
	"FBMNode": FBMNode,
	"GradientNode": GradientNode,
	"CurveNode": CurveNode,
	"TilingOffsetNode": TilingOffsetNode,
	"RotateUVNode": RotateUVNode,
	"WarpNode": WarpNode,
	"NormalFromHeightNode": NormalFromHeightNode,
	"BlendNormalsNode": BlendNormalsNode,
	"ScreenUVNode": ScreenUVNode,
	"ScreenTextureNode": ScreenTextureNode,
	"DepthFadeNode": DepthFadeNode,
	"VertexNode": VertexNode,
	"NormalMapNode": NormalMapNode,
	"AbsNode": AbsNode,
	"CeilNode": CeilNode,
	"FloorNode": FloorNode,
	"FractNode": FractNode,
	"NegateNode": NegateNode,
	"OneMinusNode": OneMinusNode,
	"RoundNode": RoundNode,
	"SqrtNode": SqrtNode,
	"MinMaxNode": MinMaxNode,
	"DivideNode": DivideNode,
	"ModNode": ModNode,
	"NormalizeNode": NormalizeNode,
	"LengthNode": LengthNode,
	"DotNode": DotNode,
	"RerouteNode": RerouteNode,
	"RelayNode": RelayNode,
	"PreviewRelayNode": PreviewRelayNode,
	"CustomGLSLNode": CustomGLSLNode,
	"Vector3Node": Vector3Node,
	"SpriteTextureNode": SpriteTextureNode,
	"VertexColorNode": VertexColorNode,
	"TexturePixelSizeNode": TexturePixelSizeNode,
	"ParticleStartNode": ParticleStartNode,
	"ParticleProcessNode": ParticleProcessNode,
	"ParticleAgeNode": ParticleAgeNode,
	"ParticleVelocityNode": ParticleVelocityNode,
	"ParticlePositionNode": ParticlePositionNode,
	"ParticleDeltaNode": ParticleDeltaNode,
	"ParticleRandomNode": ParticleRandomNode,
	"ParticleIndexNode": ParticleIndexNode,
}

signal reload_requested

var _graph_container: VBoxContainer
var _graph: GraphEdit
var _shader_type: int = 0
var _type_btn: OptionButton
var _mesh_row: HBoxContainer
var _vpc_3d: SubViewportContainer
var _vpc_2d: SubViewportContainer
var _viewport_2d: SubViewport
var _shader_material_2d: ShaderMaterial
var _preview_panel: Panel
var _type_legend: PanelContainer
var _legend_toggle: Button
var _minimap_toggle: Button
var _help_toggle: Button
var _shortcuts_overlay: PanelContainer
var _preview_dragging: bool = false
var _preview_resizing: bool = false
var _panning: bool = false
var _pan_moved: bool = false  # did the cursor move during the current empty-canvas drag?
var _clipboard: Dictionary = {}  # {nodes, connections} from the last copy
var _preview_right_offset: float = 20.0
var _preview_top_offset: float = -1.0  # -1 = not yet placed
var _preview_positioned: bool = false
var _viewport: SubViewport
var _preview_mesh: MeshInstance3D
var _preview_camera: Camera3D
var _preview_mesh_buttons: Array[Button] = []
var _shader_material: ShaderMaterial
var _shader_material_particle: ShaderMaterial
var _particles: GPUParticles3D
var _compile_timer: Timer
var _search_overlay: Control       # full-graph overlay (click-catcher + cards)
var _search_cards: HBoxContainer    # the floating [search | doc] cards, positioned at cursor
var _search_input: LineEdit
var _search_list: ItemList
var _search_item_ids: Array = []
var _doc_panel: PanelContainer
var _doc_label: RichTextLabel
var _doc_hover_timer: Timer
var _doc_pending_id: int = -1
var _export_dialog: EditorFileDialog
var _save_dialog: EditorFileDialog
var _load_dialog: EditorFileDialog
var _texture_dialog: EditorFileDialog
var _new_confirm: ConfirmationDialog
var _load_confirm: ConfirmationDialog
var _save_btn: Button
var _dirty: bool = false              # unsaved changes to the .nyx working file
var _loading: bool = false            # suppresses dirty-marking during load/new
var _pending_load_path: String = ""   # path awaiting the discard-changes confirm
var _pending_after_save: Callable = Callable()  # run after a "Save & …" completes
var _texture_target: Node = null
var _spawn_position: Vector2
var _last_shader_code: String
# Live link / linked artifact state.
const NyxCharon = preload("res://addons/nyx/core/charon.gd")
const NyxGraphRes = preload("res://addons/nyx/core/nyx_graph.gd")
const NyxNodeDataRes = preload("res://addons/nyx/core/nyx_node_data.gd")
var _export_mode: String = "full"         # "full" | "shader_only" (drives _on_export_file_selected)
var _current_nyx_path: String = ""        # working .nyx file on disk ("" = unsaved)
var _linked_shader_path: String = ""      # linked exported .gdshader ("" = unlinked)
var _live_link_on: bool = false
var _export_btn: Button                   # contextual Export… / Update
var _export_menu: MenuButton              # caret dropdown (new material / shader only / re-link / unlink)
var _live_btn: CheckButton
var _undo_stack: Array = []
var _redo_stack: Array = []
var _pre_drag_snapshot = null


func _ready() -> void:
	name = "NyxMain"

	_compile_timer = Timer.new()
	_compile_timer.wait_time = 0.3
	_compile_timer.one_shot = true
	_compile_timer.timeout.connect(_compile_shader)
	add_child(_compile_timer)

	_graph = GraphEdit.new()
	_graph.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_graph.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_graph.grid_pattern = GraphEdit.GRID_PATTERN_DOTS
	_graph.minimap_enabled = false
	_graph.show_minimap_button = false
	var graph_bg := StyleBoxFlat.new()
	graph_bg.bg_color = Color("#0C1018")
	_graph.add_theme_stylebox_override("panel", graph_bg)
	_graph.add_theme_color_override("grid_minor", Color(1, 1, 1, 0.07))
	_graph.add_theme_color_override("grid_major", Color(1, 1, 1, 0.12))
	_graph.right_disconnects = true
	_graph.connection_request.connect(_on_connection_request)
	_graph.disconnection_request.connect(_on_disconnection_request)
	_graph.delete_nodes_request.connect(_on_delete_nodes_request)
	# GraphEdit owns Ctrl+C/V/D when focused (it intercepts them in its own gui_input and
	# emits these signals), so handling them in _shortcut_input never fires. Wire the
	# signals instead — a focused text field consumes the keys first, so node copy/paste
	# only triggers when the graph itself has focus. No manual text-field guard needed.
	_graph.copy_nodes_request.connect(_copy_selected_nodes)
	_graph.paste_nodes_request.connect(_paste_clipboard)
	_graph.duplicate_nodes_request.connect(_duplicate_selected_nodes)
	_graph.gui_input.connect(_on_graph_gui_input)
	# Type IDs: 0 = vec3, 1 = float, 2 = vec2, 3 = vec4.
	# Same-type connections:
	_graph.add_valid_connection_type(0, 0)
	_graph.add_valid_connection_type(1, 1)
	_graph.add_valid_connection_type(2, 2)
	_graph.add_valid_connection_type(3, 3)
	# Implicit promotion (widening only):
	_graph.add_valid_connection_type(1, 2)  # float → vec2
	_graph.add_valid_connection_type(1, 0)  # float → vec3
	_graph.add_valid_connection_type(1, 3)  # float → vec4
	_graph.add_valid_connection_type(2, 0)  # vec2  → vec3
	_graph.add_valid_connection_type(2, 3)  # vec2  → vec4
	_graph.add_valid_connection_type(0, 3)  # vec3  → vec4
	# The one sanctioned narrowing — dropping alpha is unambiguous (.rgb):
	_graph.add_valid_connection_type(3, 0)  # vec4  → vec3

	_graph_container = VBoxContainer.new()
	_graph_container.add_child(_build_graph_toolbar())
	_graph_container.add_child(_graph)
	add_child(_graph_container)

	_build_search_popup()

	_export_dialog = EditorFileDialog.new()
	_export_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	_export_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_export_dialog.add_filter("*.gdshader", "GDShader File")
	_export_dialog.file_selected.connect(_on_export_file_selected)
	add_child(_export_dialog)

	_save_dialog = EditorFileDialog.new()
	_save_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	_save_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_save_dialog.add_filter("*.nyx", "Nyx Graph")
	_save_dialog.file_selected.connect(_on_save_file_selected)
	# Cancelling the save drops any pending "Save & New/Load" so a later plain
	# Save can't accidentally trigger the stale follow-up action.
	_save_dialog.canceled.connect(func(): _pending_after_save = Callable())
	add_child(_save_dialog)

	_load_dialog = EditorFileDialog.new()
	_load_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	_load_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_load_dialog.add_filter("*.nyx", "Nyx Graph")
	_load_dialog.file_selected.connect(load_nyx)
	add_child(_load_dialog)

	_texture_dialog = EditorFileDialog.new()
	_texture_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	_texture_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_texture_dialog.add_filter("*.png,*.jpg,*.jpeg,*.bmp,*.webp,*.tga,*.exr,*.hdr", "Image Files")
	_texture_dialog.file_selected.connect(_on_texture_file_selected)
	add_child(_texture_dialog)

	# OK button = the safe "Save & …" action, so the default/highlighted/Enter
	# choice is never the destructive Discard. Order forced to [Save | Discard | Cancel].
	_new_confirm = ConfirmationDialog.new()
	_new_confirm.title = "New Graph"
	_new_confirm.dialog_text = "You have unsaved changes."
	_new_confirm.ok_button_text = "Save & New"
	var discard_new := _new_confirm.add_button("Discard & New", false, "discard")
	_new_confirm.confirmed.connect(func(): _save_then(_new_graph))
	_new_confirm.custom_action.connect(func(action: StringName):
		if action == &"discard":
			_new_confirm.hide()
			_new_graph()
	)
	_order_dialog_buttons(_new_confirm, discard_new)
	add_child(_new_confirm)

	_load_confirm = ConfirmationDialog.new()
	_load_confirm.title = "Load Graph"
	_load_confirm.dialog_text = "You have unsaved changes."
	_load_confirm.ok_button_text = "Save & Load"
	var discard_load := _load_confirm.add_button("Discard & Load", false, "discard")
	_load_confirm.confirmed.connect(func(): _save_then(func(): _do_load(_pending_load_path)))
	_load_confirm.custom_action.connect(func(action: StringName):
		if action == &"discard":
			_load_confirm.hide()
			_do_load(_pending_load_path)
	)
	_order_dialog_buttons(_load_confirm, discard_load)
	add_child(_load_confirm)

	_preview_panel = _build_preview_panel()
	add_child(_preview_panel)
	_update_link_ui()  # unlinked: "Export…", Live disabled

	_type_legend = _build_type_legend()
	_type_legend.visible = false
	add_child(_type_legend)
	_legend_toggle = _build_legend_toggle()
	add_child(_legend_toggle)
	call_deferred("_reposition_legend")
	_minimap_toggle = _build_minimap_toggle()
	add_child(_minimap_toggle)
	_help_toggle = _build_help_toggle()
	add_child(_help_toggle)
	call_deferred("_reposition_minimap_toggle")
	_shortcuts_overlay = _build_shortcuts_overlay()
	add_child(_shortcuts_overlay)

	_add_node(OutputNode.new(), Vector2(400, 200), "OutputNode")
	_add_node(ColorNode.new(), Vector2(150, 200), "Color")


func _build_preview_panel() -> Panel:
	var floating := Panel.new()
	floating.size = Vector2(220, 200)

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.13, 0.13, 0.16, 0.95)
	bg.corner_radius_top_left = 6
	bg.corner_radius_top_right = 6
	bg.corner_radius_bottom_left = 6
	bg.corner_radius_bottom_right = 6
	floating.add_theme_stylebox_override("panel", bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	floating.add_child(vbox)

	var header := HBoxContainer.new()
	header.mouse_default_cursor_shape = Control.CURSOR_MOVE
	header.gui_input.connect(_on_preview_header_input)
	vbox.add_child(header)

	var title := Label.new()
	title.text = "Preview"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	_export_btn = Button.new()
	_export_btn.text = "Export…"
	_export_btn.pressed.connect(_on_export_pressed)
	header.add_child(_export_btn)

	_export_menu = MenuButton.new()
	_export_menu.flat = false
	_export_menu.text = "▾"
	var pm := _export_menu.get_popup()
	pm.add_item("Export new material", 0)
	pm.add_item("Export shader only", 1)
	pm.add_separator()
	pm.add_item("Export as… (re-link)", 2)
	pm.add_item("Unlink", 3)
	pm.id_pressed.connect(_on_export_menu_id)
	header.add_child(_export_menu)

	_live_btn = CheckButton.new()
	_live_btn.text = "Live"
	_live_btn.tooltip_text = "Live link: push shader changes into the linked artifact in the scene in real time (in-memory, no save)."
	_live_btn.toggled.connect(_on_live_toggled)
	header.add_child(_live_btn)

	var toggle := Button.new()
	toggle.text = "×"
	toggle.pressed.connect(_toggle_preview)
	header.add_child(toggle)

	var mesh_row := HBoxContainer.new()
	mesh_row.add_theme_constant_override("separation", 2)
	vbox.add_child(mesh_row)
	_mesh_row = mesh_row

	for pair in [["Sphere", SphereMesh.new(), Vector3.ZERO, 1.2], ["Plane", QuadMesh.new(), Vector3.ZERO, 1.2], ["Cube", BoxMesh.new(), Vector3(20, 40, 20), 1.8]]:
		var btn := Button.new()
		btn.text = pair[0]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.toggle_mode = true
		btn.button_pressed = pair[0] == "Sphere"
		btn.pressed.connect(_on_mesh_btn_pressed.bind(btn, pair[1], pair[2], pair[3]))
		mesh_row.add_child(btn)
		_preview_mesh_buttons.append(btn)

	var vpc := SubViewportContainer.new()
	vpc.stretch = true
	vpc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vpc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(vpc)
	_vpc_3d = vpc

	_viewport = SubViewport.new()
	_viewport.own_world_3d = true
	_viewport.transparent_bg = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vpc.add_child(_viewport)

	_preview_camera = Camera3D.new()
	_preview_camera.position = Vector3(0, 0, 1.2)
	_viewport.add_child(_preview_camera)

	_preview_mesh = MeshInstance3D.new()
	_preview_mesh.mesh = SphereMesh.new()
	_shader_material = ShaderMaterial.new()
	_shader_material.shader = Shader.new()
	_shader_material.shader.code = "shader_type spatial;\nvoid fragment() {\n\tALBEDO = vec3(0.5, 0.5, 0.5);\n}\n"
	_preview_mesh.material_override = _shader_material
	_viewport.add_child(_preview_mesh)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, 45, 0)
	_viewport.add_child(light)

	# Particle preview — a GPUParticles3D sharing the 3D viewport. Its process
	# material is the compiled particle shader; the draw pass is a small additive
	# billboard quad tinted by COLOR. Preview-only, not part of export.
	_shader_material_particle = ShaderMaterial.new()
	_shader_material_particle.shader = Shader.new()
	_shader_material_particle.shader.code = "shader_type particles;\nvoid start() {}\nvoid process() {}\n"

	_particles = GPUParticles3D.new()
	_particles.amount = 48
	_particles.lifetime = 2.0
	_particles.process_material = _shader_material_particle
	var quad := QuadMesh.new()
	quad.size = Vector2(0.08, 0.08)
	var draw_mat := StandardMaterial3D.new()
	draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_mat.vertex_color_use_as_albedo = true
	draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	draw_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	quad.material = draw_mat
	_particles.draw_pass_1 = quad
	_particles.visible = false
	_particles.emitting = false
	_viewport.add_child(_particles)

	_vpc_2d = SubViewportContainer.new()
	_vpc_2d.stretch = true
	_vpc_2d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vpc_2d.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_vpc_2d.visible = false
	vbox.add_child(_vpc_2d)

	_viewport_2d = SubViewport.new()
	_viewport_2d.transparent_bg = true
	_viewport_2d.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_vpc_2d.add_child(_viewport_2d)

	var preview_rect := ColorRect.new()
	preview_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shader_material_2d = ShaderMaterial.new()
	_shader_material_2d.shader = Shader.new()
	_shader_material_2d.shader.code = "shader_type canvas_item;\nvoid fragment() { COLOR = vec4(0.5, 0.5, 0.5, 1.0); }\n"
	preview_rect.material = _shader_material_2d
	_viewport_2d.add_child(preview_rect)

	var grip := Control.new()
	grip.size = Vector2(16, 16)
	grip.anchor_left = 1.0
	grip.anchor_top = 1.0
	grip.anchor_right = 1.0
	grip.anchor_bottom = 1.0
	grip.offset_left = -16
	grip.offset_top = -16
	grip.mouse_default_cursor_shape = 12
	grip.gui_input.connect(_on_preview_resize_input)
	floating.add_child(grip)

	return floating


func _add_node(node: Node, offset: Vector2, node_name: String = "") -> void:
	if node_name != "":
		node.name = node_name
	var type_name := _get_node_type(node)
	if _TYPE_COLORS.has(type_name):
		node._node_color = _TYPE_COLORS[type_name]
	node.position_offset = offset
	_graph.add_child(node)
	if node.has_signal("value_changed"):
		node.value_changed.connect(_request_compile)
		node.value_changed.connect(_mark_dirty)
	if node.has_signal("edit_started"):
		node.edit_started.connect(_push_undo_state)
	if node.has_signal("texture_pick_requested"):
		node.texture_pick_requested.connect(_on_texture_pick_requested)
	if node.has_signal("pair_removed"):
		node.pair_removed.connect(func(idx: int): _on_relay_pair_removed(node, idx))
	if node.has_signal("preview_toggled"):
		node.preview_toggled.connect(func():
			if node.has_meta("_preview_material"):
				_close_node_preview(node)
			else:
				_open_node_preview(node)
		)
	node.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_pre_drag_snapshot = _serialize_graph()
	)
	if node.has_signal("dragged"):
		node.dragged.connect(func(_f: Vector2, _t: Vector2):
			if _pre_drag_snapshot != null:
				_undo_stack.push_back(_pre_drag_snapshot)
				if _undo_stack.size() > 50:
					_undo_stack.pop_front()
				_redo_stack.clear()
				_pre_drag_snapshot = null
				_mark_dirty()
		)
	# Nodes spawned while in particle mode shouldn't carry a preview chevron.
	if _shader_type == 2 and node.has_method("set_preview_chevron_visible"):
		node.call_deferred("set_preview_chevron_visible", false)


func _toggle_preview() -> void:
	_preview_panel.visible = not _preview_panel.visible


func _on_mesh_btn_pressed(btn: Button, mesh: Mesh, rotation: Vector3, cam_z: float) -> void:
	_preview_mesh.mesh = mesh
	_preview_mesh.rotation_degrees = rotation
	_preview_camera.position.z = cam_z
	for b in _preview_mesh_buttons:
		b.button_pressed = b == btn



func _open_node_preview(node: Node) -> void:
	# No per-node previews in particle mode — values are per-particle, and a
	# spatial preview shader would reference particle-only builtins (CUSTOM, etc).
	if _shader_type == 2:
		return
	var tex_rect: TextureRect = node.get_preview_slot()
	if not tex_rect:
		return

	var vp := SubViewport.new()
	vp.size = Vector2i(100, 100)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)

	var mat := ShaderMaterial.new()
	mat.shader = Shader.new()

	if _shader_type == 1:
		# Canvas Item — use a ColorRect
		mat.shader.code = "shader_type canvas_item;\nrender_mode unshaded;\nvoid fragment() { COLOR = vec4(0.5, 0.5, 0.5, 1.0); }"
		var rect := ColorRect.new()
		rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		rect.material = mat
		vp.add_child(rect)
	else:
		# Spatial — use a quad mesh with camera
		vp.own_world_3d = true
		var cam := Camera3D.new()
		cam.position = Vector3(0, 0, 1.2)
		vp.add_child(cam)
		cam.make_current()
		var mesh_inst := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(1.84, 1.84)
		mesh_inst.mesh = qm
		mat.shader.code = "shader_type spatial;\nrender_mode unshaded;\nvoid fragment() { ALBEDO = vec3(0.5); }"
		mesh_inst.material_override = mat
		vp.add_child(mesh_inst)
		var light := DirectionalLight3D.new()
		light.rotation_degrees = Vector3(-45, 45, 0)
		vp.add_child(light)

	tex_rect.texture = vp.get_texture()
	node.set_meta("_preview_material", mat)
	node.set_meta("_preview_viewport", vp)
	_refresh_node_preview(node)


func _close_node_preview(node: Node) -> void:
	if node.has_meta("_preview_material"):
		node.remove_meta("_preview_material")
	if node.has_meta("_preview_viewport"):
		(node.get_meta("_preview_viewport") as Node).queue_free()
		node.remove_meta("_preview_viewport")
	var tex_rect: TextureRect = node.get_preview_slot()
	if tex_rect:
		tex_rect.texture = null


func _refresh_node_preview(node: Node) -> void:
	if not node.has_meta("_preview_material"):
		return
	var mat: ShaderMaterial = node.get_meta("_preview_material")
	mat.shader.code = _build_node_preview_shader(node)
	for child in _graph.get_children():
		if child.has_method("get_uniform_name") and child.has_method("get_texture"):
			var tex = child.get_texture()
			if tex:
				mat.set_shader_parameter(child.get_uniform_name(), tex)


func _refresh_all_node_previews() -> void:
	for child in _graph.get_children():
		if child.has_meta("_preview_material"):
			_refresh_node_preview(child)


func _build_node_preview_shader(node: Node) -> String:
	var c = _graph.get_connection_list()

	var uniform_lines := ""
	var seen_decls := {}
	for child in _graph.get_children():
		if child.has_method("get_uniform_declaration"):
			var decl: String = child.get_uniform_declaration()
			if decl != "" and not seen_decls.has(decl):
				uniform_lines += decl + "\n"
				seen_decls[decl] = true

	var shader_functions := {}
	for child in _graph.get_children():
		if child.has_method("get_shader_functions"):
			shader_functions.merge(child.get_shader_functions())
	var function_block := ""
	for fn in shader_functions:
		function_block += shader_functions[fn]

	var preview_expr: String
	if node.get_output_port_count() == 0:
		preview_expr = _get_snippet_for(node.name, 0, c, "vec3(0.5, 0.5, 0.5)")
	else:
		var node_result := _get_node_snippet(node, 0, c)
		preview_expr = _to_vec3_display(node_result[0], node_result[1])

	if _shader_type == 1:
		return "shader_type canvas_item;\nrender_mode unshaded;\n%s\n%svoid fragment() {\n\tCOLOR = vec4(%s, 1.0);\n}\n" % [uniform_lines, function_block, preview_expr]

	return "shader_type spatial;\nrender_mode unshaded;\n%s\n%svoid fragment() {\n\tALBEDO = %s;\n}\n" % [uniform_lines, function_block, preview_expr]


func _request_compile() -> void:
	_compile_timer.stop()
	_compile_timer.start()


func _build_shader_code() -> String:
	var uniform_lines := ""
	var seen_decls := {}
	for child in _graph.get_children():
		if child.has_method("get_uniform_declaration"):
			var decl: String = child.get_uniform_declaration()
			if decl != "" and not seen_decls.has(decl):
				uniform_lines += decl + "\n"
				seen_decls[decl] = true

	var shader_functions := {}
	for child in _graph.get_children():
		if child.has_method("get_shader_functions"):
			shader_functions.merge(child.get_shader_functions())
	var function_block := ""
	for fn in shader_functions:
		function_block += shader_functions[fn]

	var output_node = _graph.get_node_or_null("OutputNode")
	var render_mode: String = output_node.get_render_mode() if output_node else ""
	var render_mode_line: String = ("render_mode %s;\n" % render_mode) if render_mode != "" else ""

	var c = _graph.get_connection_list()

	if _shader_type == 1:
		# Canvas Item
		var color  = _get_snippet_for("OutputNode", 0, c, "vec3(1.0, 1.0, 1.0)")
		var alpha  = _get_snippet_for("OutputNode", 1, c, "1.0")
		var normal = _get_snippet_for("OutputNode", 2, c, "")
		var normal_line := "\tNORMAL_MAP = %s;\n" % normal if normal != "" else ""
		return "shader_type canvas_item;\n%s%s\n%svoid fragment() {\n\tCOLOR = vec4(%s, %s);\n%s}\n" % [render_mode_line, uniform_lines, function_block, color, alpha, normal_line]

	if _shader_type == 2:
		# Particles — process shader. Two entry points: start() (once, on spawn)
		# and process() (per frame). TRANSFORM is recomposed from decomposed
		# Position/Rotation/Scale via nyx_compose_transform. CUSTOM.y is reserved
		# for age tracking (0 at spawn, += DELTA/LIFETIME each frame → Age Ratio).
		var compose_fn := "mat4 nyx_compose_transform(vec3 pos, vec3 euler, vec3 scale) {\n" \
			+ "\tfloat cx = cos(euler.x); float sx = sin(euler.x);\n" \
			+ "\tfloat cy = cos(euler.y); float sy = sin(euler.y);\n" \
			+ "\tfloat cz = cos(euler.z); float sz = sin(euler.z);\n" \
			+ "\tmat3 rx = mat3(vec3(1.0, 0.0, 0.0), vec3(0.0, cx, sx), vec3(0.0, -sx, cx));\n" \
			+ "\tmat3 ry = mat3(vec3(cy, 0.0, -sy), vec3(0.0, 1.0, 0.0), vec3(sy, 0.0, cy));\n" \
			+ "\tmat3 rz = mat3(vec3(cz, sz, 0.0), vec3(-sz, cz, 0.0), vec3(0.0, 0.0, 1.0));\n" \
			+ "\tmat3 basis = rz * ry * rx;\n" \
			+ "\tbasis[0] *= scale.x; basis[1] *= scale.y; basis[2] *= scale.z;\n" \
			+ "\tmat4 m;\n" \
			+ "\tm[0] = vec4(basis[0], 0.0);\n" \
			+ "\tm[1] = vec4(basis[1], 0.0);\n" \
			+ "\tm[2] = vec4(basis[2], 0.0);\n" \
			+ "\tm[3] = vec4(pos, 1.0);\n" \
			+ "\treturn m;\n}\n\n"

		var s_pos := "vec3(0.0)"
		var s_vel := "vec3(0.0)"
		var s_col := "vec4(1.0)"
		var s_scale := "vec3(1.0)"
		var s_rot := "vec3(0.0)"
		if _graph.get_node_or_null("ParticleStartNode"):
			s_pos   = _get_typed_snippet_for("ParticleStartNode", 0, c, "vec3(0.0)", 0)
			s_vel   = _get_typed_snippet_for("ParticleStartNode", 1, c, "vec3(0.0)", 0)
			s_col   = _get_typed_snippet_for("ParticleStartNode", 2, c, "vec4(1.0)", 3)
			s_scale = _get_typed_snippet_for("ParticleStartNode", 3, c, "vec3(1.0)", 0)
			s_rot   = _get_typed_snippet_for("ParticleStartNode", 4, c, "vec3(0.0)", 0)

		var start_body := "\tTRANSFORM = EMISSION_TRANSFORM * nyx_compose_transform(%s, %s, %s);\n" % [s_pos, s_rot, s_scale]
		start_body += "\tVELOCITY = %s;\n" % s_vel
		start_body += "\tCOLOR = %s;\n" % s_col
		start_body += "\tCUSTOM.y = 0.0;\n"

		var process_body := "\tCUSTOM.y += DELTA / max(LIFETIME, 0.0001);\n"
		var p_pos := ""
		if _graph.get_node_or_null("ParticleProcessNode"):
			var p_vel := _get_typed_snippet_for("ParticleProcessNode", 0, c, "", 0)
			var p_col := _get_typed_snippet_for("ParticleProcessNode", 1, c, "", 3)
			p_pos = _get_typed_snippet_for("ParticleProcessNode", 2, c, "", 0)
			if p_vel != "":
				process_body += "\tVELOCITY = %s;\n" % p_vel
			if p_col != "":
				process_body += "\tCOLOR = %s;\n" % p_col
		if p_pos != "":
			process_body += "\tTRANSFORM[3].xyz = %s;\n" % p_pos
		else:
			process_body += "\tTRANSFORM[3].xyz += VELOCITY * DELTA;\n"

		return "shader_type particles;\n%s\n%s%svoid start() {\n%s}\n\nvoid process() {\n%s}\n" % [uniform_lines, function_block, compose_fn, start_body, process_body]

	# Spatial
	var albedo    = _get_snippet_for("OutputNode", 0, c, "vec3(0.5, 0.5, 0.5)")
	var alpha     = _get_snippet_for("OutputNode", 1, c, "1.0")
	var roughness = _get_snippet_for("OutputNode", 2, c, "1.0")
	var metallic  = _get_snippet_for("OutputNode", 3, c, "0.0")
	var emission  = _get_snippet_for("OutputNode", 4, c, "vec3(0.0, 0.0, 0.0)")
	var normal         = _get_snippet_for("OutputNode", 5, c, "")
	var vertex_offset  = _get_snippet_for("OutputNode", 6, c, "")
	var normal_line := "\tNORMAL_MAP = %s;\n" % normal if normal != "" else ""
	var vertex_block := "void vertex() {\n\tVERTEX += %s;\n}\n\n" % vertex_offset if vertex_offset != "" else ""
	return "shader_type spatial;\n%s%s\n%s%svoid fragment() {\n\tALBEDO = %s;\n\tALPHA = %s;\n\tROUGHNESS = %s;\n\tMETALLIC = %s;\n\tEMISSION = %s;\n%s}\n" % [render_mode_line, uniform_lines, function_block, vertex_block, albedo, alpha, roughness, metallic, emission, normal_line]


func _on_relay_pair_removed(relay: Node, removed_idx: int) -> void:
	var relay_name := str(relay.name)
	var c := _graph.get_connection_list()
	var to_reconnect := []
	for conn in c:
		var from := str(conn["from_node"])
		var to := str(conn["to_node"])
		var fp: int = conn["from_port"]
		var tp: int = conn["to_port"]
		if to == relay_name and tp == removed_idx:
			_graph.disconnect_node(from, fp, to, tp)
		elif to == relay_name and tp > removed_idx:
			_graph.disconnect_node(from, fp, to, tp)
			to_reconnect.append({"from": from, "fp": fp, "to": to, "tp": tp - 1})
		elif from == relay_name and fp == removed_idx:
			_graph.disconnect_node(from, fp, to, tp)
		elif from == relay_name and fp > removed_idx:
			_graph.disconnect_node(from, fp, to, tp)
			to_reconnect.append({"from": from, "fp": fp - 1, "to": to, "tp": tp})
	for r in to_reconnect:
		_graph.connect_node(r["from"], r["fp"], r["to"], r["tp"])
	_update_all_polymorphic_ports()
	_request_compile()


func _on_shader_type_changed(idx: int) -> void:
	_shader_type = idx
	if idx == 2:
		_ensure_particle_sinks()
	else:
		var output_node = _graph.get_node_or_null("OutputNode")
		if output_node:
			output_node.set_shader_type(idx)
	_update_sink_visibility()
	# Rebuild per-node previews for the new mode. Particle mode has no per-node
	# previews (the values are per-particle, not per-pixel), so just tear them down.
	for child in _graph.get_children():
		if child is GraphNode and child.has_meta("_preview_material"):
			if child.has_meta("_preview_viewport"):
				(child.get_meta("_preview_viewport") as Node).queue_free()
				child.remove_meta("_preview_viewport")
			child.remove_meta("_preview_material")
			if idx != 2:
				_open_node_preview(child)
	_last_shader_code = ""
	_request_compile()


func _ensure_particle_sinks() -> void:
	if not _graph.get_node_or_null("ParticleStartNode"):
		_add_node(ParticleStartNode.new(), Vector2(440, 120), "ParticleStartNode")
	if not _graph.get_node_or_null("ParticleProcessNode"):
		_add_node(ParticleProcessNode.new(), Vector2(440, 360), "ParticleProcessNode")


func _update_sink_visibility() -> void:
	var output_node = _graph.get_node_or_null("OutputNode")
	if output_node:
		output_node.visible = _shader_type != 2
	var start_node = _graph.get_node_or_null("ParticleStartNode")
	if start_node:
		start_node.visible = _shader_type == 2
	var process_node = _graph.get_node_or_null("ParticleProcessNode")
	if process_node:
		process_node.visible = _shader_type == 2
	if _preview_mesh:
		_preview_mesh.visible = _shader_type == 0
	if _particles:
		_particles.visible = _shader_type == 2
		_particles.emitting = _shader_type == 2
	_mesh_row.visible = _shader_type == 0
	_vpc_3d.visible = _shader_type == 0 or _shader_type == 2  # particles reuse the 3D viewport
	_vpc_2d.visible = _shader_type == 1
	for child in _graph.get_children():
		if child is GraphNode and child.has_method("set_preview_chevron_visible"):
			child.set_preview_chevron_visible(_shader_type != 2)


func _get_active_material() -> ShaderMaterial:
	if _shader_type == 2:
		return _shader_material_particle
	return _shader_material_2d if _shader_type == 1 else _shader_material


func _apply_texture_uniforms() -> void:
	var mat := _get_active_material()
	if mat == null:
		return
	for child in _graph.get_children():
		if child.has_method("get_uniform_name") and child.has_method("get_texture"):
			var tex = child.get_texture()
			if tex:
				mat.set_shader_parameter(child.get_uniform_name(), tex)
		if child.has_method("apply_shader_params"):
			child.apply_shader_params(mat)


func _compile_shader() -> void:
	if _graph.get_node_or_null("OutputNode") or _shader_type == 2:
		var code := _build_shader_code()
		if code != _last_shader_code:
			_last_shader_code = code
			var mat := _get_active_material()
			if mat:
				mat.shader.code = code
				# Live link: push the new code into the linked artifact's loaded
				# resource so the scene viewport updates in-memory (no disk write).
				if _live_link_on and not _linked_shader_path.is_empty():
					NyxCharon.notify_shader_updated(_linked_shader_path, mat)
			# Restart so start() changes apply to live particles immediately.
			if _shader_type == 2 and _particles:
				_particles.restart()
		_apply_texture_uniforms()
	# Per-node previews are pixel-shaded; they don't exist in particle mode.
	if _shader_type != 2:
		_refresh_all_node_previews()


func _on_texture_pick_requested(node: Node) -> void:
	_texture_target = node
	_texture_dialog.popup_centered_ratio(0.5)


func _on_texture_file_selected(path: String) -> void:
	if not _texture_target:
		return
	var tex = load(path)
	if tex is Texture2D:
		_push_undo_state()
		_texture_target.set_texture(tex)
	_texture_target = null


# --- Linked-artifact export / live link ---

# Contextual primary button: Export… when unlinked, Update when linked.
func _on_export_pressed() -> void:
	if _linked_shader_path.is_empty():
		_export_mode = "full"
		_popup_export_dialog()
	else:
		_do_update()


# Caret dropdown: rarer export ops.
func _on_export_menu_id(id: int) -> void:
	match id:
		0:  # Export new material (resets material parameters)
			if _linked_shader_path.is_empty():
				push_warning("Nyx: link a shader first (Export…) before writing a material.")
				return
			if _write_material_file(_linked_shader_path):
				EditorInterface.get_resource_filesystem().scan()
				print("Nyx: wrote material (parameters reset) → %s" % (_linked_shader_path.get_basename() + ".tres"))
		1:  # Export shader only
			if _linked_shader_path.is_empty():
				_export_mode = "shader_only"
				_popup_export_dialog()
			else:
				_do_update()
		2:  # Export as… (re-link to a new path)
			_export_mode = "full"
			_popup_export_dialog()
		3:  # Unlink
			_set_linked("")
			print("Nyx: unlinked")


func _on_live_toggled(on: bool) -> void:
	_live_link_on = on
	# Toggling on immediately reflects the current graph state in the scene.
	if on and not _linked_shader_path.is_empty():
		NyxCharon.notify_shader_updated(_linked_shader_path, _get_active_material())


func _popup_export_dialog() -> void:
	# Co-locate: default the artifact to the working file's folder when we have one.
	if not _current_nyx_path.is_empty():
		_export_dialog.current_dir = _current_nyx_path.get_base_dir()
	_export_dialog.popup_centered_ratio(0.5)


# Update the linked shader in place (no dialog, no material rewrite — material
# values are the user's to keep). Persists the .nyx too, the way Ctrl+S does.
func _do_update() -> void:
	if _linked_shader_path.is_empty():
		return
	var code := _build_shader_code()
	if not _write_shader_file(_linked_shader_path, code):
		return
	if not _current_nyx_path.is_empty():
		_write_nyx_file(_current_nyx_path)
	NyxCharon.notify_shader_updated(_linked_shader_path, _get_active_material())
	EditorInterface.get_resource_filesystem().scan()
	print("Nyx: updated shader → %s" % _linked_shader_path)


func _set_linked(path: String) -> void:
	_linked_shader_path = path
	_update_link_ui()
	# Linking implies you want to see it live — default the toggle on. (The toggle
	# stays for the rarer "edit without disturbing the scene" case.)
	if not path.is_empty():
		_live_btn.button_pressed = true


func _update_link_ui() -> void:
	if not _export_btn:
		return
	var linked := not _linked_shader_path.is_empty()
	_export_btn.text = "Update" if linked else "Export…"
	_export_btn.tooltip_text = ("Rewrite linked shader: %s" % _linked_shader_path) if linked else "Export shader + material, then link"
	_live_btn.disabled = not linked
	if not linked and _live_btn.button_pressed:
		_live_btn.button_pressed = false  # fires toggled → live off


# Writes the .gdshader with a provenance stamp (gates artifact → Nyx navigation).
func _write_shader_file(path: String, code: String) -> bool:
	var out := code
	if not _current_nyx_path.is_empty():
		# Line 1 is the machine-read provenance stamp (read_nyx_source parses it);
		# line 2 is a human warning. Keep them on separate lines.
		out = "%s%s\n// Generated by Nyx — do not hand-edit; overwritten on Update.\n%s" % [NyxCharon.PROVENANCE_PREFIX, _current_nyx_path, code]
	var f := FileAccess.open(path, FileAccess.WRITE)
	if not f:
		push_error("Nyx: could not write shader to %s" % path)
		return false
	f.store_string(out)
	f.close()
	return true


# Writes the companion .tres ShaderMaterial next to the shader. Bakes texture/
# sub-resource/float-param values — overwrites any existing material values.
func _write_material_file(shader_path: String) -> bool:
	var path := shader_path
	# Collect nodes by export type
	var file_tex_nodes := []
	var sub_nodes := []
	var value_param_nodes := []
	for child in _graph.get_children():
		if not child.has_method("get_uniform_declaration"):
			continue
		var decl: String = child.get_uniform_declaration()
		if decl == "":
			continue
		if child.has_method("export_as_sub_resource"):
			sub_nodes.append(child)
		elif child.has_method("get_texture"):
			var tex = child.get_texture()
			if tex != null and not tex.resource_path.is_empty():
				file_tex_nodes.append(child)
		elif child.has_method("get_param_export_line"):
			var export_line: String = child.get_param_export_line()
			if export_line != "":
				value_param_nodes.append(child)

	var total_sub_count := sub_nodes.size() * 2
	var load_steps := 1 + file_tex_nodes.size() + total_sub_count + 1
	var lines := PackedStringArray()
	lines.append("[gd_resource type=\"ShaderMaterial\" load_steps=%d format=3]" % load_steps)
	lines.append("")
	lines.append("[ext_resource type=\"Shader\" path=\"%s\" id=\"1\"]" % path)

	var tex_id := 2
	var tex_id_map := {}
	for node in file_tex_nodes:
		var uname: String = node.get_uniform_name()
		lines.append("[ext_resource type=\"Texture2D\" path=\"%s\" id=\"%d\"]" % [node.get_texture().resource_path, tex_id])
		tex_id_map[uname] = tex_id
		tex_id += 1

	lines.append("")

	var sub_id_start := 1
	var sub_param_lines := PackedStringArray()
	for node in sub_nodes:
		var result: Dictionary = node.export_as_sub_resource(sub_id_start)
		for line in (result["lines"] as PackedStringArray):
			lines.append(line)
		sub_param_lines.append(result["param_line"])
		sub_id_start += result["count"] as int

	lines.append("[resource]")
	lines.append("shader = ExtResource(\"1\")")

	for uname in tex_id_map:
		lines.append("shader_parameter/%s = ExtResource(\"%d\")" % [uname, tex_id_map[uname]])

	for line in sub_param_lines:
		lines.append(line)

	for node in value_param_nodes:
		lines.append(node.get_param_export_line())

	lines.append("")

	var tres_path := path.get_basename() + ".tres"
	var tf := FileAccess.open(tres_path, FileAccess.WRITE)
	if not tf:
		push_error("Nyx: could not write material to %s" % tres_path)
		return false
	tf.store_string("\n".join(lines))
	tf.close()
	return true


# Dialog callback: full export (shader + material) or shader-only, then link.
func _on_export_file_selected(path: String) -> void:
	if not path.ends_with(".gdshader"):
		path += ".gdshader"
	var code := _build_shader_code()
	if not _write_shader_file(path, code):
		return
	if _export_mode != "shader_only":
		_write_material_file(path)
	_set_linked(path)
	NyxCharon.notify_shader_updated(path, _get_active_material())
	EditorInterface.get_resource_filesystem().scan()
	if _export_mode == "shader_only":
		print("Nyx: exported shader → %s (linked)" % path)
	else:
		print("Nyx: exported\n  shader  → %s\n  material → %s (linked)" % [path, path.get_basename() + ".tres"])


func _get_snippet_typed(to_node: String, to_port: int, connections: Array, default_val: String, default_type: int) -> Array:
	for conn in connections:
		if str(conn["to_node"]) == to_node and conn["to_port"] == to_port:
			var from := _graph.get_node_or_null(str(conn["from_node"]))
			if from:
				return _get_node_snippet(from, conn["from_port"], connections)
	return [default_val, default_type]


func _get_snippet_for(to_node: String, to_port: int, connections: Array, default_val: String) -> String:
	# Heuristic default type from the literal — fine for float/vec3 defaults, but
	# can't tell vec3 from vec4. Use _get_typed_snippet_for when the slot is vec4.
	var default_type: int = 1 if not default_val.begins_with("vec") else 0
	return _get_typed_snippet_for(to_node, to_port, connections, default_val, default_type)


func _get_typed_snippet_for(to_node: String, to_port: int, connections: Array, default_val: String, default_type: int) -> String:
	var result := _get_snippet_typed(to_node, to_port, connections, default_val, default_type)
	var snippet: String = result[0]
	if snippet.is_empty():
		return snippet
	var from_type: int = result[1]
	var to_node_ref := _graph.get_node_or_null(to_node)
	var to_type: int = to_node_ref.get_input_port_type(to_port) if to_node_ref else 0
	return _promote(snippet, from_type, to_type)


func _get_node_snippet(node: Node, from_port: int, connections: Array) -> Array:
	var defaults: Array = node.get_default_inputs() if node.has_method("get_default_inputs") else []
	var default_types: Array = node.get_default_input_types() if node.has_method("get_default_input_types") else []

	var raw_inputs := []
	for i in range(node.get_input_port_count()):
		var default_val: String = defaults[i] if i < defaults.size() else "0.0"
		var default_type: int = default_types[i] if i < default_types.size() else node.get_input_port_type(i)
		raw_inputs.append(_get_snippet_typed(node.name, i, connections, default_val, default_type))

	var input_types := []
	for r in raw_inputs:
		input_types.append(r[1])

	var output_type: int
	if node.has_method("get_output_type"):
		output_type = node.get_output_type(from_port, input_types)
	else:
		output_type = node.get_output_port_type(from_port) if node.get_output_port_count() > from_port else 0

	var is_poly: bool = node.has_method("is_polymorphic") and node.is_polymorphic()

	var inputs := []
	for i in range(raw_inputs.size()):
		var snippet: String = raw_inputs[i][0]
		var in_type: int = raw_inputs[i][1]
		# Polymorphic nodes operate at their resolved output type, so promote
		# every input up to it. Fixed-type nodes promote to the declared port type.
		var target_type: int = output_type if is_poly else (node.get_input_port_type(i) if i < node.get_input_port_count() else 0)
		inputs.append(_promote(snippet, in_type, target_type))

	return [node.get_output_snippet(from_port, inputs), output_type]


func _resolve_output_type(node: Node, from_port: int) -> int:
	if not node.has_method("is_polymorphic") or not node.is_polymorphic():
		return node.get_output_port_type(from_port)
	var c := _graph.get_connection_list()
	var default_types: Array = node.get_default_input_types() if node.has_method("get_default_input_types") else []
	var input_types := []
	for i in range(node.get_input_port_count()):
		var in_type: int = default_types[i] if i < default_types.size() else node.get_input_port_type(i)
		for conn in c:
			if str(conn["to_node"]) == node.name and conn["to_port"] == i:
				var from_n := _graph.get_node_or_null(str(conn["from_node"]))
				if from_n:
					in_type = _resolve_output_type(from_n, conn["from_port"])
				break
		input_types.append(in_type)
	return node.get_output_type(from_port, input_types) if node.has_method("get_output_type") else node.get_output_port_type(from_port)


func _update_all_polymorphic_ports() -> void:
	for child in _graph.get_children():
		if not (child is GraphNode):
			continue
		if not child.has_method("is_polymorphic") or not child.is_polymorphic():
			continue
		for port in range(child.get_output_port_count()):
			var resolved_type := _resolve_output_type(child, port)
			if child.get_output_port_type(port) == resolved_type:
				continue
			var port_color := NyxNodeBase._type_color(resolved_type)
			child.set_slot(port,
				child.is_slot_enabled_left(port), child.get_slot_type_left(port), child.get_slot_color_left(port),
				child.is_slot_enabled_right(port), resolved_type, port_color)


func sync_size(new_size: Vector2) -> void:
	if _graph_container:
		_graph_container.size = new_size
	if not _preview_positioned and _preview_panel:
		_preview_positioned = true
		call_deferred("_position_preview_default")
	elif _preview_panel and _preview_top_offset >= 0.0:
		_preview_panel.position = Vector2(
			_graph_container.size.x - _preview_panel.size.x - _preview_right_offset,
			_preview_top_offset
		).clamp(Vector2.ZERO, _graph_container.size - _preview_panel.size)
	_reposition_legend()
	_reposition_minimap_toggle()
	if _search_overlay and _search_overlay.visible:
		_search_overlay.size = _graph_container.size


func _position_preview_default() -> void:
	# Place just below the graph toolbar, not overlapping it.
	var toolbar_h := 0.0
	if _graph_container.get_child_count() > 0:
		toolbar_h = _graph_container.get_child(0).get_combined_minimum_size().y
	_preview_top_offset = toolbar_h + 12.0
	_preview_right_offset = 20.0
	_preview_panel.position = Vector2(
		_graph_container.size.x - _preview_panel.size.x - _preview_right_offset,
		_preview_top_offset
	)


# Static key in the bottom-left corner of the graph mapping the four data-type
# dot colors to plain-language names. The dot color is the real type encoding;
# this just reinforces it without any per-port hover machinery.
func _build_type_legend() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.047, 0.063, 0.094, 0.85)
	bg.set_corner_radius_all(6)
	bg.set_content_margin_all(5)
	bg.set_border_width_all(1)
	bg.border_color = Color(1, 1, 1, 0.08)
	panel.add_theme_stylebox_override("panel", bg)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)

	# [type_id, friendly_name, glsl_name]
	var entries := [
		[1, "Value", "float"],
		[2, "UV", "vec2"],
		[0, "Color", "vec3"],
		[3, "Color + Alpha", "vec4"],
	]
	for e in entries:
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 6)

		var sw := ColorRect.new()
		sw.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sw.color = NyxNodeBase._type_color(e[0])
		sw.custom_minimum_size = Vector2(9, 9)
		sw.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(sw)

		var lbl := Label.new()
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.text = "%s  (%s)" % [e[1], e[2]]
		lbl.add_theme_color_override("font_color", Color(0.85, 0.87, 0.92))
		lbl.add_theme_font_size_override("font_size", 10)
		row.add_child(lbl)

		vbox.add_child(row)

	return panel


func _build_legend_toggle() -> Button:
	var btn := Button.new()
	btn.text = "Types  ▴"
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 10)
	btn.add_theme_color_override("font_color", Color(0.85, 0.87, 0.92))

	var chip := StyleBoxFlat.new()
	chip.bg_color = Color(0.047, 0.063, 0.094, 0.85)
	chip.set_corner_radius_all(6)
	chip.set_content_margin_all(4)
	chip.set_border_width_all(1)
	chip.border_color = Color(1, 1, 1, 0.08)
	btn.add_theme_stylebox_override("normal", chip)

	var chip_hover := chip.duplicate() as StyleBoxFlat
	chip_hover.bg_color = Color(0.09, 0.11, 0.15, 0.9)
	btn.add_theme_stylebox_override("hover", chip_hover)
	btn.add_theme_stylebox_override("pressed", chip_hover)

	btn.pressed.connect(_on_legend_toggle)
	return btn


func _on_legend_toggle() -> void:
	_type_legend.visible = not _type_legend.visible
	_legend_toggle.text = "Types  ▾" if _type_legend.visible else "Types  ▴"
	_reposition_legend()


func _reposition_legend() -> void:
	if not _legend_toggle or not _graph_container:
		return
	var bh: float = _legend_toggle.get_combined_minimum_size().y
	_legend_toggle.position = Vector2(20, _graph_container.size.y - bh - 20)
	if _type_legend:
		var ph: float = _type_legend.get_combined_minimum_size().y
		_type_legend.position = Vector2(20, _legend_toggle.position.y - ph - 6)


func _build_minimap_toggle() -> Button:
	var btn := Button.new()
	btn.text = "Map  ▴"
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 10)
	btn.add_theme_color_override("font_color", Color(0.85, 0.87, 0.92))
	var chip := StyleBoxFlat.new()
	chip.bg_color = Color(0.047, 0.063, 0.094, 0.85)
	chip.set_corner_radius_all(6)
	chip.set_content_margin_all(4)
	chip.set_border_width_all(1)
	chip.border_color = Color(1, 1, 1, 0.08)
	btn.add_theme_stylebox_override("normal", chip)
	var chip_hover := chip.duplicate() as StyleBoxFlat
	chip_hover.bg_color = Color(0.09, 0.11, 0.15, 0.9)
	btn.add_theme_stylebox_override("hover", chip_hover)
	btn.add_theme_stylebox_override("pressed", chip_hover)
	btn.pressed.connect(_on_minimap_toggle)
	return btn


func _on_minimap_toggle() -> void:
	_graph.minimap_enabled = not _graph.minimap_enabled
	_minimap_toggle.text = "Map  ▾" if _graph.minimap_enabled else "Map  ▴"


func _build_help_toggle() -> Button:
	var btn := Button.new()
	btn.text = "?"
	btn.tooltip_text = "Keyboard shortcuts (?)"
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 10)
	btn.add_theme_color_override("font_color", Color(0.85, 0.87, 0.92))
	var chip := StyleBoxFlat.new()
	chip.bg_color = Color(0.047, 0.063, 0.094, 0.85)
	chip.set_corner_radius_all(6)
	chip.set_content_margin_all(4)
	chip.content_margin_left = 8
	chip.content_margin_right = 8
	chip.set_border_width_all(1)
	chip.border_color = Color(1, 1, 1, 0.08)
	btn.add_theme_stylebox_override("normal", chip)
	var chip_hover := chip.duplicate() as StyleBoxFlat
	chip_hover.bg_color = Color(0.09, 0.11, 0.15, 0.9)
	btn.add_theme_stylebox_override("hover", chip_hover)
	btn.add_theme_stylebox_override("pressed", chip_hover)
	btn.pressed.connect(_toggle_shortcuts_overlay)
	return btn


# Positions both bottom-right chips: [?] [Map] anchored to the bottom-right corner.
func _reposition_minimap_toggle() -> void:
	if not _minimap_toggle or not _graph_container:
		return
	var mw: float = _minimap_toggle.get_combined_minimum_size().x
	var mh: float = _minimap_toggle.get_combined_minimum_size().y
	_minimap_toggle.position = Vector2(_graph_container.size.x - mw - 20, _graph_container.size.y - mh - 20)
	if _help_toggle:
		var hw: float = _help_toggle.get_combined_minimum_size().x
		var hh: float = _help_toggle.get_combined_minimum_size().y
		_help_toggle.position = Vector2(_minimap_toggle.position.x - hw - 6, _graph_container.size.y - hh - 20)


func _build_shortcuts_overlay() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.visible = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.09, 0.12, 0.93)
	bg.set_corner_radius_all(8)
	bg.set_content_margin_all(14)
	bg.set_border_width_all(1)
	bg.border_color = Color(1, 1, 1, 0.1)
	panel.add_theme_stylebox_override("panel", bg)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Shortcuts"
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", Color(0.6, 0.7, 0.65))
	vbox.add_child(title)

	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 4)
	vbox.add_child(sep)

	var entries := [
		["Right-click / A", "Add node"],
		["X", "Delete selected"],
		["R", "Add Reroute"],
		["Ctrl+C", "Copy selected"],
		["Ctrl+V", "Paste"],
		["Ctrl+D", "Duplicate selected"],
		["Left-drag", "Pan canvas"],
		["Shift+Left-drag", "Box select"],
		["Ctrl+N", "New graph"],
		["Ctrl+O", "Open graph"],
		["Ctrl+S", "Save (+ Update if linked)"],
		["Ctrl+Shift+S", "Save As"],
		["Ctrl+U", "Reload Nyx"],
		["?", "Toggle this chart"],
	]
	for e in entries:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var key_lbl := Label.new()
		key_lbl.text = e[0]
		key_lbl.custom_minimum_size.x = 150
		key_lbl.add_theme_font_size_override("font_size", 11)
		key_lbl.add_theme_color_override("font_color", Color(0.85, 0.9, 0.88))
		var desc_lbl := Label.new()
		desc_lbl.text = e[1]
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.add_theme_color_override("font_color", Color(0.55, 0.58, 0.62))
		row.add_child(key_lbl)
		row.add_child(desc_lbl)
		vbox.add_child(row)

	return panel


func _on_preview_header_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_preview_dragging = event.pressed
	elif event is InputEventMouseMotion and _preview_dragging:
		_preview_panel.position += event.relative
		_preview_right_offset = _graph_container.size.x - _preview_panel.position.x - _preview_panel.size.x
		_preview_top_offset = _preview_panel.position.y


func _on_preview_resize_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_preview_resizing = event.pressed
	elif event is InputEventMouseMotion and _preview_resizing:
		var new_size: Vector2 = _preview_panel.size + event.relative
		new_size.x = max(new_size.x, 160.0)
		new_size.y = max(new_size.y, 120.0)
		_preview_panel.size = new_size


func _push_undo_state() -> void:
	_undo_stack.push_back(_serialize_graph())
	if _undo_stack.size() > 50:
		_undo_stack.pop_front()
	_redo_stack.clear()
	_mark_dirty()


# --- Dirty tracking (unsaved .nyx working-file changes) ---

func _mark_dirty() -> void:
	if _loading or _dirty:
		return
	_dirty = true
	_update_save_button()


func _set_clean() -> void:
	_dirty = false
	_update_save_button()


func _update_save_button() -> void:
	if _save_btn:
		_save_btn.text = "Save*" if _dirty else "Save"


func _undo() -> void:
	if _undo_stack.is_empty():
		return
	_redo_stack.push_back(_serialize_graph())
	_deserialize_graph(_undo_stack.pop_back())


func _redo() -> void:
	if _redo_stack.is_empty():
		return
	_undo_stack.push_back(_serialize_graph())
	_deserialize_graph(_redo_stack.pop_back())


func _on_delete_nodes_request(nodes: Array[StringName]) -> void:
	_push_undo_state()
	for node_name in nodes:
		if str(node_name) == "OutputNode":
			continue
		var to_disconnect := []
		for conn in _graph.get_connection_list():
			if str(conn["from_node"]) == str(node_name) or str(conn["to_node"]) == str(node_name):
				to_disconnect.append(conn)
		for conn in to_disconnect:
			_graph.disconnect_node(conn["from_node"], conn["from_port"], conn["to_node"], conn["to_port"])
		var node := _graph.get_node_or_null(str(node_name))
		if node:
			node.queue_free()
	_request_compile()


# --- Copy / paste / duplicate ---

# The singleton sink nodes (Output / particle Start+Process) are fixed-name and must
# never be copied or duplicated.
func _is_sink_node(node: Node) -> bool:
	var n := str(node.name)
	return n == "OutputNode" or n == "ParticleStartNode" or n == "ParticleProcessNode"


# Serialize the currently-selected (non-sink) nodes plus the connections wholly between
# them, into a {nodes, connections} buffer — the shared payload for copy and duplicate.
func _serialize_selected_nodes() -> Dictionary:
	var selected := {}
	var nodes := []
	for child in _graph.get_children():
		if not child is GraphNode or not child.selected or _is_sink_node(child):
			continue
		var type := _get_node_type(child)
		if type == "":
			continue
		selected[str(child.name)] = true
		nodes.append({
			"type": type,
			"name": str(child.name),
			"position": [child.position_offset.x, child.position_offset.y],
			"state": child.get_state(),
		})
	var connections := []
	for conn in _graph.get_connection_list():
		if selected.has(str(conn["from_node"])) and selected.has(str(conn["to_node"])):
			connections.append({
				"from_node": str(conn["from_node"]),
				"from_port": conn["from_port"],
				"to_node": str(conn["to_node"]),
				"to_port": conn["to_port"],
			})
	return {"nodes": nodes, "connections": connections}


# Recreate a {nodes, connections} buffer into the graph, offset from the originals, and
# leave the new nodes selected (so they can be dragged immediately). Used by paste and
# duplicate; new names auto-uniquify on add_child, captured into name_map for the conns.
func _paste_buffer(buf: Dictionary, offset: Vector2 = Vector2(30, 30)) -> void:
	# NOTE: paste does NOT gate on shader mode. The clipboard is per-session and persists
	# across load/new, so you can paste a node that's invalid for the current mode (e.g. a
	# spatial Fresnel into a particle graph). This can't crash — it's a soft failure: an
	# off-mode node only produces bad GLSL if it's actually wired into the output chain
	# (the compiler walks from the sink), and that's recoverable by deleting it. A precise
	# gate would need a parallel type→mode-flags table (the registry is keyed by id, not
	# type), which we deliberately avoid. Same non-enforcement already exists for load.
	var src: Array = buf.get("nodes", [])
	if src.is_empty():
		return
	_push_undo_state()
	_deselect_all_nodes()
	var name_map := {}
	var new_nodes: Array[Node] = []
	for nd in src:
		var type: String = nd["type"]
		if not NODE_CLASSES.has(type):
			continue
		var node = NODE_CLASSES[type].new()
		var pos: Array = nd["position"]
		var base: String = nd["name"]
		if base.begins_with("@"):
			base = type.trim_suffix("Node")
		_add_node(node, Vector2(pos[0], pos[1]) + offset, base)
		name_map[nd["name"]] = str(node.name)
		var state: Dictionary = nd.get("state", {})
		if not state.is_empty():
			node.set_state(state)
		new_nodes.append(node)
	for conn in buf.get("connections", []):
		var from = name_map.get(conn["from_node"])
		var to = name_map.get(conn["to_node"])
		if from != null and to != null:
			_graph.connect_node(from, conn["from_port"], to, conn["to_port"])
	for node in new_nodes:
		node.selected = true
	_update_all_polymorphic_ports()
	_request_compile()
	_mark_dirty()


func _copy_selected_nodes() -> void:
	var buf := _serialize_selected_nodes()
	if not (buf["nodes"] as Array).is_empty():
		_clipboard = buf


func _paste_clipboard() -> void:
	# Paste anchors the copied group's top-left at the mouse cursor (in graph space), so it
	# lands where you're pointing rather than back at the originals' (maybe scrolled-away)
	# location. Relative layout between the pasted nodes is preserved.
	var src: Array = _clipboard.get("nodes", [])
	if src.is_empty():
		return
	var min_pos := Vector2(INF, INF)
	for nd in src:
		var p: Array = nd["position"]
		min_pos = min_pos.min(Vector2(p[0], p[1]))
	var mouse_graph := _graph.get_local_mouse_position() / _graph.zoom + _graph.scroll_offset
	_paste_buffer(_clipboard, mouse_graph - min_pos)


func _duplicate_selected_nodes() -> void:
	# Duplicate stays a small offset from the originals (the cursor is usually right on the
	# node you just selected, so cursor-anchoring would stack the copy on top). Uses its own
	# buffer so it never clobbers the copy/paste clipboard.
	_paste_buffer(_serialize_selected_nodes())


func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	var from := _graph.get_node_or_null(str(from_node))
	var to := _graph.get_node_or_null(str(to_node))
	if not from or not to:
		return
	var from_type: int = _resolve_output_type(from, from_port)
	var to_type: int = to.get_input_port_type(to_port)
	if not _can_promote(from_type, to_type):
		return
	_push_undo_state()
	_graph.connect_node(from_node, from_port, to_node, to_port)
	_update_all_polymorphic_ports()
	_request_compile()


# Type IDs: 0 = vec3, 1 = float, 2 = vec2, 3 = vec4.
func _can_promote(from_type: int, to_type: int) -> bool:
	if from_type == to_type:
		return true
	match from_type:
		1: return to_type in [2, 0, 3]  # float → vec2/vec3/vec4
		2: return to_type in [0, 3]     # vec2  → vec3/vec4
		0: return to_type == 3          # vec3  → vec4
		3: return to_type == 0          # vec4  → vec3 (drop alpha, .rgb)
	return false


# Widen a GLSL snippet from one type to another (no-op if already matching).
func _promote(snippet: String, from_type: int, to_type: int) -> String:
	if from_type == to_type:
		return snippet
	match to_type:
		2:
			if from_type == 1: return "vec2(%s)" % snippet
		0:
			if from_type == 1: return "vec3(%s)" % snippet
			if from_type == 2: return "vec3(%s, 0.0)" % snippet
			if from_type == 3: return "(%s).rgb" % snippet
		3:
			if from_type == 1: return "vec4(%s)" % snippet
			if from_type == 2: return "vec4(%s, 0.0, 1.0)" % snippet
			if from_type == 0: return "vec4(%s, 1.0)" % snippet
	return snippet


# Narrow any type down to a vec3 for display in per-node previews.
func _to_vec3_display(snippet: String, type: int) -> String:
	match type:
		1: return "vec3(%s)" % snippet
		2: return "vec3(%s, 0.0)" % snippet
		3: return "(%s).rgb" % snippet
	return snippet



func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	_push_undo_state()
	_graph.disconnect_node(from_node, from_port, to_node, to_port)
	_update_all_polymorphic_ports()
	_request_compile()


# True when the mouse is over any node (body or its port dots). GraphEdit's gui_input
# fires for presses over nodes too — it manages node drag/connection centrally — so we
# must NOT pan there or we'd steal the press from node-dragging. The rect is grown to
# cover the port dots that overhang the node edge (the connection grab zone).
func _is_mouse_over_node() -> bool:
	var m := get_global_mouse_position()
	for child in _graph.get_children():
		if child is GraphNode and (child as GraphNode).get_global_rect().grow(12.0).has_point(m):
			return true
	return false


func _deselect_all_nodes() -> void:
	for child in _graph.get_children():
		if child is GraphNode:
			child.selected = false


func _shortcut_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var ctrl: bool = event.ctrl_pressed
	var shift: bool = event.shift_pressed
	if not ctrl:
		return
	# NB: Ctrl+C/V/D are NOT here — GraphEdit consumes them when focused, so they're wired
	# via its copy_nodes_request / paste_nodes_request / duplicate_nodes_request signals.
	match event.keycode:
		KEY_U:
			if not shift:
				emit_signal("reload_requested")
				accept_event()
		KEY_N:
			if not shift:
				_on_new_pressed()
				accept_event()
		KEY_S:
			if shift:
				_popup_save_dialog()
			else:
				_on_save_pressed()
				if not _linked_shader_path.is_empty():
					_do_update()
			accept_event()
		KEY_O:
			if not shift:
				_load_dialog.popup_centered_ratio(0.5)
				accept_event()


func _on_graph_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_spawn_position = event.position / _graph.zoom + _graph.scroll_offset
			_open_search_popup()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			# Plain left-drag on EMPTY canvas pans. Over a node (body or dots) we do nothing
			# so GraphEdit's own node-drag / connection-drag runs. Shift also defers (native
			# box-select). The whole pan lifecycle lives here: GraphEdit captures mouse focus
			# on the press, so the drag motion and release come back even over nodes.
			if event.pressed:
				if not event.shift_pressed and not _is_mouse_over_node():
					_panning = true
					_pan_moved = false
					accept_event()
			else:
				if _panning:
					_panning = false
					# A clean click on empty canvas (no drag) deselects all nodes — the
					# pan intercept means GraphEdit never gets to do this itself.
					if not _pan_moved:
						_deselect_all_nodes()
					accept_event()
	elif event is InputEventMouseMotion and _panning:
		_pan_moved = true
		_graph.scroll_offset -= event.relative / _graph.zoom
		accept_event()


# Bare graph shortcuts (A / R / X / ?). Handled here rather than in the graph's gui_input
# so they fire without first clicking to focus GraphEdit — _unhandled_key_input runs for
# any key the focused control didn't consume. Gated on the cursor being over the graph
# (so they don't fire while editing elsewhere) and Ctrl/Cmd-free (those belong to
# _shortcut_input). A focused field consumes its own keys, so typing is unaffected.
func _unhandled_key_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.ctrl_pressed or event.meta_pressed:
		return
	if _search_overlay and _search_overlay.visible:
		return
	if not _graph.get_global_rect().has_point(get_global_mouse_position()):
		return
	if event.keycode == KEY_SLASH and event.shift_pressed:
		_toggle_shortcuts_overlay()
		accept_event()
		return
	match event.keycode:
		KEY_X:
			var selected: Array[StringName] = []
			for child in _graph.get_children():
				if child is GraphNode and child.selected:
					selected.append(child.name)
			if not selected.is_empty():
				_on_delete_nodes_request(selected)
				accept_event()
		KEY_R:
			_push_undo_state()
			_spawn_position = _graph.get_local_mouse_position() / _graph.zoom + _graph.scroll_offset
			_add_node(RerouteNode.new(), _spawn_position, "Reroute")
			accept_event()
		KEY_A:
			_spawn_position = _graph.get_local_mouse_position() / _graph.zoom + _graph.scroll_offset
			_open_search_popup()
			accept_event()


func _toggle_shortcuts_overlay() -> void:
	_shortcuts_overlay.visible = not _shortcuts_overlay.visible
	if _shortcuts_overlay.visible:
		_shortcuts_overlay.move_to_front()
		_shortcuts_overlay.reset_size()
		var sz := _shortcuts_overlay.get_combined_minimum_size()
		_shortcuts_overlay.position = ((_graph_container.size - sz) * 0.5).max(Vector2.ZERO)


func _on_context_menu_selected(id: int) -> void:
	_push_undo_state()
	match id:
		0: _add_node(ColorNode.new(), _spawn_position, "Color")
		1: _add_node(AddNode.new(), _spawn_position, "Add")
		2: _add_node(MultiplyNode.new(), _spawn_position, "Multiply")
		3: _add_node(MixNode.new(), _spawn_position, "Mix")
		4: _add_node(UVNode.new(), _spawn_position, "UV")
		5: _add_node(FloatNode.new(), _spawn_position, "Float")
		6: _add_node(SubtractNode.new(), _spawn_position, "Subtract")
		7: _add_node(ClampNode.new(), _spawn_position, "Clamp")
		8: _add_node(PowerNode.new(), _spawn_position, "Power")
		9: _add_node(SinNode.new(), _spawn_position, "Sin")
		10: _add_node(CosNode.new(), _spawn_position, "Cos")
		11: _add_node(TimeNode.new(), _spawn_position, "Time")
		12: _add_node(SplitNode.new(), _spawn_position, "Split")
		13: _add_node(CombineNode.new(), _spawn_position, "Combine")
		14: _add_node(TextureSampleNode.new(), _spawn_position, "TextureSample")
		15: _add_node(FresnelNode.new(), _spawn_position, "Fresnel")
		16: _add_node(ScaleNode.new(), _spawn_position, "Scale")
		17: _add_node(StepNode.new(), _spawn_position, "Step")
		18: _add_node(SmoothstepNode.new(), _spawn_position, "Smoothstep")
		19: _add_node(NoiseNode.new(), _spawn_position, "Noise")
		36: _add_node(FBMNode.new(), _spawn_position, "FBM")
		37: _add_node(GradientNode.new(), _spawn_position, "Gradient")
		38: _add_node(CurveNode.new(), _spawn_position, "Curve")
		39: _add_node(TilingOffsetNode.new(), _spawn_position, "TilingOffset")
		40: _add_node(RotateUVNode.new(), _spawn_position, "RotateUV")
		41: _add_node(WarpNode.new(), _spawn_position, "Warp")
		42: _add_node(NormalFromHeightNode.new(), _spawn_position, "NormalFromHeight")
		43: _add_node(BlendNormalsNode.new(), _spawn_position, "BlendNormals")
		44: _add_node(ScreenUVNode.new(), _spawn_position, "ScreenUV")
		45: _add_node(ScreenTextureNode.new(), _spawn_position, "ScreenTexture")
		46: _add_node(DepthFadeNode.new(), _spawn_position, "DepthFade")
		20: _add_node(VertexNode.new(), _spawn_position, "Vertex")
		21: _add_node(NormalMapNode.new(), _spawn_position, "NormalMap")
		22: _add_node(AbsNode.new(), _spawn_position, "Abs")
		29: _add_node(CeilNode.new(), _spawn_position, "Ceil")
		30: _add_node(FloorNode.new(), _spawn_position, "Floor")
		31: _add_node(FractNode.new(), _spawn_position, "Fract")
		32: _add_node(NegateNode.new(), _spawn_position, "Negate")
		33: _add_node(OneMinusNode.new(), _spawn_position, "OneMinus")
		34: _add_node(RoundNode.new(), _spawn_position, "Round")
		35: _add_node(SqrtNode.new(), _spawn_position, "Sqrt")
		23: _add_node(MinMaxNode.new(), _spawn_position, "MinMax")
		24: _add_node(DivideNode.new(), _spawn_position, "Divide")
		25: _add_node(ModNode.new(), _spawn_position, "Mod")
		26: _add_node(NormalizeNode.new(), _spawn_position, "Normalize")
		27: _add_node(LengthNode.new(), _spawn_position, "Length")
		28: _add_node(DotNode.new(), _spawn_position, "Dot")
		52: _add_node(RerouteNode.new(), _spawn_position, "Reroute")
		53: _add_node(RelayNode.new(), _spawn_position, "Relay")
		54: _add_node(PreviewRelayNode.new(), _spawn_position, "PreviewRelay")
		47: _add_node(CustomGLSLNode.new(), _spawn_position, "CustomGLSL")
		48: _add_node(Vector3Node.new(), _spawn_position, "Vector3")
		49: _add_node(SpriteTextureNode.new(), _spawn_position, "SpriteTexture")
		50: _add_node(VertexColorNode.new(), _spawn_position, "VertexColor")
		51: _add_node(TexturePixelSizeNode.new(), _spawn_position, "PixelSize")
		55:
			if not _graph.get_node_or_null("ParticleStartNode"):
				_add_node(ParticleStartNode.new(), _spawn_position, "ParticleStartNode")
				_update_sink_visibility()
		56:
			if not _graph.get_node_or_null("ParticleProcessNode"):
				_add_node(ParticleProcessNode.new(), _spawn_position, "ParticleProcessNode")
				_update_sink_visibility()
		57: _add_node(ParticleAgeNode.new(), _spawn_position, "ParticleAge")
		58: _add_node(ParticleVelocityNode.new(), _spawn_position, "ParticleVelocity")
		59: _add_node(ParticlePositionNode.new(), _spawn_position, "ParticlePosition")
		60: _add_node(ParticleDeltaNode.new(), _spawn_position, "ParticleDelta")
		61: _add_node(ParticleRandomNode.new(), _spawn_position, "ParticleRandom")
		62: _add_node(ParticleIndexNode.new(), _spawn_position, "ParticleIndex")


func _build_graph_toolbar() -> HBoxContainer:
	var toolbar := HBoxContainer.new()

	var new_btn := Button.new()
	new_btn.text = "New"
	new_btn.pressed.connect(_on_new_pressed)
	toolbar.add_child(new_btn)

	var save_btn := Button.new()
	save_btn.text = "Save"
	save_btn.pressed.connect(_on_save_pressed)
	toolbar.add_child(save_btn)
	_save_btn = save_btn

	var load_btn := Button.new()
	load_btn.text = "Load"
	load_btn.pressed.connect(func(): _load_dialog.popup_centered_ratio(0.5))
	toolbar.add_child(load_btn)

	var sep := VSeparator.new()
	toolbar.add_child(sep)

	var undo_btn := Button.new()
	undo_btn.text = "Undo"
	undo_btn.pressed.connect(_undo)
	toolbar.add_child(undo_btn)

	var redo_btn := Button.new()
	redo_btn.text = "Redo"
	redo_btn.pressed.connect(_redo)
	toolbar.add_child(redo_btn)

	var sep2 := VSeparator.new()
	toolbar.add_child(sep2)

	_type_btn = OptionButton.new()
	_type_btn.add_item("Spatial")
	_type_btn.add_item("Canvas Item")
	_type_btn.add_item("Particles")
	_type_btn.item_selected.connect(_on_shader_type_changed)
	toolbar.add_child(_type_btn)

	return toolbar


func _get_node_type(node: Node) -> String:
	for type_name in NODE_CLASSES:
		if node.get_script() == NODE_CLASSES[type_name]:
			return type_name
	return ""


func _serialize_graph() -> Dictionary:
	var nodes := []
	for child in _graph.get_children():
		if not child is GraphNode:
			continue
		var type := _get_node_type(child)
		if type == "":
			continue
		nodes.append({
			"type": type,
			"name": str(child.name),
			"position": [child.position_offset.x, child.position_offset.y],
			"state": child.get_state(),
		})

	var connections := []
	for conn in _graph.get_connection_list():
		connections.append({
			"from_node": str(conn["from_node"]),
			"from_port": conn["from_port"],
			"to_node": str(conn["to_node"]),
			"to_port": conn["to_port"],
		})

	return {
		"nodes": nodes,
		"connections": connections,
		"shader_type": _shader_type,
		"linked_shader_path": _linked_shader_path,
	}


func _clear_graph_nodes() -> void:
	_graph.clear_connections()
	var to_remove: Array[Node] = []
	for child in _graph.get_children():
		if child is GraphNode:
			to_remove.append(child)
	for child in to_remove:
		_graph.remove_child(child)
		child.free()


func _deserialize_graph(data: Dictionary) -> void:
	# Reconstruction (and undo/redo) must not mark the graph dirty; the caller
	# decides cleanliness (load/new = clean, undo = leaves dirty unchanged).
	_loading = true
	_clear_graph_nodes()

	var saved_type: int = data.get("shader_type", 0)
	_shader_type = saved_type
	_type_btn.selected = saved_type
	# Restore the artifact link. Lazy: store the path only; the Shader resource is
	# re-resolved (ResourceLoader.load) on first Update / live-link use, not now.
	_linked_shader_path = data.get("linked_shader_path", "")
	_update_link_ui()
	# OutputNode restores its own slot config via set_state (which calls
	# set_shader_type); sink visibility is updated after recreation below.

	var name_map := {}
	for node_data in data.get("nodes", []):
		var type: String = node_data["type"]
		if not NODE_CLASSES.has(type):
			push_warning("Nyx: unknown node type '%s', skipping" % type)
			continue
		var node = NODE_CLASSES[type].new()
		var pos: Array = node_data["position"]
		var saved_name: String = node_data["name"]
		var target_name := saved_name if not saved_name.begins_with("@") else type.trim_suffix("Node")
		_add_node(node, Vector2(pos[0], pos[1]), target_name)
		name_map[saved_name] = str(node.name)
		var state: Dictionary = node_data.get("state", {})
		if not state.is_empty():
			node.set_state(state)

	for conn in data.get("connections", []):
		var from: String = name_map.get(conn["from_node"], conn["from_node"])
		var to: String = name_map.get(conn["to_node"], conn["to_node"])
		_graph.connect_node(from, conn["from_port"], to, conn["to_port"])

	if _shader_type == 2:
		_ensure_particle_sinks()
	_update_sink_visibility()
	_request_compile()
	_loading = false


func _on_new_pressed() -> void:
	# Skip the confirm when there's nothing to lose.
	if _dirty:
		_new_confirm.popup_centered()
	else:
		_new_graph()


# Force a 3-button confirm to read [OK | mid_btn | Cancel], right-aligned: move
# each to the end of the button row in turn (any leading spacer stays put, so
# alignment is preserved). OK is the safe "Save & …" action.
func _order_dialog_buttons(dialog: AcceptDialog, mid_btn: Button) -> void:
	var ok: Button = dialog.get_ok_button()
	var cancel: Button = dialog.get_cancel_button()
	var row := ok.get_parent()
	row.move_child(ok, row.get_child_count() - 1)
	row.move_child(mid_btn, row.get_child_count() - 1)
	row.move_child(cancel, row.get_child_count() - 1)


# Reset to a fresh editor state (mirrors the initial _ready setup): empty graph,
# default starting nodes, spatial mode, unlinked, no working-file path.
func _new_graph() -> void:
	_loading = true
	_clear_graph_nodes()
	_shader_type = 0
	_type_btn.selected = 0
	_current_nyx_path = ""
	_set_linked("")
	_last_shader_code = ""
	_undo_stack.clear()
	_redo_stack.clear()
	_add_node(OutputNode.new(), Vector2(400, 200), "OutputNode")
	_add_node(ColorNode.new(), Vector2(150, 200), "Color")
	_update_sink_visibility()
	_request_compile()
	_loading = false
	_set_clean()  # fresh editor = nothing unsaved


# Direct save to the current file; only pops the dialog for a never-saved graph.
# (Save As / fork-to-new-file arrives with the File menu.)
func _on_save_pressed() -> void:
	if _current_nyx_path.is_empty():
		_popup_save_dialog()
	elif _write_nyx_file(_current_nyx_path):
		_set_clean()
		print("Nyx: saved graph → %s" % _current_nyx_path)


func _popup_save_dialog() -> void:
	# Co-locate: default the .nyx next to its linked artifact when there is one.
	if _current_nyx_path.is_empty() and not _linked_shader_path.is_empty():
		_save_dialog.current_dir = _linked_shader_path.get_base_dir()
	_save_dialog.popup_centered_ratio(0.5)


# Save the current graph, then run `after` once the save succeeds. If there's no
# path yet, open the save dialog first and continue once the user picks one.
func _save_then(after: Callable) -> void:
	if _current_nyx_path.is_empty():
		_pending_after_save = after
		_popup_save_dialog()
	elif _write_nyx_file(_current_nyx_path):
		_set_clean()
		after.call()


func _on_save_file_selected(path: String) -> void:
	if not path.ends_with(".nyx"):
		path += ".nyx"
	_current_nyx_path = path
	if _write_nyx_file(path):
		_set_clean()
		print("Nyx: saved graph → %s" % path)
		# Continue a pending "Save & New / Load" once the save succeeded.
		if _pending_after_save.is_valid():
			var after := _pending_after_save
			_pending_after_save = Callable()
			after.call()


# Writes the graph to disk as a native NyxGraph resource (`.nyx`). Returns success.
func _write_nyx_file(path: String) -> bool:
	var graph := _dict_to_resource(_serialize_graph())
	var err := ResourceSaver.save(graph, path)
	if err != OK:
		push_error("Nyx: could not write graph to %s (err %d)" % [path, err])
		return false
	if path.begins_with("res://"):
		EditorInterface.get_resource_filesystem().update_file(path)
	return true


# --- NyxGraph resource <-> serialize-dict translation ---
# Save/load go through the resource; undo/redo keep using the dict directly. The
# dict is the single source of truth; these just wrap/unwrap it.

func _dict_to_resource(d: Dictionary) -> NyxGraphRes:
	var graph := NyxGraphRes.new()
	graph.shader_type = d.get("shader_type", 0)
	graph.linked_shader_path = d.get("linked_shader_path", "")
	for nd in d.get("nodes", []):
		var data := NyxNodeDataRes.new()
		data.type = nd.get("type", "")
		data.node_name = nd.get("name", "")
		var pos: Array = nd.get("position", [0.0, 0.0])
		data.position = Vector2(pos[0], pos[1])
		data.state = nd.get("state", {})
		graph.nodes.append(data)
	graph.connections = d.get("connections", [])
	return graph


func _resource_to_dict(graph: NyxGraphRes) -> Dictionary:
	var nodes := []
	for data in graph.nodes:
		nodes.append({
			"type": data.type,
			"name": data.node_name,
			"position": [data.position.x, data.position.y],
			"state": data.state,
		})
	return {
		"nodes": nodes,
		"connections": graph.connections,
		"shader_type": graph.shader_type,
		"linked_shader_path": graph.linked_shader_path,
	}


# Public, guarded entry point: the Load dialog, "Open in Nyx" navigation, and
# double-click-to-open all route here. Confirms before discarding unsaved work.
func load_nyx(path: String) -> void:
	if _dirty:
		_pending_load_path = path
		_load_confirm.popup_centered()
	else:
		_do_load(path)


func _do_load(path: String) -> void:
	var graph = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if graph == null or not graph is NyxGraphRes:
		push_error("Nyx: could not read graph from %s" % path)
		return
	_current_nyx_path = path
	_deserialize_graph(_resource_to_dict(graph))
	_set_clean()  # freshly loaded from disk
	# A loaded linked graph goes live by default (same as just-linked).
	if not _linked_shader_path.is_empty():
		_live_btn.button_pressed = true
	print("Nyx: loaded graph ← %s" % path)


# --- Node search popup ---

func _build_search_popup() -> void:
	# Rendered as plain Control overlays in the main viewport (NOT a popup window) so the
	# live graph shows through everywhere the cards don't draw — the gap between the search
	# and doc cards is genuinely the graph below. An embedded popup window can't do this
	# (no per-pixel transparency → opaque gap).
	#
	# Structure: an IGNORE overlay container holding [backdrop, cards]. The backdrop is a
	# full-rect STOP control (child 0) whose only job is to dismiss on a press in the empty
	# surround. The cards (child 1) render on top, so a click on the search list reaches the
	# list first and the backdrop only catches clicks that miss the cards. There is no global
	# _input handler — panning lives entirely in the graph's gui_input.
	_search_overlay = Control.new()
	_search_overlay.visible = false
	_search_overlay.position = Vector2.ZERO
	_search_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var backdrop := Control.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			_close_search())
	_search_overlay.add_child(backdrop)

	# HBox: [search card | doc card (hidden until hover)]. No background — the gap and
	# surround show the graph through.
	var hbox := HBoxContainer.new()
	_search_cards = hbox
	hbox.add_theme_constant_override("separation", 10)

	# --- Search card ---
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.14, 0.14, 0.18)
	card_style.border_color = Color(0.28, 0.28, 0.38)
	card_style.set_border_width_all(1)
	card_style.set_corner_radius_all(8)
	card_style.set_content_margin_all(8)

	var search_card := PanelContainer.new()
	search_card.custom_minimum_size = Vector2(260, 360)
	search_card.add_theme_stylebox_override("panel", card_style)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)

	_search_input = LineEdit.new()
	_search_input.placeholder_text = "Search nodes..."

	var input_normal := StyleBoxFlat.new()
	input_normal.bg_color = Color(0.20, 0.20, 0.26)
	input_normal.border_color = Color(0.35, 0.35, 0.45)
	input_normal.set_border_width_all(1)
	input_normal.set_corner_radius_all(4)
	input_normal.content_margin_left = 8
	input_normal.content_margin_right = 8
	input_normal.content_margin_top = 5
	input_normal.content_margin_bottom = 5

	var input_focus := StyleBoxFlat.new()
	input_focus.bg_color = Color(0.20, 0.20, 0.26)
	input_focus.border_color = Color(0.15, 0.61, 0.36)
	input_focus.set_border_width_all(1)
	input_focus.set_corner_radius_all(4)
	input_focus.content_margin_left = 8
	input_focus.content_margin_right = 8
	input_focus.content_margin_top = 5
	input_focus.content_margin_bottom = 5

	_search_input.add_theme_stylebox_override("normal", input_normal)
	_search_input.add_theme_stylebox_override("focus", input_focus)
	_search_input.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	_search_input.add_theme_color_override("font_placeholder_color", Color(0.45, 0.45, 0.52))
	_search_input.text_changed.connect(_on_search_changed)
	_search_input.gui_input.connect(_on_search_input_key)
	vbox.add_child(_search_input)

	_search_list = ItemList.new()
	_search_list.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var list_bg := StyleBoxFlat.new()
	list_bg.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	list_bg.set_border_width_all(0)
	_search_list.add_theme_stylebox_override("panel", list_bg)

	# Hovering an item auto-selects it (see _on_search_list_hover), so the visible
	# style for a hovered row is actually "hovered_selected" — all selection/hover
	# states must be overridden to Hunter green or the editor's muddy default bleeds
	# through. One shared green stylebox covers every highlighted state.
	var highlight := StyleBoxFlat.new()
	highlight.bg_color = Color("#31614F")
	highlight.set_corner_radius_all(3)
	highlight.content_margin_left = 4
	highlight.content_margin_right = 4
	for state in ["selected", "selected_focus", "hovered", "hovered_selected", "hovered_selected_focus"]:
		_search_list.add_theme_stylebox_override(state, highlight)

	_search_list.add_theme_color_override("font_color", Color(0.90, 0.90, 0.90))
	_search_list.add_theme_color_override("font_selected_color", Color.WHITE)
	_search_list.add_theme_color_override("font_hovered_color", Color.WHITE)
	_search_list.add_theme_color_override("font_disabled_color", Color(0.45, 0.45, 0.55))

	_search_list.item_selected.connect(_on_search_item_selected_by_mouse)
	_search_list.gui_input.connect(_on_search_list_hover)
	vbox.add_child(_search_list)

	search_card.add_child(vbox)
	hbox.add_child(search_card)

	# Doc panel — plain PanelContainer, not a Popup. Sits beside the search list in
	# the same window so it never participates in the popup stack and never eats clicks.
	_doc_panel = PanelContainer.new()
	_doc_panel.custom_minimum_size = Vector2(260, 0)
	_doc_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_doc_panel.visible = false
	_doc_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var doc_panel_style := StyleBoxFlat.new()
	doc_panel_style.bg_color = Color(0.14, 0.14, 0.18)
	doc_panel_style.border_color = Color(0.28, 0.28, 0.38)
	doc_panel_style.set_border_width_all(1)
	doc_panel_style.set_corner_radius_all(8)
	_doc_panel.add_theme_stylebox_override("panel", doc_panel_style)

	var doc_margin := MarginContainer.new()
	doc_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	doc_margin.add_theme_constant_override("margin_left", 12)
	doc_margin.add_theme_constant_override("margin_right", 10)
	doc_margin.add_theme_constant_override("margin_top", 10)
	doc_margin.add_theme_constant_override("margin_bottom", 10)

	_doc_label = RichTextLabel.new()
	_doc_label.bbcode_enabled = true
	_doc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_doc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_doc_label.scroll_active = true
	_doc_label.add_theme_color_override("default_color", Color(0.88, 0.88, 0.92))

	var doc_bg := StyleBoxFlat.new()
	doc_bg.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	doc_bg.set_border_width_all(0)
	_doc_label.add_theme_stylebox_override("normal", doc_bg)

	doc_margin.add_child(_doc_label)
	_doc_panel.add_child(doc_margin)
	hbox.add_child(_doc_panel)

	_search_overlay.add_child(hbox)
	add_child(_search_overlay)

	_doc_hover_timer = Timer.new()
	_doc_hover_timer.one_shot = true
	_doc_hover_timer.wait_time = 0.4
	_doc_hover_timer.timeout.connect(_on_doc_hover_timeout)
	add_child(_doc_hover_timer)


func _open_search_popup() -> void:
	_search_input.text = ""
	_populate_search_grouped()
	_doc_label.clear()
	_doc_panel.hide()
	# Cover the whole graph area so the catcher can dismiss on any outside click.
	_search_overlay.size = _graph_container.size
	_search_overlay.visible = true
	_search_overlay.move_to_front()
	_search_cards.reset_size()
	# Anchor the cards at the cursor, clamped so they stay on-screen.
	var local_mouse := _graph_container.get_local_mouse_position()
	var max_pos := _graph_container.size - _search_cards.size
	_search_cards.position = local_mouse.clamp(Vector2.ZERO, max_pos.max(Vector2.ZERO))
	_search_input.call_deferred("grab_focus")


func _close_search() -> void:
	_search_overlay.visible = false
	_doc_panel.hide()
	_doc_hover_timer.stop()


func _is_node_unavailable(entry: Dictionary) -> bool:
	if _shader_type == 2:
		# Particle mode: only particle nodes plus nodes that operate on plain
		# values. Anything fragment/UV/screen/canvas-bound is meaningless here.
		if entry.get("particle_only", false):
			return false
		return entry.get("particle_unsafe", false) \
			or entry.get("spatial_only", false) \
			or entry.get("canvas_only", false)
	# Spatial / canvas modes: particle nodes are never available.
	if entry.get("particle_only", false):
		return true
	return (entry.get("spatial_only", false) and _shader_type == 1) or \
		   (entry.get("canvas_only", false) and _shader_type == 0)


func _populate_search_grouped() -> void:
	_search_list.clear()
	_search_item_ids.clear()
	for category in _NODE_REGISTRY:
		var header_idx: int = _search_list.add_item(category["category"])
		_search_list.set_item_disabled(header_idx, true)
		_search_item_ids.append(-1)
		for entry in category["nodes"]:
			var item_idx := _search_list.add_item("  " + entry["label"])
			_search_item_ids.append(entry["id"])
			if _is_node_unavailable(entry):
				_search_list.set_item_disabled(item_idx, true)
				_search_list.set_item_custom_fg_color(item_idx, Color(1, 1, 1, 0.25))


func _populate_search_filtered(query: String) -> void:
	_search_list.clear()
	_search_item_ids.clear()
	for category in _NODE_REGISTRY:
		var category_matches := _fuzzy_match(query, category["category"])
		for entry in category["nodes"]:
			if category_matches or _fuzzy_match(query, entry["label"]):
				var item_idx := _search_list.add_item(entry["label"])
				_search_item_ids.append(entry["id"])
				if _is_node_unavailable(entry):
					_search_list.set_item_disabled(item_idx, true)
					_search_list.set_item_custom_fg_color(item_idx, Color(1, 1, 1, 0.25))
	if _search_list.item_count > 0:
		_search_list.select(0)


func _fuzzy_match(query: String, candidate: String) -> bool:
	query = query.to_lower()
	candidate = candidate.to_lower()
	var qi := 0
	for c in candidate:
		if qi < query.length() and c == query[qi]:
			qi += 1
	return qi == query.length()


func _move_search_selection(delta: int) -> void:
	var count := _search_list.item_count
	if count == 0:
		return
	var sel := _search_list.get_selected_items()
	var idx: int = sel[0] + delta if not sel.is_empty() else (0 if delta > 0 else count - 1)
	while idx >= 0 and idx < count and _search_list.is_item_disabled(idx):
		idx += delta
	if idx < 0 or idx >= count:
		return
	_search_list.select(idx)
	_search_list.ensure_current_is_visible()
	_show_doc_for(_search_item_ids[idx])


func _confirm_search_selection() -> void:
	var sel := _search_list.get_selected_items()
	if sel.is_empty():
		return
	var id: int = _search_item_ids[sel[0]]
	if id < 0:
		return
	_close_search()
	_push_undo_state()
	_on_context_menu_selected(id)


func _on_search_changed(text: String) -> void:
	if text.is_empty():
		_populate_search_grouped()
	else:
		_populate_search_filtered(text)


func _on_search_input_key(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	match event.keycode:
		KEY_DOWN:
			_move_search_selection(1)
			_search_input.accept_event()
		KEY_UP:
			_move_search_selection(-1)
			_search_input.accept_event()
		KEY_ENTER, KEY_KP_ENTER, KEY_RIGHT:
			_confirm_search_selection()
			_search_input.accept_event()
		KEY_ESCAPE:
			_close_search()
			_search_input.accept_event()


func _on_search_item_selected_by_mouse(index: int) -> void:
	_show_doc_for(_search_item_ids[index])


func _on_search_list_hover(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var idx := _search_list.get_item_at_position(event.position, true)
		if idx >= 0 and not _search_list.is_item_disabled(idx):
			_search_list.select(idx)
			_show_doc_for(_search_item_ids[idx])
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var idx := _search_list.get_item_at_position(event.position, true)
		if idx >= 0 and not _search_list.is_item_disabled(idx):
			var id: int = _search_item_ids[idx]
			if id >= 0:
				_close_search()
				_push_undo_state()
				_on_context_menu_selected(id)
				get_viewport().set_input_as_handled()


func _show_doc_for(id: int) -> void:
	if _doc_panel.visible:
		_update_doc_panel(id)
	else:
		_doc_pending_id = id
		_doc_hover_timer.start()


func _on_doc_hover_timeout() -> void:
	_update_doc_panel(_doc_pending_id)


func _estimate_doc_height(entry: Dictionary) -> int:
	var h := 38
	if entry.has("description"):
		h += maxi(44, int((entry["description"] as String).length() / 38.0) * 18)
	if entry.has("ports"):
		h += 20 + (entry["ports"] as Array).size() * 18
	if entry.has("uses"):
		h += 20 + (entry["uses"] as Array).size() * 18
	return clampi(h + 10, 50, 480)


func _get_node_entry(id: int) -> Dictionary:
	for category in _NODE_REGISTRY:
		for entry in category["nodes"]:
			if entry["id"] == id:
				return entry
	return {}


func _update_doc_panel(id: int) -> void:
	_doc_label.clear()
	if id < 0:
		if _doc_panel.visible:
			_doc_panel.hide()
			_search_cards.reset_size()
		return
	var entry := _get_node_entry(id)
	if entry.is_empty():
		if _doc_panel.visible:
			_doc_panel.hide()
			_search_cards.reset_size()
		return

	_doc_label.append_text("[b]" + entry["label"] + "[/b]\n")
	if entry.has("summary"):
		_doc_label.append_text("[color=#8888bb]" + entry["summary"] + "[/color]\n")
	if entry.has("description"):
		_doc_label.append_text("\n" + entry["description"] + "\n")
	if entry.has("ports") and not (entry["ports"] as Array).is_empty():
		_doc_label.append_text("\n[b]Ports[/b]\n")
		for port in entry["ports"]:
			_doc_label.append_text("  • " + port + "\n")
	if entry.has("uses") and not (entry["uses"] as Array).is_empty():
		_doc_label.append_text("\n[b]Good for[/b]\n")
		for use in entry["uses"]:
			_doc_label.append_text("  • " + use + "\n")

	if not _doc_panel.visible:
		_doc_panel.show()
		_search_cards.reset_size()
		# Keep the widened cards on-screen (doc opens to the right).
		var max_x := _graph_container.size.x - _search_cards.size.x
		_search_cards.position.x = minf(_search_cards.position.x, maxf(max_x, 0.0))
	_search_input.grab_focus()
