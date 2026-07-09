extends CharacterBody3D

@export var speed: float = 5.0
@export var acceleration: float = 12.0
@export var jump_velocity: float = 4.5
@export var look_sensitivity: float = 0.003

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var pitch: float = 0.0

@onready var head: Node3D = $Head

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * look_sensitivity)
		pitch = clamp(pitch - event.relative.y * look_sensitivity, deg_to_rad(-80), deg_to_rad(80))
		head.rotation.x = pitch

	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (global_transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	var target_x := direction.x * speed
	var target_z := direction.z * speed
	velocity.x = move_toward(velocity.x, target_x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_z, acceleration * delta)

	move_and_slide()
