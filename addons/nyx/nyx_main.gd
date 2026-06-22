@tool
extends Control

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
const LengthNode = preload("res://addons/nyx/nodes/length_node.gd")
const DotNode = preload("res://addons/nyx/nodes/dot_node.gd")

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
		{"label": "UV", "id": 4,
			"summary": "The mesh's texture coordinates.",
			"description": "Outputs the UV coordinates of the current fragment as a vec3 (Z is always 0). UV runs from (0,0) at one corner to (1,1) at the opposite corner.",
			"ports": ["Out (vec3) — UV.x, UV.y, 0.0"],
			"uses": ["Input for textures and noise", "Coordinate-based effects", "Tiling operations"]},
		{"label": "Vertex", "id": 20,
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
		{"label": "Texture Sample", "id": 14,
			"summary": "Samples a colour from a 2D texture at UV coordinates.",
			"description": "The texture is exported as a shader uniform, so it's baked into the material. Connect a UV or Tiling & Offset node to control mapping.",
			"ports": ["UV (vec3) — texture coordinates", "Out (vec3) — sampled RGB colour"],
			"uses": ["Painted textures", "Photo albedo", "Using a texture as a mask or detail layer"]},
		{"label": "Normal Map", "id": 21,
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
		{"label": "Normal from Height", "id": 42,
			"summary": "Converts a greyscale height field into a normal map using screen-space derivatives.",
			"description": "Uses dFdx/dFdy to compute the surface gradient of the height input and outputs a tangent-space normal. Connects directly to the Output node's Normal slot. Strength controls how pronounced the bumps appear.",
			"ports": ["Height (float) — the height field (e.g. FBM output)", "Strength (float) — bump intensity", "Normal (vec3) — tangent-space normal for Output Normal slot"],
			"uses": ["Procedural water normals from FBM", "Bump mapping without a texture", "Converting any noise to surface detail"]},
		{"label": "Blend Normals", "id": 43,
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
		{"label": "Fresnel", "id": 15,
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
		{"label": "Screen UV", "id": 44,
			"summary": "The current fragment's position in screen space (0-1).",
			"description": "Outputs the UV coordinates of the current pixel on screen. Use as input to Screen Texture for basic sampling, or offset it with a normal map for refraction effects.",
			"ports": ["Screen UV (vec3) — screen-space UV, XY in 0-1 range"],
			"uses": ["Input to Screen Texture for refraction", "Warping with a normal for underwater distortion"]},
		{"label": "Screen Texture", "id": 45,
			"summary": "Samples the rendered scene behind the current surface.",
			"description": "Reads the colour of what's been rendered behind this transparent surface. Offset the UV input with a water normal to create convincing refraction. Requires the material's render mode to be Mix, Add, or Premult Alpha.",
			"ports": ["UV (vec3) — screen UV to sample (offset for refraction)", "Color (vec3) — the scene colour at that UV"],
			"uses": ["Water refraction", "Glass distortion", "Heat haze", "Any transparent surface that should show a distorted view of what's behind it"]},
		{"label": "Depth Fade", "id": 46,
			"summary": "Returns 0 at surface intersections and 1 in deep water.",
			"description": "Compares the depth buffer against the current surface depth. Where scene geometry is close to the surface (shallow water, shorelines), the output is near 0. Where the water is deep, it approaches 1. Requires a transparent render mode.",
			"ports": ["Distance (float) — the depth range over which the fade occurs", "Out (float) — 0 at edges/intersections, 1 in deep areas"],
			"uses": ["Shoreline foam (1 - DepthFade drives foam mask)", "Soft transparency at water edges", "Depth-based colour (shallow vs deep)", "Soft particles that don't clip geometry"]},
	]},
	{"category": "UV", "nodes": [
		{"label": "Tiling & Offset", "id": 39,
			"summary": "Tiles and scrolls UV coordinates.",
			"description": "Multiplies UV by a tiling factor (zoom) and adds an offset (scroll). Connect Time to Offset X or Y to animate scrolling. Use two of these at different speeds for layered water or cloud effects.",
			"ports": ["UV (vec3) — coordinate input", "Tiling X (float) — horizontal tile count", "Tiling Y (float) — vertical tile count", "Offset X (float) — horizontal scroll", "Offset Y (float) — vertical scroll", "Out (vec3) — transformed UV"],
			"uses": ["Scrolling normal maps for water", "Tiling a texture at a different scale", "Animated UV for fire or clouds", "Offsetting two layers at different speeds"]},
		{"label": "Rotate UV", "id": 40,
			"summary": "Rotates UV coordinates around the centre.",
			"description": "Rotates the UV around the point (0.5, 0.5). Angle is in radians. Connect Time to Angle for a continuously spinning effect, or use a small fixed angle to make two texture layers feel independent.",
			"ports": ["UV (vec3) — coordinate input", "Angle (float) — rotation in radians", "Out (vec3) — rotated UV"],
			"uses": ["Spinning effects", "Making two water normal layers feel independent", "Slow UV rotation for lava or energy fields"]},
		{"label": "Warp", "id": 41,
			"summary": "Distorts UV coordinates using an offset input.",
			"description": "Shifts UV by the XY of an Offset vector, scaled by Strength. Feed noise or FBM into Offset to get organic, fluid-looking distortion. The key node for making water feel alive rather than just sliding.",
			"ports": ["UV (vec3) — coordinate input", "Offset (vec3) — distortion direction, uses XY", "Strength (float) — distortion amount", "Out (vec3) — distorted UV"],
			"uses": ["Water surface distortion", "Heat haze", "Warping a texture with noise", "Organic UV deformation"]},
	]},
	{"category": "Noise", "nodes": [
		{"label": "Noise", "id": 19,
			"summary": "Procedural noise — organic, hash-based variation across a surface.",
			"description": "Three types via dropdown: Value (smooth, slightly blocky), Gradient (classic Perlin-style, most organic), Voronoi (cell-based, crystalline or cracked). Scale controls feature size — higher values mean smaller, denser features.",
			"ports": ["UV (vec3) — coordinate input (use Vertex for seamless noise on spheres)", "Scale (float) — feature size", "Out (float)"],
			"uses": ["Organic textures", "Dissolve masks", "Cloud-like patterns", "Randomising roughness or emission"]},
		{"label": "FBM", "id": 36,
			"summary": "Fractal Brownian Motion — noise layered at multiple scales for natural, rich detail.",
			"description": "Stacks multiple octaves of gradient noise, each at higher frequency and lower amplitude. The result looks like natural phenomena — clouds, terrain, smoke, fire. Octaves adds detail layers. Lacunarity controls frequency growth per octave (default 2.0). Gain controls how fast amplitude fades (default 0.5).",
			"ports": ["UV (vec3) — coordinate input (use Vertex for seamless results on spheres)", "Scale (float) — base feature size", "Out (float)"],
			"uses": ["Clouds and smoke", "Fire and lava", "Organic terrain", "Any effect needing natural multi-scale variation"]},
	]},
	{"category": "Advanced", "nodes": [
		{"label": "Custom Function", "id": 47,
			"summary": "Write raw GLSL directly as a node in the graph.",
			"description": "The function body you write receives up to 4 vec3 inputs named in0–in3 and must return a vec3. Use this when the graph can't express what you need — complex math, custom sampling, or anything that would take dozens of nodes to wire up.",
			"ports": ["in0–in3 (vec3) — connected inputs", "Out (vec3) — return value of your function"],
			"uses": ["Complex custom math", "Escape hatch for unsupported operations", "Porting existing GLSL snippets into the graph"]},
	]},
]

const _TYPE_COLORS := {
	# Inputs — coral
	"FloatNode":    Color("#CC5B4F"),
	"Vector3Node":  Color("#CC5B4F"),
	"UVNode":       Color("#CC5B4F"),
	"VertexNode":   Color("#CC5B4F"),
	"TimeNode":     Color("#CC5B4F"),
	# Screen — coral
	"ScreenUVNode":      Color("#CC5B4F"),
	"ScreenTextureNode": Color("#CC5B4F"),
	"DepthFadeNode":     Color("#CC5B4F"),
	# Math — green
	"AddNode":      Color("#269B5B"),
	"SubtractNode": Color("#269B5B"),
	"MultiplyNode": Color("#269B5B"),
	"DivideNode":   Color("#269B5B"),
	"MixNode":      Color("#269B5B"),
	"ClampNode":    Color("#269B5B"),
	"PowerNode":    Color("#269B5B"),
	"MinMaxNode":   Color("#269B5B"),
	"ModNode":      Color("#269B5B"),
	"AbsNode":      Color("#269B5B"),
	"CeilNode":     Color("#269B5B"),
	"FloorNode":    Color("#269B5B"),
	"FractNode":    Color("#269B5B"),
	"NegateNode":   Color("#269B5B"),
	"OneMinusNode": Color("#269B5B"),
	"RoundNode":    Color("#269B5B"),
	"SqrtNode":     Color("#269B5B"),
	"SinNode":      Color("#269B5B"),
	"CosNode":      Color("#269B5B"),
	# Shape — green (mathematical value ops)
	"FresnelNode":    Color("#269B5B"),
	"StepNode":       Color("#269B5B"),
	"SmoothstepNode": Color("#269B5B"),
	# Advanced — green
	"CustomGLSLNode": Color("#269B5B"),
	# Vector — blue
	"NormalizeNode":       Color("#3B82F6"),
	"LengthNode":          Color("#3B82F6"),
	"DotNode":             Color("#3B82F6"),
	"SplitNode":           Color("#3B82F6"),
	"CombineNode":         Color("#3B82F6"),
	"NormalFromHeightNode": Color("#3B82F6"),
	"BlendNormalsNode":    Color("#3B82F6"),
	"ScaleNode":           Color("#3B82F6"),
	# Texture — yellow
	"TextureSampleNode": Color("#E79D13"),
	"NormalMapNode":     Color("#E79D13"),
	"GradientNode":      Color("#E79D13"),
	"CurveNode":         Color("#E79D13"),
	# UV — yellow
	"TilingOffsetNode": Color("#E79D13"),
	"RotateUVNode":     Color("#E79D13"),
	"WarpNode":         Color("#E79D13"),
	# Noise/Procedural — yellow
	"NoiseNode": Color("#E79D13"),
	"FBMNode":   Color("#E79D13"),
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
	"CustomGLSLNode": CustomGLSLNode,
	"Vector3Node": Vector3Node,
}

var _graph_container: VBoxContainer
var _graph: GraphEdit
var _preview_panel: Panel
var _preview_dragging: bool = false
var _preview_resizing: bool = false
var _preview_positioned: bool = false
var _viewport: SubViewport
var _preview_mesh: MeshInstance3D
var _preview_camera: Camera3D
var _preview_mesh_buttons: Array[Button] = []
var _shader_material: ShaderMaterial
var _compile_timer: Timer
var _search_popup: PopupPanel
var _search_input: LineEdit
var _search_list: ItemList
var _search_item_ids: Array = []
var _doc_popup: PopupPanel
var _doc_label: RichTextLabel
var _doc_hover_timer: Timer
var _doc_pending_id: int = -1
var _export_dialog: EditorFileDialog
var _save_dialog: EditorFileDialog
var _load_dialog: EditorFileDialog
var _texture_dialog: EditorFileDialog
var _texture_target: Node = null
var _spawn_position: Vector2
var _last_shader_code: String
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
	var graph_bg := StyleBoxFlat.new()
	graph_bg.bg_color = Color("#0C1018")
	_graph.add_theme_stylebox_override("panel", graph_bg)
	_graph.add_theme_color_override("grid_minor", Color(1, 1, 1, 0.07))
	_graph.add_theme_color_override("grid_major", Color(1, 1, 1, 0.12))
	_graph.right_disconnects = true
	_graph.connection_request.connect(_on_connection_request)
	_graph.disconnection_request.connect(_on_disconnection_request)
	_graph.delete_nodes_request.connect(_on_delete_nodes_request)
	_graph.gui_input.connect(_on_graph_gui_input)
	_graph.add_valid_connection_type(0, 0)
	_graph.add_valid_connection_type(1, 1)
	_graph.add_valid_connection_type(1, 0)

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
	add_child(_save_dialog)

	_load_dialog = EditorFileDialog.new()
	_load_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	_load_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_load_dialog.add_filter("*.nyx", "Nyx Graph")
	_load_dialog.file_selected.connect(_on_load_file_selected)
	add_child(_load_dialog)

	_texture_dialog = EditorFileDialog.new()
	_texture_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	_texture_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_texture_dialog.add_filter("*.png,*.jpg,*.jpeg,*.bmp,*.webp,*.tga,*.exr,*.hdr", "Image Files")
	_texture_dialog.file_selected.connect(_on_texture_file_selected)
	add_child(_texture_dialog)

	_preview_panel = _build_preview_panel()
	add_child(_preview_panel)

	_add_node(OutputNode.new(), Vector2(400, 200), "OutputNode")
	_add_node(ColorNode.new(), Vector2(150, 200))


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

	var export_btn := Button.new()
	export_btn.text = "Export"
	export_btn.pressed.connect(func(): _export_dialog.popup_centered_ratio(0.5))
	header.add_child(export_btn)

	var toggle := Button.new()
	toggle.text = "×"
	toggle.pressed.connect(_toggle_preview)
	header.add_child(toggle)

	var mesh_row := HBoxContainer.new()
	mesh_row.add_theme_constant_override("separation", 2)
	vbox.add_child(mesh_row)

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
	if node.has_signal("edit_started"):
		node.edit_started.connect(_push_undo_state)
	if node.has_signal("texture_pick_requested"):
		node.texture_pick_requested.connect(_on_texture_pick_requested)
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
		)


func _toggle_preview() -> void:
	_preview_panel.visible = not _preview_panel.visible


func _on_mesh_btn_pressed(btn: Button, mesh: Mesh, rotation: Vector3, cam_z: float) -> void:
	_preview_mesh.mesh = mesh
	_preview_mesh.rotation_degrees = rotation
	_preview_camera.position.z = cam_z
	for b in _preview_mesh_buttons:
		b.button_pressed = b == btn



func _open_node_preview(node: Node) -> void:
	var tex_rect: TextureRect = node.get_preview_slot()
	if not tex_rect:
		return

	var vp := SubViewport.new()
	vp.size = Vector2i(100, 100)
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)

	var cam := Camera3D.new()
	cam.position = Vector3(0, 0, 1.2)
	vp.add_child(cam)
	cam.make_current()

	var mesh_inst := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(1.84, 1.84)
	mesh_inst.mesh = qm
	var shader := Shader.new()
	shader.code = "shader_type spatial;\nrender_mode unshaded;\nvoid fragment() { ALBEDO = vec3(0.5); }"
	var mat := ShaderMaterial.new()
	mat.shader = shader
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

	var albedo_expr: String
	if node.get_output_port_count() == 0:
		albedo_expr = _get_snippet_for(node.name, 0, c, "vec3(0.5, 0.5, 0.5)")
	else:
		var node_result := _get_node_snippet(node, 0, c)
		albedo_expr = "vec3(%s)" % node_result[0] if node_result[1] == 1 else node_result[0]

	return "shader_type spatial;\nrender_mode unshaded;\n%s\n%svoid fragment() {\n\tALBEDO = %s;\n}\n" % [uniform_lines, function_block, albedo_expr]


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


func _apply_texture_uniforms() -> void:
	for child in _graph.get_children():
		if child.has_method("get_uniform_name") and child.has_method("get_texture"):
			var tex = child.get_texture()
			if tex:
				_shader_material.set_shader_parameter(child.get_uniform_name(), tex)
		if child.has_method("apply_shader_params"):
			child.apply_shader_params(_shader_material)


func _compile_shader() -> void:
	if _graph.get_node_or_null("OutputNode"):
		var code := _build_shader_code()
		if code != _last_shader_code:
			_last_shader_code = code
			_shader_material.shader.code = code
		_apply_texture_uniforms()
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


func _on_export_file_selected(path: String) -> void:
	if not path.ends_with(".gdshader"):
		path += ".gdshader"

	var shader_code := _build_shader_code()
	var f := FileAccess.open(path, FileAccess.WRITE)
	if not f:
		push_error("Nyx: could not write shader to %s" % path)
		return
	f.store_string(shader_code)
	f.close()

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
		return
	tf.store_string("\n".join(lines))
	tf.close()

	EditorInterface.get_resource_filesystem().scan()
	print("Nyx: exported\n  shader  → %s\n  material → %s" % [path, tres_path])



func _get_snippet_typed(to_node: String, to_port: int, connections: Array, default_val: String, default_type: int) -> Array:
	for conn in connections:
		if str(conn["to_node"]) == to_node and conn["to_port"] == to_port:
			var from := _graph.get_node_or_null(str(conn["from_node"]))
			if from:
				return _get_node_snippet(from, conn["from_port"], connections)
	return [default_val, default_type]


func _get_snippet_for(to_node: String, to_port: int, connections: Array, default_val: String) -> String:
	var default_type: int = 1 if not default_val.begins_with("vec") else 0
	var result := _get_snippet_typed(to_node, to_port, connections, default_val, default_type)
	var snippet: String = result[0]
	if snippet.is_empty():
		return snippet
	var from_type: int = result[1]
	var to_node_ref := _graph.get_node_or_null(to_node)
	var to_type: int = to_node_ref.get_input_port_type(to_port) if to_node_ref else 0
	if from_type == 1 and to_type == 0:
		return "vec3(%s)" % snippet
	return snippet


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
		var port_type: int = node.get_input_port_type(i) if i < node.get_input_port_count() else 0
		if in_type == 1 and port_type == 0:
			if is_poly and output_type == 1:
				inputs.append(snippet)
			else:
				inputs.append("vec3(%s)" % snippet)
		else:
			inputs.append(snippet)

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
	var float_color := Color(0.35, 0.9, 0.85)
	var vec3_color := Color.WHITE
	for child in _graph.get_children():
		if not (child is GraphNode):
			continue
		if not child.has_method("is_polymorphic") or not child.is_polymorphic():
			continue
		for port in range(child.get_output_port_count()):
			var resolved_type := _resolve_output_type(child, port)
			if child.get_output_port_type(port) == resolved_type:
				continue
			var port_color := float_color if resolved_type == 1 else vec3_color
			child.set_slot(port,
				child.is_slot_enabled_left(port), child.get_slot_type_left(port), child.get_slot_color_left(port),
				child.is_slot_enabled_right(port), resolved_type, port_color)


func sync_size(new_size: Vector2) -> void:
	if _graph_container:
		_graph_container.size = new_size
	if not _preview_positioned and _preview_panel:
		_preview_positioned = true
		call_deferred("_position_preview_default")


func _position_preview_default() -> void:
	_preview_panel.position = Vector2(_graph_container.size.x - _preview_panel.size.x - 20, 20)


func _on_preview_header_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_preview_dragging = event.pressed
	elif event is InputEventMouseMotion and _preview_dragging:
		_preview_panel.position += event.relative


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


func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	var from := _graph.get_node_or_null(str(from_node))
	var to := _graph.get_node_or_null(str(to_node))
	if not from or not to:
		return
	var from_type: int = _resolve_output_type(from, from_port)
	var to_type: int = to.get_input_port_type(to_port)
	if from_type != to_type and not (from_type == 1 and to_type == 0):
		return
	_push_undo_state()
	_graph.connect_node(from_node, from_port, to_node, to_port)
	_update_all_polymorphic_ports()
	_request_compile()


func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	_push_undo_state()
	_graph.disconnect_node(from_node, from_port, to_node, to_port)
	_update_all_polymorphic_ports()
	_request_compile()


func _on_graph_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_spawn_position = event.position / _graph.zoom + _graph.scroll_offset
			_open_search_popup()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_X:
			var selected: Array[StringName] = []
			for child in _graph.get_children():
				if child is GraphNode and child.selected:
					selected.append(child.name)
			if not selected.is_empty():
				_on_delete_nodes_request(selected)
		elif event.keycode == KEY_A:
			_spawn_position = _graph.get_local_mouse_position() / _graph.zoom + _graph.scroll_offset
			_open_search_popup()


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
		47: _add_node(CustomGLSLNode.new(), _spawn_position, "CustomGLSL")
		48: _add_node(Vector3Node.new(), _spawn_position, "Vector3")


func _build_graph_toolbar() -> HBoxContainer:
	var toolbar := HBoxContainer.new()

	var save_btn := Button.new()
	save_btn.text = "Save"
	save_btn.pressed.connect(func(): _save_dialog.popup_centered_ratio(0.5))
	toolbar.add_child(save_btn)

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

	return {"nodes": nodes, "connections": connections}


func _deserialize_graph(data: Dictionary) -> void:
	_graph.clear_connections()
	var to_remove: Array[Node] = []
	for child in _graph.get_children():
		if child is GraphNode:
			to_remove.append(child)
	for child in to_remove:
		_graph.remove_child(child)
		child.free()

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

	_request_compile()


func _on_save_file_selected(path: String) -> void:
	if not path.ends_with(".nyx"):
		path += ".nyx"
	var f := FileAccess.open(path, FileAccess.WRITE)
	if not f:
		push_error("Nyx: could not write graph to %s" % path)
		return
	f.store_string(JSON.stringify(_serialize_graph(), "\t"))
	f.close()
	print("Nyx: saved graph → %s" % path)


func _on_load_file_selected(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		push_error("Nyx: could not read graph from %s" % path)
		return
	var result := JSON.parse_string(f.get_as_text())
	f.close()
	if not result is Dictionary:
		push_error("Nyx: invalid graph file %s" % path)
		return
	_deserialize_graph(result)
	print("Nyx: loaded graph ← %s" % path)


# --- Node search popup ---

func _build_search_popup() -> void:
	# --- Search popup (compact) ---
	_search_popup = PopupPanel.new()
	_search_popup.min_size = Vector2i(260, 360)
	_search_popup.transparent = true

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.14, 0.14, 0.18)
	panel_style.border_color = Color(0.28, 0.28, 0.38)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(8)
	_search_popup.add_theme_stylebox_override("panel", panel_style)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)

	var vbox := VBoxContainer.new()
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

	var selected_style := StyleBoxFlat.new()
	selected_style.bg_color = Color(0.15, 0.61, 0.36)
	selected_style.set_corner_radius_all(3)
	selected_style.content_margin_left = 4
	selected_style.content_margin_right = 4
	_search_list.add_theme_stylebox_override("selected", selected_style)
	_search_list.add_theme_stylebox_override("selected_focus", selected_style)

	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color(0.15, 0.61, 0.36, 0.25)
	hover_style.set_corner_radius_all(3)
	hover_style.content_margin_left = 4
	hover_style.content_margin_right = 4
	_search_list.add_theme_stylebox_override("hovered", hover_style)

	_search_list.add_theme_color_override("font_color", Color(0.90, 0.90, 0.90))
	_search_list.add_theme_color_override("font_selected_color", Color.WHITE)
	_search_list.add_theme_color_override("font_disabled_color", Color(0.45, 0.45, 0.55))

	_search_list.item_selected.connect(_on_search_item_selected_by_mouse)
	_search_list.gui_input.connect(_on_search_list_hover)
	vbox.add_child(_search_list)

	margin.add_child(vbox)
	_search_popup.add_child(margin)
	_search_popup.popup_hide.connect(func():
		_doc_popup.hide()
		_doc_hover_timer.stop()
	)
	add_child(_search_popup)

	_doc_hover_timer = Timer.new()
	_doc_hover_timer.one_shot = true
	_doc_hover_timer.wait_time = 0.4
	_doc_hover_timer.timeout.connect(_on_doc_hover_timeout)
	add_child(_doc_hover_timer)

	# --- Doc popup (floats alongside, child of search popup so it doesn't close it) ---
	_doc_popup = PopupPanel.new()
	_doc_popup.min_size = Vector2i(260, 0)
	_doc_popup.transparent = true
	_doc_popup.unfocusable = true
	_doc_popup.visible = false

	var doc_panel_style := StyleBoxFlat.new()
	doc_panel_style.bg_color = Color(0.14, 0.14, 0.18)
	doc_panel_style.border_color = Color(0.28, 0.28, 0.38)
	doc_panel_style.set_border_width_all(1)
	doc_panel_style.set_corner_radius_all(8)
	_doc_popup.add_theme_stylebox_override("panel", doc_panel_style)

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
	_doc_popup.add_child(doc_margin)
	_search_popup.add_child(_doc_popup)


func _open_search_popup() -> void:
	_search_input.text = ""
	_populate_search_grouped()
	_doc_label.clear()
	_doc_popup.hide()
	_search_popup.popup(Rect2(get_global_mouse_position(), Vector2(260, 360)))
	_search_input.call_deferred("grab_focus")


func _populate_search_grouped() -> void:
	_search_list.clear()
	_search_item_ids.clear()
	for category in _NODE_REGISTRY:
		var header_idx: int = _search_list.add_item(category["category"])
		_search_list.set_item_disabled(header_idx, true)
		_search_item_ids.append(-1)
		for entry in category["nodes"]:
			_search_list.add_item("  " + entry["label"])
			_search_item_ids.append(entry["id"])


func _populate_search_filtered(query: String) -> void:
	_search_list.clear()
	_search_item_ids.clear()
	for category in _NODE_REGISTRY:
		var category_matches := _fuzzy_match(query, category["category"])
		for entry in category["nodes"]:
			if category_matches or _fuzzy_match(query, entry["label"]):
				_search_list.add_item(entry["label"])
				_search_item_ids.append(entry["id"])
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
	_search_popup.hide()
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
			_search_popup.hide()
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
				_search_popup.hide()
				_push_undo_state()
				_on_context_menu_selected(id)
				get_viewport().set_input_as_handled()


func _show_doc_for(id: int) -> void:
	if _doc_popup.visible:
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
		_doc_popup.hide()
		return
	var entry := _get_node_entry(id)
	if entry.is_empty():
		_doc_popup.hide()
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

	var h := _estimate_doc_height(entry)
	var x := _search_popup.position.x + _search_popup.size.x + 10
	var y := _search_popup.position.y
	_doc_popup.position = Vector2i(x, y)
	_doc_popup.size = Vector2i(260, h)
	if not _doc_popup.visible:
		_doc_popup.show()
	_search_input.grab_focus()
