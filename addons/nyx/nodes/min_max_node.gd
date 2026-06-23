@tool
extends "res://addons/nyx/nodes/nyx_node.gd"

var _type: int = 0
var _option_btn: OptionButton


func _ready() -> void:
	super._ready()
	title = "Min Max"

	var label_a := Label.new()
	label_a.text = "A"
	add_child(label_a)

	var label_b := Label.new()
	label_b.text = "B"
	add_child(label_b)

	set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)
	set_slot(1, true, 0, Color.WHITE, false, -1, Color.WHITE)

	_option_btn = OptionButton.new()
	_option_btn.add_item("Min")
	_option_btn.add_item("Max")
	_option_btn.selected = _type
	_option_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_option_btn.item_selected.connect(_on_type_selected)
	add_child(_option_btn)


func _on_type_selected(idx: int) -> void:
	emit_signal("edit_started")
	_type = idx
	emit_signal("value_changed")


func is_polymorphic() -> bool:
	return true

func get_shader_snippet(inputs: Array = []) -> String:
	var op := "min" if _type == 0 else "max"
	return "%s(%s, %s)" % [op, inputs[0], inputs[1]]

func get_default_inputs() -> Array:
	return ["0.0", "0.0"]

func get_default_input_types() -> Array:
	return [1, 1]


func get_state() -> Dictionary:
	return {"type": _type}


func set_state(state: Dictionary) -> void:
	_type = state.get("type", 0)
	_option_btn.selected = _type
