extends Area3D

signal collected

@export var spin_speed: float = 2.5

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	rotate_y(spin_speed * delta)

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		collected.emit()
		queue_free()
