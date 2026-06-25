@tool
@icon("res://addons/nyx/icons/nyx.svg")
class_name NyxGraph
extends Resource

## The `.nyx` working file as a native Godot Resource (hybrid model): typed
## top-level structure, with each node's state kept as a Dictionary so the
## existing get_state()/set_state() seam is reused unchanged. Saved/loaded via
## the custom `.nyx` ResourceFormatSaver/Loader (see core/nyx_format_*.gd).
##
## `version` is here for future migrations — if the format ever changes, old
## files can be upgraded on load rather than broken.

@export var version: int = 1
@export var shader_type: int = 0
@export var linked_shader_path: String = ""
@export var nodes: Array = []        # of NyxNodeData
@export var connections: Array = []  # of { from_node, from_port, to_node, to_port }
