extends CharacterBody3D

@export var speed: float = 5.0
@export var acceleration: float = 12.0
@export var jump_velocity: float = 4.5
@export var look_sensitivity: float = 0.003

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var pitch: float = 0.0
var mobile_move_vector: Vector2 = Vector2.ZERO
var mobile_jump_requested: bool = false

@onready var head: Node3D = $Head

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func connect_mobile_controls(controls: CanvasLayer) -> void:
	controls.move_changed.connect(_on_mobile_move_changed)
	controls.look_changed.connect(_on_mobile_look_changed)
	controls.jump_pressed.connect(_on_mobile_jump_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_apply_look(Vector2(event.relative.x * look_sensitivity, event.relative.y * look_sensitivity))

	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if (Input.is_action_just_pressed("jump") or mobile_jump_requested) and is_on_floor():
		velocity.y = jump_velocity
	mobile_jump_requested = false

	var keyboard_input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var input_dir := keyboard_input
	if mobile_move_vector.length() > 0.05:
		input_dir = Vector2(mobile_move_vector.x, mobile_move_vector.y)

	var direction := (global_transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	var target_x := direction.x * speed
	var target_z := direction.z * speed
	velocity.x = move_toward(velocity.x, target_x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_z, acceleration * delta)

	move_and_slide()

func _apply_look(delta: Vector2) -> void:
	rotate_y(-delta.x)
	pitch = clamp(pitch - delta.y, deg_to_rad(-80), deg_to_rad(80))
	head.rotation.x = pitch

func _on_mobile_move_changed(direction: Vector2) -> void:
	mobile_move_vector = direction

func _on_mobile_look_changed(delta: Vector2) -> void:
	_apply_look(delta)

func _on_mobile_jump_pressed() -> void:
	mobile_jump_requested = true
