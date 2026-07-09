extends CharacterBody3D

@export var speed: float = 5.6
@export var acceleration: float = 18.0
@export var air_acceleration: float = 8.0
@export var jump_velocity: float = 4.9
@export var look_sensitivity: float = 0.003
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var pitch: float = 0.0
var mobile_move_vector: Vector2 = Vector2.ZERO
var mobile_jump_requested: bool = false
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0

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
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer = max(coyote_timer - delta, 0.0)
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") or mobile_jump_requested:
		jump_buffer_timer = jump_buffer_time
	mobile_jump_requested = false
	jump_buffer_timer = max(jump_buffer_timer - delta, 0.0)

	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0

	var keyboard_input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var input_dir := keyboard_input
	if mobile_move_vector.length() > 0.05:
		input_dir = mobile_move_vector.limit_length(1.0)

	var direction := (global_transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	var accel := acceleration if is_on_floor() else air_acceleration
	var target_x := direction.x * speed
	var target_z := direction.z * speed
	velocity.x = move_toward(velocity.x, target_x, accel * delta)
	velocity.z = move_toward(velocity.z, target_z, accel * delta)

	move_and_slide()

func _apply_look(delta: Vector2) -> void:
	rotate_y(-delta.x)
	pitch = clamp(pitch - delta.y, deg_to_rad(-80), deg_to_rad(80))
	head.rotation.x = pitch

func teleport_to(pos: Vector3) -> void:
	global_position = pos
	velocity = Vector3.ZERO

func get_echo_rotation() -> Vector3:
	return Vector3(0.0, global_rotation.y, 0.0)

func _on_mobile_move_changed(direction: Vector2) -> void:
	mobile_move_vector = direction

func _on_mobile_look_changed(delta: Vector2) -> void:
	_apply_look(delta)

func _on_mobile_jump_pressed() -> void:
	mobile_jump_requested = true
