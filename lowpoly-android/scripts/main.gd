extends Node3D

var gems_collected: int = 0
var total_gems: int = 0

@onready var player: CharacterBody3D = $Player
@onready var mobile_controls: CanvasLayer = $MobileControls
@onready var objective_label: Label = $HUD/ObjectiveLabel

func _ready() -> void:
	if player.has_method("connect_mobile_controls"):
		player.connect_mobile_controls(mobile_controls)

	var gems := get_tree().get_nodes_in_group("gems")
	total_gems = gems.size()
	for gem in gems:
		if gem.has_signal("collected"):
			gem.collected.connect(_on_gem_collected)
	_update_objective()

func _on_gem_collected() -> void:
	gems_collected += 1
	_update_objective()

func _update_objective() -> void:
	if gems_collected >= total_gems and total_gems > 0:
		objective_label.text = "All gems collected! Prototype clear."
	else:
		objective_label.text = "Collect gems: %d / %d" % [gems_collected, total_gems]
