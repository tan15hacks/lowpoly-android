extends Area3D

signal plate_pressed
signal plate_released

var bodies_on_plate: Array[Node3D] = []
var is_pressed: bool = false

@onready var plate_mesh: MeshInstance3D = $PlateMesh

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if _can_trigger(body) and not bodies_on_plate.has(body):
		bodies_on_plate.append(body)
		_update_state()

func _on_body_exited(body: Node3D) -> void:
	if bodies_on_plate.has(body):
		bodies_on_plate.erase(body)
		_update_state()

func _can_trigger(body: Node3D) -> bool:
	return body is CharacterBody3D

func _update_state() -> void:
	var new_pressed := bodies_on_plate.size() > 0
	if new_pressed == is_pressed:
		return
	is_pressed = new_pressed
	if is_pressed:
		plate_mesh.position.y = -0.08
		plate_pressed.emit()
	else:
		plate_mesh.position.y = 0.0
		plate_released.emit()
