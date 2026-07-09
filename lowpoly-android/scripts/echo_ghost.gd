extends CharacterBody3D

signal replay_finished

var frames: Array = []
var frame_index: int = 0
var replay_speed: float = 1.0
var elapsed: float = 0.0

@onready var body: MeshInstance3D = $Body

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

func _apply_frame(frame: Dictionary) -> void:
	global_position = frame["position"]
	global_rotation = frame["rotation"]
