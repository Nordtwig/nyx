@tool
extends RefCounted

## Nyx node catalog — the complete node registry.
##
## Three things live here:
##   NODE_REGISTRY  — search/doc metadata (id, label, summary, ports, uses, gating flags)
##   NODE_CLASSES   — type-name → Script map (factory; also used by serializer + paste)
##   NODE_TYPE_CATEGORY / NODE_TYPE_COLORS — per-type category string + body colour
##
## Also owns two static utilities that only need registry data:
##   get_node_type(node)  → type-name string (used by serializer, add_node, paste)
##   is_sink(node)        → true for OutputNode / VertexOutputNode / particle sinks
##
## No class_name (preload-const pattern like Charon — avoids global symbol collisions).
## Extracted from nyx_main.gd.

const NODE_REGISTRY := [
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
		{"label": "Object Position", "id": 63, "spatial_only": true,
			"summary": "The world-space position of the object this shader is applied to.",
			"description": "Outputs NODE_POSITION_WORLD — the origin of the node the material is on, in world space. Note for MultiMeshInstance3D: this is the position of the MultiMesh node itself, not each individual instance — every instance reads the same value.",
			"ports": ["Out (vec3) — world-space XYZ of the object's origin"],
			"uses": ["Per-object phase offset so wind sway or pulsing doesn't sync across separately placed objects", "Seeding position-based random variation between objects", "World-space effects that should stay stable regardless of UV or local vertex position"]},
		{"label": "World Position", "id": 64, "spatial_only": true,
			"summary": "The world-space position of the exact point currently being shaded.",
			"description": "Unlike Object Position (one fixed value for the whole object), World Position varies continuously across the surface — the base and tip of a mesh report different values. Stage-correct in both Vertex Offset and Albedo: in the vertex stage it's MODEL_MATRIX * VERTEX (model→world); in the fragment stage it's INV_VIEW_MATRIX * VERTEX (view→world), which reports the DISPLACED world position after any vertex offset — exactly what depth and foam math want. MultiMesh caveat: in the fragment stage MODEL_MATRIX falls back to the MultiMesh node's own transform, so a per-instance world position only varies when read through Vertex Offset / Vertex Output.",
			"ports": ["Out (vec3) — world-space XYZ of the current surface point"],
			"uses": ["World-space colour gradients across a large surface or between objects (biome-style blending) — on ordinary meshes, not MultiMesh fragment use", "Position-seeded noise/patterns that stay stable in world space regardless of UV unwrapping", "A spatially-varying wave (e.g. wind gusts that sweep across a field) when wired through Vertex Offset — safe on MultiMesh since that's the vertex stage"]},
		{"label": "Instance Custom Data", "id": 65, "spatial_only": true,
			"summary": "Per-instance custom data for a MultiMesh, set from GDScript.",
			"description": "Reads INSTANCE_CUSTOM — a vec4 you populate per instance via multimesh.set_instance_custom_data() (requires multimesh.use_custom_data = true). Use it to give every instance in a MultiMesh field its own seed, phase offset, or position — something Object Position can't do, since every instance in a MultiMesh shares the same object. Vertex-stage only: Godot doesn't expose INSTANCE_CUSTOM in the fragment function, so wire it through Vertex Offset / Vertex Output, not Albedo or other fragment slots.",
			"ports": ["Out (vec4) — the instance's custom data, channels meaning whatever you packed into them"],
			"uses": ["Per-instance phase/seed so animation doesn't sync across a MultiMesh field (e.g. grass blades swaying out of sync)", "Per-instance scale or rotation driven from GDScript", "Carrying a baked per-instance world position into the shader for motion math"]},
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
		{"label": "Ocean Waves", "id": 67, "spatial_only": true,
			"summary": "A stack of Gerstner waves — displacement, matching normal, and a foam crest mask in one node.",
			"description": "Sums several Gerstner waves of different sizes and directions into a believable ocean surface. Wire a world-space position (the World Position node) into Position, send Offset and Normal to the Vertex Output node to displace the mesh, and use Crest to drive foam. Amplitude sets wave height; Steepness (0–1) sharpens the crests without ever folding them; per-wave speed follows real deep-water physics so long waves outrun short ones. Waves sets how many are summed; Direction and Spread aim them and fan them out so fronts never look like a grid.",
			"ports": ["Position (vec3) — world-space position to evaluate the waves at", "Offset (vec3) — Gerstner displacement, for Vertex Output · Offset", "Normal (vec3) — matching geometric surface normal, for Vertex Output · Normal", "Crest (float) — 0 in troughs, 1 at peaks, for driving foam"],
			"uses": ["Ocean and lake surfaces (the whole point)", "A single rolling swell on a stylized pond — set Waves to 1, Spread to 0", "A gentle wobble on a jelly or flag by keeping Steepness and Amplitude low"]},
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
		{"label": "Value Relay (Experimental)", "id": 66, "particle_unsafe": true,
			"summary": "Pass-through that shows the exact raw number(s) flowing through it.",
			"description": "A single in/out pass-through, like Preview Relay, but instead of a colour swatch it shows the live value as plain text — one number for a float, up to four for a vec4. Unlike a preview swatch, nothing is clamped to 0-1 or has its sign dropped, so it works for quantities as well as colours.",
			"ports": ["In — any type", "Out — same type as input"],
			"uses": ["Checking a value is actually what you expect, not just what it looks like", "Debugging signed or out-of-range quantities (vertex displacement, particle velocity)", "Verifying threshold/mask edges land where intended"]},
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

# ── Node-class preloads ───────────────────────────────────────────────────────
# All node scripts in one place so NODE_CLASSES, nyx_main factory calls, and
# any future consumer can reference them without duplicating the preload paths.

const NyxNodeBase          = preload("res://addons/nyx/nodes/nyx_node.gd")
const OutputNode           = preload("res://addons/nyx/nodes/output_node.gd")
const VertexOutputNode     = preload("res://addons/nyx/nodes/vertex_output_node.gd")
const ColorNode            = preload("res://addons/nyx/nodes/color_node.gd")
const AddNode              = preload("res://addons/nyx/nodes/add_node.gd")
const MultiplyNode         = preload("res://addons/nyx/nodes/multiply_node.gd")
const MixNode              = preload("res://addons/nyx/nodes/mix_node.gd")
const UVNode               = preload("res://addons/nyx/nodes/uv_node.gd")
const FloatNode            = preload("res://addons/nyx/nodes/float_node.gd")
const SubtractNode         = preload("res://addons/nyx/nodes/subtract_node.gd")
const ClampNode            = preload("res://addons/nyx/nodes/clamp_node.gd")
const PowerNode            = preload("res://addons/nyx/nodes/power_node.gd")
const SinNode              = preload("res://addons/nyx/nodes/sin_node.gd")
const CosNode              = preload("res://addons/nyx/nodes/cos_node.gd")
const TimeNode             = preload("res://addons/nyx/nodes/time_node.gd")
const SplitNode            = preload("res://addons/nyx/nodes/split_node.gd")
const CombineNode          = preload("res://addons/nyx/nodes/combine_node.gd")
const TextureSampleNode    = preload("res://addons/nyx/nodes/texture_sample_node.gd")
const FresnelNode          = preload("res://addons/nyx/nodes/fresnel_node.gd")
const ScaleNode            = preload("res://addons/nyx/nodes/scale_node.gd")
const StepNode             = preload("res://addons/nyx/nodes/step_node.gd")
const SmoothstepNode       = preload("res://addons/nyx/nodes/smoothstep_node.gd")
const NoiseNode            = preload("res://addons/nyx/nodes/noise_node.gd")
const FBMNode              = preload("res://addons/nyx/nodes/fbm_node.gd")
const OceanWavesNode       = preload("res://addons/nyx/nodes/ocean_waves_node.gd")
const GradientNode         = preload("res://addons/nyx/nodes/gradient_node.gd")
const CurveNode            = preload("res://addons/nyx/nodes/curve_node.gd")
const TilingOffsetNode     = preload("res://addons/nyx/nodes/tiling_offset_node.gd")
const NormalFromHeightNode = preload("res://addons/nyx/nodes/normal_from_height_node.gd")
const BlendNormalsNode     = preload("res://addons/nyx/nodes/blend_normals_node.gd")
const ScreenUVNode         = preload("res://addons/nyx/nodes/screen_uv_node.gd")
const ScreenTextureNode    = preload("res://addons/nyx/nodes/screen_texture_node.gd")
const DepthFadeNode        = preload("res://addons/nyx/nodes/depth_fade_node.gd")
const RotateUVNode         = preload("res://addons/nyx/nodes/rotate_uv_node.gd")
const WarpNode             = preload("res://addons/nyx/nodes/warp_node.gd")
const VertexNode           = preload("res://addons/nyx/nodes/vertex_node.gd")
const ObjectPositionNode   = preload("res://addons/nyx/nodes/object_position_node.gd")
const WorldPositionNode    = preload("res://addons/nyx/nodes/world_position_node.gd")
const InstanceCustomDataNode = preload("res://addons/nyx/nodes/instance_custom_data_node.gd")
const NormalMapNode        = preload("res://addons/nyx/nodes/normal_map_node.gd")
const AbsNode              = preload("res://addons/nyx/nodes/abs_node.gd")
const CeilNode             = preload("res://addons/nyx/nodes/ceil_node.gd")
const FloorNode            = preload("res://addons/nyx/nodes/floor_node.gd")
const FractNode            = preload("res://addons/nyx/nodes/fract_node.gd")
const NegateNode           = preload("res://addons/nyx/nodes/negate_node.gd")
const OneMinusNode         = preload("res://addons/nyx/nodes/one_minus_node.gd")
const RoundNode            = preload("res://addons/nyx/nodes/round_node.gd")
const SqrtNode             = preload("res://addons/nyx/nodes/sqrt_node.gd")
const MinMaxNode           = preload("res://addons/nyx/nodes/min_max_node.gd")
const DivideNode           = preload("res://addons/nyx/nodes/divide_node.gd")
const ModNode              = preload("res://addons/nyx/nodes/mod_node.gd")
const NormalizeNode        = preload("res://addons/nyx/nodes/normalize_node.gd")
const LengthNode           = preload("res://addons/nyx/nodes/length_node.gd")
const DotNode              = preload("res://addons/nyx/nodes/dot_node.gd")
const RerouteNode          = preload("res://addons/nyx/nodes/reroute_node.gd")
const RelayNode            = preload("res://addons/nyx/nodes/relay_node.gd")
const PreviewRelayNode     = preload("res://addons/nyx/nodes/preview_relay_node.gd")
const ValueRelayNode       = preload("res://addons/nyx/nodes/value_relay_node.gd")
const CustomGLSLNode       = preload("res://addons/nyx/nodes/custom_glsl_node.gd")
const Vector3Node          = preload("res://addons/nyx/nodes/vector3_node.gd")
const SpriteTextureNode    = preload("res://addons/nyx/nodes/sprite_texture_node.gd")
const VertexColorNode      = preload("res://addons/nyx/nodes/vertex_color_node.gd")
const TexturePixelSizeNode = preload("res://addons/nyx/nodes/texture_pixel_size_node.gd")
const ParticleStartNode    = preload("res://addons/nyx/nodes/particle_start_node.gd")
const ParticleProcessNode  = preload("res://addons/nyx/nodes/particle_process_node.gd")
const ParticleAgeNode      = preload("res://addons/nyx/nodes/particle_age_node.gd")
const ParticleVelocityNode = preload("res://addons/nyx/nodes/particle_velocity_node.gd")
const ParticlePositionNode = preload("res://addons/nyx/nodes/particle_position_node.gd")
const ParticleDeltaNode    = preload("res://addons/nyx/nodes/particle_delta_node.gd")
const ParticleRandomNode   = preload("res://addons/nyx/nodes/particle_random_node.gd")
const ParticleIndexNode    = preload("res://addons/nyx/nodes/particle_index_node.gd")


# ── Factory map + category/colour data ───────────────────────────────────────

# Maps type-name string → Script. Used by the node factory, serializer, and paste.
const NODE_CLASSES := {
	"OutputNode": OutputNode,           "VertexOutputNode": VertexOutputNode,
	"ColorNode": ColorNode,             "FloatNode": FloatNode,
	"Vector3Node": Vector3Node,         "UVNode": UVNode,
	"VertexNode": VertexNode,           "TimeNode": TimeNode,
	"ObjectPositionNode": ObjectPositionNode, "WorldPositionNode": WorldPositionNode,
	"InstanceCustomDataNode": InstanceCustomDataNode,
	"FresnelNode": FresnelNode,         "AddNode": AddNode,
	"SubtractNode": SubtractNode,       "MultiplyNode": MultiplyNode,
	"DivideNode": DivideNode,           "MixNode": MixNode,
	"ClampNode": ClampNode,             "PowerNode": PowerNode,
	"MinMaxNode": MinMaxNode,           "ModNode": ModNode,
	"AbsNode": AbsNode,                 "CeilNode": CeilNode,
	"FloorNode": FloorNode,             "FractNode": FractNode,
	"NegateNode": NegateNode,           "OneMinusNode": OneMinusNode,
	"RoundNode": RoundNode,             "SqrtNode": SqrtNode,
	"SinNode": SinNode,                 "CosNode": CosNode,
	"StepNode": StepNode,               "SmoothstepNode": SmoothstepNode,
	"NormalizeNode": NormalizeNode,     "LengthNode": LengthNode,
	"DotNode": DotNode,                 "SplitNode": SplitNode,
	"CombineNode": CombineNode,         "ScaleNode": ScaleNode,
	"NoiseNode": NoiseNode,             "FBMNode": FBMNode,
	"OceanWavesNode": OceanWavesNode,
	"TextureSampleNode": TextureSampleNode, "NormalMapNode": NormalMapNode,
	"GradientNode": GradientNode,       "CurveNode": CurveNode,
	"TilingOffsetNode": TilingOffsetNode, "RotateUVNode": RotateUVNode,
	"WarpNode": WarpNode,               "NormalFromHeightNode": NormalFromHeightNode,
	"BlendNormalsNode": BlendNormalsNode,
	"ScreenUVNode": ScreenUVNode,       "ScreenTextureNode": ScreenTextureNode,
	"DepthFadeNode": DepthFadeNode,
	"SpriteTextureNode": SpriteTextureNode, "VertexColorNode": VertexColorNode,
	"TexturePixelSizeNode": TexturePixelSizeNode,
	"RerouteNode": RerouteNode,         "RelayNode": RelayNode,
	"PreviewRelayNode": PreviewRelayNode, "ValueRelayNode": ValueRelayNode,
	"CustomGLSLNode": CustomGLSLNode,
	"ParticleStartNode": ParticleStartNode, "ParticleProcessNode": ParticleProcessNode,
	"ParticleAgeNode": ParticleAgeNode, "ParticleVelocityNode": ParticleVelocityNode,
	"ParticlePositionNode": ParticlePositionNode, "ParticleDeltaNode": ParticleDeltaNode,
	"ParticleRandomNode": ParticleRandomNode, "ParticleIndexNode": ParticleIndexNode,
}

# Node body colour (all monochrome dark — category expressed via icon, not colour).
const _NODE_COLOR := Color(0.14, 0.14, 0.18, 0.95)
const NODE_TYPE_COLORS := {
	"FloatNode": _NODE_COLOR,    "Vector3Node": _NODE_COLOR,  "UVNode": _NODE_COLOR,
	"VertexNode": _NODE_COLOR,   "TimeNode": _NODE_COLOR,     "FresnelNode": _NODE_COLOR,
	"ObjectPositionNode": _NODE_COLOR, "WorldPositionNode": _NODE_COLOR, "InstanceCustomDataNode": _NODE_COLOR,
	"ScreenUVNode": _NODE_COLOR, "ScreenTextureNode": _NODE_COLOR, "DepthFadeNode": _NODE_COLOR,
	"AddNode": _NODE_COLOR,      "SubtractNode": _NODE_COLOR, "MultiplyNode": _NODE_COLOR,
	"DivideNode": _NODE_COLOR,   "MixNode": _NODE_COLOR,      "ClampNode": _NODE_COLOR,
	"PowerNode": _NODE_COLOR,    "MinMaxNode": _NODE_COLOR,   "ModNode": _NODE_COLOR,
	"AbsNode": _NODE_COLOR,      "CeilNode": _NODE_COLOR,     "FloorNode": _NODE_COLOR,
	"FractNode": _NODE_COLOR,    "NegateNode": _NODE_COLOR,   "OneMinusNode": _NODE_COLOR,
	"RoundNode": _NODE_COLOR,    "SqrtNode": _NODE_COLOR,     "SinNode": _NODE_COLOR,
	"CosNode": _NODE_COLOR,      "StepNode": _NODE_COLOR,     "SmoothstepNode": _NODE_COLOR,
	"CustomGLSLNode": _NODE_COLOR,
	"NormalizeNode": _NODE_COLOR, "LengthNode": _NODE_COLOR,  "DotNode": _NODE_COLOR,
	"SplitNode": _NODE_COLOR,    "CombineNode": _NODE_COLOR,  "NormalFromHeightNode": _NODE_COLOR,
	"BlendNormalsNode": _NODE_COLOR, "ScaleNode": _NODE_COLOR,
	"TextureSampleNode": _NODE_COLOR, "NormalMapNode": _NODE_COLOR,
	"GradientNode": _NODE_COLOR, "CurveNode": _NODE_COLOR,
	"TilingOffsetNode": _NODE_COLOR, "RotateUVNode": _NODE_COLOR, "WarpNode": _NODE_COLOR,
	"NoiseNode": _NODE_COLOR,    "FBMNode": _NODE_COLOR,      "OceanWavesNode": _NODE_COLOR,
	"RerouteNode": _NODE_COLOR,  "RelayNode": _NODE_COLOR,    "PreviewRelayNode": _NODE_COLOR,
	"ValueRelayNode": _NODE_COLOR,
	"SpriteTextureNode": _NODE_COLOR, "VertexColorNode": _NODE_COLOR,
	"TexturePixelSizeNode": _NODE_COLOR,
	"ParticleAgeNode": _NODE_COLOR,      "ParticleVelocityNode": _NODE_COLOR,
	"ParticlePositionNode": _NODE_COLOR, "ParticleDeltaNode": _NODE_COLOR,
	"ParticleRandomNode": _NODE_COLOR,   "ParticleIndexNode": _NODE_COLOR,
}

# Maps type-name → category string. Used by _add_node to set node._category.
const NODE_TYPE_CATEGORY := {
	"ColorNode": "Inputs",    "FloatNode": "Inputs",     "Vector3Node": "Inputs",
	"UVNode": "Inputs",       "VertexNode": "Inputs",    "TimeNode": "Inputs",
	"FresnelNode": "Inputs", "ObjectPositionNode": "Inputs", "WorldPositionNode": "Inputs",
	"InstanceCustomDataNode": "Inputs",
	"AddNode": "Math",        "SubtractNode": "Math",    "MultiplyNode": "Math",
	"DivideNode": "Math",     "MixNode": "Math",         "ClampNode": "Math",
	"PowerNode": "Math",      "MinMaxNode": "Math",      "ModNode": "Math",
	"AbsNode": "Math",        "CeilNode": "Math",        "FloorNode": "Math",
	"FractNode": "Math",      "NegateNode": "Math",      "OneMinusNode": "Math",
	"RoundNode": "Math",      "SqrtNode": "Math",        "SinNode": "Math",
	"CosNode": "Math",        "StepNode": "Math",        "SmoothstepNode": "Math",
	"NormalizeNode": "Vector", "LengthNode": "Vector",   "DotNode": "Vector",
	"SplitNode": "Vector",    "CombineNode": "Vector",   "ScaleNode": "Vector",
	"NoiseNode": "Noise",     "FBMNode": "Noise",        "OceanWavesNode": "Noise",
	"TextureSampleNode": "Texture", "NormalMapNode": "Texture",
	"GradientNode": "Texture", "CurveNode": "Texture",
	"TilingOffsetNode": "UV", "RotateUVNode": "UV",      "WarpNode": "UV",
	"NormalFromHeightNode": "UV", "BlendNormalsNode": "UV",
	"ScreenUVNode": "Screen", "ScreenTextureNode": "Screen", "DepthFadeNode": "Screen",
	"SpriteTextureNode": "Canvas", "VertexColorNode": "Canvas",
	"TexturePixelSizeNode": "Canvas",
	"ParticleStartNode": "Particles",   "ParticleProcessNode": "Particles",
	"ParticleAgeNode": "Particles",     "ParticleVelocityNode": "Particles",
	"ParticlePositionNode": "Particles","ParticleDeltaNode": "Particles",
	"ParticleRandomNode": "Particles",  "ParticleIndexNode": "Particles",
	"RerouteNode": "Organisation",      "RelayNode": "Organisation",
	"PreviewRelayNode": "Organisation", "ValueRelayNode": "Organisation",
	"CustomGLSLNode": "Advanced",
}

# Minimum body width per node, in 3 tiers (100/140/160) so graphs read as
# intentionally laid out instead of purely content-driven. A minimum only —
# content-heavy nodes (texture/gradient/curve, Color, Custom Function,
# Reroute/Relay/Preview Relay) are deliberately left out so they keep growing
# from their own content exactly as before. Used by _add_node in nyx_main.gd.
# Values are 1.0-scale LOGICAL widths — multiply by EditorInterface.get_editor_scale()
# at apply time (done in nyx_main._add_node via NyxNodeBase._s). Originally hand-tuned
# at 0.75 editor scale on the laptop (100/110/140/160); re-normalized to a 1.0 base
# (÷0.75, rounded) so the same relationship holds on any DPI. See the "editor scale"
# gotcha in CLAUDE.md.
const NODE_WIDTH_TIERS := {
	# 135 — every row's own content (port labels, a single unlabeled widget)
	# is short/single-word. Port COUNT doesn't push a node out of this tier by
	# itself (2026-07-04 revision) — each port is its own row, so more of them
	# just adds height, not width, as long as no individual row's content is
	# long. Includes the bare math ops, the "few short labels stacked
	# vertically" multi-port nodes (Clamp/Power/MinMax/Mod/Mix/Split/Combine/
	# Time/BlendNormals — labels are all things like "A"/"Min"/"Exp"/"Sin"),
	# and single-port nodes with a short title and no widget (UV/Vertex/
	# Screen UV/the particle value readers/Vertex Color/Pixel Size), plus
	# Float (a bare SpinBox with no separate label at all).
	"AddNode": 135.0,        "SubtractNode": 135.0,   "MultiplyNode": 135.0,
	"DivideNode": 135.0,     "AbsNode": 135.0,        "CeilNode": 135.0,
	"FloorNode": 135.0,      "FractNode": 135.0,      "NegateNode": 135.0,
	"OneMinusNode": 135.0,   "RoundNode": 135.0,      "SqrtNode": 135.0,
	"SinNode": 135.0,        "CosNode": 135.0,        "NormalizeNode": 135.0,
	"LengthNode": 135.0,     "DotNode": 135.0,        "ScaleNode": 135.0,
	"RelayNode": 135.0,      "PreviewRelayNode": 135.0,   "ValueRelayNode": 135.0,
	"ClampNode": 135.0,      "PowerNode": 135.0,      "MinMaxNode": 135.0,
	"ModNode": 135.0,        "MixNode": 135.0,        "SplitNode": 135.0,
	"CombineNode": 135.0,    "TimeNode": 135.0,       "BlendNormalsNode": 135.0,
	"UVNode": 135.0,         "VertexNode": 135.0,     "ScreenUVNode": 135.0,
	"ParticleVelocityNode": 135.0,   "ParticlePositionNode": 135.0,
	"ParticleDeltaNode": 135.0,      "ParticleIndexNode": 135.0,
	"ParticleAgeNode": 135.0,        "VertexColorNode": 135.0,
	"TexturePixelSizeNode": 135.0,   "FloatNode": 135.0,
	# Every remaining "content-heavy" node also gets the same 135 FLOOR
	# (2026-07-04) — nothing in Nyx should render narrower than the smallest
	# tier just because its own content happens to be simpler/unconstrained.
	# A floor never fights content that genuinely needs more: Vector3's 3
	# stacked X/Y/Z rows, Texture Sample/Normal Map's texture-path label
	# (140), and Custom Function's code editor (200) already exceed 135 on
	# their own, so this is a no-op for them — added for consistency, not
	# because they measured narrow. Color/Curve/Gradient's own explicit
	# widths (120 / unset / unset) genuinely were narrower than 135 before
	# this, a real inconsistency Noah caught in the live graph. Reroute gets
	# it too on the same principle, though its shape is the documented
	# special/parked case (see the Reroute known-gotcha) — worth a look if
	# the floor visibly fights its intentionally minimal pill.
	"Vector3Node": 135.0,    "ColorNode": 135.0,      "CurveNode": 135.0,
	"GradientNode": 135.0,   "TextureSampleNode": 135.0, "NormalMapNode": 135.0,
	"SpriteTextureNode": 135.0, "CustomGLSLNode": 135.0, "RerouteNode": 135.0,

	# 150 — sink/terminal nodes. Measured: even the thickest (Output, 8 labeled
	# slots) doesn't need more than this, so a shared floor actually equalizes
	# the sinks instead of being a no-op on the wider ones.
	"OutputNode": 150.0,     "VertexOutputNode": 150.0,
	"ParticleStartNode": 150.0, "ParticleProcessNode": 150.0,

	# 185 — a genuinely long title (Object/World Position, Instance Custom
	# Data, Screen Texture — 14+ characters, well past what 135 comfortably
	# holds), OR a labeled EditorSpinSlider/OptionButton alongside its own
	# separately labeled port rows (Fresnel/Step/RotateUV/Warp/
	# NormalFromHeight/DepthFade/Noise) — the slider's own internal
	# composition (label + value + arrows in one control) needs more room
	# than a bare port row, unlike Float's label-less SpinBox above.
	"ObjectPositionNode": 185.0, "WorldPositionNode": 185.0,
	"InstanceCustomDataNode": 185.0, "ScreenTextureNode": 185.0,
	"FresnelNode": 185.0,    "StepNode": 185.0,       "RotateUVNode": 185.0,
	"WarpNode": 185.0,       "NormalFromHeightNode": 185.0,
	"DepthFadeNode": 185.0,  "NoiseNode": 185.0,

	# 215 — genuinely multi-control nodes (2+ sliders/spinboxes/dropdowns):
	# visually denser, earns the extra width even though each row alone
	# wouldn't strictly need it.
	"SmoothstepNode": 215.0, "FBMNode": 215.0, "TilingOffsetNode": 215.0,
	"ParticleRandomNode": 215.0, "OceanWavesNode": 215.0,
}


# Registry id -> Array[int] of that node type's real INPUT port types (0=vec3,
# 1=float, 2=vec2, 3=vec4; empty = no input ports at all). Used by the
# connection-drop "quick add" popup's output-side candidate list (nyx_main.gd's
# _build_output_drop_candidates) to only ever offer nodes that could actually
# accept the dragged output - see .nyx-notes/backlog.md's "Connection-drop node
# spawn" for the full design/history.
#
# Hand-derived by reading every node's own set_slot() calls directly, NOT by
# instantiating nodes at runtime to probe them - a bare `.new()` never fires
# _ready() (Godot only calls it once a Node enters a SceneTree), so a runtime
# probe would need to parent-then-immediately-free ~68 node instances (several
# EditorSpinSlider-backed) on every connection-drag release, which is both
# unverifiable headless and a real crash-risk surface (a node's _ready() may
# call_deferred() something that could fire after the probe frees it). Reading
# set_slot()'s declared type directly is NOT an approximation of that: this
# codebase's own architecture guarantees a port's REGISTERED input type never
# changes after _ready() (see nyx_compiler.gd's update_all_polymorphic_ports -
# "the input side only ever changes the port's displayed color, never its
# registered type"), so get_input_port_type() at runtime always returns exactly
# what's written here. A polymorphic node's nominal declared type (nearly
# always vec3) already accepts every real type through the promotion matrix
# (float/vec2/vec3 widen to it, vec4 narrows to it) - that's why most poly
# single-input math nodes list just [0].
#
# Verified against 3 dynamic-port node types by reading their _ready()/state
# directly rather than assuming a shape: Relay defaults to 1 pair
# (_pair_count := 1), Custom Function defaults to 1 input (_input_count := 1),
# Tiling & Offset's "row 1" is a label-only master slider with no port at all
# (real ports are 0,2,3,4,5).
const NODE_INPUT_TYPES := {
	0: [], 1: [0], 2: [0], 3: [0, 1], 4: [], 5: [], 6: [0], 7: [0, 1],
	8: [0], 9: [0], 10: [0], 11: [], 12: [3], 13: [1], 14: [0], 15: [1],
	16: [0, 1], 17: [1], 18: [1], 19: [0, 1], 20: [], 21: [0], 22: [0],
	23: [0], 24: [0], 25: [0], 26: [0], 27: [0], 28: [0], 29: [0], 30: [0],
	31: [0], 32: [0], 33: [0], 34: [0], 35: [0], 36: [0, 1], 37: [1],
	38: [1], 39: [0, 1], 40: [0, 1], 41: [0, 1], 42: [1], 43: [0], 44: [],
	45: [0], 46: [1], 47: [0], 48: [], 49: [0], 50: [], 51: [], 52: [0],
	53: [0], 54: [0], 55: [0, 3], 56: [0, 3], 57: [], 58: [], 59: [],
	60: [], 61: [], 62: [], 63: [], 64: [], 65: [], 66: [0], 67: [0],
}


# ── Static utilities ──────────────────────────────────────────────────────────

# Returns the type-name string for a node (its key in NODE_CLASSES), or "" if unknown.
static func get_node_type(node: Node) -> String:
	for type_name in NODE_CLASSES:
		if node.get_script() == NODE_CLASSES[type_name]:
			return type_name
	return ""


# True for the fixed output/sink nodes that should never be copied or serialised
# as regular graph nodes (they're always recreated by _ensure_*_sinks).
static func is_sink(node: Node) -> bool:
	var n := str(node.name)
	return n == "OutputNode" or n == "VertexOutputNode" \
		or n == "ParticleStartNode" or n == "ParticleProcessNode"
