extends SceneTree

## Dev tool — generates node_gallery.nyx: one instance of every registered node
## type, laid out in rows grouped by NyxRegistry.NODE_WIDTH_TIERS (ascending),
## with a final row for the untiered "content-heavy" nodes. Lets Noah eyeball
## sizing across the whole node library at once instead of respawning each
## node by hand.
##
## Run with: godot --headless --script dev_tools/generate_node_gallery.gd
## (run from the project root so res:// resolves correctly)
##
## Generates data only (type/name/position) via NyxSerializer.dict_to_resource —
## it never instantiates the actual node scripts, so it's safe to run headless.
## Open the resulting node_gallery.nyx in Nyx normally; the real _add_node()
## path (tiers + editor scale) reconstructs every node for real.

const NyxRegistry = preload("res://addons/nyx/nyx_registry.gd")
const NyxSerializer = preload("res://addons/nyx/nyx_serializer.gd")

const OUT_PATH := "res://dev_tools/node_gallery.nyx"
const ITEM_GAP := 20.0
# CustomGLSLNode's 200px-wide code editor is the widest untiered node we know
# of; there's no shared "tier" width to trust for this row, so it's the basis
# for a flat step instead.
const UNTIERED_X_STEP := 200.0 + ITEM_GAP
const Y_STEP := 250.0
const START_Y := 1000.0  # clears the default OutputNode/VertexOutputNode area


func _initialize() -> void:
	# Manually register the custom .nyx saver — plugins aren't loaded outside
	# the running editor, so this doesn't happen automatically here.
	var saver = preload("res://addons/nyx/core/nyx_format_saver.gd").new()
	ResourceSaver.add_resource_format_saver(saver)

	# Group node types by tier (ascending); anything not in the tier table
	# (the 11 content-heavy nodes) goes into a final "untiered" row.
	var by_tier := {}
	var untiered := []
	for type_name in NyxRegistry.NODE_CLASSES:
		if NyxRegistry.NODE_WIDTH_TIERS.has(type_name):
			var tier: float = NyxRegistry.NODE_WIDTH_TIERS[type_name]
			if not by_tier.has(tier):
				by_tier[tier] = []
			by_tier[tier].append(type_name)
		else:
			untiered.append(type_name)

	var tiers := by_tier.keys()
	tiers.sort()

	var nodes := []
	var y := START_Y
	for tier in tiers:
		var names: Array = by_tier[tier]
		names.sort()
		var x := 0.0
		var x_step: float = tier + ITEM_GAP  # the tier width itself is the known-width step
		for type_name in names:
			# Distinct names (not the reserved sink names) so sink-type nodes
			# (Output/VertexOutput/ParticleStart/Process) don't get swept up
			# by _update_sink_visibility()'s shader-type-based hiding — every
			# tier row stays visible together regardless of the file's
			# shader_type.
			nodes.append({
				"type": type_name, "name": "%s_gallery" % type_name,
				"position": [x, y], "state": {},
			})
			x += x_step
		y += Y_STEP

	untiered.sort()
	var x := 0.0
	for type_name in untiered:
		nodes.append({
			"type": type_name, "name": "%s_gallery" % type_name,
			"position": [x, y], "state": {},
		})
		x += UNTIERED_X_STEP

	var d := {
		"shader_type": 0, "linked_shader_path": "",
		"nodes": nodes, "connections": [],
	}
	var graph := NyxSerializer.dict_to_resource(d)
	var err := ResourceSaver.save(graph, OUT_PATH)
	if err != OK:
		printerr("Failed to save gallery: %d" % err)
	else:
		print("Wrote %s — %d nodes across %d tier rows + 1 untiered row (%d nodes)" % [
			OUT_PATH, nodes.size(), tiers.size(), untiered.size()
		])
	quit()
