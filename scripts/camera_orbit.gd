extends Camera3D

@export var target := Vector3.ZERO
@export var distance := 5.0
@export var orbit_speed := 0.3
@export var zoom_speed := 0.5
@export var min_distance := 0.5
@export var max_distance := 50.0
@export var move_speed := 3.0

var _yaw := 0.0
var _pitch := 20.0
var _dragging := false


func _ready() -> void:
	_update_transform()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				_dragging = event.pressed
			MOUSE_BUTTON_WHEEL_UP:
				distance = max(min_distance, distance - zoom_speed)
				_update_transform()
			MOUSE_BUTTON_WHEEL_DOWN:
				distance = min(max_distance, distance + zoom_speed)
				_update_transform()
	elif event is InputEventMouseMotion and _dragging:
		_yaw -= event.relative.x * orbit_speed
		_pitch = clamp(_pitch - event.relative.y * orbit_speed, -89.0, 89.0)
		_update_transform()


func _process(delta: float) -> void:
	var move := Vector2.ZERO
	if Input.is_key_pressed(KEY_W): move.y += 1.0
	if Input.is_key_pressed(KEY_S): move.y -= 1.0
	if Input.is_key_pressed(KEY_A): move.x -= 1.0
	if Input.is_key_pressed(KEY_D): move.x += 1.0
	if move == Vector2.ZERO:
		return
	var yaw := deg_to_rad(_yaw)
	var forward := Vector3(-sin(yaw), 0.0, -cos(yaw))
	var right := Vector3(cos(yaw), 0.0, -sin(yaw))
	target += (forward * move.y + right * move.x) * move_speed * delta
	_update_transform()


func _update_transform() -> void:
	var yaw := deg_to_rad(_yaw)
	var pitch := deg_to_rad(_pitch)
	position = target + Vector3(
		sin(yaw) * cos(pitch),
		sin(pitch),
		cos(yaw) * cos(pitch)
	) * distance
	look_at(target)
