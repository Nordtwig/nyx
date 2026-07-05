@tool
extends RefCounted

## Nyx persistence layer - owns the `.nyx` disk format and the dict↔resource bridge.
##
## Stateless (all static). The boundary is deliberate: the live-editor side stays in
## nyx_main - graph->dict via `_serialize_graph`, dict->graph via `_deserialize_graph`
## (the latter is editor-reconstruction orchestration, not serialization). This file
## only knows how to turn a serialize-dict into a NyxGraph resource on disk and back.
##
## The serialize-dict is the single source of truth; save/load go through the resource,
## undo/redo keep using the dict directly. Extracted from nyx_main.gd.

const NyxGraphRes = preload("res://addons/nyx/core/nyx_graph.gd")
const NyxNodeDataRes = preload("res://addons/nyx/core/nyx_node_data.gd")

# `.nyx` is no longer a registered ResourceFormatSaver/Loader type (see
# core/nyx_shader_importer.gd - it's imported directly as a Shader instead), so
# write()/read() do the temp-.tres delegation privately: Godot's built-in text
# resource format can serialize/parse any Resource, we just retarget the bytes
# to/from the `.nyx` path ourselves. Two distinct tmp names in case a write and
# a read ever land close together (e.g. Save followed immediately by a reload).
const _WRITE_TMP := "user://__nyx_write_tmp.tres"
const _READ_TMP := "user://__nyx_read_tmp.tres"


# Writes a serialize-dict to disk as `.nyx` text. Returns success.
static func write(path: String, d: Dictionary) -> bool:
	var graph := dict_to_resource(d)
	var err := ResourceSaver.save(graph, _WRITE_TMP)
	if err != OK:
		push_error("Nyx: could not write graph to %s (err %d)" % [path, err])
		return false
	var text := FileAccess.get_file_as_string(_WRITE_TMP)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_WRITE_TMP))
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("Nyx: could not write graph to %s" % path)
		return false
	f.store_string(text)
	f.close()
	if path.begins_with("res://"):
		EditorInterface.get_resource_filesystem().update_file(path)
	return true


# Reads a `.nyx` file back into a serialize-dict. Returns null on failure (bad path or
# not a NyxGraph resource), so callers can guard before handing it to _deserialize_graph.
static func read(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("Nyx: could not read graph from %s" % path)
		return null
	var text := FileAccess.get_file_as_string(path)
	var f := FileAccess.open(_READ_TMP, FileAccess.WRITE)
	if f == null:
		push_error("Nyx: could not read graph from %s" % path)
		return null
	f.store_string(text)
	f.close()
	var graph = ResourceLoader.load(_READ_TMP, "", ResourceLoader.CACHE_MODE_IGNORE)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_READ_TMP))
	if graph == null or not graph is NyxGraphRes:
		push_error("Nyx: could not read graph from %s" % path)
		return null
	return resource_to_dict(graph)


static func dict_to_resource(d: Dictionary) -> NyxGraphRes:
	var graph := NyxGraphRes.new()
	graph.shader_type = d.get("shader_type", 0)
	graph.exported_shader_path = d.get("exported_shader_path", "")
	graph.compiled_code = d.get("compiled_code", "")
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


# Writes a compiled .gdshader with a provenance stamp on line 1 (read back by
# NyxCharon.read_nyx_source - gates artifact->Nyx navigation). nyx_path may be ""
# if the graph is unsaved (stamp is omitted).
const _Registry = preload("res://addons/nyx/nyx_registry.gd")


# Serialises the currently selected (non-sink) nodes + the connections between
# them into a {nodes, connections} dict - the same format used by the clipboard.
# Pass _graph.get_children() and _graph.get_connection_list() from the caller.
static func serialize_selected(graph: GraphEdit) -> Dictionary:
	var selected := {}
	var nodes := []
	for child in graph.get_children():
		if not child is GraphNode or not child.selected or _Registry.is_sink(child):
			continue
		var type := _Registry.get_node_type(child)
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
	for conn in graph.get_connection_list():
		if selected.has(str(conn["from_node"])) and selected.has(str(conn["to_node"])):
			connections.append({
				"from_node": str(conn["from_node"]),
				"from_port": conn["from_port"],
				"to_node": str(conn["to_node"]),
				"to_port": conn["to_port"],
			})
	return {"nodes": nodes, "connections": connections}


# graph_dict is the live _serialize_graph() dict, embedded as a single-line JSON
# comment block at the end of the file - a recovery path for when nyx_path gets
# deleted/moved/never-shipped (see charon.gd's GRAPH_BEGIN/GRAPH_END doc). Only
# written alongside the stamp (nyx_path non-empty) - a shader exported before
# any `.nyx` was ever saved has no stamp and is out of scope for this recovery,
# same as before.
static func write_shader(path: String, code: String, nyx_path: String, graph_dict: Dictionary) -> bool:
	var out := code
	if not nyx_path.is_empty():
		const CHARON = preload("res://addons/nyx/core/charon.gd")
		var header := "%s%s\n" % [CHARON.PROVENANCE_PREFIX, nyx_path]
		header += "// Generated by Nyx - hand edits here are overwritten on the next Update.\n"
		header += "// Don't modify this header or the nyx_graph block below - they're what\n"
		header += "// lets Nyx reopen this file's graph (right-click it in the FileSystem\n"
		header += "// dock and choose \"Open in Nyx\").\n"
		var footer := "\n%s\n// %s\n%s\n" % [CHARON.GRAPH_BEGIN, JSON.stringify(graph_dict), CHARON.GRAPH_END]
		out = header + code + footer
	var f := FileAccess.open(path, FileAccess.WRITE)
	if not f:
		push_error("Nyx: could not write shader to %s" % path)
		return false
	f.store_string(out)
	f.close()
	return true


# Writes the companion .tres ShaderMaterial next to the shader. Bakes texture /
# sub-resource / float-param values - overwrites any existing material values.
# graph_children = _graph.get_children() (passed by caller; no graph ref here).
static func write_material(shader_path: String, graph_children: Array) -> bool:
	var file_tex_nodes := []
	var sub_nodes := []
	var value_param_nodes := []
	for child in graph_children:
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
	lines.append("[ext_resource type=\"Shader\" path=\"%s\" id=\"1\"]" % shader_path)

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

	var tres_path := shader_path.get_basename() + ".tres"
	var tf := FileAccess.open(tres_path, FileAccess.WRITE)
	if not tf:
		push_error("Nyx: could not write material to %s" % tres_path)
		return false
	tf.store_string("\n".join(lines))
	tf.close()
	return true


static func resource_to_dict(graph: NyxGraphRes) -> Dictionary:
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
		"exported_shader_path": graph.exported_shader_path,
		"compiled_code": graph.compiled_code,
	}
