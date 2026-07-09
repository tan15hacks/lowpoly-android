extends Node3D

@export var level_time: float = 90.0

var gems_collected: int = 0
var total_gems: int = 0
var time_left: float = 0.0
var level_finished: bool = false
var portal_active: bool = false

@onready var player: CharacterBody3D = $Player
@onready var mobile_controls: CanvasLayer = $MobileControls
@onready var objective_label: Label = $HUD/ObjectiveLabel
@onready var timer_label: Label = $HUD/TimerLabel
@onready var portal: Area3D = $Portal

func _ready() -> void:
	time_left = level_time

	if player.has_method("connect_mobile_controls"):
		player.connect_mobile_controls(mobile_controls)

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
		objective_label.text = "Time's up! Pull again after restart feature."
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
	if level_finished:
		return
	if portal_active:
		objective_label.text = "Portal active! Enter the purple ring."
	else:
		objective_label.text = "Collect gems: %d / %d" % [gems_collected, total_gems]
