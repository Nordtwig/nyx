@tool
class_name NyxNodeData
extends Resource

## One node inside a NyxGraph. Type + name + position are typed; the node's
## own UI state stays a Dictionary (the get_state()/set_state() payload), so
## nodes don't need a parallel typed schema and node UX can churn freely.

@export var type: String = ""
@export var node_name: String = ""
@export var position: Vector2 = Vector2.ZERO
@export var state: Dictionary = {}
