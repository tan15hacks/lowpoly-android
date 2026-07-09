extends Node3D

@export var level_time: float = 150.0
@export var spawn_position: Vector3 = Vector3(0, 2, 12)

var gems_collected: int = 0
var total_gems: int = 0
var time_left: float = 0.0
var level_finished: bool = false
var portal_active: bool = false
var door_has_been_opened: bool = false
var echo_status: String = "Goal: record an echo on the orange plate, pass the door, collect 5 gems."
var start_time: float = 0.0
var clear_time: float = 0.0

@onready var player: CharacterBody3D = $Player
@onready var mobile_controls: CanvasLayer = $MobileControls
@onready var objective_label: Label = $HUD/ObjectiveLabel
@onready var timer_label: Label = $HUD/TimerLabel
@onready var echo_label: Label = $HUD/EchoLabel
@onready var portal: Area3D = $Portal
@onready var echo_recorder: Node = $EchoRecorder
@onready var pressure_plate: Area3D = $PressurePlate
@onready var puzzle_door: Node3D = $PuzzleDoor

func _ready() -> void:
	time_left = level_time
	start_time = Time.get_ticks_msec() / 1000.0
	_add_runtime_tree_collisions()
	_add_runtime_level_boundaries()
	_add_runtime_challenge_blocks()
	_style_hud()

	if portal.has_method("set_active"):
		portal.set_active(false)

	if player.has_method("connect_mobile_controls"):
		player.connect_mobile_controls(mobile_controls)
	if player.has_method("teleport_to"):
		player.teleport_to(spawn_position)

	if mobile_controls.has_signal("record_pressed"):
		mobile_controls.record_pressed.connect(_on_record_pressed)
	if mobile_controls.has_signal("reset_pressed"):
		mobile_controls.reset_pressed.connect(_on_reset_pressed)

	if echo_recorder.has_method("setup"):
		echo_recorder.setup(player)
	if echo_recorder.has_signal("recording_started"):
		echo_recorder.recording_started.connect(_on_echo_recording_started)
	if echo_recorder.has_signal("recording_finished"):
		echo_recorder.recording_finished.connect(_on_echo_recording_finished)
	if echo_recorder.has_signal("replay_started"):
		echo_recorder.replay_started.connect(_on_echo_replay_started)
	if echo_recorder.has_signal("recording_blocked"):
		echo_recorder.recording_blocked.connect(_on_echo_recording_blocked)
	if echo_recorder.has_signal("recording_progress"):
		echo_recorder.recording_progress.connect(_on_echo_recording_progress)

	if pressure_plate.has_signal("plate_pressed"):
		pressure_plate.plate_pressed.connect(_on_plate_pressed)
	if pressure_plate.has_signal("plate_released"):
		pressure_plate.plate_released.connect(_on_plate_released)

	var gems := get_tree().get_nodes_in_group("gems")
	total_gems = gems.size()
	for gem in gems:
		if gem.has_signal("collected"):
			gem.collected.connect(_on_gem_collected)

	if portal.has_signal("entered"):
		portal.entered.connect(_on_portal_entered)

	_update_hud()

func _process(delta: float) -> void:
	if level_finished:
		return

	time_left = max(time_left - delta, 0.0)

	if player.global_position.y < -6.0:
		_respawn_player()

	if time_left <= 0.0:
		level_finished = true
		objective_label.text = "Time's up! Press RESET and try a faster echo route."

	_update_hud()

func _on_record_pressed() -> void:
	if level_finished:
		return
	if echo_recorder.has_method("start_recording"):
		echo_recorder.start_recording()

func _on_reset_pressed() -> void:
	get_tree().reload_current_scene()

func _on_echo_recording_started() -> void:
	echo_status = "Recording echo... move to the plate and stand on it."
	_update_hud()

func _on_echo_recording_progress(seconds_left: float) -> void:
	echo_status = "Recording echo: %.1fs left" % seconds_left
	_update_hud()

func _on_echo_recording_finished(_frames: Array) -> void:
	echo_status = "Echo created. When it steps on the plate, sprint through the door."
	_update_hud()

func _on_echo_replay_started() -> void:
	echo_status = "Echo replaying. Watch the door and move fast."
	_update_hud()

func _on_echo_recording_blocked() -> void:
	echo_status = "Already recording. Wait for the echo to finish."
	_update_hud()

func _on_plate_pressed() -> void:
	door_has_been_opened = true
	if puzzle_door.has_method("set_open"):
		puzzle_door.set_open(true)
	echo_status = "Plate pressed. Door open! Go now."
	_update_hud()

func _on_plate_released() -> void:
	if puzzle_door.has_method("set_open"):
		puzzle_door.set_open(false)
	echo_status = "Door closed. Record a better echo or time your run."
	_update_hud()

func _on_gem_collected() -> void:
	if level_finished:
		return
	gems_collected += 1
	if gems_collected >= total_gems and not portal_active:
		portal_active = true
		if portal.has_method("set_active"):
			portal.set_active(true)
		echo_status = "All gems collected. The portal is awake."
	_update_hud()

func _on_portal_entered() -> void:
	if portal_active and not level_finished:
		level_finished = true
		clear_time = (Time.get_ticks_msec() / 1000.0) - start_time
		var rank := _get_clear_rank(clear_time)
		objective_label.text = "LEVEL COMPLETE! Rank %s  Time %.1fs  Press RESET to replay." % [rank, clear_time]
		echo_status = "Try again for a faster rank."

func _update_hud() -> void:
	timer_label.text = "Time: %03d" % int(ceil(time_left))
	echo_label.text = echo_status
	if level_finished:
		return
	if portal_active:
		objective_label.text = "Portal active! Reach the purple ring. Gems: %d / %d" % [gems_collected, total_gems]
	elif not door_has_been_opened:
		objective_label.text = "Tutorial: REC → stand on plate → echo opens door. Gems: %d / %d" % [gems_collected, total_gems]
	else:
		objective_label.text = "Door solved. Collect all gems, then enter the portal. Gems: %d / %d" % [gems_collected, total_gems]

func _respawn_player() -> void:
	echo_status = "You fell. Respawned at the start."
	if player.has_method("teleport_to"):
		player.teleport_to(spawn_position)
	else:
		player.global_position = spawn_position
	_update_hud()

func _get_clear_rank(seconds: float) -> String:
	if seconds <= 35.0:
		return "S"
	if seconds <= 55.0:
		return "A"
	if seconds <= 80.0:
		return "B"
	return "C"

func _style_hud() -> void:
	objective_label.add_theme_font_size_override("font_size", 22)
	timer_label.add_theme_font_size_override("font_size", 22)
	echo_label.add_theme_font_size_override("font_size", 18)

func _add_runtime_tree_collisions() -> void:
	_add_static_box_collision("Tree1TrunkCollision", Vector3(-7, 1.0, -7), Vector3(0.65, 2.0, 0.65))
	_add_static_box_collision("Tree1LeavesCollision", Vector3(-7, 2.5, -7), Vector3(2.1, 2.0, 2.1))
	_add_static_box_collision("Tree2TrunkCollision", Vector3(7, 1.0, 6), Vector3(0.65, 2.0, 0.65))
	_add_static_box_collision("Tree2LeavesCollision", Vector3(7, 2.5, 6), Vector3(2.1, 2.0, 2.1))

func _add_runtime_level_boundaries() -> void:
	_add_static_box_collision("NorthBoundary", Vector3(0, 1.5, -22), Vector3(44, 3, 1))
	_add_static_box_collision("SouthBoundary", Vector3(0, 1.5, 22), Vector3(44, 3, 1))
	_add_static_box_collision("EastBoundary", Vector3(22, 1.5, 0), Vector3(1, 3, 44))
	_add_static_box_collision("WestBoundary", Vector3(-22, 1.5, 0), Vector3(1, 3, 44))

func _add_runtime_challenge_blocks() -> void:
	_add_visible_static_box("ShortcutBlockA", Vector3(4.5, 0.45, 0.5), Vector3(2.5, 0.9, 1.2), Color(0.18, 0.35, 0.24, 1))
	_add_visible_static_box("ShortcutBlockB", Vector3(-4.5, 0.45, -1.2), Vector3(2.5, 0.9, 1.2), Color(0.18, 0.35, 0.24, 1))
	_add_visible_static_box("PortalStep", Vector3(0, 0.3, -12.5), Vector3(3.2, 0.6, 2.0), Color(0.24, 0.20, 0.34, 1))

func _add_static_box_collision(node_name: String, pos: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = pos
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	add_child(body)
	return body

func _add_visible_static_box(node_name: String, pos: Vector3, size: Vector3, color: Color) -> void:
	var body := _add_static_box_collision(node_name, pos, size)
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	mesh_instance.set_surface_override_material(0, material)
	body.add_child(mesh_instance)
