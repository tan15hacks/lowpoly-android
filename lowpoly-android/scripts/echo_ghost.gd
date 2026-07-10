extends CharacterBody3D

const ProceduralAnimatorScript = preload("res://scripts/procedural_humanoid_animator.gd")

signal replay_finished

@export var character_model_path: String = "res://assets/characters/skater/characterMedium.fbx"
@export var character_skin_path: String = "res://assets/characters/skater/skaterMaleA.png"
@export var model_scale: float = 0.95
@export var foot_offset_y: float = 0.0

var frames: Array = []
var frame_index: int = 0
var replay_speed: float = 1.0
var elapsed: float = 0.0
var visual_root: Node3D
var procedural_animator: ProceduralHumanoidAnimator

@onready var body: MeshInstance3D = $Body

func _ready() -> void:
	_setup_echo_visual()
	_setup_procedural_animator()

func start_replay(recorded_frames: Array) -> void:
	frames = recorded_frames.duplicate(true)
	frame_index = 0
	elapsed = 0.0
	if frames.is_empty():
		replay_finished.emit()
		queue_free()
		return
	_apply_frame(frames[0])

func _physics_process(delta: float) -> void:
	if frames.is_empty():
		return

	var previous_position: Vector3 = global_position
	elapsed += delta * replay_speed
	while frame_index < frames.size() - 1 and frames[frame_index + 1]["time"] <= elapsed:
		frame_index += 1

	if frame_index >= frames.size() - 1:
		_apply_frame(frames.back())
		if procedural_animator != null:
			procedural_animator.update_animation(delta, 0.0, 0.0, true)
		replay_finished.emit()
		queue_free()
		return

	var current: Dictionary = frames[frame_index]
	var next: Dictionary = frames[frame_index + 1]
	var span: float = max(next["time"] - current["time"], 0.001)
	var t: float = clamp((elapsed - current["time"]) / span, 0.0, 1.0)

	global_position = current["position"].lerp(next["position"], t)
	global_rotation = current["rotation"].lerp(next["rotation"], t)

	if procedural_animator != null:
		var movement: Vector3 = global_position - previous_position
		var horizontal_speed: float = Vector2(movement.x, movement.z).length() / max(delta, 0.001)
		var vertical_velocity: float = movement.y / max(delta, 0.001)
		var appears_grounded: bool = abs(vertical_velocity) < 0.30
		procedural_animator.update_animation(delta, horizontal_speed, vertical_velocity, appears_grounded)

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

	var packed_scene: PackedScene = load(character_model_path)
	if packed_scene == null:
		if body:
			body.visible = true
		return

	visual_root = packed_scene.instantiate() as Node3D
	if visual_root == null:
		if body:
			body.visible = true
		return

	visual_root.name = "EchoSkaterCharacter"
	visual_root.scale = Vector3.ONE * model_scale
	visual_root.position = Vector3(0, foot_offset_y, 0)
	visual_root.rotation.y = PI
	add_child(visual_root)
	_apply_echo_skin(visual_root)

func _setup_procedural_animator() -> void:
	if visual_root == null:
		return
	procedural_animator = ProceduralAnimatorScript.new() as ProceduralHumanoidAnimator
	procedural_animator.name = "ProceduralHumanoidAnimator"
	add_child(procedural_animator)
	procedural_animator.setup(visual_root)

func _apply_echo_skin(root: Node) -> void:
	var material := StandardMaterial3D.new()
	if ResourceLoader.exists(character_skin_path):
		var texture: Texture2D = load(character_skin_path)
		if texture:
			material.albedo_texture = texture
	material.albedo_color = Color(0.6, 1.0, 1.0, 1.0)
	material.emission_enabled = true
	material.emission = Color(0.05, 0.35, 0.9, 1.0)
	material.emission_energy_multiplier = 0.25
	material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 0.8
	_apply_material_to_meshes(root, material)

func _apply_material_to_meshes(node: Node, material: Material) -> void:
	if node is MeshInstance3D:
		var mesh_node := node as MeshInstance3D
		mesh_node.visible = true
		mesh_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		mesh_node.set_surface_override_material(0, material)
	for child in node.get_children():
		_apply_material_to_meshes(child, material)
