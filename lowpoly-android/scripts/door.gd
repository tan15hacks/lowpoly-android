extends StaticBody3D

@export var closed_position: Vector3 = Vector3.ZERO
@export var open_offset: Vector3 = Vector3(0, 4, 0)
@export var move_speed: float = 5.0

var is_open: bool = false
var target_position: Vector3

func _ready() -> void:
	closed_position = position
	target_position = closed_position

func _process(delta: float) -> void:
	position = position.lerp(target_position, clamp(move_speed * delta, 0.0, 1.0))

func set_open(value: bool) -> void:
	is_open = value
	target_position = closed_position + open_offset if is_open else closed_position
