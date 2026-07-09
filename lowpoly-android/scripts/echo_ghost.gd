extends CharacterBody3D

signal replay_finished

@export var character_model_path: String = "res://assets/characters/skater/characterMedium.fbx"
@export var character_skin_path: String = "res://assets/characters/skater/skaterMaleA.png"
@export var idle_animation_path: String = "res://assets/characters/skater/idle.fbx"
@export var run_animation_path: String = "res://assets/characters/skater/run.fbx"
@export var jump_animation_path: String = "res://assets/characters/skater/jump.fbx"
@export var model_scale: float = 0.95
@export var echo_alpha: float = 0.55

var frames: Array = []
var frame_index: int = 0
var replay_speed: float = 1.0
var elapsed: float = 0.0
var visual_root: Node3D
var animation_player: AnimationPlayer
var current_anim: String = ""
var last_position: Vector3 = Vector3.ZERO

@onready var body: MeshInstance3D = $Body

func _ready() -> void:
	_setup_echo_visual()

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
	_play_anim("idle")

func _physics_process(delta: float) -> void:
	if frames.is_empty():
		return

	last_position = global_position
	elapsed += delta * replay_speed
	while frame_index < frames.size() - 1 and frames[frame_index + 1]["time"] <= elapsed:
		frame_index += 1

	if frame_index >= frames.size() - 1:
		_apply_frame(frames.back())
		_play_anim("idle")
		replay_finished.emit()
		queue_free()
		return

	var current: Dictionary = frames[frame_index]
	var next: Dictionary = frames[frame_index + 1]
	var span: float = max(next["time"] - current["time"], 0.001)
	var t: float = clamp((elapsed - current["time"]) / span, 0.0, 1.0)

	global_position = current["position"].lerp(next["position"], t)
	global_rotation = current["rotation"].lerp(next["rotation"], t)
	_update_echo_animation(delta)

func _apply_frame(frame: Dictionary) -> void:
	global_position = frame["position"]
	global_rotation = frame["rotation"]

func _setup_echo_visual() -> void:
	if body:
		body.visible = false

	if not ResourceLoader.exists(character_model_path):
		if body:
			body.visible = true
		print("Echo skater model missing: ", character_model_path)
		return

	var packed_scene := load(character_model_path)
	if packed_scene == null:
		if body:
			body.visible = true
		return

	visual_root = packed_scene.instantiate()
	visual_root.name = "EchoSkaterCharacter"
	visual_root.scale = Vector3.ONE * model_scale
	visual_root.position = Vector3(0, -1.15, -0.18)
	visual_root.rotation.y = PI
	add_child(visual_root)
	_apply_echo_skin(visual_root)
	_setup_animation_player()

func _setup_animation_player() -> void:
	animation_player = _find_animation_player(visual_root)
	if animation_player == null:
		animation_player = AnimationPlayer.new()
		animation_player.name = "AnimationPlayer"
		animation_player.root_node = NodePath("..")
		visual_root.add_child(animation_player)

	var lib := AnimationLibrary.new()
	_add_external_animation_to_library(lib, "idle", idle_animation_path, true)
	_add_external_animation_to_library(lib, "run", run_animation_path, true)
	_add_external_animation_to_library(lib, "jump", jump_animation_path, false)
	if lib.get_animation_list().size() > 0:
		if animation_player.has_animation_library("echo"):
			animation_player.remove_animation_library("echo")
		animation_player.add_animation_library("echo", lib)
		_play_anim("idle")

func _add_external_animation_to_library(target_library: AnimationLibrary, clip_name: String, path: String, loop: bool) -> void:
	if not ResourceLoader.exists(path):
		print("Animation file missing: ", path)
		return
	var scene := load(path)
	if scene == null:
		return
	var instance := scene.instantiate()
	var source_player := _find_animation_player(instance)
	if source_player == null:
		instance.queue_free()
		return
	var copied := false
	for library_name in source_player.get_animation_library_list():
		var source_library := source_player.get_animation_library(library_name)
		for animation_name in source_library.get_animation_list():
			var animation := source_library.get_animation(animation_name).duplicate(true)
			animation.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
			target_library.add_animation(clip_name, animation)
			copied = true
			break
		if copied:
			break
	instance.queue_free()

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found:
			return found
	return null

func _update_echo_animation(delta: float) -> void:
	var movement := global_position - last_position
	var horizontal_speed := Vector2(movement.x, movement.z).length() / max(delta, 0.001)
	var vertical_speed := abs(movement.y) / max(delta, 0.001)
	if vertical_speed > 0.8:
		_play_anim("jump")
	elif horizontal_speed > 0.25:
		_play_anim("run")
	else:
		_play_anim("idle")

func _play_anim(name: String) -> void:
	if animation_player == null or current_anim == name:
		return
	var full_name := "echo/" + name
	if animation_player.has_animation(full_name):
		animation_player.play(full_name)
		current_anim = name

func _apply_echo_skin(root: Node) -> void:
	var material := StandardMaterial3D.new()
	if ResourceLoader.exists(character_skin_path):
		var texture := load(character_skin_path)
		if texture:
			material.albedo_texture = texture
	material.albedo_color = Color(0.2, 0.9, 1.0, echo_alpha)
	material.emission_enabled = true
	material.emission = Color(0.05, 0.55, 1.0, 1.0)
	material.emission_energy_multiplier = 0.65
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 0.8
	_apply_material_to_meshes(root, material)

func _apply_material_to_meshes(node: Node, material: Material) -> void:
	if node is MeshInstance3D:
		node.set_surface_override_material(0, material)
	for child in node.get_children():
		_apply_material_to_meshes(child, material)
