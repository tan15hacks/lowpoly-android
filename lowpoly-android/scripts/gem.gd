extends Area3D

signal collected

@export var spin_speed: float = 3.4
@export var bob_height: float = 0.18
@export var bob_speed: float = 3.0

var start_y: float = 0.0
var time: float = 0.0
var already_collected: bool = false

func _ready() -> void:
	start_y = position.y
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	time += delta
	rotate_y(spin_speed * delta)
	position.y = start_y + sin(time * bob_speed) * bob_height

func _on_body_entered(body: Node3D) -> void:
	if already_collected:
		return
	if body is CharacterBody3D and not body.name.contains("Echo"):
		already_collected = true
		collected.emit()
		queue_free()
