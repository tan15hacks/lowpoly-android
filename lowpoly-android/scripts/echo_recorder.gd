extends Node

signal recording_started
signal recording_finished(frames: Array)
signal replay_started

@export var max_record_time: float = 5.0
@export var echo_scene: PackedScene

var is_recording: bool = false
var record_time: float = 0.0
var frames: Array = []
var target: Node3D

func setup(record_target: Node3D) -> void:
	target = record_target

func start_recording() -> void:
	if target == null or is_recording:
		return
	is_recording = true
	record_time = 0.0
	frames.clear()
	recording_started.emit()

func _physics_process(delta: float) -> void:
	if not is_recording or target == null:
		return

	record_time += delta
	frames.append({
		"time": record_time,
		"position": target.global_position,
		"rotation": target.global_rotation
	})

	if record_time >= max_record_time:
		finish_recording()

func finish_recording() -> void:
	if not is_recording:
		return
	is_recording = false
	recording_finished.emit(frames.duplicate(true))
	_spawn_echo(frames.duplicate(true))

func _spawn_echo(recorded_frames: Array) -> void:
	if echo_scene == null or recorded_frames.is_empty():
		return
	var ghost := echo_scene.instantiate()
	get_tree().current_scene.add_child(ghost)
	if ghost.has_method("start_replay"):
		ghost.start_replay(recorded_frames)
	replay_started.emit()
