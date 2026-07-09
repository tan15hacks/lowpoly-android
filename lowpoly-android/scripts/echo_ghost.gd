extends CharacterBody3D

signal replay_finished

@export var character_model_path: String = "res://assets/characters/skater/characterMedium.fbx"
@export var character_skin_path: String = "res://assets/characters/skater/skaterMaleA.png"
@export var idle_animation_path: String = "res://assets/characters/skater/idle.fbx"
@export var run_animation_path: String = "res://assets/characters/skater/run.fbx"
@export var jump_animation_path: String = "res://assets/characters/skater/jump.fbx"
@export var model_scale: float = 0.95

var frames: Array = []
var frame_index: int = 0
var replay_speed: float = 1.0
var elapsed: float = 0.0
var last_position: Vector3 = Vector3.ZERO
var current_state: String = ""
var visuals: Dictionary = {}
var state_players: Dictionary = {}
var state_animation_names: Dictionary = {}

@onready var body: MeshInstance3D = $Body

func _ready() -> void:
	_setup_echo_visuals()

func start_replay(recorded_frames: Array) -> void:
	frames = recorded_frames.duplicate(true)
	frame_index = 0
	elapsed = 0.0
	if frames.is_empty():
		replay_finished.emit()
		queue_free()
		return
	_apply_frame(frames[0])
	last_position = global_position
	_set_visual_state("idle")

func _physics_process(delta: float) -> void:
	if frames.is_empty():
		return

	last_position = global_position
	elapsed += delta * replay_speed
	while frame_index < frames.size() - 1 and frames[frame_index + 1]["time"] <= elapsed:
		frame_index += 1

	if frame_index >= frames.size() - 1:
		_apply_frame(frames.back())
		_set_visual_state("idle")
		replay_finished.emit()
		queue_free()
		return

	var current: Dictionary = frames[frame_index]
	var next: Dictionary = frames[frame_index + 1]
	var span: float = max(next["time"] - current["time"], 0.001)
	var t: float = clamp((elapsed - current["time"]) / span, 0.0, 1.0)

	global_position = current["position"].lerp(next["position"], t)
	global_rotation = current["rotation"].lerp(next["rotation"], t)
	_update_echo_state(delta)

func _apply_frame(frame: Dictionary) -> void:
	global_position = frame["position"]
	global_rotation = frame["rotation"]

func _setup_echo_visuals() -> void:
	if body:
		body.visible = false

	_create_visual_state("idle", idle_animation_path)
	_create_visual_state("run", run_animation_path)
	_create_visual_state("jump", jump_animation_path)

	if visuals.is_empty():
		_create_visual_state("idle", character_model_path)

	if visuals.is_empty():
		if body:
			body.visible = true
		print("Echo has no valid skater visual assets.")
		return

	_set_visual_state("idle")

func _create_visual_state(state_name: String, path: String) -> void:
	if not ResourceLoader.exists(path):
		print("Echo visual state missing: ", path)
		return

	var packed_scene: PackedScene = load(path)
	if packed_scene == null:
		return

	var instance: Node3D = packed_scene.instantiate() as Node3D
	if instance == null:
		return

	instance.name = "EchoState_" + state_name
	instance.scale = Vector3.ONE * model_scale
	instance.position = Vector3(0, -1.15, -0.18)
	instance.rotation.y = PI
	instance.visible = false
	add_child(instance)

	_apply_echo_skin(instance)
	visuals[state_name] = instance

	var player: AnimationPlayer = _find_animation_player(instance)
	if player != null:
		state_players[state_name] = player
		var animation_names: PackedStringArray = player.get_animation_list()
		if animation_names.size() > 0:
			state_animation_names[state_name] = String(animation_names[0])

func _set_visual_state(state_name: String) -> void:
	if not visuals.has(state_name):
		state_name = "idle"
	if not visuals.has(state_name):
		return

	if current_state == state_name:
		return

	for key in visuals.keys():
		var visual_node: Node3D = visuals[key] as Node3D
		if visual_node != null:
			visual_node.visible = false

	var active_visual: Node3D = visuals[state_name] as Node3D
	if active_visual != null:
		active_visual.visible = true

	current_state = state_name
	_play_state_animation(state_name)

func _play_state_animation(state_name: String) -> void:
	if not state_players.has(state_name) or not state_animation_names.has(state_name):
		return
	var player: AnimationPlayer = state_players[state_name] as AnimationPlayer
	var animation_name: String = state_animation_names[state_name]
	if player != null and player.has_animation(animation_name):
		player.play(animation_name)

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found: AnimationPlayer = _find_animation_player(child)
		if found != null:
			return found
	return null

func _update_echo_state(delta: float) -> void:
	var movement: Vector3 = global_position - last_position
	var horizontal_speed: float = Vector2(movement.x, movement.z).length() / max(delta, 0.001)
	var vertical_speed: float = abs(movement.y) / max(delta, 0.001)

	if vertical_speed > 0.8:
		_set_visual_state("jump")
	elif horizontal_speed > 0.25:
		_set_visual_state("run")
	else:
		_set_visual_state("idle")

func _apply_echo_skin(root: Node) -> void:
	var material := StandardMaterial3D.new()
	if ResourceLoader.exists(character_skin_path):
		var texture: Texture2D = load(character_skin_path)
		if texture:
			material.albedo_texture = texture
	material.albedo_color = Color(0.45, 0.95, 1.0, 1.0)
	material.emission_enabled = true
	material.emission = Color(0.05, 0.45, 0.9, 1.0)
	material.emission_energy_multiplier = 0.35
	material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 0.8
	_apply_material_to_meshes(root, material)

func _apply_material_to_meshes(node: Node, material: Material) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).visible = true
		(node as MeshInstance3D).set_surface_override_material(0, material)
	for child in node.get_children():
		_apply_material_to_meshes(child, material)
