@tool
extends "res://addons/nyx/nodes/particle_sink_node.gd"

# Particle Start sink — runs once when a particle (re)spawns. Initial values.
# Decomposed TRANSFORM (Position / Scale / Rotation) recomposed by the compiler
# via nyx_compose_transform(). Unconnected slots fall back to sensible defaults
# (Position 0, Velocity 0, Color white, Scale 1, Rotation 0).
# Fixed node name "ParticleStartNode" so the compiler can find it.

const _LABELS := ["Position", "Velocity", "Color", "Scale", "Rotation"]


func _ready() -> void:
	super._ready()
	title = "Particle Start"
	var vec3_color := _type_color(0)
	var vec4_color := _type_color(3)

	# Type IDs: 0 = vec3, 3 = vec4.
	set_slot(0, true, 0, vec3_color, false, -1, vec3_color)  # Position
	set_slot(1, true, 0, vec3_color, false, -1, vec3_color)  # Velocity
	set_slot(2, true, 3, vec4_color, false, -1, vec4_color)  # Color
	set_slot(3, true, 0, vec3_color, false, -1, vec3_color)  # Scale
	set_slot(4, true, 0, vec3_color, false, -1, vec3_color)  # Rotation

	for label_text in _LABELS:
		var label := Label.new()
		label.text = label_text
		add_child(label)
