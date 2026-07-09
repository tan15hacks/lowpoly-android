extends Node3D

@onready var player: CharacterBody3D = $Player
@onready var mobile_controls: CanvasLayer = $MobileControls

func _ready() -> void:
	if player.has_method("connect_mobile_controls"):
		player.connect_mobile_controls(mobile_controls)
