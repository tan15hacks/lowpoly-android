extends CharacterBody3D

@export var speed: float = 5.6
@export var acceleration: float = 18.0
@export var air_acceleration: float = 8.0
@export var jump_velocity: float = 4.9
@export var look_sensitivity: float = 0.003
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12
@export var character_model_path: String = "res://assets/characters/skater/characterMedium.fbx"
@export var character_skin_path: String = "res://assets/characters/skater/skaterMaleA.png"
@export var model_scale: float = 0.95
@export var show_local_body_in_first_person: bool = false

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var pitch: float = 0.0
var mobile_move_vector: Vector2 = Vector2.ZERO
var mobile_jump_requested: bool = false
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var visual_root: Node3D

@onready var head: Node3D = $Head

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_setup_character_visual()

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

	_update_visual_facing(direction, delta)
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

func _setup_character_visual() -> void:
	var placeholder := get_node_or_null("Body")
	if placeholder:
		placeholder.visible = false

	if not show_local_body_in_first_person:
		return

	if not ResourceLoader.exists(character_model_path):
		if placeholder:
			placeholder.visible = true
		print("Skater character model missing: ", character_model_path)
		return

	var packed_scene := load(character_model_path)
	if packed_scene == null:
		if placeholder:
			placeholder.visible = true
		print("Failed to load character model: ", character_model_path)
		return

	visual_root = packed_scene.instantiate()
	visual_root.name = "SkaterCharacter"
	visual_root.scale = Vector3.ONE * model_scale
	visual_root.position = Vector3(0, -1.15, -0.18)
	visual_root.rotation.y = PI
	add_child(visual_root)
	_apply_skater_skin(visual_root)

func _apply_skater_skin(root: Node) -> void:
	if not ResourceLoader.exists(character_skin_path):
		print("Skater skin missing: ", character_skin_path)
		return

	var texture := load(character_skin_path)
	if texture == null:
		return

	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.roughness = 0.85
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_apply_material_to_meshes(root, material)

func _apply_material_to_meshes(node: Node, material: Material) -> void:
	if node is MeshInstance3D:
		node.set_surface_override_material(0, material)
	for child in node.get_children():
		_apply_material_to_meshes(child, material)

func _update_visual_facing(direction: Vector3, delta: float) -> void:
	if visual_root == null or direction.length() < 0.05:
		return
	var target_yaw := atan2(direction.x, direction.z) + PI
	visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_yaw, min(delta * 12.0, 1.0))

func _on_mobile_move_changed(direction: Vector2) -> void:
	mobile_move_vector = direction

func _on_mobile_look_changed(delta: Vector2) -> void:
	_apply_look(delta)

func _on_mobile_jump_pressed() -> void:
	mobile_jump_requested = true
