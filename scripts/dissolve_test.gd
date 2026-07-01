extends MeshInstance3D

@export var speed: float = 0.5

var _time: float = 0.0


func _process(delta: float) -> void:
	_time += delta * speed
	var mat := get_active_material(0)
	if mat:
		mat.set_shader_parameter("dissolve", fmod(_time, 1.0))
