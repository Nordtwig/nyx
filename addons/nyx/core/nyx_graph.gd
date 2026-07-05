@tool
@icon("res://addons/nyx/icons/nyx.svg")
class_name NyxGraph
extends Resource

## The `.nyx` working file as a native Godot Resource (hybrid model): typed
## top-level structure, with each node's state kept as a Dictionary so the
## existing get_state()/set_state() seam is reused unchanged. Read/written via
## NyxSerializer's private temp-.tres round trip (see nyx_serializer.gd) - no
## longer a registered ResourceFormatSaver/Loader; `.nyx` is imported directly
## as a Shader (core/nyx_shader_importer.gd), which is why this class is not
## the resource type `.nyx` files load as anymore.
##
## `version` is here for future migrations - if the format ever changes, old
## files can be upgraded on load rather than broken.

@export var version: int = 1
@export var shader_type: int = 0
@export var exported_shader_path: String = ""  # optional exported .gdshader ("" = none exported yet)
@export var compiled_code: String = ""  # baked shader source, written at save; consumed by the importer
@export var nodes: Array = []        # of NyxNodeData
@export var connections: Array = []  # of { from_node, from_port, to_node, to_port }
