extends Node3D

@export var level_time: float = 120.0

var gems_collected: int = 0
var total_gems: int = 0
var time_left: float = 0.0
var level_finished: bool = false
var portal_active: bool = false
var echo_status: String = "Record an echo standing on the orange plate."

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

	if player.has_method("connect_mobile_controls"):
		player.connect_mobile_controls(mobile_controls)

	if mobile_controls.has_signal("record_pressed"):
		mobile_controls.record_pressed.connect(_on_record_pressed)

	if echo_recorder.has_method("setup"):
		echo_recorder.setup(player)
	if echo_recorder.has_signal("recording_started"):
		echo_recorder.recording_started.connect(_on_echo_recording_started)
	if echo_recorder.has_signal("recording_finished"):
		echo_recorder.recording_finished.connect(_on_echo_recording_finished)
	if echo_recorder.has_signal("replay_started"):
		echo_recorder.replay_started.connect(_on_echo_replay_started)

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
	if portal.has_method("set_active"):
		portal.set_active(false)

	_update_hud()

func _process(delta: float) -> void:
	if level_finished:
		return
	time_left = max(time_left - delta, 0.0)
	if time_left <= 0.0:
		level_finished = true
		objective_label.text = "Time's up!"
	_update_hud()

func _on_record_pressed() -> void:
	if level_finished:
		return
	if echo_recorder.has_method("start_recording"):
		echo_recorder.start_recording()

func _on_echo_recording_started() -> void:
	echo_status = "Recording... stand on the plate or move for 5 seconds."
	_update_hud()

func _on_echo_recording_finished(_frames: Array) -> void:
	echo_status = "Echo created. Let it hold the plate, then pass the door."
	_update_hud()

func _on_echo_replay_started() -> void:
	echo_status = "Echo replaying. Use it to solve the door puzzle."
	_update_hud()

func _on_plate_pressed() -> void:
	if puzzle_door.has_method("set_open"):
		puzzle_door.set_open(true)
	echo_status = "Plate pressed. Door open."
	_update_hud()

func _on_plate_released() -> void:
	if puzzle_door.has_method("set_open"):
		puzzle_door.set_open(false)
	echo_status = "Plate released. Door closed. Use your echo."
	_update_hud()

func _on_gem_collected() -> void:
	if level_finished:
		return
	gems_collected += 1
	if gems_collected >= total_gems and not portal_active:
		portal_active = true
		if portal.has_method("set_active"):
			portal.set_active(true)
	_update_hud()

func _on_portal_entered() -> void:
	if portal_active and not level_finished:
		level_finished = true
		objective_label.text = "LEVEL COMPLETE!"

func _update_hud() -> void:
	timer_label.text = "Time: %02d" % int(ceil(time_left))
	echo_label.text = echo_status
	if level_finished:
		return
	if portal_active:
		objective_label.text = "Portal active! Enter the purple ring."
	else:
		objective_label.text = "Use echo + plate to pass the door. Gems: %d / %d" % [gems_collected, total_gems]
