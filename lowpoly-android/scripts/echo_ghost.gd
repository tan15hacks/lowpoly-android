extends CharacterBody3D

signal replay_finished

@export var character_model_path: String = "res://assets/characters/skater/characterMedium.fbx"
@export var character_skin_path: String = "res://assets/characters/skater/skaterMaleA.png"
@export var model_scale: float = 0.95

var frames: Array = []
var frame_index: int = 0
var replay_speed: float = 1.0
var elapsed: float = 0.0
var last_position: Vector3 = Vector3.ZERO
var visual_root: Node3D
var visual_start_y: float = 0.0
var bob_time: float = 0.0

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

func _physics_process(delta: float) -> void:
	if frames.is_empty():
		return

	last_position = global_position
	elapsed += delta * replay_speed
	while frame_index < frames.size() - 1 and frames[frame_index + 1]["time"] <= elapsed:
		frame_index += 1

	if frame_index >= frames.size() - 1:
		_apply_frame(frames.back())
		replay_finished.emit()
		queue_free()
		return

	var current: Dictionary = frames[frame_index]
	var next: Dictionary = frames[frame_index + 1]
	var span: float = max(next["time"] - current["time"], 0.001)
	var t: float = clamp((elapsed - current["time"]) / span, 0.0, 1.0)

	global_position = current["position"].lerp(next["position"], t)
	global_rotation = current["rotation"].lerp(next["rotation"], t)
	_update_procedural_visual(delta)

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
	visual_root.position = Vector3(0, -1.15, -0.18)
	visual_root.rotation.y = PI
	visual_start_y = visual_root.position.y
	add_child(visual_root)
	_apply_echo_skin(visual_root)

func _update_procedural_visual(delta: float) -> void:
	if visual_root == null:
		return

	var movement: Vector3 = global_position - last_position
	var horizontal_speed: float = Vector2(movement.x, movement.z).length() / max(delta, 0.001)
	bob_time += delta * clamp(horizontal_speed * 4.0, 1.0, 12.0)

	var bob_amount: float = 0.0
	var lean_amount: float = 0.0
	if horizontal_speed > 0.25:
		bob_amount = sin(bob_time) * 0.045
		lean_amount = -0.12

	visual_root.position.y = visual_start_y + bob_amount
	visual_root.rotation.x = lerp(visual_root.rotation.x, lean_amount, min(delta * 10.0, 1.0))

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
