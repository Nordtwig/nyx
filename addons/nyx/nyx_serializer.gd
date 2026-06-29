@tool
extends RefCounted

## Nyx persistence layer — owns the `.nyx` disk format and the dict↔resource bridge.
##
## Stateless (all static). The boundary is deliberate: the live-editor side stays in
## nyx_main — graph→dict via `_serialize_graph`, dict→graph via `_deserialize_graph`
## (the latter is editor-reconstruction orchestration, not serialization). This file
## only knows how to turn a serialize-dict into a NyxGraph resource on disk and back.
##
## The serialize-dict is the single source of truth; save/load go through the resource,
## undo/redo keep using the dict directly. Extracted from nyx_main.gd.

const NyxGraphRes = preload("res://addons/nyx/core/nyx_graph.gd")
const NyxNodeDataRes = preload("res://addons/nyx/core/nyx_node_data.gd")


# Writes a serialize-dict to disk as a native NyxGraph resource (`.nyx`). Returns success.
static func write(path: String, d: Dictionary) -> bool:
	var graph := dict_to_resource(d)
	var err := ResourceSaver.save(graph, path)
	if err != OK:
		push_error("Nyx: could not write graph to %s (err %d)" % [path, err])
		return false
	if path.begins_with("res://"):
		EditorInterface.get_resource_filesystem().update_file(path)
	return true


# Reads a `.nyx` file back into a serialize-dict. Returns null on failure (bad path or
# not a NyxGraph resource), so callers can guard before handing it to _deserialize_graph.
static func read(path: String) -> Variant:
	var graph = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if graph == null or not graph is NyxGraphRes:
		push_error("Nyx: could not read graph from %s" % path)
		return null
	return resource_to_dict(graph)


static func dict_to_resource(d: Dictionary) -> NyxGraphRes:
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
		"linked_shader_path": graph.linked_shader_path,
	}
